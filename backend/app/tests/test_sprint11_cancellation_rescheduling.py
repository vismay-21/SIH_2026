import uuid
from decimal import Decimal
from datetime import date, time, datetime, timezone, timedelta
from typing import Tuple
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.db.models.user import User, WorkerProfile, WorkerMetric
from app.db.models.cooperative import Cooperative
from app.db.models.service import ServiceCategory, ServiceTask, WorkerCategory, WorkerAvailability
from app.db.models.gig import Gig, GigWorkerOpportunity
from app.db.models.payment import Payment
from app.db.models.cancellation import GigCancellation, RescheduleRequest
from app.db.models.communication import GigEvent, Notification
from app.db.models.enums import (
    GigStatus,
    OpportunityStatus,
    PaymentMethod,
    PaymentStatus,
    PaymentType,
    RescheduleStatus,
    UserRole,
)
from app.services.catalogue_service import CatalogueService


@pytest.fixture(autouse=True)
def seed_catalog_fixture(db_session: Session):
    """Ensure catalog is populated."""
    CatalogueService.seed_catalogue_if_empty(db_session)


def create_test_customer(client: TestClient, db_session: Session, email_prefix: str = "cust11") -> Tuple[str, dict]:
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
    email_prefix: str = "w11",
    with_weekly_availability: bool = True,
) -> Tuple[str, dict]:
    """Helper to initialize a worker with category, optional availability, and return (jwt_token, user_dict)."""
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

    if with_weekly_availability:
        # Define availability for Monday-Sunday from 08:00 to 20:00
        profile = db_session.query(WorkerProfile).filter(WorkerProfile.user_id == worker_id).first()
        if profile:
            for day in range(7):
                db_session.add(
                    WorkerAvailability(
                        worker_id=profile.user_id,
                        day_of_week=day,
                        start_time=time(8, 0),
                        end_time=time(20, 0),
                        is_available=True,
                    )
                )
            db_session.commit()

    return token, worker_data


def setup_agreed_gig(
    client: TestClient,
    db_session: Session,
    email_prefix: str = "s11",
    advance_to_scheduled: bool = False,
) -> Tuple[str, dict, str, dict, str]:
    """Helper to create and advance a gig to WORKER_SELECTED (or SCHEDULED).
    Returns (token_cust, cust, token_w, worker, gig_id).
    """
    token_cust, cust = create_test_customer(client, db_session, email_prefix=f"c_{email_prefix}")
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_w, w = create_test_worker(client, db_session, plumbing.id, final_score=0.50, email_prefix=f"w_{email_prefix}")

    future_date = (datetime.now(timezone.utc) + timedelta(days=2)).date()

    # 1. Customer creates and posts gig
    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task.id)],
            "scheduled_date": future_date.isoformat(),
            "scheduled_start_time": "10:00:00",
            "scheduled_end_time": "12:00:00",
        },
    )
    assert res_create.status_code == 201
    gig_id = res_create.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    # 2. Worker accepts
    res_opps = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"})
    opp = next(o for o in res_opps.json()["data"] if o["gig_id"] == gig_id)
    opp_id = opp["id"]
    client.post(f"/api/v1/worker/opportunities/{opp_id}/accept", headers={"Authorization": f"Bearer {token_w}"})

    # 3. Customer selects worker -> WORKER_SELECTED
    res_select = client.post(
        f"/api/v1/gigs/{gig_id}/select-worker",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"worker_id": w["id"]},
    )
    assert res_select.status_code == 200

    if advance_to_scheduled:
        gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
        gig.status = GigStatus.SCHEDULED
        db_session.commit()

    return token_cust, cust, token_w, w, gig_id


# =========================================================================
# 1. CANCELLATION FEE CALCULATION & LIFECYCLE TESTS
# =========================================================================

def test_customer_cancel_draft_gig_free(client: TestClient, db_session: Session):
    """Customer cancels a DRAFT gig -> ₹0 fee, CANCELLED status, no payment required."""
    token_cust, cust = create_test_customer(client, db_session, email_prefix="cancel_draft")
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    res = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res.json()["data"]["id"]

    res_cancel = client.post(
        f"/api/v1/gigs/{gig_id}/cancel",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reason": "Customer no longer requires this service"},
    )
    assert res_cancel.status_code == 200
    data = res_cancel.json()["data"]
    assert data["status"] == "CANCELLED"
    assert Decimal(str(data["fee_amount"])) == Decimal("0.00")
    assert data["payment_required"] is False
    assert data["payment_status"] is None

    # Verify no payment record created
    payments = db_session.query(Payment).filter(Payment.gig_id == uuid.UUID(gig_id)).all()
    assert len(payments) == 0


def test_customer_cancel_posted_gig_free(client: TestClient, db_session: Session):
    """Customer cancels a POSTED gig before worker selection -> ₹0 fee."""
    token_cust, cust = create_test_customer(client, db_session, email_prefix="cancel_posted")
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    res = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    gig_id = res.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})

    res_cancel = client.post(
        f"/api/v1/gigs/{gig_id}/cancel",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reason": "Changed my mind about the plumbing work"},
    )
    assert res_cancel.status_code == 200
    assert Decimal(str(res_cancel.json()["data"]["fee_amount"])) == Decimal("0.00")
    assert res_cancel.json()["data"]["payment_required"] is False


def test_customer_cancel_after_worker_selected_fee_obligation(client: TestClient, db_session: Session):
    """Customer cancels in WORKER_SELECTED -> ₹50 fee obligation created, payment PENDING."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(client, db_session, email_prefix="cancel_sel")

    res_cancel = client.post(
        f"/api/v1/gigs/{gig_id}/cancel",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reason": "Need to cancel after worker was assigned"},
    )
    assert res_cancel.status_code == 200
    data = res_cancel.json()["data"]
    assert data["status"] == "CANCELLED"
    assert Decimal(str(data["fee_amount"])) == Decimal("50.00")
    assert data["payment_required"] is True
    assert data["payment_status"] == "PENDING"

    # Verify payment record in DB
    payment = db_session.query(Payment).filter(Payment.gig_id == uuid.UUID(gig_id)).first()
    assert payment is not None
    assert Decimal(str(payment.amount)) == Decimal("50.00")
    assert payment.payment_type == PaymentType.CANCELLATION
    assert payment.status == PaymentStatus.PENDING
    assert payment.customer_id == uuid.UUID(cust["id"])
    assert payment.worker_id == uuid.UUID(w["id"])


def test_customer_cancel_in_scheduled_fee_obligation(client: TestClient, db_session: Session):
    """Customer cancels in SCHEDULED -> ₹50 fee obligation created."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(
        client, db_session, email_prefix="cancel_sched", advance_to_scheduled=True
    )

    res_cancel = client.post(
        f"/api/v1/gigs/{gig_id}/cancel",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reason": "Emergency travel arose, cancelling appointment"},
    )
    assert res_cancel.status_code == 200
    data = res_cancel.json()["data"]
    assert data["status"] == "CANCELLED"
    assert Decimal(str(data["fee_amount"])) == Decimal("50.00")
    assert data["payment_required"] is True


def test_worker_cancel_in_worker_selected_free(client: TestClient, db_session: Session):
    """Worker cancels in WORKER_SELECTED -> ₹0 fee, gig CANCELLED."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(client, db_session, email_prefix="w_cancel_sel")

    res_cancel = client.post(
        f"/api/v1/gigs/{gig_id}/cancel",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"reason": "Equipment broke down, cannot take job"},
    )
    assert res_cancel.status_code == 200
    data = res_cancel.json()["data"]
    assert data["status"] == "CANCELLED"
    assert Decimal(str(data["fee_amount"])) == Decimal("0.00")
    assert data["payment_required"] is False
    assert data["cancelled_by"] == w["id"]


# =========================================================================
# 2. CANCELLATION PAYMENT SETTLEMENT & INVARIANTS
# =========================================================================

def test_cancellation_payment_settlement_e2e(client: TestClient, db_session: Session):
    """Customer pays ₹50 fee -> Worker confirms receipt -> Gig strictly REMAINS CANCELLED."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(client, db_session, email_prefix="settle_e2e")

    # Step 1: Customer cancels
    res_cancel = client.post(
        f"/api/v1/gigs/{gig_id}/cancel",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reason": "Personal reasons for cancellation"},
    )
    assert res_cancel.status_code == 200

    # Step 2: Customer checks payment status
    res_pay_status = client.get(f"/api/v1/gigs/{gig_id}/payment", headers={"Authorization": f"Bearer {token_cust}"})
    assert res_pay_status.status_code == 200
    ps1 = res_pay_status.json()["data"]
    assert Decimal(str(ps1["amount"])) == Decimal("50.00")
    assert ps1["status"] == "PENDING"
    assert ps1["payment_type"] == "CANCELLATION"
    assert ps1["can_pay"] is True
    assert ps1["can_confirm"] is False

    # Step 3: Customer pays via UPI
    res_pay = client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "UPI"},
    )
    assert res_pay.status_code == 200
    ps2 = res_pay.json()["data"]
    assert ps2["status"] == "CUSTOMER_PAID"
    assert ps2["payment_method"] == "UPI"

    # Verify GIG STATUS REMAINS CANCELLED
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig.status == GigStatus.CANCELLED

    # Step 4: Worker checks status: can_confirm should now be True
    res_w_status = client.get(f"/api/v1/gigs/{gig_id}/payment", headers={"Authorization": f"Bearer {token_w}"})
    assert res_w_status.status_code == 200
    ps_w = res_w_status.json()["data"]
    assert ps_w["can_confirm"] is True

    # Step 5: Worker confirms receipt
    res_confirm = client.post(
        f"/api/v1/gigs/{gig_id}/payment/confirm-receipt",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"confirmed": True},
    )
    assert res_confirm.status_code == 200
    ps3 = res_confirm.json()["data"]
    assert ps3["status"] == "WORKER_CONFIRMED"

    # Invariant: GIG STATUS NEVER MOVES TO COMPLETED - IT STAYS CANCELLED
    db_session.refresh(gig)
    assert gig.status == GigStatus.CANCELLED


def test_cancellation_payment_method_immutability(client: TestClient, db_session: Session):
    """Once customer pays with UPI, switching to CASH triggers 409 Conflict."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(client, db_session, email_prefix="immut")

    client.post(
        f"/api/v1/gigs/{gig_id}/cancel",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reason": "Customer cancellation requiring settlement"},
    )

    # Customer records payment via UPI
    res_pay1 = client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "UPI"},
    )
    assert res_pay1.status_code == 200

    # Retry with CASH must fail with 409 Conflict
    res_pay2 = client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "CASH"},
    )
    assert res_pay2.status_code == 409
    assert res_pay2.json()["error"]["code"] == "PAYMENT_METHOD_IMMUTABLE"

    # Idempotent retry with UPI succeeds
    res_pay3 = client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "UPI"},
    )
    assert res_pay3.status_code == 200


# =========================================================================
# 3. CUSTOMER FINANCIAL INTEGRITY GUARD
# =========================================================================

def test_customer_blocked_from_creating_gigs_with_unsettled_fee(client: TestClient, db_session: Session):
    """Customer with an outstanding cancellation fee cannot create new gigs."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(client, db_session, email_prefix="guard")
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    # Cancel gig -> generates ₹50 fee in PENDING
    client.post(
        f"/api/v1/gigs/{gig_id}/cancel",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reason": "Cancelling with fee obligation"},
    )

    # Attempt to create a new gig while fee is PENDING -> 409 OUTSTANDING_CANCELLATION_PAYMENT
    res_new1 = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    assert res_new1.status_code == 409
    assert res_new1.json()["error"]["code"] == "OUTSTANDING_CANCELLATION_PAYMENT"

    # Customer pays fee -> status is CUSTOMER_PAID (still unsettled from worker perspective)
    client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "UPI"},
    )

    # Attempt again while CUSTOMER_PAID -> still 409
    res_new2 = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    assert res_new2.status_code == 409
    assert res_new2.json()["error"]["code"] == "OUTSTANDING_CANCELLATION_PAYMENT"

    # Worker confirms receipt -> WORKER_CONFIRMED
    client.post(
        f"/api/v1/gigs/{gig_id}/payment/confirm-receipt",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"confirmed": True},
    )

    # Now customer can create new gigs again!
    res_new3 = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(plumbing.id), "task_ids": [str(task.id)]},
    )
    assert res_new3.status_code == 201


# =========================================================================
# 4. GIG REOPENING POLICY TESTS
# =========================================================================

def test_customer_cannot_reopen_self_cancelled_gig(client: TestClient, db_session: Session):
    """Customer-cancelled gigs cannot be reopened for matching."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(client, db_session, email_prefix="reopen_cust")

    client.post(
        f"/api/v1/gigs/{gig_id}/cancel",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reason": "Customer cancels own gig"},
    )

    res_reopen = client.post(
        f"/api/v1/gigs/{gig_id}/reopen",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_reopen.status_code == 400
    assert res_reopen.json()["error"]["code"] == "CUSTOMER_CANCELLATION_CANNOT_REOPEN"


def test_customer_can_reopen_worker_cancelled_gig(client: TestClient, db_session: Session):
    """Worker cancels gig -> Customer successfully reopens gig -> GIG moves to POSTED."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(client, db_session, email_prefix="reopen_worker")

    # Worker cancels
    res_w_cancel = client.post(
        f"/api/v1/gigs/{gig_id}/cancel",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"reason": "Emergency vehicle failure cannot reach customer"},
    )
    assert res_w_cancel.status_code == 200

    # Customer reopens gig
    res_reopen = client.post(
        f"/api/v1/gigs/{gig_id}/reopen",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_reopen.status_code == 200
    data = res_reopen.json()["data"]
    assert data["status"] == "POSTED"

    # Verify gig state in DB
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig.status == GigStatus.POSTED
    assert gig.selected_worker_id is None


def test_unauthorized_reopen_rejected(client: TestClient, db_session: Session):
    """Only customer can reopen; worker attempting to reopen receives 403."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(client, db_session, email_prefix="reopen_forbid")

    client.post(
        f"/api/v1/gigs/{gig_id}/cancel",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"reason": "Worker cancel for permission test"},
    )

    res_reopen = client.post(
        f"/api/v1/gigs/{gig_id}/reopen",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    assert res_reopen.status_code == 403


# =========================================================================
# 5. CANCELLATION STATE RESTRICTIONS
# =========================================================================

def test_cannot_cancel_in_progress_gig(client: TestClient, db_session: Session):
    """Gigs IN_PROGRESS cannot be cancelled via standard cancellation."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(client, db_session, email_prefix="cancel_inprog")

    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    gig.status = GigStatus.IN_PROGRESS
    db_session.commit()

    res_cancel = client.post(
        f"/api/v1/gigs/{gig_id}/cancel",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reason": "Attempting to cancel mid-work"},
    )
    assert res_cancel.status_code == 409
    assert res_cancel.json()["error"]["code"] == "GIG_CANNOT_BE_CANCELLED"


def test_cannot_cancel_completed_gig(client: TestClient, db_session: Session):
    """COMPLETED gigs cannot be cancelled."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(client, db_session, email_prefix="cancel_done")

    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    gig.status = GigStatus.COMPLETED
    db_session.commit()

    res_cancel = client.post(
        f"/api/v1/gigs/{gig_id}/cancel",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reason": "Attempting to cancel after job is completed"},
    )
    assert res_cancel.status_code == 409
    assert res_cancel.json()["error"]["code"] == "GIG_CANNOT_BE_CANCELLED"


def test_unauthorized_user_cannot_cancel_gig(client: TestClient, db_session: Session):
    """An unrelated customer or worker cannot cancel someone else's gig."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(client, db_session, email_prefix="cancel_unauth")
    token_other, _ = create_test_customer(client, db_session, email_prefix="intruder")

    res_cancel = client.post(
        f"/api/v1/gigs/{gig_id}/cancel",
        headers={"Authorization": f"Bearer {token_other}"},
        json={"reason": "Malicious attempt to cancel stranger's gig"},
    )
    assert res_cancel.status_code == 403


# =========================================================================
# 6. RESCHEDULING NEGOTIATIONS
# =========================================================================

def test_reschedule_negotiation_full_flow_accept(client: TestClient, db_session: Session):
    """Customer requests reschedule -> Worker accepts -> Schedule updated to new slot."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(client, db_session, email_prefix="resched_acc")

    target_date = (datetime.now(timezone.utc) + timedelta(days=4)).date()

    # Customer proposes reschedule
    res_req = client.post(
        f"/api/v1/gigs/{gig_id}/reschedule",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "proposed_date": target_date.isoformat(),
            "proposed_start_time": "14:00:00",
            "proposed_end_time": "16:00:00",
            "reason": "Family visiting in morning, prefer afternoon",
        },
    )
    assert res_req.status_code == 200
    req_data = res_req.json()["data"]
    assert req_data["status"] == "REQUESTED"
    request_id = req_data["id"]

    # Requester cannot accept their own request
    res_self_acc = client.post(
        f"/api/v1/gigs/{gig_id}/reschedule/{request_id}/accept",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_self_acc.status_code == 403

    # Worker accepts reschedule
    res_acc = client.post(
        f"/api/v1/gigs/{gig_id}/reschedule/{request_id}/accept",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    assert res_acc.status_code == 200
    assert res_acc.json()["data"]["status"] == "ACCEPTED"

    # Verify gig updated
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig.scheduled_date == target_date
    assert gig.scheduled_start_time == time(14, 0)
    assert gig.scheduled_end_time == time(16, 0)
    assert gig.status == GigStatus.SCHEDULED


def test_reschedule_negotiation_reject(client: TestClient, db_session: Session):
    """Worker proposes reschedule -> Customer rejects -> Schedule remains unchanged."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(client, db_session, email_prefix="resched_rej")

    gig_before = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    orig_date = gig_before.scheduled_date
    orig_start = gig_before.scheduled_start_time

    target_date = (datetime.now(timezone.utc) + timedelta(days=5)).date()

    # Worker proposes reschedule
    res_req = client.post(
        f"/api/v1/gigs/{gig_id}/reschedule",
        headers={"Authorization": f"Bearer {token_w}"},
        json={
            "proposed_date": target_date.isoformat(),
            "proposed_start_time": "11:00:00",
            "proposed_end_time": "13:00:00",
            "reason": "Need to adjust timing",
        },
    )
    assert res_req.status_code == 200
    request_id = res_req.json()["data"]["id"]

    # Customer rejects
    res_rej = client.post(
        f"/api/v1/gigs/{gig_id}/reschedule/{request_id}/reject",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reason": "Cannot do that day"},
    )
    assert res_rej.status_code == 200
    assert res_rej.json()["data"]["status"] == "REJECTED"

    # Verify gig schedule stayed as original
    db_session.refresh(gig_before)
    assert gig_before.scheduled_date == orig_date
    assert gig_before.scheduled_start_time == orig_start


def test_reschedule_alternative_counter_proposal(client: TestClient, db_session: Session):
    """Customer requests -> Worker proposes alternative slot -> Customer accepts counter proposal."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(client, db_session, email_prefix="resched_alt")

    slot1_date = (datetime.now(timezone.utc) + timedelta(days=3)).date()
    slot2_date = (datetime.now(timezone.utc) + timedelta(days=4)).date()

    # Customer requests Slot 1
    res1 = client.post(
        f"/api/v1/gigs/{gig_id}/reschedule",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "proposed_date": slot1_date.isoformat(),
            "proposed_start_time": "09:00:00",
            "proposed_end_time": "11:00:00",
            "reason": "Slot 1 proposal",
        },
    )
    request1_id = res1.json()["data"]["id"]

    # Worker counters with Slot 2
    res2 = client.post(
        f"/api/v1/gigs/{gig_id}/reschedule/{request1_id}/alternative",
        headers={"Authorization": f"Bearer {token_w}"},
        json={
            "proposed_date": slot2_date.isoformat(),
            "proposed_start_time": "15:00:00",
            "proposed_end_time": "17:00:00",
            "reason": "How about next day afternoon?",
        },
    )
    assert res2.status_code == 200
    counter_req = res2.json()["data"]
    assert counter_req["status"] == "REQUESTED"
    assert counter_req["requested_by"] == w["id"]

    # Verify old request status is now ALTERNATIVE_PROPOSED
    old_req = db_session.query(RescheduleRequest).filter(RescheduleRequest.id == uuid.UUID(request1_id)).first()
    assert old_req.status == RescheduleStatus.ALTERNATIVE_PROPOSED

    # Customer accepts counter-proposal
    res_acc = client.post(
        f"/api/v1/gigs/{gig_id}/reschedule/{counter_req['id']}/accept",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_acc.status_code == 200

    # Verify gig has Slot 2
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig.scheduled_date == slot2_date
    assert gig.scheduled_start_time == time(15, 0)


def test_reschedule_conflict_rejected(client: TestClient, db_session: Session):
    """If worker already has a confirmed overlapping gig, reschedule is rejected with 409."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(client, db_session, email_prefix="resched_conf")
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()

    conflict_date = (datetime.now(timezone.utc) + timedelta(days=3)).date()

    coop = db_session.query(Cooperative).first()
    other_gig = Gig(
        customer_id=uuid.UUID(cust["id"]),
        cooperative_id=coop.id,
        category_id=plumbing.id,
        scheduled_date=conflict_date,
        scheduled_start_time=time(14, 0),
        scheduled_end_time=time(16, 0),
        selected_worker_id=uuid.UUID(w["id"]),
        status=GigStatus.SCHEDULED,
        description="Conflicting gig",
        address="123 Conflict Lane",
        base_price=Decimal("300.00"),
    )
    db_session.add(other_gig)
    db_session.commit()

    # Propose reschedule overlapping with 14:00 - 16:00 (e.g. 15:00 - 17:00)
    res_conflict = client.post(
        f"/api/v1/gigs/{gig_id}/reschedule",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "proposed_date": conflict_date.isoformat(),
            "proposed_start_time": "15:00:00",
            "proposed_end_time": "17:00:00",
            "reason": "Conflict test",
        },
    )
    assert res_conflict.status_code == 409
    assert res_conflict.json()["error"]["code"] == "WORKER_SCHEDULE_CONFLICT"


def test_reschedule_invalid_date_or_time_rejected(client: TestClient, db_session: Session):
    """Past date or start >= end returns 400 Bad Request."""
    token_cust, cust, token_w, w, gig_id = setup_agreed_gig(client, db_session, email_prefix="resched_inv")

    past_date = (datetime.now(timezone.utc) - timedelta(days=2)).date()

    # Past date
    res1 = client.post(
        f"/api/v1/gigs/{gig_id}/reschedule",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "proposed_date": past_date.isoformat(),
            "proposed_start_time": "10:00:00",
            "proposed_end_time": "12:00:00",
        },
    )
    assert res1.status_code == 400
    assert res1.json()["error"]["code"] == "INVALID_DATE"

    future_date = (datetime.now(timezone.utc) + timedelta(days=3)).date()

    # Start >= End
    res2 = client.post(
        f"/api/v1/gigs/{gig_id}/reschedule",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "proposed_date": future_date.isoformat(),
            "proposed_start_time": "14:00:00",
            "proposed_end_time": "12:00:00",
        },
    )
    assert res2.status_code == 400
    assert res2.json()["error"]["code"] == "INVALID_TIME_RANGE"
