import uuid
from datetime import date, time, timedelta
from typing import Tuple, List, Optional
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.db.models.service import ServiceCategory, ServiceTask
from app.db.models.gig import Gig
from app.db.models.communication import GigEvent
from app.db.models.enums import GigStatus, GigType, MaterialProcurementMode
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


def create_test_worker(client: TestClient, db_session: Session, email_prefix: str = "work") -> Tuple[str, dict]:
    """Helper to initialize a worker and return (jwt_token, user_dict)."""
    sub = str(uuid.uuid4())
    token = create_access_token({"sub": sub, "email": f"{email_prefix}_{sub[:8]}@sahakaar.org"})
    res = client.post(
        "/api/v1/me/initialize",
        headers={"Authorization": f"Bearer {token}"},
        json={"role": "WORKER", "full_name": f"Worker {sub[:6]}"},
    )
    assert res.status_code == 201
    return token, res.json()["data"]


# --- 1. Gig Creation Tests ---

def test_create_gig_single_task_success(client: TestClient, db_session: Session):
    """Customer creates a gig with a single 15-min task, enforcing 45-min minimum base price."""
    token, customer = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task_15 = db_session.query(ServiceTask).filter(
        ServiceTask.category_id == plumbing.id,
        ServiceTask.standard_duration_minutes == 15,
    ).first()

    tomorrow = date.today() + timedelta(days=1)
    payload = {
        "category_id": str(plumbing.id),
        "task_ids": [str(task_15.id)],
        "gig_type": "NORMAL",
        "description": "Fix leaking bathroom fixture",
        "instructions": "Call before arriving",
        "address": "42 Indiranagar, Bengaluru",
        "latitude": 12.9716,
        "longitude": 77.5946,
        "google_maps_link": "https://maps.google.com/?q=12.9716,77.5946",
        "scheduled_date": str(tomorrow),
        "scheduled_start_time": "10:00:00",
        "scheduled_end_time": "11:00:00",
        "is_emergency": False,
        "material_procurement_mode": "CUSTOMER_PURCHASES",
    }

    res = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token}"},
        json=payload,
    )
    assert res.status_code == 201
    data = res.json()["data"]

    # Verify attributes
    assert data["customer_id"] == customer["id"]
    assert data["category_id"] == str(plumbing.id)
    assert data["status"] == "DRAFT"
    assert data["base_price"] == 225.00  # 45 min * 5.00
    assert data["minimum_billable_minutes_snapshot"] == 45
    assert data["base_rate_per_minute_snapshot"] == 5.0
    assert data["address"] == "42 Indiranagar, Bengaluru"
    assert data["google_maps_link"] == "https://maps.google.com/?q=12.9716,77.5946"
    assert len(data["tasks"]) == 1
    assert data["tasks"][0]["task_id"] == str(task_15.id)
    assert data["tasks"][0]["standard_duration_minutes_snapshot"] == 15

    # Verify audit event in DB
    event = db_session.query(GigEvent).filter(
        GigEvent.gig_id == uuid.UUID(data["id"]),
        GigEvent.event_type == "GIG_CREATED",
    ).first()
    assert event is not None
    assert event.metadata_json["base_price"] == 225.0


def test_create_gig_multiple_tasks_accumulates_duration(client: TestClient, db_session: Session):
    """Customer creates a gig with multiple tasks; standard durations sum correctly."""
    token, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task_20 = db_session.query(ServiceTask).filter(
        ServiceTask.category_id == plumbing.id,
        ServiceTask.standard_duration_minutes == 20,
    ).first()
    task_25 = db_session.query(ServiceTask).filter(
        ServiceTask.category_id == plumbing.id,
        ServiceTask.standard_duration_minutes == 25,
    ).first()

    payload = {
        "category_id": str(plumbing.id),
        "task_ids": [str(task_20.id), str(task_25.id)],
        "description": "Double plumbing repair",
        "material_procurement_mode": "WORKER_PURCHASES",
    }

    res = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token}"},
        json=payload,
    )
    assert res.status_code == 201
    data = res.json()["data"]

    assert len(data["tasks"]) == 2
    # 20 + 25 = 45 min -> 45 min * 5.00 = 225.00
    assert data["base_price"] == 225.00
    assert data["material_procurement_mode"] == "WORKER_PURCHASES"


def test_create_gig_rejects_category_mismatch(client: TestClient, db_session: Session):
    """Attempting to add tasks from a different category is rejected with CATEGORY_TASK_MISMATCH."""
    token, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    carpentry = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Carpentry").first()

    plumb_task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()
    carp_task = db_session.query(ServiceTask).filter(ServiceTask.category_id == carpentry.id).first()

    payload = {
        "category_id": str(plumbing.id),
        "task_ids": [str(plumb_task.id), str(carp_task.id)],
        "description": "Cross category mix",
    }

    res = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token}"},
        json=payload,
    )
    assert res.status_code == 400
    assert res.json()["error"]["code"] == "CATEGORY_TASK_MISMATCH"


def test_create_gig_rejects_nonexistent_category_or_invalid_task(client: TestClient, db_session: Session):
    """Invalid category ID or invalid task ID returns appropriate error."""
    token, _ = create_test_customer(client, db_session)
    fake_cat = str(uuid.uuid4())
    fake_task = str(uuid.uuid4())

    # Invalid category
    res_cat = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token}"},
        json={"category_id": fake_cat, "task_ids": [fake_task]},
    )
    assert res_cat.status_code == 404
    assert res_cat.json()["error"]["code"] == "CATEGORY_NOT_FOUND"

    # Valid category, fake task
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    res_task = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token}"},
        json={"category_id": str(plumbing.id), "task_ids": [fake_task]},
    )
    assert res_task.status_code == 400
    assert res_task.json()["error"]["code"] == "INVALID_TASKS"


def test_create_gig_schedule_validations(client: TestClient, db_session: Session):
    """Scheduled date in past and inverted times are validated."""
    token, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    # Past date for non-emergency -> 400
    yesterday = date.today() - timedelta(days=1)
    res_past = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task.id)],
            "scheduled_date": str(yesterday),
            "is_emergency": False,
        },
    )
    assert res_past.status_code == 400
    assert res_past.json()["error"]["code"] == "INVALID_SCHEDULE_DATE"

    # Inverted times (end before start) -> 400
    res_time = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task.id)],
            "scheduled_start_time": "14:00:00",
            "scheduled_end_time": "12:00:00",
        },
    )
    assert res_time.status_code == 400
    assert res_time.json()["error"]["code"] == "INVALID_SCHEDULE_TIME"


def test_worker_cannot_create_gig(client: TestClient, db_session: Session):
    """A user with WORKER role is forbidden from calling POST /api/v1/gigs."""
    worker_token, _ = create_test_worker(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    res = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {worker_token}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    assert res.status_code == 403
    assert res.json()["error"]["code"] in {"FORBIDDEN", "FORBIDDEN_ROLE"}



# --- 2. Gig Posting Tests ---

def test_post_gig_success_and_audit_event(client: TestClient, db_session: Session):
    """Customer can post their DRAFT gig, transitioning to POSTED and logging GIG_POSTED."""
    token, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    # 1. Create gig (DRAFT)
    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]
    assert res_create.json()["data"]["status"] == "DRAFT"

    # 2. Post gig
    res_post = client.post(
        f"/api/v1/gigs/{gig_id}/post",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert res_post.status_code == 200
    posted_data = res_post.json()["data"]
    assert posted_data["status"] == "POSTED"

    # Verify GIG_POSTED audit event
    posted_event = db_session.query(GigEvent).filter(
        GigEvent.gig_id == uuid.UUID(gig_id),
        GigEvent.event_type == "GIG_POSTED",
    ).first()
    assert posted_event is not None
    assert posted_event.metadata_json["new_status"] == "POSTED"

    # 3. Cannot post an already posted gig
    res_repost = client.post(
        f"/api/v1/gigs/{gig_id}/post",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert res_repost.status_code == 400
    assert res_repost.json()["error"]["code"] == "INVALID_GIG_STATE"


def test_other_customer_cannot_post_or_access_gig(client: TestClient, db_session: Session):
    """Customer B cannot post or view Customer A's gig."""
    token_a, _ = create_test_customer(client, db_session, email_prefix="owner")
    token_b, _ = create_test_customer(client, db_session, email_prefix="intruder")

    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    res = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_a}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res.json()["data"]["id"]

    # Intruder tries to post Customer A's gig -> 403
    res_post = client.post(
        f"/api/v1/gigs/{gig_id}/post",
        headers={"Authorization": f"Bearer {token_b}"},
    )
    assert res_post.status_code == 403
    assert res_post.json()["error"]["code"] == "FORBIDDEN"

    # Intruder tries to get Customer A's gig -> 403
    res_get = client.get(
        f"/api/v1/gigs/{gig_id}",
        headers={"Authorization": f"Bearer {token_b}"},
    )
    assert res_get.status_code == 403
    assert res_get.json()["error"]["code"] == "FORBIDDEN"


# --- 3. Gig Retrieval and List Tests ---

def test_get_gig_by_id_success(client: TestClient, db_session: Session):
    """Owner customer can retrieve complete gig details."""
    token, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)], "description": "Sink tap fix"},
    )
    gig_id = res_create.json()["data"]["id"]

    res_get = client.get(
        f"/api/v1/gigs/{gig_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert res_get.status_code == 200
    assert res_get.json()["data"]["id"] == gig_id
    assert res_get.json()["data"]["description"] == "Sink tap fix"


def test_customer_gigs_filtering_and_pagination(client: TestClient, db_session: Session):
    """GET /api/v1/customer/gigs filters by status, category, and paginates."""
    token, _ = create_test_customer(client, db_session, email_prefix="multi")
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    carpentry = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Carpentry").first()

    p_task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()
    c_task = db_session.query(ServiceTask).filter(ServiceTask.category_id == carpentry.id).first()

    # 1. Create Gig 1 (Plumbing, DRAFT)
    res1 = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(p_task.id)]},
    )
    gig1_id = res1.json()["data"]["id"]

    # 2. Create Gig 2 (Carpentry, POSTED)
    res2 = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token}"},
        json={"category_id": str(carpentry.id), "task_ids": [str(c_task.id)]},
    )
    gig2_id = res2.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig2_id}/post", headers={"Authorization": f"Bearer {token}"})

    # Fetch all gigs for this customer
    res_all = client.get("/api/v1/customer/gigs", headers={"Authorization": f"Bearer {token}"})
    assert res_all.status_code == 200
    all_data = res_all.json()["data"]
    assert len(all_data) >= 2

    # Filter by status=DRAFT
    res_draft = client.get("/api/v1/customer/gigs?status=DRAFT", headers={"Authorization": f"Bearer {token}"})
    draft_gigs = res_draft.json()["data"]
    assert all(g["status"] == "DRAFT" for g in draft_gigs)
    assert any(g["id"] == gig1_id for g in draft_gigs)

    # Filter by status=POSTED
    res_posted = client.get("/api/v1/customer/gigs?status=POSTED", headers={"Authorization": f"Bearer {token}"})
    posted_gigs = res_posted.json()["data"]
    assert all(g["status"] == "POSTED" for g in posted_gigs)
    assert any(g["id"] == gig2_id for g in posted_gigs)

    # Filter by category=Carpentry
    res_carp = client.get(f"/api/v1/customer/gigs?category_id={carpentry.id}", headers={"Authorization": f"Bearer {token}"})
    carp_gigs = res_carp.json()["data"]
    assert all(g["category_id"] == str(carpentry.id) for g in carp_gigs)

    # Pagination test
    res_paged = client.get("/api/v1/customer/gigs?page=1&page_size=1", headers={"Authorization": f"Bearer {token}"})
    assert len(res_paged.json()["data"]) == 1
    assert res_paged.json()["pagination"]["total"] >= 2
    assert res_paged.json()["pagination"]["total_pages"] >= 2


# --- 4. Focused Verification Tests (Sprint 4 Audit) ---

def test_schedule_validation_emergency_cannot_bypass_past_date(client: TestClient, db_session: Session):
    """Emergency gigs cannot bypass the past-date schedule validation rule."""
    token, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    yesterday = date.today() - timedelta(days=1)
    res_emergency_past = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task.id)],
            "scheduled_date": str(yesterday),
            "is_emergency": True,
        },
    )
    assert res_emergency_past.status_code == 400
    assert res_emergency_past.json()["error"]["code"] == "INVALID_SCHEDULE_DATE"

    # Today is allowed for emergency
    res_emergency_today = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task.id)],
            "scheduled_date": str(date.today()),
            "is_emergency": True,
        },
    )
    assert res_emergency_today.status_code == 201


def test_expected_duration_minutes_not_authoritative_for_pricing(client: TestClient, db_session: Session):
    """expected_duration_minutes is purely customer estimation and NOT authoritative for pricing."""
    token, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task_15 = db_session.query(ServiceTask).filter(
        ServiceTask.category_id == plumbing.id,
        ServiceTask.standard_duration_minutes == 15,
    ).first()

    # Customer estimates 300 minutes (5 hours). If used for pricing, price would be 300 * 5 = 1500.
    # Authoritative base price MUST be max(15, 45) * 5.0 = 225.00
    res = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task_15.id)],
            "expected_duration_minutes": 300,
        },
    )
    assert res.status_code == 201
    data = res.json()["data"]
    assert data["expected_duration_minutes"] == 300
    assert data["base_price"] == 225.00
    assert data["minimum_billable_minutes_snapshot"] == 45
    assert data["base_rate_per_minute_snapshot"] == 5.0


def test_client_supplied_base_price_cannot_override_backend_pricing(client: TestClient, db_session: Session):
    """Client-supplied base_price or snapshots in payload cannot override backend authoritative pricing."""
    token, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task_15 = db_session.query(ServiceTask).filter(
        ServiceTask.category_id == plumbing.id,
        ServiceTask.standard_duration_minutes == 15,
    ).first()

    # Malicious attempt to force price to 10.00 and snapshots to 1 min
    res = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task_15.id)],
            "base_price": 10.00,
            "minimum_billable_minutes_snapshot": 1,
            "base_rate_per_minute_snapshot": 1.00,
        },
    )
    assert res.status_code == 201
    data = res.json()["data"]
    # Backend strictly overrides with authoritative catalogue-derived pricing
    assert data["base_price"] == 225.00
    assert data["minimum_billable_minutes_snapshot"] == 45
    assert data["base_rate_per_minute_snapshot"] == 5.0

    # Verify persisted record in database
    gig_in_db = db_session.query(Gig).filter(Gig.id == uuid.UUID(data["id"])).first()
    assert float(gig_in_db.base_price) == 225.00
    assert gig_in_db.minimum_billable_minutes_snapshot == 45
    assert float(gig_in_db.base_rate_per_minute_snapshot) == 5.0


def test_gig_creation_atomic_rollback_on_audit_event_failure(client: TestClient, db_session: Session, monkeypatch):
    """If GigEvent creation fails, the entire gig creation transaction must roll back with no orphaned Gig."""
    token, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    count_before = db_session.query(Gig).count()

    # Simulate an audit event failure during gig creation
    def mock_init(*args, **kwargs):
        raise RuntimeError("Simulated GigEvent failure")

    monkeypatch.setattr("app.services.gig_service.GigEvent", mock_init)

    with pytest.raises(RuntimeError, match="Simulated GigEvent failure"):
        # Calling via service or client
        from app.services.gig_service import GigService
        from app.schemas.gig import GigCreateRequest
        from app.db.models.user import User

        customer_user = db_session.query(User).filter(User.role == "CUSTOMER").first()
        req = GigCreateRequest(category_id=plumbing.id, task_ids=[task.id])
        GigService.create_gig(customer_user, req, db_session)

    # Verify no gig was persisted
    count_after = db_session.query(Gig).count()
    assert count_after == count_before


def test_gig_posting_atomic_rollback_on_audit_event_failure(client: TestClient, db_session: Session, monkeypatch):
    """If GigEvent creation fails on post_gig, status update must roll back and remain DRAFT."""
    token, _ = create_test_customer(client, db_session)
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    # Create normal draft gig
    res = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = uuid.UUID(res.json()["data"]["id"])

    # Simulate audit event failure during post
    def mock_init(*args, **kwargs):
        raise RuntimeError("Simulated GigEvent failure on post")

    monkeypatch.setattr("app.services.gig_service.GigEvent", mock_init)

    with pytest.raises(RuntimeError, match="Simulated GigEvent failure on post"):
        from app.services.gig_service import GigService
        from app.db.models.user import User

        customer_user = db_session.query(User).filter(User.id == uuid.UUID(res.json()["data"]["customer_id"])).first()
        GigService.post_gig(customer_user, gig_id, db_session)

    # In DB, gig must still be DRAFT, not POSTED
    db_session.rollback()  # Refresh session view
    gig = db_session.query(Gig).filter(Gig.id == gig_id).first()
    assert gig.status == GigStatus.DRAFT
