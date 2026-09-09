import uuid
from decimal import Decimal
from datetime import datetime, timezone
from typing import Tuple
from unittest.mock import patch
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import create_access_token
from app.db.models.user import User, WorkerProfile, WorkerMetric
from app.db.models.service import ServiceCategory, ServiceTask
from app.db.models.gig import Gig, GigTask, GigWorkerOpportunity
from app.db.models.visitation import VisitationProposal, VisitationProposalTask
from app.db.models.payment import Payment
from app.db.models.communication import GigEvent, Notification
from app.db.models.enums import (
    GigType,
    GigStatus,
    PaymentMethod,
    PaymentStatus,
    VisitationProposalStatus,
)
from app.services.catalogue_service import CatalogueService


@pytest.fixture(autouse=True)
def seed_catalog_fixture(db_session: Session):
    """Ensure service catalogue is populated."""
    CatalogueService.seed_catalogue_if_empty(db_session)


def create_test_customer(client: TestClient, db_session: Session, email_prefix: str = "cust9") -> Tuple[str, dict]:
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
    email_prefix: str = "w9",
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


def setup_visitation_gig(
    client: TestClient,
    db_session: Session,
    email_prefix: str = "vis",
) -> Tuple[str, dict, str, dict, str, ServiceCategory, list]:
    """Helper to setup an IN_PROGRESS visitation gig with assigned worker.

    Returns (token_cust, cust, token_w, worker, gig_id, category, tasks).
    """
    token_cust, cust = create_test_customer(client, db_session, email_prefix=f"c_{email_prefix}")
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    tasks = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).all()
    assert len(tasks) >= 2

    token_w, w = create_test_worker(client, db_session, plumbing.id, final_score=0.50, email_prefix=f"w_{email_prefix}")

    # 1. Customer creates and posts gig
    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(tasks[0].id)],
            "gig_type": "VISITATION",
        },
    )
    assert res_create.status_code == 201
    gig_id = res_create.json()["data"]["id"]

    # Post gig
    res_post = client.post(f"/api/v1/gigs/{gig_id}/post", headers={"Authorization": f"Bearer {token_cust}"})
    assert res_post.status_code == 200

    # Ensure gig is explicitly converted/confirmed as visitation workflow
    res_vis = client.post(f"/api/v1/gigs/{gig_id}/visitation/request", headers={"Authorization": f"Bearer {token_cust}"})
    assert res_vis.status_code == 200

    # 2. Worker accepts opportunity
    res_opps = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"})
    assert res_opps.status_code == 200
    opp = next(o for o in res_opps.json()["data"] if o["gig_id"] == gig_id)
    res_accept = client.post(f"/api/v1/worker/opportunities/{opp['id']}/accept", headers={"Authorization": f"Bearer {token_w}"})
    assert res_accept.status_code == 200

    # 3. Customer selects worker
    res_select = client.post(
        f"/api/v1/gigs/{gig_id}/select-worker",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"worker_id": w["id"]},
    )
    assert res_select.status_code == 200

    # 4. Worker starts work -> IN_PROGRESS
    res_start = client.post(f"/api/v1/gigs/{gig_id}/start", headers={"Authorization": f"Bearer {token_w}"})
    assert res_start.status_code == 200

    return token_cust, cust, token_w, w, gig_id, plumbing, tasks


def test_visitation_request_and_details_overview(client: TestClient, db_session: Session):
    """Test requesting visitation inspection and viewing overview."""
    token_cust, cust = create_test_customer(client, db_session, "req")
    cat = db_session.query(ServiceCategory).first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == cat.id).first()

    # Create normal gig
    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"category_id": str(cat.id), "task_ids": [str(task.id)]},
    )
    assert res_create.status_code == 201
    gig_id = res_create.json()["data"]["id"]

    # Customer converts gig to VISITATION
    res_req = client.post(f"/api/v1/gigs/{gig_id}/visitation/request", headers={"Authorization": f"Bearer {token_cust}"})
    assert res_req.status_code == 200
    data = res_req.json()["data"]
    assert data["is_visitation"] is True
    assert Decimal(str(data["visitation_fee"])) == Decimal("100.00")
    assert data["active_proposal"] is None

    # Inspect GET details
    res_get = client.get(f"/api/v1/gigs/{gig_id}/visitation", headers={"Authorization": f"Bearer {token_cust}"})
    assert res_get.status_code == 200
    assert res_get.json()["data"]["gig_id"] == gig_id


def test_case_a_accepted_proposal_payment_flow(client: TestClient, db_session: Session):
    """CASE A: Visitation -> Worker Proposes Tasks -> Customer Accepts -> ₹100 Absorbed -> Payment Settles at ₹300."""
    token_cust, cust, token_w, worker, gig_id, plumbing, tasks = setup_visitation_gig(client, db_session, "case_a")

    # Initial gig base_price is ₹100 visitation fee
    gig_before = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert Decimal(str(gig_before.base_price)) == Decimal("100.00")

    # Snapshot worker opportunity before proposal
    opp_before = db_session.query(GigWorkerOpportunity).filter(
        GigWorkerOpportunity.gig_id == uuid.UUID(gig_id),
        GigWorkerOpportunity.worker_id == uuid.UUID(worker["id"]),
    ).first()
    exact_wage_before = Decimal(str(opp_before.exact_wage))
    base_snapshot_before = Decimal(str(opp_before.base_price_snapshot))

    # Worker submits proposal with 2 tasks
    proposal_task_ids = [str(tasks[0].id), str(tasks[1].id)]
    res_prop = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"task_ids": proposal_task_ids},
    )
    assert res_prop.status_code == 201
    proposal_data = res_prop.json()["data"]
    proposal_id = proposal_data["id"]
    proposed_price = Decimal(str(proposal_data["base_price"]))
    assert proposal_data["status"] == "PENDING"
    assert len(proposal_data["tasks"]) == 2

    # Audit event VISITATION_PROPOSED exists
    event_prop = db_session.query(GigEvent).filter(
        GigEvent.gig_id == uuid.UUID(gig_id),
        GigEvent.event_type == "VISITATION_PROPOSED",
    ).first()
    assert event_prop is not None
    assert Decimal(str(event_prop.metadata_json["proposed_base_price"])) == proposed_price

    # Customer accepts proposal
    res_accept = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals/{proposal_id}/accept",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_accept.status_code == 200
    accepted_data = res_accept.json()["data"]
    assert accepted_data["status"] == "ACCEPTED"
    assert accepted_data["customer_responded_at"] is not None

    # CRITICAL CHECK: Gig base_price is now the proposed work price (₹100 fee absorbed, NOT added)
    db_session.expire_all()
    gig_after_accept = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert Decimal(str(gig_after_accept.base_price)) == proposed_price

    # CRITICAL CHECK: Worker opportunity snapshots are completely UNTOUCHED
    opp_after_accept = db_session.query(GigWorkerOpportunity).filter(
        GigWorkerOpportunity.gig_id == uuid.UUID(gig_id),
        GigWorkerOpportunity.worker_id == uuid.UUID(worker["id"]),
    ).first()
    assert Decimal(str(opp_after_accept.exact_wage)) == exact_wage_before
    assert Decimal(str(opp_after_accept.base_price_snapshot)) == base_snapshot_before

    # Worker completes work and submits completion evidence
    res_compl = client.post(
        f"/api/v1/gigs/{gig_id}/completion",
        headers={"Authorization": f"Bearer {token_w}"},
        json={
            "description": "Completed all proposed plumbing tasks.",
            "evidence_items": [
                {
                    "evidence_type": "PHOTO",
                    "file_url": "https://storage.sahakaar.org/evidence/p1.jpg",
                }
            ],
        },
    )
    assert res_compl.status_code == 200

    # Customer confirms completion -> CUSTOMER_CONFIRMED
    res_confirm = client.post(
        f"/api/v1/gigs/{gig_id}/completion/confirm",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"confirmed": True},
    )
    assert res_confirm.status_code == 200

    # Payment Status check: authoritative amount must be exactly proposed_price (not proposed_price + 100)
    res_pay_status = client.get(f"/api/v1/gigs/{gig_id}/payment", headers={"Authorization": f"Bearer {token_cust}"})
    assert res_pay_status.status_code == 200
    assert Decimal(str(res_pay_status.json()["data"]["amount"])) == proposed_price

    # Customer records payment (CASH)
    res_pay = client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "CASH"},
    )
    assert res_pay.status_code == 200
    assert Decimal(str(res_pay.json()["data"]["amount"])) == proposed_price

    # Verify payment record in database
    payment = db_session.query(Payment).filter(Payment.gig_id == uuid.UUID(gig_id)).first()
    assert payment is not None
    assert Decimal(str(payment.amount)) == proposed_price

    # Worker confirms receipt -> COMPLETED
    res_confirm_rcpt = client.post(
        f"/api/v1/gigs/{gig_id}/payment/confirm-receipt",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"confirmed": True},
    )
    assert res_confirm_rcpt.status_code == 200
    db_session.expire_all()
    gig_final = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig_final.status == GigStatus.COMPLETED


def test_case_b_rejected_proposal_visitation_payment_flow(client: TestClient, db_session: Session):
    """CASE B: Visitation -> Worker Proposes Tasks -> Customer Rejects -> Fixed ₹100 Payable -> Settles at ₹100."""
    token_cust, cust, token_w, worker, gig_id, plumbing, tasks = setup_visitation_gig(client, db_session, "case_b")

    # Worker submits proposal
    proposal_task_ids = [str(tasks[0].id), str(tasks[1].id)]
    res_prop = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"task_ids": proposal_task_ids},
    )
    assert res_prop.status_code == 201
    proposal_id = res_prop.json()["data"]["id"]

    # Customer REJECTS proposal
    res_reject = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals/{proposal_id}/reject",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_reject.status_code == 200
    assert res_reject.json()["data"]["status"] == "REJECTED"

    # CRITICAL CHECK: Gig base_price remains strictly the ₹100 visitation fee
    db_session.expire_all()
    gig_rejected = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert Decimal(str(gig_rejected.base_price)) == Decimal("100.00")
    # Gig transitioned to CUSTOMER_CONFIRMED so customer can pay the inspection fee
    assert gig_rejected.status == GigStatus.CUSTOMER_CONFIRMED

    # Audit event VISITATION_REJECTED exists
    event_rej = db_session.query(GigEvent).filter(
        GigEvent.gig_id == uuid.UUID(gig_id),
        GigEvent.event_type == "VISITATION_REJECTED",
    ).first()
    assert event_rej is not None
    assert Decimal(str(event_rej.metadata_json["payable_visitation_fee"])) == Decimal("100.00")

    # Payment Status check: authoritative amount must be strictly ₹100.00
    res_pay_status = client.get(f"/api/v1/gigs/{gig_id}/payment", headers={"Authorization": f"Bearer {token_cust}"})
    assert res_pay_status.status_code == 200
    assert Decimal(str(res_pay_status.json()["data"]["amount"])) == Decimal("100.00")

    # Customer pays ₹100 via UPI
    res_pay = client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "UPI"},
    )
    assert res_pay.status_code == 200
    assert Decimal(str(res_pay.json()["data"]["amount"])) == Decimal("100.00")

    # Worker confirms receipt -> COMPLETED
    res_confirm_rcpt = client.post(
        f"/api/v1/gigs/{gig_id}/payment/confirm-receipt",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"confirmed": True},
    )
    assert res_confirm_rcpt.status_code == 200
    db_session.expire_all()
    gig_final = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig_final.status == GigStatus.COMPLETED


def test_visitation_opportunity_snapshot_immutability(client: TestClient, db_session: Session):
    """Test that GigWorkerOpportunity snapshots are byte-for-byte immutable across the visitation lifecycle."""
    token_cust, cust, token_w, worker, gig_id, plumbing, tasks = setup_visitation_gig(client, db_session, "immut")

    opp = db_session.query(GigWorkerOpportunity).filter(
        GigWorkerOpportunity.gig_id == uuid.UUID(gig_id),
        GigWorkerOpportunity.worker_id == uuid.UUID(worker["id"]),
    ).first()
    initial_exact_wage = opp.exact_wage
    initial_base_snapshot = opp.base_price_snapshot
    initial_premium = opp.premium_percentage
    initial_score = opp.final_score_snapshot

    # Worker submits proposal
    res_prop = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"task_ids": [str(tasks[0].id)]},
    )
    assert res_prop.status_code == 201
    proposal_id = res_prop.json()["data"]["id"]

    # Customer accepts proposal
    res_accept = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals/{proposal_id}/accept",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_accept.status_code == 200

    # Re-query opportunity: snapshots MUST NOT be modified
    db_session.expire_all()
    opp_after = db_session.query(GigWorkerOpportunity).filter(
        GigWorkerOpportunity.gig_id == uuid.UUID(gig_id),
        GigWorkerOpportunity.worker_id == uuid.UUID(worker["id"]),
    ).first()

    assert opp_after.exact_wage == initial_exact_wage
    assert opp_after.base_price_snapshot == initial_base_snapshot
    assert opp_after.premium_percentage == initial_premium
    assert opp_after.final_score_snapshot == initial_score


def test_concurrent_duplicate_pending_proposals(client: TestClient, db_session: Session):
    """Prevent submitting multiple pending proposals concurrently on the same gig."""
    token_cust, cust, token_w, worker, gig_id, plumbing, tasks = setup_visitation_gig(client, db_session, "dup")

    # First proposal succeeds
    res1 = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"task_ids": [str(tasks[0].id)]},
    )
    assert res1.status_code == 201

    # Second proposal while first is still pending must be rejected with 409 Conflict
    res2 = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"task_ids": [str(tasks[1].id)]},
    )
    assert res2.status_code == 409
    assert "PROPOSAL_PENDING" in res2.json()["error"]["code"]


def test_proposal_response_retries_and_conflict(client: TestClient, db_session: Session):
    """Retrying accept or reject on an already-resolved proposal returns 409 Conflict."""
    token_cust, cust, token_w, worker, gig_id, plumbing, tasks = setup_visitation_gig(client, db_session, "retry")

    res_prop = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"task_ids": [str(tasks[0].id)]},
    )
    proposal_id = res_prop.json()["data"]["id"]

    # Accept once
    res_acc = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals/{proposal_id}/accept",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_acc.status_code == 200

    # Accept again -> 409 Conflict
    res_acc2 = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals/{proposal_id}/accept",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_acc2.status_code == 409
    assert "PROPOSAL_ALREADY_RESPONDED" in res_acc2.json()["error"]["code"]

    # Reject after accepted -> 409 Conflict
    res_rej = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals/{proposal_id}/reject",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_rej.status_code == 409


def test_category_boundary_validation(client: TestClient, db_session: Session):
    """Worker cannot propose tasks belonging to a different category."""
    token_cust, cust, token_w, worker, gig_id, plumbing, tasks = setup_visitation_gig(client, db_session, "cat_bound")

    # Find another category and task (e.g. Electrical)
    other_cat = db_session.query(ServiceCategory).filter(ServiceCategory.name != "Plumbing").first()
    other_task = db_session.query(ServiceTask).filter(ServiceTask.category_id == other_cat.id).first()

    res = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"task_ids": [str(other_task.id)]},
    )
    assert res.status_code == 400
    assert "CATEGORY_TASK_MISMATCH" in res.json()["error"]["code"]


def test_strict_role_and_ownership_authorization(client: TestClient, db_session: Session):
    """Enforce strict role separation: customer cannot propose, worker cannot accept, third-party blocked."""
    token_cust, cust, token_w, worker, gig_id, plumbing, tasks = setup_visitation_gig(client, db_session, "auth")

    # Customer tries to propose -> 403 Forbidden (worker role required)
    res_cust_prop = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"task_ids": [str(tasks[0].id)]},
    )
    assert res_cust_prop.status_code == 403

    # Worker submits proposal
    res_prop = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"task_ids": [str(tasks[0].id)]},
    )
    proposal_id = res_prop.json()["data"]["id"]

    # Worker tries to accept proposal -> 403 Forbidden (customer role required)
    res_w_acc = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals/{proposal_id}/accept",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    assert res_w_acc.status_code == 403

    # Third party user
    token_other, _ = create_test_customer(client, db_session, "other")
    res_other = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals/{proposal_id}/accept",
        headers={"Authorization": f"Bearer {token_other}"},
    )
    assert res_other.status_code == 403


def test_visitation_transactional_rollback(client: TestClient, db_session: Session):
    """Verify that a database exception during proposal acceptance cleanly rolls back all mutations."""
    token_cust, cust, token_w, worker, gig_id, plumbing, tasks = setup_visitation_gig(client, db_session, "roll")

    res_prop = client.post(
        f"/api/v1/gigs/{gig_id}/visitation/proposals",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"task_ids": [str(tasks[0].id)]},
    )
    proposal_id = res_prop.json()["data"]["id"]

    # Mock an error during db.commit in accept_proposal
    with patch.object(Session, "commit", side_effect=RuntimeError("Simulated DB connection failure")):
        with pytest.raises(RuntimeError):
            client.post(
                f"/api/v1/gigs/{gig_id}/visitation/proposals/{proposal_id}/accept",
                headers={"Authorization": f"Bearer {token_cust}"},
            )

    # Verify proposal status remained PENDING and gig base_price remained ₹100
    db_session.expire_all()
    proposal = db_session.query(VisitationProposal).filter(VisitationProposal.id == uuid.UUID(proposal_id)).first()
    assert proposal.status == VisitationProposalStatus.PENDING

    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert Decimal(str(gig.base_price)) == Decimal("100.00")
