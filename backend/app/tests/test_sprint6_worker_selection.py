import uuid
from datetime import date, time, datetime, timezone, timedelta
from typing import Tuple, List, Optional
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.db.models.user import User, WorkerProfile, WorkerMetric
from app.db.models.service import ServiceCategory, ServiceTask, WorkerCategory
from app.db.models.gig import Gig, GigWorkerOpportunity
from app.db.models.communication import GigEvent, Notification
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
    completed_jobs: int = 0,
    rating_avg: float = 0.0,
    rating_count: int = 0,
    email_prefix: str = "work",
) -> Tuple[str, dict]:
    """Helper to initialize a worker, set metrics, and associate category."""
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

    # Set metric values
    metric = db_session.query(WorkerMetric).filter(WorkerMetric.worker_id == worker_id).first()
    if metric:
        metric.final_score = final_score
        metric.completed_jobs_count = completed_jobs
        metric.rating_average = rating_avg
        metric.rating_count = rating_count
        db_session.commit()

    return token, worker_data


# --- 1. Candidate List & Transparency ---

def test_customer_views_candidate_list_with_metrics_and_exact_wages(client: TestClient, db_session: Session):
    """Customer can view accepted candidates with transparent metrics and individual exact wages."""
    token_cust, cust = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(
        ServiceTask.category_id == plumbing.id,
        ServiceTask.standard_duration_minutes == 15,
    ).first()

    token_w1, w1 = create_test_worker(
        client, db_session, plumbing.id,
        final_score=0.35, completed_jobs=2, rating_avg=4.5, rating_count=2,
        email_prefix="cand_w1",
    )
    token_w2, w2 = create_test_worker(
        client, db_session, plumbing.id,
        final_score=0.80, completed_jobs=35, rating_avg=4.9, rating_count=28,
        email_prefix="cand_w2",
    )

    # 1. Customer creates and posts gig
    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    # Both workers accept opportunity
    opps_w1 = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w1}"}).json()["data"]
    opp1_id = next(o["id"] for o in opps_w1 if o["gig_id"] == gig_id)
    client.post(f"/api/v1/worker/opportunities/{opp1_id}/accept", headers={"Authorization": f"Bearer {token_w1}"})

    opps_w2 = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w2}"}).json()["data"]
    opp2_id = next(o["id"] for o in opps_w2 if o["gig_id"] == gig_id)
    client.post(f"/api/v1/worker/opportunities/{opp2_id}/accept", headers={"Authorization": f"Bearer {token_w2}"})

    # 2. Customer views candidates
    res_cands = client.get(f"/api/v1/gigs/{gig_id}/candidates", headers={"Authorization": f"Bearer {token_cust}"})
    assert res_cands.status_code == 200
    candidates = res_cands.json()["data"]
    assert len(candidates) == 2

    # Check candidate 1
    c1 = next(c for c in candidates if c["worker_id"] == w1["id"])
    assert c1["name"] == w1["full_name"]
    assert c1["exact_wage"] == 248.62
    assert c1["completed_jobs_count"] == 2
    assert c1["rating_average"] == 4.5
    assert c1["rating_count"] == 2
    assert c1["final_score"] == 0.35
    assert c1["recommendation"] is None

    # Check candidate 2
    c2 = next(c for c in candidates if c["worker_id"] == w2["id"])
    assert c2["name"] == w2["full_name"]
    assert c2["exact_wage"] == 279.00
    assert c2["completed_jobs_count"] == 35
    assert c2["rating_average"] == 4.9
    assert c2["rating_count"] == 28
    assert c2["final_score"] == 0.80
    assert c2["recommendation"] is None


# --- 2. Worker Selection Transaction ---

def test_customer_selects_worker_success(client: TestClient, db_session: Session):
    """Customer selects one candidate: updates gig status to WORKER_SELECTED, closes other candidates as NOT_SELECTED, logs audit event, and sends notifications."""
    token_cust, cust = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w1, w1 = create_test_worker(client, db_session, plumbing.id, final_score=0.35, email_prefix="sel_w1")
    token_w2, w2 = create_test_worker(client, db_session, plumbing.id, final_score=0.70, email_prefix="sel_w2")

    # Post gig and both accept
    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    opp1_id = next(o["id"] for o in client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w1}"}).json()["data"] if o["gig_id"] == gig_id)
    client.post(f"/api/v1/worker/opportunities/{opp1_id}/accept", headers={"Authorization": f"Bearer {token_w1}"})

    opp2_id = next(o["id"] for o in client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w2}"}).json()["data"] if o["gig_id"] == gig_id)
    client.post(f"/api/v1/worker/opportunities/{opp2_id}/accept", headers={"Authorization": f"Bearer {token_w2}"})

    # Customer selects Worker 2
    res_sel = client.post(
        f"/api/v1/gigs/{gig_id}/select-worker",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"worker_id": w2["id"]},
    )
    assert res_sel.status_code == 200
    sel_data = res_sel.json()["data"]
    assert sel_data["selected_worker_id"] == w2["id"]
    assert sel_data["status"] == "WORKER_SELECTED"

    # Verify Gig state in database
    db_session.rollback()
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig.selected_worker_id == uuid.UUID(w2["id"])
    assert gig.status == GigStatus.WORKER_SELECTED

    # Verify Worker 2 opportunity remains ACCEPTED
    opp2 = db_session.query(GigWorkerOpportunity).filter(GigWorkerOpportunity.id == uuid.UUID(opp2_id)).first()
    assert opp2.status == OpportunityStatus.ACCEPTED

    # Verify Worker 1 opportunity transitioned to NOT_SELECTED
    opp1 = db_session.query(GigWorkerOpportunity).filter(GigWorkerOpportunity.id == uuid.UUID(opp1_id)).first()
    assert opp1.status == OpportunityStatus.NOT_SELECTED

    # Verify audit event in database
    event = db_session.query(GigEvent).filter(
        GigEvent.gig_id == uuid.UUID(gig_id),
        GigEvent.event_type == "WORKER_SELECTED",
    ).first()
    assert event is not None
    assert event.metadata_json["selected_worker_id"] == w2["id"]

    # Verify notifications in database
    notif_w2 = db_session.query(Notification).filter(
        Notification.recipient_id == uuid.UUID(w2["id"]),
        Notification.type == "WORKER_SELECTED",
    ).first()
    assert notif_w2 is not None

    notif_w1 = db_session.query(Notification).filter(
        Notification.recipient_id == uuid.UUID(w1["id"]),
        Notification.type == "NOT_SELECTED",
    ).first()
    assert notif_w1 is not None


# --- 3. Boundary & Error Validations ---

def test_cannot_select_worker_who_did_not_accept(client: TestClient, db_session: Session):
    """Customer cannot select a worker who did not accept the opportunity."""
    token_cust, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w, w = create_test_worker(client, db_session, plumbing.id, email_prefix="no_acc")

    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    # Worker has opportunity in PENDING status (has NOT accepted)
    res_sel = client.post(
        f"/api/v1/gigs/{gig_id}/select-worker",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"worker_id": w["id"]},
    )
    assert res_sel.status_code == 400
    assert res_sel.json()["error"]["code"] == "WORKER_NOT_ACCEPTED"


def test_cannot_select_worker_twice_or_from_invalid_state(client: TestClient, db_session: Session):
    """Once a worker is selected, subsequent selection attempts are rejected."""
    token_cust, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w, w = create_test_worker(client, db_session, plumbing.id, email_prefix="dup_sel")

    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    opp_id = next(o["id"] for o in client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"}).json()["data"] if o["gig_id"] == gig_id)
    client.post(f"/api/v1/worker/opportunities/{opp_id}/accept", headers={"Authorization": f"Bearer {token_w}"})

    # First selection succeeds
    res_sel1 = client.post(
        f"/api/v1/gigs/{gig_id}/select-worker",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"worker_id": w["id"]},
    )
    assert res_sel1.status_code == 200

    # Second selection attempt fails
    res_sel2 = client.post(
        f"/api/v1/gigs/{gig_id}/select-worker",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"worker_id": w["id"]},
    )
    assert res_sel2.status_code == 400
    assert res_sel2.json()["error"]["code"] in ("INVALID_GIG_STATE", "WORKER_ALREADY_SELECTED")


def test_cross_customer_and_role_authorization(client: TestClient, db_session: Session):
    """Another customer or a worker cannot access candidates or select workers for this gig."""
    token_owner, _ = create_test_customer(client, db_session, email_prefix="owner_c")
    token_intruder, _ = create_test_customer(client, db_session, email_prefix="intruder_c")

    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w, w = create_test_worker(client, db_session, plumbing.id, email_prefix="auth_w")

    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_owner}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_owner}"})

    opp_id = next(o["id"] for o in client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"}).json()["data"] if o["gig_id"] == gig_id)
    client.post(f"/api/v1/worker/opportunities/{opp_id}/accept", headers={"Authorization": f"Bearer {token_w}"})

    # Intruder customer cannot view candidates -> 403
    res_cands = client.get(f"/api/v1/gigs/{gig_id}/candidates", headers={"Authorization": f"Bearer {token_intruder}"})
    assert res_cands.status_code == 403
    assert res_cands.json()["error"]["code"] == "FORBIDDEN"

    # Intruder customer cannot select worker -> 403
    res_sel = client.post(
        f"/api/v1/gigs/{gig_id}/select-worker",
        headers={"Authorization": f"Bearer {token_intruder}"},
        json={"worker_id": w["id"]},
    )
    assert res_sel.status_code == 403
    assert res_sel.json()["error"]["code"] == "FORBIDDEN"

    # Worker cannot access customer candidates endpoint -> 403
    res_worker = client.get(f"/api/v1/gigs/{gig_id}/candidates", headers={"Authorization": f"Bearer {token_w}"})
    assert res_worker.status_code == 403


def test_atomic_rollback_on_worker_selection_failure(client: TestClient, db_session: Session, monkeypatch):
    """If audit event or notification fails during worker selection, the entire transaction rolls back."""
    token_cust, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w, w = create_test_worker(client, db_session, plumbing.id, email_prefix="sel_fail")

    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    opp_id = next(o["id"] for o in client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"}).json()["data"] if o["gig_id"] == gig_id)
    client.post(f"/api/v1/worker/opportunities/{opp_id}/accept", headers={"Authorization": f"Bearer {token_w}"})

    # Simulate failure on GigEvent creation during worker selection
    def mock_init(*args, **kwargs):
        raise RuntimeError("Simulated GigEvent failure during worker selection")

    monkeypatch.setattr("app.services.gig_service.GigEvent", mock_init)

    with pytest.raises(RuntimeError, match="Simulated GigEvent failure during worker selection"):
        from app.services.gig_service import GigService
        from app.db.models.user import User

        customer_user = db_session.query(User).filter(User.role == "CUSTOMER").first()
        GigService.select_worker(customer_user, uuid.UUID(gig_id), uuid.UUID(w["id"]), db_session)

    # In database, gig must still have selected_worker_id as None, status as POSTED
    db_session.rollback()
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig.selected_worker_id is None
    assert gig.status == GigStatus.POSTED

    # Opportunity must still be ACCEPTED, not NOT_SELECTED
    opp = db_session.query(GigWorkerOpportunity).filter(GigWorkerOpportunity.id == uuid.UUID(opp_id)).first()
    assert opp.status == OpportunityStatus.ACCEPTED


def test_concurrency_simultaneous_worker_selection(client: TestClient, db_session: Session):
    """Near-simultaneous selection requests on the same gig: exactly one succeeds and the other is rejected."""
    import concurrent.futures

    token_cust, _ = create_test_customer(client, db_session, email_prefix="sel_conc_c")
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w1, w1 = create_test_worker(client, db_session, plumbing.id, email_prefix="sel_conc_w1")
    token_w2, w2 = create_test_worker(client, db_session, plumbing.id, email_prefix="sel_conc_w2")

    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    # Both accept
    opp1 = next(o["id"] for o in client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w1}"}).json()["data"] if o["gig_id"] == gig_id)
    opp2 = next(o["id"] for o in client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w2}"}).json()["data"] if o["gig_id"] == gig_id)
    client.post(f"/api/v1/worker/opportunities/{opp1}/accept", headers={"Authorization": f"Bearer {token_w1}"})
    client.post(f"/api/v1/worker/opportunities/{opp2}/accept", headers={"Authorization": f"Bearer {token_w2}"})

    def do_select(worker_id):
        return client.post(
            f"/api/v1/gigs/{gig_id}/select-worker",
            headers={"Authorization": f"Bearer {token_cust}"},
            json={"worker_id": worker_id},
        )

    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        f1 = executor.submit(do_select, w1["id"])
        f2 = executor.submit(do_select, w2["id"])
        r1 = f1.result()
        r2 = f2.result()

    status_codes = sorted([r1.status_code, r2.status_code])
    assert status_codes == [200, 400]
    error_res = r1 if r1.status_code == 400 else r2
    assert error_res.json()["error"]["code"] in ("INVALID_GIG_STATE", "WORKER_ALREADY_SELECTED")

    # Verify DB consistency
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig.status == GigStatus.WORKER_SELECTED
    assert gig.selected_worker_id in (uuid.UUID(w1["id"]), uuid.UUID(w2["id"]))

    events = db_session.query(GigEvent).filter(GigEvent.gig_id == uuid.UUID(gig_id), GigEvent.event_type == "WORKER_SELECTED").all()
    assert len(events) == 1

