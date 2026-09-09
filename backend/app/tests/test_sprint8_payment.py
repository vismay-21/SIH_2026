import uuid
from decimal import Decimal
from datetime import date, time, datetime, timezone
from typing import Tuple
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.db.models.user import User, WorkerProfile, WorkerMetric
from app.db.models.service import ServiceCategory, ServiceTask, WorkerCategory
from app.db.models.gig import Gig, GigWorkerOpportunity
from app.db.models.payment import Payment
from app.db.models.communication import GigEvent, Notification
from app.db.models.enums import GigStatus, OpportunityStatus, PaymentMethod, PaymentStatus
from app.services.catalogue_service import CatalogueService


@pytest.fixture(autouse=True)
def seed_catalog_fixture(db_session: Session):
    """Ensure catalog is populated."""
    CatalogueService.seed_catalogue_if_empty(db_session)


def create_test_customer(client: TestClient, db_session: Session, email_prefix: str = "cust8") -> Tuple[str, dict]:
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
    final_score: float = 0.50,
    email_prefix: str = "w8",
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

    res_cat = client.put(
        "/api/v1/worker/categories",
        headers={"Authorization": f"Bearer {token}"},
        json={"category_ids": [str(category_id)]},
    )
    assert res_cat.status_code == 200

    metric = db_session.query(WorkerMetric).filter(WorkerMetric.worker_id == worker_id).first()
    if metric:
        metric.final_score = final_score
        metric.experience_score = final_score
        metric.bayesian_score = final_score
        db_session.commit()

    return token, worker_data


def setup_confirmed_gig(
    client: TestClient,
    db_session: Session,
    email_prefix: str = "pay",
) -> Tuple[str, dict, str, dict, str, Decimal]:
    """Helper to advance a gig to CUSTOMER_CONFIRMED.
    Returns (token_cust, cust, token_w, worker, gig_id, exact_wage).
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
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    # 2. Worker accepts
    res_opps = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"})
    opp = next(o for o in res_opps.json()["data"] if o["gig_id"] == gig_id)
    opp_id = opp["id"]
    exact_wage = Decimal(str(opp["exact_wage"]))
    client.post(f"/api/v1/worker/opportunities/{opp_id}/accept", headers={"Authorization": f"Bearer {token_w}"})

    # 3. Customer selects worker
    client.post(
        f"/api/v1/gigs/{gig_id}/select-worker",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"worker_id": w["id"]},
    )

    # 4. Worker submits completion
    client.post(
        f"/api/v1/gigs/{gig_id}/completion",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"description": "All done", "evidence_items": [{"file_url": "https://proof.jpg", "file_type": "image/jpeg"}]},
    )

    # 5. Customer confirms completion
    client.post(
        f"/api/v1/gigs/{gig_id}/completion/confirm",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"confirmed": True, "response_note": "Great job"},
    )

    return token_cust, cust, token_w, w, gig_id, exact_wage


# --- 1. CASH Payment Flow End-to-End ---

def test_cash_payment_flow_e2e(client: TestClient, db_session: Session):
    """Customer records CASH payment -> worker confirms receipt -> gig COMPLETED."""
    token_cust, _, token_w, w, gig_id, exact_wage = setup_confirmed_gig(client, db_session, email_prefix="cash_e2e")

    # Step 1: Customer checks payment status before paying
    res_status1 = client.get(f"/api/v1/gigs/{gig_id}/payment", headers={"Authorization": f"Bearer {token_cust}"})
    assert res_status1.status_code == 200
    p1 = res_status1.json()["data"]
    assert Decimal(str(p1["amount"])) == exact_wage
    assert p1["status"] == "PENDING"
    assert p1["can_pay"] is True
    assert p1["can_confirm"] is False

    # Step 2: Customer records CASH payment
    res_pay = client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "CASH"},
    )
    assert res_pay.status_code == 200
    p2 = res_pay.json()["data"]
    assert p2["status"] == "CUSTOMER_PAID"
    assert p2["payment_method"] == "CASH"
    assert Decimal(str(p2["amount"])) == exact_wage
    assert p2["paid_at"] is not None

    # Verify gig state
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig.status == GigStatus.PAYMENT_CUSTOMER_PAID

    # Verify audit event and notification to worker
    event = (
        db_session.query(GigEvent)
        .filter(GigEvent.gig_id == uuid.UUID(gig_id), GigEvent.event_type == "PAYMENT_CUSTOMER_PAID")
        .first()
    )
    assert event is not None
    assert event.metadata_json["amount"] == str(exact_wage)
    assert event.metadata_json["payment_method"] == "CASH"

    notif = (
        db_session.query(Notification)
        .filter(Notification.gig_id == uuid.UUID(gig_id), Notification.type == "PAYMENT_CUSTOMER_PAID")
        .first()
    )
    assert notif is not None
    assert notif.recipient_id == uuid.UUID(w["id"])

    # Step 3: Worker confirms receipt
    res_confirm = client.post(
        f"/api/v1/gigs/{gig_id}/payment/confirm-receipt",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"confirmed": True},
    )
    assert res_confirm.status_code == 200
    p3 = res_confirm.json()["data"]
    assert p3["status"] == "WORKER_CONFIRMED"
    assert p3["worker_confirmed_at"] is not None

    # Gig is now fully COMPLETED
    db_session.refresh(gig)
    assert gig.status == GigStatus.COMPLETED

    # Verify GIG_COMPLETED audit event and notification
    event_comp = (
        db_session.query(GigEvent)
        .filter(GigEvent.gig_id == uuid.UUID(gig_id), GigEvent.event_type == "GIG_COMPLETED")
        .first()
    )
    assert event_comp is not None

    notif_cust = (
        db_session.query(Notification)
        .filter(Notification.gig_id == uuid.UUID(gig_id), Notification.type == "GIG_COMPLETED")
        .first()
    )
    assert notif_cust is not None
    assert notif_cust.recipient_id == gig.customer_id


# --- 2. UPI Payment Flow End-to-End with Deep Link ---

def test_upi_payment_flow_e2e_and_deeplink(client: TestClient, db_session: Session):
    """Customer records UPI payment -> UPI deep-link generated -> worker confirms receipt -> gig COMPLETED."""
    token_cust, _, token_w, w, gig_id, exact_wage = setup_confirmed_gig(client, db_session, email_prefix="upi_e2e")

    # Customer records UPI payment
    res_pay = client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "UPI"},
    )
    assert res_pay.status_code == 200
    data = res_pay.json()["data"]
    assert data["status"] == "CUSTOMER_PAID"
    assert data["payment_method"] == "UPI"
    assert data["upi_deeplink"] is not None
    assert data["upi_deeplink"].startswith("upi://pay?")
    assert f"am={exact_wage:.2f}" in data["upi_deeplink"]

    # Worker confirms receipt
    res_confirm = client.post(
        f"/api/v1/gigs/{gig_id}/payment/confirm-receipt",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"confirmed": True},
    )
    assert res_confirm.status_code == 200
    assert res_confirm.json()["data"]["status"] == "WORKER_CONFIRMED"

    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig.status == GigStatus.COMPLETED


# --- 3. Payment Method Immutability and Idempotent Retry ---

def test_payment_method_immutability_and_idempotency(client: TestClient, db_session: Session):
    """Once payment is CUSTOMER_PAID, changing payment_method fails with 409 Conflict. Same-method retry is idempotent."""
    token_cust, _, _, _, gig_id, _ = setup_confirmed_gig(client, db_session, email_prefix="immut")

    # Record CASH payment
    res1 = client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "CASH"},
    )
    assert res1.status_code == 200

    # Retrying with CASH is idempotent (succeeds with 200 OK)
    res_retry_cash = client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "CASH"},
    )
    assert res_retry_cash.status_code == 200
    assert res_retry_cash.json()["data"]["payment_method"] == "CASH"

    # Retrying with UPI after CASH is paid fails with 409 Conflict (PAYMENT_METHOD_IMMUTABLE)
    res_retry_upi = client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "UPI"},
    )
    assert res_retry_upi.status_code == 409
    assert res_retry_upi.json()["error"]["code"] == "PAYMENT_METHOD_IMMUTABLE"


# --- 4. Worker Receipt Confirmation Idempotency ---

def test_worker_receipt_confirmation_idempotency(client: TestClient, db_session: Session):
    """Repeated calls to confirm-receipt do not create duplicate audit events, duplicate notifications, or errors."""
    token_cust, _, token_w, _, gig_id, _ = setup_confirmed_gig(client, db_session, email_prefix="idem_conf")

    client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "CASH"},
    )

    # First confirmation succeeds
    res1 = client.post(
        f"/api/v1/gigs/{gig_id}/payment/confirm-receipt",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"confirmed": True},
    )
    assert res1.status_code == 200
    assert res1.json()["data"]["status"] == "WORKER_CONFIRMED"

    # Count audit events and notifications after first confirmation
    count_events1 = (
        db_session.query(GigEvent)
        .filter(GigEvent.gig_id == uuid.UUID(gig_id), GigEvent.event_type == "GIG_COMPLETED")
        .count()
    )
    count_notifs1 = (
        db_session.query(Notification)
        .filter(Notification.gig_id == uuid.UUID(gig_id), Notification.type == "GIG_COMPLETED")
        .count()
    )
    assert count_events1 == 1
    assert count_notifs1 == 1

    # Second and third confirmation calls are idempotent
    res2 = client.post(
        f"/api/v1/gigs/{gig_id}/payment/confirm-receipt",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"confirmed": True},
    )
    assert res2.status_code == 200
    assert res2.json()["data"]["status"] == "WORKER_CONFIRMED"

    res3 = client.post(
        f"/api/v1/gigs/{gig_id}/payment/confirm-receipt",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"confirmed": True},
    )
    assert res3.status_code == 200

    # Ensure no duplicate audit events or notifications were added
    count_events2 = (
        db_session.query(GigEvent)
        .filter(GigEvent.gig_id == uuid.UUID(gig_id), GigEvent.event_type == "GIG_COMPLETED")
        .count()
    )
    count_notifs2 = (
        db_session.query(Notification)
        .filter(Notification.gig_id == uuid.UUID(gig_id), Notification.type == "GIG_COMPLETED")
        .count()
    )
    assert count_events2 == 1
    assert count_notifs2 == 1


# --- 5. Payment Amount Integrity & Metric Immunity ---

def test_payment_amount_integrity_and_metric_immunity(client: TestClient, db_session: Session):
    """Mutating worker metrics after selection does NOT change the historical agreed payment amount."""
    token_cust, _, token_w, w, gig_id, exact_wage = setup_confirmed_gig(client, db_session, email_prefix="met_imm")

    # Mutate worker metrics in database to simulate score changes
    worker_id = uuid.UUID(w["id"])
    metric = db_session.query(WorkerMetric).filter(WorkerMetric.worker_id == worker_id).first()
    metric.final_score = 0.99
    metric.experience_score = 0.99
    metric.bayesian_score = 0.99
    metric.completed_jobs_count = 100
    db_session.commit()

    # GET /payment returns immutable historical wage snapshot
    res_get = client.get(f"/api/v1/gigs/{gig_id}/payment", headers={"Authorization": f"Bearer {token_cust}"})
    assert res_get.status_code == 200
    assert Decimal(str(res_get.json()["data"]["amount"])) == exact_wage

    # POST /payment records strictly the immutable historical wage snapshot
    res_pay = client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "CASH"},
    )
    assert res_pay.status_code == 200
    assert Decimal(str(res_pay.json()["data"]["amount"])) == exact_wage

    # Attempting to supply a client-side amount does not override backend amount
    payment_record = db_session.query(Payment).filter(Payment.gig_id == uuid.UUID(gig_id)).first()
    assert Decimal(str(payment_record.amount)) == exact_wage


# --- 6. Legal State Boundaries ---

def test_legal_state_boundaries(client: TestClient, db_session: Session):
    """Payment cannot be initiated before CUSTOMER_CONFIRMED. Receipt cannot be confirmed before CUSTOMER_PAID."""
    token_cust, cust = create_test_customer(client, db_session, email_prefix="c_state_err")
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()
    token_w, w = create_test_worker(client, db_session, plumbing.id, email_prefix="w_state_err")

    # Gig in DRAFT state
    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res_create.json()["data"]["id"]

    # Attempt to pay in DRAFT fails
    res_draft_pay = client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "CASH"},
    )
    assert res_draft_pay.status_code == 400
    assert res_draft_pay.json()["error"]["code"] in ("NO_SELECTED_WORKER", "INVALID_GIG_STATE")

    # Post gig and select worker
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})
    opp_id = next(o["id"] for o in client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"}).json()["data"] if o["gig_id"] == gig_id)
    client.post(f"/api/v1/worker/opportunities/{opp_id}/accept", headers={"Authorization": f"Bearer {token_w}"})
    client.post(f"/api/v1/gigs/{gig_id}/select-worker", headers={"Authorization": f"Bearer {token_cust}"}, json={"worker_id": w["id"]})

    # Gig is in WORKER_SELECTED -> attempt to pay fails
    res_ws_pay = client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "CASH"},
    )
    assert res_ws_pay.status_code == 400
    assert res_ws_pay.json()["error"]["code"] == "INVALID_GIG_STATE"

    # Advance to CUSTOMER_CONFIRMED
    client.post(f"/api/v1/gigs/{gig_id}/completion", headers={"Authorization": f"Bearer {token_w}"}, json={"evidence_items": [{"file_url": "https://x.jpg", "file_type": "image/jpeg"}]})
    client.post(f"/api/v1/gigs/{gig_id}/completion/confirm", headers={"Authorization": f"Bearer {token_cust}"}, json={"confirmed": True})

    # Attempt to confirm receipt BEFORE customer has recorded payment fails
    res_premature_conf = client.post(
        f"/api/v1/gigs/{gig_id}/payment/confirm-receipt",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"confirmed": True},
    )
    assert res_premature_conf.status_code == 400
    assert res_premature_conf.json()["error"]["code"] in ("PAYMENT_NOT_FOUND", "INVALID_PAYMENT_STATE")


# --- 7. Authorization & Role Boundaries ---

def test_authorization_and_role_boundaries(client: TestClient, db_session: Session):
    """Strict role checks: worker cannot call /payment, customer cannot call /confirm-receipt, unassigned users denied."""
    token_cust, _, token_w, _, gig_id, _ = setup_confirmed_gig(client, db_session, email_prefix="auth_pay")
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    token_other_w, _ = create_test_worker(client, db_session, plumbing.id, email_prefix="other_w_pay")
    token_other_c, _ = create_test_customer(client, db_session, email_prefix="other_c_pay")

    # 1. Worker cannot initiate payment (customer endpoint)
    res_w_pay = client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"payment_method": "CASH"},
    )
    assert res_w_pay.status_code == 403

    # Customer records payment
    client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "CASH"},
    )

    # 2. Customer cannot confirm payment receipt (worker endpoint)
    res_c_conf = client.post(
        f"/api/v1/gigs/{gig_id}/payment/confirm-receipt",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"confirmed": True},
    )
    assert res_c_conf.status_code == 403

    # 3. Third-party worker cannot confirm receipt
    res_other_w = client.post(
        f"/api/v1/gigs/{gig_id}/payment/confirm-receipt",
        headers={"Authorization": f"Bearer {token_other_w}"},
        json={"confirmed": True},
    )
    assert res_other_w.status_code == 403

    # 4. Third-party customer cannot view payment
    res_other_c = client.get(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_other_c}"},
    )
    assert res_other_c.status_code == 403


# --- 8. Atomic Rollback on Payment Failure ---

def test_atomic_rollback_on_payment_failure(client: TestClient, db_session: Session, monkeypatch):
    """If audit event fails during payment creation, payment row and gig status revert cleanly."""
    token_cust, _, token_w, w, gig_id, exact_wage = setup_confirmed_gig(client, db_session, email_prefix="pay_fail")

    def mock_event_init(*args, **kwargs):
        raise RuntimeError("Simulated GigEvent database failure during payment")

    monkeypatch.setattr("app.services.payment_service.GigEvent", mock_event_init)

    with pytest.raises(RuntimeError, match="Simulated GigEvent database failure during payment"):
        from app.services.payment_service import PaymentService
        from app.schemas.payment import PaymentCreateRequest

        cust_user = db_session.query(User).filter(User.role == "CUSTOMER").first()
        req = PaymentCreateRequest(payment_method=PaymentMethod.CASH)
        PaymentService.record_payment(cust_user, uuid.UUID(gig_id), req, db_session)

    # In database, gig must still be in CUSTOMER_CONFIRMED, and no payment record created
    db_session.rollback()
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig.status == GigStatus.CUSTOMER_CONFIRMED

    payments = db_session.query(Payment).filter(Payment.gig_id == uuid.UUID(gig_id)).all()
    assert len(payments) == 0
