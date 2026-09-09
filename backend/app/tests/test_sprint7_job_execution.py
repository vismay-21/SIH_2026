import uuid
from datetime import date, time, datetime, timezone, timedelta
from typing import Tuple
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.db.models.user import User, WorkerProfile, WorkerMetric
from app.db.models.service import ServiceCategory, ServiceTask, WorkerCategory
from app.db.models.gig import Gig, GigWorkerOpportunity
from app.db.models.completion import CompletionSubmission, CompletionEvidence, CompletionConfirmation
from app.db.models.communication import GigEvent, Notification
from app.db.models.enums import GigStatus, OpportunityStatus
from app.services.catalogue_service import CatalogueService


@pytest.fixture(autouse=True)
def seed_catalog_fixture(db_session: Session):
    """Ensure catalog is populated."""
    CatalogueService.seed_catalogue_if_empty(db_session)


def create_test_customer(client: TestClient, db_session: Session, email_prefix: str = "cust7") -> Tuple[str, dict]:
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
    email_prefix: str = "w7",
) -> Tuple[str, dict]:
    """Helper to initialize a worker with category and return (jwt_token, user_dict)."""
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
        metric.experience_score = final_score
        metric.bayesian_score = final_score
        db_session.commit()

    return token, worker_data


def setup_selected_gig(
    client: TestClient,
    db_session: Session,
    email_prefix: str = "exec",
) -> Tuple[str, dict, str, dict, str]:
    """Helper to create, post, accept, and select a worker for a gig.
    Returns (token_cust, cust, token_w, worker, gig_id).
    """
    token_cust, cust = create_test_customer(client, db_session, email_prefix=f"c_{email_prefix}")
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w, w = create_test_worker(client, db_session, plumbing.id, final_score=0.50, email_prefix=f"w_{email_prefix}")

    # 1. Customer creates and posts gig
    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    assert res_create.status_code == 201
    gig_id = res_create.json()["data"]["id"]

    res_post = client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})
    assert res_post.status_code == 200

    # 2. Worker accepts
    res_opps = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"})
    opp_id = next(o["id"] for o in res_opps.json()["data"] if o["gig_id"] == gig_id)
    res_acc = client.post(f"/api/v1/worker/opportunities/{opp_id}/accept", headers={"Authorization": f"Bearer {token_w}"})
    assert res_acc.status_code == 200

    # 3. Customer selects worker
    res_sel = client.post(
        f"/api/v1/gigs/{gig_id}/select-worker",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"worker_id": w["id"]},
    )
    assert res_sel.status_code == 200

    return token_cust, cust, token_w, w, gig_id


# --- 1. Worker Gigs Listing & Tabs ---

def test_worker_gigs_listing_and_tab_filtering(client: TestClient, db_session: Session):
    """Worker retrieves assigned gigs with exact wage snapshot and tab filtering."""
    token_cust, _, token_w, w, gig_id = setup_selected_gig(client, db_session, email_prefix="wg_tabs")

    # 1. Default listing
    res_all = client.get("/api/v1/worker/gigs", headers={"Authorization": f"Bearer {token_w}"})
    assert res_all.status_code == 200
    data = res_all.json()["data"]
    assert len(data) >= 1
    item = next(g for g in data if g["id"] == gig_id)
    assert item["status"] == "WORKER_SELECTED"
    assert item["exact_wage"] == 258.75  # 225 base * (1 + 0.50 * 0.30)
    assert item["category_name"] == "Plumbing"

    # 2. Tab: upcoming includes WORKER_SELECTED
    res_upcoming = client.get("/api/v1/worker/gigs?tab=upcoming", headers={"Authorization": f"Bearer {token_w}"})
    assert res_upcoming.status_code == 200
    assert any(g["id"] == gig_id for g in res_upcoming.json()["data"])

    # 3. Tab: completed does not include WORKER_SELECTED
    res_comp = client.get("/api/v1/worker/gigs?tab=completed", headers={"Authorization": f"Bearer {token_w}"})
    assert res_comp.status_code == 200
    assert not any(g["id"] == gig_id for g in res_comp.json()["data"])


# --- 2. Worker Starts Work ---

def test_worker_starts_work(client: TestClient, db_session: Session):
    """Worker starts work ('Arrived & Start Work'): moves to IN_PROGRESS and logs audit event."""
    token_cust, _, token_w, w, gig_id = setup_selected_gig(client, db_session, email_prefix="start_w")

    res_start = client.post(f"/api/v1/gigs/{gig_id}/start", headers={"Authorization": f"Bearer {token_w}"})
    assert res_start.status_code == 200
    assert res_start.json()["data"]["status"] == "IN_PROGRESS"

    # In DB
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig.status == GigStatus.IN_PROGRESS

    # Audit event
    event = (
        db_session.query(GigEvent)
        .filter(GigEvent.gig_id == uuid.UUID(gig_id), GigEvent.event_type == "WORK_STARTED")
        .first()
    )
    assert event is not None
    assert event.actor_id == uuid.UUID(w["id"])

    # Attempting to start again fails
    res_start2 = client.post(f"/api/v1/gigs/{gig_id}/start", headers={"Authorization": f"Bearer {token_w}"})
    assert res_start2.status_code == 400
    assert res_start2.json()["error"]["code"] == "INVALID_GIG_STATE"


# --- 3. Completion Submission & Intentional Active States ---

def test_completion_submission_from_active_states(client: TestClient, db_session: Session):
    """Worker can submit completion from active states (WORKER_SELECTED and IN_PROGRESS)."""
    # Case A: Directly from WORKER_SELECTED (intentional MVP decision)
    token_cust, _, token_w, w, gig_id = setup_selected_gig(client, db_session, email_prefix="sub_direct")

    payload = {
        "description": "Repaired kitchen sink pipe and sealed joint.",
        "evidence_items": [
            {"file_url": "https://storage.sahakaar.org/evidence/sink_after.jpg", "file_type": "image/jpeg"},
            {"file_url": "https://storage.sahakaar.org/evidence/seal_proof.jpg", "file_type": "image/jpeg"},
        ],
    }
    res_sub = client.post(
        f"/api/v1/gigs/{gig_id}/completion",
        headers={"Authorization": f"Bearer {token_w}"},
        json=payload,
    )
    assert res_sub.status_code == 200
    sub_data = res_sub.json()["data"]
    assert sub_data["gig_id"] == gig_id
    assert sub_data["worker_id"] == w["id"]
    assert sub_data["description"] == payload["description"]
    assert len(sub_data["evidence_files"]) == 2

    # Verify gig state
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig.status == GigStatus.COMPLETION_SUBMITTED

    # Verify audit event and customer notification
    event = (
        db_session.query(GigEvent)
        .filter(GigEvent.gig_id == uuid.UUID(gig_id), GigEvent.event_type == "COMPLETION_SUBMITTED")
        .first()
    )
    assert event is not None
    assert event.metadata_json["evidence_count"] == 2

    notif = (
        db_session.query(Notification)
        .filter(Notification.gig_id == uuid.UUID(gig_id), Notification.type == "COMPLETION_SUBMITTED")
        .first()
    )
    assert notif is not None
    assert notif.recipient_id == gig.customer_id


# --- 4. Get Completion Details ---

def test_get_completion_details(client: TestClient, db_session: Session):
    """Customer and assigned worker can view completion evidence; unassigned users are denied."""
    token_cust, cust, token_w, w, gig_id = setup_selected_gig(client, db_session, email_prefix="get_comp")

    # Worker submits completion
    client.post(
        f"/api/v1/gigs/{gig_id}/completion",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"description": "Pipe replaced", "evidence_items": [{"file_url": "https://proof.jpg", "file_type": "image/jpeg"}]},
    )

    # 1. Customer can view
    res_cust = client.get(f"/api/v1/gigs/{gig_id}/completion", headers={"Authorization": f"Bearer {token_cust}"})
    assert res_cust.status_code == 200
    assert res_cust.json()["data"]["submission"]["description"] == "Pipe replaced"
    assert len(res_cust.json()["data"]["submission"]["evidence_files"]) == 1

    # 2. Worker can view
    res_worker = client.get(f"/api/v1/gigs/{gig_id}/completion", headers={"Authorization": f"Bearer {token_w}"})
    assert res_worker.status_code == 200
    assert res_worker.json()["data"]["submission"]["description"] == "Pipe replaced"

    # 3. Third-party customer denied
    token_other_c, _ = create_test_customer(client, db_session, email_prefix="intruder_c")
    res_intruder = client.get(f"/api/v1/gigs/{gig_id}/completion", headers={"Authorization": f"Bearer {token_other_c}"})
    assert res_intruder.status_code == 403


# --- 5. Customer Confirms Completion ---

def test_customer_confirms_completion(client: TestClient, db_session: Session):
    """Customer confirms completion: gig status moves to CUSTOMER_CONFIRMED, audit logged, worker notified."""
    token_cust, _, token_w, w, gig_id = setup_selected_gig(client, db_session, email_prefix="conf_comp")

    client.post(
        f"/api/v1/gigs/{gig_id}/completion",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"description": "Finished", "evidence_items": [{"file_url": "https://img.jpg", "file_type": "image/jpeg"}]},
    )

    res_confirm = client.post(
        f"/api/v1/gigs/{gig_id}/completion/confirm",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"confirmed": True, "response_note": "Great quality work!"},
    )
    assert res_confirm.status_code == 200
    assert res_confirm.json()["data"]["confirmed"] is True

    # Gig status
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig.status == GigStatus.CUSTOMER_CONFIRMED

    # Audit event & notification
    event = (
        db_session.query(GigEvent)
        .filter(GigEvent.gig_id == uuid.UUID(gig_id), GigEvent.event_type == "COMPLETION_CONFIRMED")
        .first()
    )
    assert event is not None

    notif = (
        db_session.query(Notification)
        .filter(Notification.gig_id == uuid.UUID(gig_id), Notification.type == "COMPLETION_CONFIRMED")
        .first()
    )
    assert notif is not None
    assert notif.recipient_id == uuid.UUID(w["id"])


# --- 6. End-to-End Rework & Resubmission Cycle ---

def test_rework_loop_end_to_end_resubmission(client: TestClient, db_session: Session):
    """Customer rejects completion -> returns gig to IN_PROGRESS -> worker resubmits -> customer approves."""
    token_cust, _, token_w, w, gig_id = setup_selected_gig(client, db_session, email_prefix="rework_e2e")

    # Step 1: Worker starts work & submits initial evidence
    client.post(f"/api/v1/gigs/{gig_id}/start", headers={"Authorization": f"Bearer {token_w}"})
    client.post(
        f"/api/v1/gigs/{gig_id}/completion",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"description": "Initial attempt", "evidence_items": [{"file_url": "https://initial.jpg", "file_type": "image/jpeg"}]},
    )

    # Step 2: Customer rejects completion (rework requested)
    res_reject = client.post(
        f"/api/v1/gigs/{gig_id}/completion/confirm",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"confirmed": False, "response_note": "Water is still leaking around the base valve."},
    )
    assert res_reject.status_code == 200
    assert res_reject.json()["data"]["confirmed"] is False

    # Gig must revert to IN_PROGRESS (approved active rework state)
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig.status == GigStatus.IN_PROGRESS

    # Audit event COMPLETION_REJECTED & notification
    event_rej = (
        db_session.query(GigEvent)
        .filter(GigEvent.gig_id == uuid.UUID(gig_id), GigEvent.event_type == "COMPLETION_REJECTED")
        .first()
    )
    assert event_rej is not None
    assert event_rej.metadata_json["response_note"] == "Water is still leaking around the base valve."

    notif_rej = (
        db_session.query(Notification)
        .filter(Notification.gig_id == uuid.UUID(gig_id), Notification.type == "COMPLETION_REJECTED")
        .first()
    )
    assert notif_rej is not None
    assert notif_rej.type == "COMPLETION_REJECTED"

    # Step 3: Worker addresses feedback and resubmits completion
    res_resub = client.post(
        f"/api/v1/gigs/{gig_id}/completion",
        headers={"Authorization": f"Bearer {token_w}"},
        json={
            "description": "Replaced valve washer and tightened pipe fitting. Zero leaks now.",
            "evidence_items": [
                {"file_url": "https://fixed_valve.jpg", "file_type": "image/jpeg"},
                {"file_url": "https://dry_test.jpg", "file_type": "image/jpeg"},
            ],
        },
    )
    assert res_resub.status_code == 200

    db_session.refresh(gig)
    assert gig.status == GigStatus.COMPLETION_SUBMITTED

    # Step 4: Customer approves final work
    res_approve = client.post(
        f"/api/v1/gigs/{gig_id}/completion/confirm",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"confirmed": True, "response_note": "Now it looks completely dry and solid. Approved!"},
    )
    assert res_approve.status_code == 200
    assert res_approve.json()["data"]["confirmed"] is True

    db_session.refresh(gig)
    assert gig.status == GigStatus.CUSTOMER_CONFIRMED


# --- 7. Authorization & State Validation Errors ---

def test_authorization_and_state_validations(client: TestClient, db_session: Session):
    """Enforces strict role checks and state boundaries on execution/completion endpoints."""
    token_cust, _, token_w, w, gig_id = setup_selected_gig(client, db_session, email_prefix="auth_err")
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    token_other_w, other_w = create_test_worker(client, db_session, plumbing.id, email_prefix="other_w7")

    # 1. Customer cannot call /start or /completion (worker endpoints)
    res_c_start = client.post(f"/api/v1/gigs/{gig_id}/start", headers={"Authorization": f"Bearer {token_cust}"})
    assert res_c_start.status_code == 403

    res_c_sub = client.post(
        f"/api/v1/gigs/{gig_id}/completion",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"evidence_items": [{"file_url": "https://x.jpg", "file_type": "image/jpeg"}]},
    )
    assert res_c_sub.status_code == 403

    # 2. Unassigned worker cannot call /start or /completion
    res_other_start = client.post(f"/api/v1/gigs/{gig_id}/start", headers={"Authorization": f"Bearer {token_other_w}"})
    assert res_other_start.status_code == 403

    res_other_sub = client.post(
        f"/api/v1/gigs/{gig_id}/completion",
        headers={"Authorization": f"Bearer {token_other_w}"},
        json={"evidence_items": [{"file_url": "https://x.jpg", "file_type": "image/jpeg"}]},
    )
    assert res_other_sub.status_code == 403

    # 3. Worker cannot confirm completion (customer endpoint)
    res_w_conf = client.post(
        f"/api/v1/gigs/{gig_id}/completion/confirm",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"confirmed": True},
    )
    assert res_w_conf.status_code == 403

    # 4. Cannot confirm completion if gig is not yet in COMPLETION_SUBMITTED
    res_early_conf = client.post(
        f"/api/v1/gigs/{gig_id}/completion/confirm",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"confirmed": True},
    )
    assert res_early_conf.status_code == 400
    assert res_early_conf.json()["error"]["code"] == "INVALID_GIG_STATE"

    # 5. Cannot submit completion without evidence items
    res_empty_ev = client.post(
        f"/api/v1/gigs/{gig_id}/completion",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"description": "No pictures", "evidence_items": []},
    )
    assert res_empty_ev.status_code == 422  # Pydantic min_length=1 validation error


# --- 8. Atomic Rollback on Failure ---

def test_atomic_rollback_on_completion_submission_failure(client: TestClient, db_session: Session, monkeypatch):
    """If notification or audit event fails during completion submission, gig status and submission revert cleanly."""
    token_cust, _, token_w, w, gig_id = setup_selected_gig(client, db_session, email_prefix="sub_fail")

    def mock_notification_init(*args, **kwargs):
        raise RuntimeError("Simulated notification service failure on completion")

    monkeypatch.setattr("app.services.completion_service.Notification", mock_notification_init)

    with pytest.raises(RuntimeError, match="Simulated notification service failure on completion"):
        from app.services.completion_service import CompletionService
        from app.schemas.completion import CompletionSubmissionRequest, CompletionEvidenceCreate

        worker_user = db_session.query(User).filter(User.id == uuid.UUID(w["id"])).first()
        req = CompletionSubmissionRequest(
            description="Test",
            evidence_items=[CompletionEvidenceCreate(file_url="https://x.jpg", file_type="image/jpeg")],
        )
        CompletionService.submit_completion(worker_user, uuid.UUID(gig_id), req, db_session)

    # In database, gig must still be in WORKER_SELECTED, and no submission record created
    db_session.rollback()
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig.status == GigStatus.WORKER_SELECTED

    submissions = db_session.query(CompletionSubmission).filter(CompletionSubmission.gig_id == uuid.UUID(gig_id)).all()
    assert len(submissions) == 0
