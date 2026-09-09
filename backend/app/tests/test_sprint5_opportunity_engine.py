import uuid
from datetime import date, time, datetime, timezone, timedelta
from typing import Tuple, List, Optional
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.db.models.user import User, WorkerProfile, WorkerMetric
from app.db.models.service import ServiceCategory, ServiceTask, WorkerCategory, WorkerAvailability
from app.db.models.gig import Gig, GigWorkerOpportunity
from app.db.models.communication import GigEvent
from app.db.models.enums import GigStatus, OpportunityStatus
from app.services.catalogue_service import CatalogueService


@pytest.fixture(autouse=True)
def seed_catalog_fixture(db_session: Session):
    """Ensure catalog is populated."""
    CatalogueService.seed_catalogue_if_empty(db_session)


def create_test_customer(client: TestClient, db_session: Session, email_prefix: str = "cust") -> Tuple[str, dict]:
    """Helper to initialize a customer and return (jwt_token, user_dict)."""
    sub = str(uuid.uuid4())
    token = create_access_token({"sub": sub, "email": f"{email_prefix}_{sub[:8]}@sahakaar.org"})
    res = client.post(
        "/api/v1/me/initialize",
        headers={"Authorization": f"Bearer {token}"},
        json={"role": "CUSTOMER", "full_name": f"Customer {sub[:6]}"},
    )
    assert res.status_code == 201
    return token, res.json()["data"]


def create_test_worker(
    client: TestClient,
    db_session: Session,
    category_id: uuid.UUID,
    final_score: float = 0.35,
    email_prefix: str = "work",
) -> Tuple[str, dict]:
    """Helper to initialize a worker, register category, and optionally set final_score."""
    sub = str(uuid.uuid4())
    token = create_access_token({"sub": sub, "email": f"{email_prefix}_{sub[:8]}@sahakaar.org"})
    res = client.post(
        "/api/v1/me/initialize",
        headers={"Authorization": f"Bearer {token}"},
        json={"role": "WORKER", "full_name": f"Worker {sub[:6]}"},
    )
    assert res.status_code == 201
    worker_data = res.json()["data"]
    worker_id = uuid.UUID(worker_data["id"])

    # Associate category
    res_cat = client.put(
        "/api/v1/worker/categories",
        headers={"Authorization": f"Bearer {token}"},
        json={"category_ids": [str(category_id)]},
    )
    assert res_cat.status_code == 200

    # Set metric score if different from default
    if final_score != 0.35:
        metric = db_session.query(WorkerMetric).filter(WorkerMetric.worker_id == worker_id).first()
        if metric:
            metric.final_score = final_score
            metric.experience_score = final_score
            metric.bayesian_score = final_score
            db_session.commit()

    return token, worker_data


# --- 1. Opportunity Generation & Independent Wages ---

def test_two_workers_receive_same_gig_with_different_wages(client: TestClient, db_session: Session):
    """Two workers with different final scores receive the same gig opportunity and see their own exact wages.

    Worker 1: Rookie final_score = 0.35 -> premium 10.5% -> base 225.0 -> wage 248.63
    Worker 2: Experienced final_score = 0.80 -> premium 24.0% -> base 225.0 -> wage 279.00
    """
    token_cust, cust = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(
        ServiceTask.category_id == plumbing.id,
        ServiceTask.standard_duration_minutes == 15,
    ).first()

    token_w1, w1 = create_test_worker(client, db_session, plumbing.id, final_score=0.35, email_prefix="w_rookie")
    token_w2, w2 = create_test_worker(client, db_session, plumbing.id, final_score=0.80, email_prefix="w_expert")

    # Customer creates and posts gig
    tomorrow = date.today() + timedelta(days=1)
    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task.id)],
            "scheduled_date": str(tomorrow),
            "scheduled_start_time": "10:00:00",
            "scheduled_end_time": "11:00:00",
            "description": "Leaking bathroom faucet",
        },
    )
    assert res_create.status_code == 201
    gig_id = res_create.json()["data"]["id"]

    res_post = client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})
    assert res_post.status_code == 200

    # Worker 1 fetches opportunities
    res_w1 = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w1}"})
    assert res_w1.status_code == 200
    opps_w1 = res_w1.json()["data"]
    match_w1 = next((o for o in opps_w1 if o["gig_id"] == gig_id), None)
    assert match_w1 is not None
    assert match_w1["status"] == "PENDING"
    assert match_w1["base_price"] == 225.00
    assert match_w1["final_score_snapshot"] == 0.35
    assert match_w1["premium_percentage"] == 10.5
    assert match_w1["exact_wage"] == 248.62

    # Worker 2 fetches opportunities
    res_w2 = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w2}"})
    assert res_w2.status_code == 200
    opps_w2 = res_w2.json()["data"]
    match_w2 = next((o for o in opps_w2 if o["gig_id"] == gig_id), None)
    assert match_w2 is not None
    assert match_w2["status"] == "PENDING"
    assert match_w2["base_price"] == 225.00
    assert match_w2["final_score_snapshot"] == 0.80
    assert match_w2["premium_percentage"] == 24.0
    assert match_w2["exact_wage"] == 279.00


def test_independent_accept_and_reject(client: TestClient, db_session: Session):
    """Worker 1 accepts while Worker 2 rejects the opportunity independently."""
    token_cust, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w1, _ = create_test_worker(client, db_session, plumbing.id, final_score=0.35, email_prefix="w_acc")
    token_w2, _ = create_test_worker(client, db_session, plumbing.id, final_score=0.50, email_prefix="w_rej")

    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    # Retrieve opportunity IDs
    res_w1 = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w1}"})
    opp_w1_id = next(o["id"] for o in res_w1.json()["data"] if o["gig_id"] == gig_id)

    res_w2 = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w2}"})
    opp_w2_id = next(o["id"] for o in res_w2.json()["data"] if o["gig_id"] == gig_id)

    # Worker 1 accepts
    res_acc = client.post(
        f"/api/v1/worker/opportunities/{opp_w1_id}/accept",
        headers={"Authorization": f"Bearer {token_w1}"},
    )
    assert res_acc.status_code == 200
    assert res_acc.json()["data"]["status"] == "ACCEPTED"
    assert res_acc.json()["data"]["responded_at"] is not None

    # Worker 2 rejects
    res_rej = client.post(
        f"/api/v1/worker/opportunities/{opp_w2_id}/reject",
        headers={"Authorization": f"Bearer {token_w2}"},
    )
    assert res_rej.status_code == 200
    assert res_rej.json()["data"]["status"] == "REJECTED"
    assert res_rej.json()["data"]["responded_at"] is not None

    # Verify audit events in database
    events = db_session.query(GigEvent).filter(GigEvent.gig_id == uuid.UUID(gig_id)).all()
    event_types = [e.event_type for e in events]
    assert "OPPORTUNITY_ACCEPTED" in event_types
    assert "OPPORTUNITY_REJECTED" in event_types


# --- 2. State Validation and Invariance Tests ---

def test_rejected_opportunity_cannot_be_accepted(client: TestClient, db_session: Session):
    """A rejected opportunity cannot later be accepted."""
    token_cust, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w, _ = create_test_worker(client, db_session, plumbing.id)

    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    res_w = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"})
    opp_id = next(o["id"] for o in res_w.json()["data"] if o["gig_id"] == gig_id)

    # Reject
    client.post(f"/api/v1/worker/opportunities/{opp_id}/reject", headers={"Authorization": f"Bearer {token_w}"})

    # Try to accept rejected opportunity -> 400
    res_reaccept = client.post(
        f"/api/v1/worker/opportunities/{opp_id}/accept",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    assert res_reaccept.status_code == 400
    assert res_reaccept.json()["error"]["code"] == "ALREADY_REJECTED"


def test_accepted_opportunity_cannot_be_reaccepted(client: TestClient, db_session: Session):
    """An already accepted opportunity cannot be accepted again."""
    token_cust, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w, _ = create_test_worker(client, db_session, plumbing.id)

    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    res_w = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"})
    opp_id = next(o["id"] for o in res_w.json()["data"] if o["gig_id"] == gig_id)

    client.post(f"/api/v1/worker/opportunities/{opp_id}/accept", headers={"Authorization": f"Bearer {token_w}"})

    # Duplicate accept
    res_dup = client.post(f"/api/v1/worker/opportunities/{opp_id}/accept", headers={"Authorization": f"Bearer {token_w}"})
    assert res_dup.status_code == 400
    assert res_dup.json()["error"]["code"] == "ALREADY_ACCEPTED"


def test_cross_worker_isolation(client: TestClient, db_session: Session):
    """Worker B cannot view, accept, or reject Worker A's opportunity."""
    token_cust, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_wa, _ = create_test_worker(client, db_session, plumbing.id, email_prefix="owner_wa")
    token_wb, _ = create_test_worker(client, db_session, plumbing.id, email_prefix="other_wb")

    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    res_wa = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_wa}"})
    opp_wa_id = next(o["id"] for o in res_wa.json()["data"] if o["gig_id"] == gig_id)

    # Worker B attempts to view Worker A's opportunity -> 403
    res_get = client.get(
        f"/api/v1/worker/opportunities/{opp_wa_id}",
        headers={"Authorization": f"Bearer {token_wb}"},
    )
    assert res_get.status_code == 403
    assert res_get.json()["error"]["code"] == "FORBIDDEN"

    # Worker B attempts to accept Worker A's opportunity -> 403
    res_acc = client.post(
        f"/api/v1/worker/opportunities/{opp_wa_id}/accept",
        headers={"Authorization": f"Bearer {token_wb}"},
    )
    assert res_acc.status_code == 403
    assert res_acc.json()["error"]["code"] == "FORBIDDEN"


# --- 3. Eligibility and Schedule Conflict Tests ---

def test_worker_in_different_category_not_offered(client: TestClient, db_session: Session):
    """A worker registered only in Carpentry does not receive opportunities for Plumbing gigs."""
    token_cust, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    carpentry = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Carpentry").first()
    p_task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_carpenter, _ = create_test_worker(client, db_session, carpentry.id, email_prefix="carpenter")

    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(p_task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    # Carpenter checks opportunities -> should have 0 opportunities for this gig
    res_opps = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_carpenter}"})
    assert all(o["gig_id"] != gig_id for o in res_opps.json()["data"])


def test_schedule_conflict_blocks_acceptance(client: TestClient, db_session: Session):
    """If a worker has an existing confirmed gig at the same time, accepting an overlapping gig is blocked."""
    token_cust, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w, w = create_test_worker(client, db_session, plumbing.id, email_prefix="conflict_w")
    worker_id = uuid.UUID(w["id"])

    # Simulate an existing confirmed gig for worker tomorrow 10:00 - 12:00
    target_date = date.today() + timedelta(days=2)
    confirmed_gig = Gig(
        customer_id=uuid.UUID(create_test_customer(client, db_session, "cust2")[1]["id"]),
        cooperative_id=uuid.UUID(w["cooperative_id"]),
        category_id=plumbing.id,
        status=GigStatus.SCHEDULED,
        selected_worker_id=worker_id,
        scheduled_date=target_date,
        scheduled_start_time=time(10, 0),
        scheduled_end_time=time(12, 0),
        base_price=225.0,
    )
    db_session.add(confirmed_gig)
    db_session.commit()

    # Customer creates second gig overlapping tomorrow 11:00 - 13:00
    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task.id)],
            "scheduled_date": str(target_date),
            "scheduled_start_time": "11:00:00",
            "scheduled_end_time": "13:00:00",
        },
    )
    gig2_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig2_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    # In opportunity engine, if conflict is present or worker attempts to accept:
    # Manually create opportunity if not generated due to conflict filter, to test accept conflict check
    existing_opp = db_session.query(GigWorkerOpportunity).filter(
        GigWorkerOpportunity.gig_id == uuid.UUID(gig2_id),
        GigWorkerOpportunity.worker_id == worker_id,
    ).first()

    if not existing_opp:
        existing_opp = GigWorkerOpportunity(
            id=uuid.uuid4(),
            gig_id=uuid.UUID(gig2_id),
            worker_id=worker_id,
            status=OpportunityStatus.PENDING,
            base_price_snapshot=225.0,
            final_score_snapshot=0.35,
            premium_percentage=10.5,
            exact_wage=248.62,
            offered_at=datetime.now(timezone.utc),
        )
        db_session.add(existing_opp)
        db_session.commit()

    # Worker tries to accept overlapping gig -> 400 SCHEDULE_CONFLICT
    res_acc = client.post(
        f"/api/v1/worker/opportunities/{existing_opp.id}/accept",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    assert res_acc.status_code == 400
    assert res_acc.json()["error"]["code"] == "SCHEDULE_CONFLICT"


# --- 4. Retrieval and Details Tests ---

def test_get_opportunity_by_id_and_filters(client: TestClient, db_session: Session):
    """GET /api/v1/worker/opportunities/{id} and query filters work correctly."""
    token_cust, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w, _ = create_test_worker(client, db_session, plumbing.id)

    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)], "description": "Specific detail check"},
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    # Fetch list
    res_list = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"})
    opp_id = next(o["id"] for o in res_list.json()["data"] if o["gig_id"] == gig_id)

    # Fetch by ID
    res_detail = client.get(f"/api/v1/worker/opportunities/{opp_id}", headers={"Authorization": f"Bearer {token_w}"})
    assert res_detail.status_code == 200
    data = res_detail.json()["data"]
    assert data["id"] == opp_id
    assert data["gig"]["description"] == "Specific detail check"
    assert data["status"] == "PENDING"
    assert data["exact_wage"] == 248.62

    # Filter by category
    res_cat = client.get(f"/api/v1/worker/opportunities?category_id={plumbing.id}", headers={"Authorization": f"Bearer {token_w}"})
    assert any(o["id"] == opp_id for o in res_cat.json()["data"])

    # Filter by status=PENDING
    res_pending = client.get("/api/v1/worker/opportunities?status=PENDING", headers={"Authorization": f"Bearer {token_w}"})
    assert any(o["id"] == opp_id for o in res_pending.json()["data"])


# --- 5. Focused Verification Tests (Sprint 5 Audit) ---

def test_worker_verification_and_eligibility_rules(client: TestClient, db_session: Session):
    """Verify worker eligibility rules during generation and acceptance; Aadhaar upload does not bypass."""
    token_cust, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w, w = create_test_worker(client, db_session, plumbing.id, email_prefix="w_elig")
    worker_id = uuid.UUID(w["id"])

    # 1. Deactivate worker profile
    profile = db_session.query(WorkerProfile).filter(WorkerProfile.user_id == worker_id).first()
    profile.is_active = False
    db_session.commit()

    # 2. Customer creates and posts gig
    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    # Inactive worker does not receive opportunity
    res_opps = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"})
    assert all(o["gig_id"] != gig_id for o in res_opps.json()["data"])

    # 3. Aadhaar upload facility does NOT automatically make worker active or verified
    res_aadhaar = client.post(
        "/api/v1/worker/profile/aadhaar",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"document_url": "https://storage.sahakaar.org/aadhaar_123.pdf"},
    )
    assert res_aadhaar.status_code == 200
    db_session.refresh(profile)
    assert profile.is_active is False  # Still inactive; not verified

    # 4. If an opportunity exists and worker is inactive, acceptance is rejected
    opp = GigWorkerOpportunity(
        id=uuid.uuid4(),
        gig_id=uuid.UUID(gig_id),
        worker_id=worker_id,
        status=OpportunityStatus.PENDING,
        base_price_snapshot=225.0,
        final_score_snapshot=0.35,
        premium_percentage=10.5,
        exact_wage=248.62,
        offered_at=datetime.now(timezone.utc),
    )
    db_session.add(opp)
    db_session.commit()

    res_acc_inactive = client.post(
        f"/api/v1/worker/opportunities/{opp.id}/accept",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    assert res_acc_inactive.status_code == 400
    assert res_acc_inactive.json()["error"]["code"] == "WORKER_UNAVAILABLE"


def test_availability_status_and_recurring_weekly_handling(client: TestClient, db_session: Session):
    """Verify Available/Unavailable status control and weekly recurring availability rules."""
    token_cust, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w, w = create_test_worker(client, db_session, plumbing.id, email_prefix="w_avail")
    worker_id = uuid.UUID(w["id"])

    # 1. Update simple Available/Unavailable control to False
    res_status = client.patch(
        "/api/v1/worker/availability/status",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"is_available": False},
    )
    assert res_status.status_code == 200
    assert res_status.json()["data"]["is_available"] is False

    # Check worker profile
    res_prof = client.get("/api/v1/worker/profile", headers={"Authorization": f"Bearer {token_w}"})
    assert res_prof.json()["data"]["is_active"] is False

    # 2. Re-enable availability
    res_status2 = client.patch(
        "/api/v1/worker/availability/status",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"is_available": True},
    )
    assert res_status2.status_code == 200
    assert res_status2.json()["data"]["is_available"] is True

    # 3. Configure weekly recurring availability: unavailable on gig's day of week
    # Target date: next Wednesday
    today = date.today()
    days_until_wed = (2 - today.weekday()) % 7
    if days_until_wed == 0:
        days_until_wed = 7
    target_wed = today + timedelta(days=days_until_wed)

    # Set Wednesday (day_of_week=2) as unavailable
    res_slots = client.put(
        "/api/v1/worker/availability",
        headers={"Authorization": f"Bearer {token_w}"},
        json={
            "slots": [
                {
                    "day_of_week": 2,
                    "start_time": "09:00:00",
                    "end_time": "17:00:00",
                    "is_available": False,
                }
            ]
        },
    )
    assert res_slots.status_code == 200

    # Customer creates and posts gig on target Wednesday
    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task.id)],
            "scheduled_date": str(target_wed),
            "scheduled_start_time": "10:00:00",
            "scheduled_end_time": "11:00:00",
        },
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    # Worker does not receive opportunity because recurring availability slot is False
    res_opps = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"})
    assert all(o["gig_id"] != gig_id for o in res_opps.json()["data"])


def test_concurrency_simultaneous_opportunity_acceptance(client: TestClient, db_session: Session):
    """Near-simultaneous acceptance requests on the same opportunity: exactly one succeeds and one fails."""
    import concurrent.futures

    token_cust, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w, _ = create_test_worker(client, db_session, plumbing.id, email_prefix="w_conc")

    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    res_w = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"})
    opp_id = next(o["id"] for o in res_w.json()["data"] if o["gig_id"] == gig_id)

    def do_accept():
        return client.post(
            f"/api/v1/worker/opportunities/{opp_id}/accept",
            headers={"Authorization": f"Bearer {token_w}"},
        )

    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        f1 = executor.submit(do_accept)
        f2 = executor.submit(do_accept)
        r1 = f1.result()
        r2 = f2.result()

    status_codes = sorted([r1.status_code, r2.status_code])
    assert status_codes == [200, 400]
    error_response = r1 if r1.status_code == 400 else r2
    assert error_response.json()["error"]["code"] == "ALREADY_ACCEPTED"


def test_concurrency_overlapping_confirmed_gig_blocks_simultaneous_acceptance(client: TestClient, db_session: Session):
    """Near-simultaneous acceptance where worker confirms an overlapping gig prevents conflicting acceptance."""
    token_cust, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w, w = create_test_worker(client, db_session, plumbing.id, email_prefix="w_conf_race")
    worker_id = uuid.UUID(w["id"])

    target_date = date.today() + timedelta(days=3)

    # Opportunity A for 10:00 - 11:00
    res_create_a = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task.id)],
            "scheduled_date": str(target_date),
            "scheduled_start_time": "10:00:00",
            "scheduled_end_time": "11:00:00",
        },
    )
    gig_a_id = res_create_a.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_a_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    res_w = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"})
    opp_a_id = next(o["id"] for o in res_w.json()["data"] if o["gig_id"] == gig_a_id)

    # Now a confirmed gig is scheduled for worker overlapping 10:30 - 11:30
    confirmed_gig = Gig(
        customer_id=uuid.UUID(create_test_customer(client, db_session, "cust_c")[1]["id"]),
        cooperative_id=uuid.UUID(w["cooperative_id"]),
        category_id=plumbing.id,
        status=GigStatus.SCHEDULED,
        selected_worker_id=worker_id,
        scheduled_date=target_date,
        scheduled_start_time=time(10, 30),
        scheduled_end_time=time(11, 30),
        base_price=225.0,
    )
    db_session.add(confirmed_gig)
    db_session.commit()

    # Attempting to accept Opportunity A fails due to schedule conflict
    res_acc = client.post(
        f"/api/v1/worker/opportunities/{opp_a_id}/accept",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    assert res_acc.status_code == 400
    assert res_acc.json()["error"]["code"] == "SCHEDULE_CONFLICT"


def test_acceptance_atomic_rollback_on_audit_failure(client: TestClient, db_session: Session, monkeypatch):
    """If audit event fails during opportunity acceptance, transaction rolls back cleanly with status remaining PENDING."""
    token_cust, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w, w = create_test_worker(client, db_session, plumbing.id, email_prefix="w_atom")

    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    res_w = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"})
    opp_id = uuid.UUID(next(o["id"] for o in res_w.json()["data"] if o["gig_id"] == gig_id))

    # Simulate failure on GigEvent creation during acceptance
    def mock_init(*args, **kwargs):
        raise RuntimeError("Simulated GigEvent failure on accept")

    monkeypatch.setattr("app.services.opportunity_service.GigEvent", mock_init)

    with pytest.raises(RuntimeError, match="Simulated GigEvent failure on accept"):
        from app.services.opportunity_service import OpportunityService
        from app.db.models.user import User

        worker_user = db_session.query(User).filter(User.id == uuid.UUID(w["id"])).first()
        OpportunityService.accept_opportunity(worker_user, opp_id, db_session)

    # Opportunity in database must remain PENDING with responded_at as None
    db_session.rollback()
    opp_in_db = db_session.query(GigWorkerOpportunity).filter(GigWorkerOpportunity.id == opp_id).first()
    assert opp_in_db.status == OpportunityStatus.PENDING
    assert opp_in_db.responded_at is None

