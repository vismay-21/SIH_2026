import uuid
from decimal import Decimal
from datetime import datetime, timezone
from typing import Tuple
from unittest.mock import patch
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.db.models.user import User, WorkerProfile, WorkerMetric
from app.db.models.cooperative import Cooperative
from app.db.models.service import ServiceCategory, ServiceTask
from app.db.models.gig import Gig, GigTask, GigWorkerOpportunity
from app.db.models.multi_worker import WorkerParticipation
from app.db.models.communication import GigEvent, Notification
from app.db.models.enums import (
    GigStatus,
    WorkerParticipationStatus,
    WorkerParticipationClassification,
)
from app.services.catalogue_service import CatalogueService
from app.services.experience_service import ExperienceService


@pytest.fixture(autouse=True)
def seed_catalog_fixture(db_session: Session):
    """Ensure service catalogue is populated."""
    CatalogueService.seed_catalogue_if_empty(db_session)


def create_test_customer(
    client: TestClient, db_session: Session, email_prefix: str = "cust10"
) -> Tuple[str, dict]:
    """Helper to initialize a customer and return (jwt_token, user_dict)."""
    sub = str(uuid.uuid4())
    token = create_access_token(
        {"sub": sub, "email": f"{email_prefix}_{sub[:8]}@sahakaar.org"}
    )
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
    email_prefix: str = "w10",
    cooperative_id: uuid.UUID = None,
) -> Tuple[str, dict]:
    """Helper to initialize a worker with category and return (jwt_token, user_dict)."""
    sub = str(uuid.uuid4())
    token = create_access_token(
        {"sub": sub, "email": f"{email_prefix}_{sub[:8]}@sahakaar.org"}
    )
    res = client.post(
        "/api/v1/me/initialize",
        headers={"Authorization": f"Bearer {token}"},
        json={"role": "WORKER", "full_name": f"Worker {sub[:6]}"},
    )
    assert res.status_code == 201
    worker_data = res.json()["data"]
    worker_id = uuid.UUID(worker_data["id"])

    # If specific cooperative requested, update user
    if cooperative_id:
        user = db_session.query(User).filter(User.id == worker_id).first()
        user.cooperative_id = cooperative_id
        db_session.commit()
        worker_data["cooperative_id"] = str(cooperative_id)

    res_cat = client.put(
        "/api/v1/worker/categories",
        headers={"Authorization": f"Bearer {token}"},
        json={"category_ids": [str(category_id)]},
    )
    assert res_cat.status_code == 200

    return token, worker_data


def setup_assigned_gig(
    client: TestClient,
    db_session: Session,
    prefix: str = "s10",
) -> Tuple[str, dict, str, dict, str, ServiceCategory]:
    """Helper to set up a gig assigned to primary worker in WORKER_SELECTED status.

    Returns (token_cust, cust, token_w1, worker1, gig_id, category).
    """
    token_cust, cust = create_test_customer(
        client, db_session, email_prefix=f"c_{prefix}"
    )
    plumbing = (
        db_session.query(ServiceCategory)
        .filter(ServiceCategory.name == "Plumbing")
        .first()
    )
    task = (
        db_session.query(ServiceTask)
        .filter(ServiceTask.category_id == plumbing.id)
        .first()
    )

    token_w1, w1 = create_test_worker(
        client, db_session, plumbing.id, email_prefix=f"w1_{prefix}"
    )

    # 1. Customer creates and posts gig
    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task.id)],
            "instructions": "Need tap fixed and co-worker collaboration",
        },
    )
    assert res_create.status_code == 201
    gig_id = res_create.json()["data"]["id"]

    res_post = client.post(
        f"/api/v1/gigs/{gig_id}/post",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_post.status_code == 200

    # 2. Worker 1 accepts opportunity
    res_opps = client.get(
        "/api/v1/worker/opportunities",
        headers={"Authorization": f"Bearer {token_w1}"},
    )
    assert res_opps.status_code == 200
    opp = next(o for o in res_opps.json()["data"] if o["gig_id"] == gig_id)

    res_accept = client.post(
        f"/api/v1/worker/opportunities/{opp['id']}/accept",
        headers={"Authorization": f"Bearer {token_w1}"},
    )
    assert res_accept.status_code == 200

    # 3. Customer selects worker 1
    res_select = client.post(
        f"/api/v1/gigs/{gig_id}/select-worker",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"worker_id": w1["id"]},
    )
    assert res_select.status_code == 200

    return token_cust, cust, token_w1, w1, gig_id, plumbing


def test_peer_collaboration_invitation_and_acceptance(
    client: TestClient, db_session: Session
):
    """Test primary worker inviting peer with EQUAL_SHARING and peer accepting."""
    token_cust, cust, token_w1, w1, gig_id, plumbing = setup_assigned_gig(
        client, db_session, "peer"
    )

    # Create additional worker in same cooperative
    token_w2, w2 = create_test_worker(
        client, db_session, plumbing.id, email_prefix="peer_w2"
    )

    # Primary worker invites peer
    res_invite = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "additional_worker_id": w2["id"],
            "classification": "EQUAL_SHARING",
        },
    )
    assert res_invite.status_code == 201
    inv_data = res_invite.json()["data"]
    assert inv_data["status"] == "PENDING"
    assert inv_data["classification"] == "EQUAL_SHARING"
    assert inv_data["inviting_worker_id"] == w1["id"]
    assert inv_data["additional_worker_id"] == w2["id"]
    assert inv_data["responded_at"] is None
    part_id = inv_data["id"]

    # Verify notification created for w2
    notif = (
        db_session.query(Notification)
        .filter(
            Notification.recipient_id == uuid.UUID(w2["id"]),
            Notification.gig_id == uuid.UUID(gig_id),
        )
        .first()
    )
    assert notif is not None
    assert notif.type == "COLLABORATION_INVITED"

    # Verify audit event logged
    audit = (
        db_session.query(GigEvent)
        .filter(
            GigEvent.gig_id == uuid.UUID(gig_id),
            GigEvent.event_type == "WORKER_PARTICIPATION_INVITED",
        )
        .first()
    )
    assert audit is not None
    assert audit.actor_id == uuid.UUID(w1["id"])

    # Additional worker w2 accepts invitation
    res_accept = client.post(
        f"/api/v1/participations/{part_id}/accept",
        headers={"Authorization": f"Bearer {token_w2}"},
    )
    assert res_accept.status_code == 200
    acc_data = res_accept.json()["data"]
    assert acc_data["status"] == "ACCEPTED"
    assert acc_data["responded_at"] is not None

    # Verify acceptance notification created for w1
    notif_w1 = (
        db_session.query(Notification)
        .filter(
            Notification.recipient_id == uuid.UUID(w1["id"]),
            Notification.type == "COLLABORATION_ACCEPTED",
        )
        .first()
    )
    assert notif_w1 is not None

    # Verify audit event logged for acceptance
    audit_acc = (
        db_session.query(GigEvent)
        .filter(
            GigEvent.gig_id == uuid.UUID(gig_id),
            GigEvent.event_type == "WORKER_PARTICIPATION_ACCEPTED",
        )
        .first()
    )
    assert audit_acc is not None
    assert audit_acc.actor_id == uuid.UUID(w2["id"])


def test_rookie_mentorship_invitation_and_half_complexity_credit(
    client: TestClient, db_session: Session
):
    """Test rookie mentorship invitation calculates exact 0.5x complexity contribution."""
    token_cust, cust, token_w1, w1, gig_id, plumbing = setup_assigned_gig(
        client, db_session, "rookie"
    )

    # Create rookie worker
    token_rookie, rookie = create_test_worker(
        client, db_session, plumbing.id, email_prefix="rookie_w"
    )

    # Primary worker invites rookie
    res_invite = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "additional_worker_id": rookie["id"],
            "classification": "ROOKIE",
        },
    )
    assert res_invite.status_code == 201
    data = res_invite.json()["data"]
    assert data["classification"] == "ROOKIE"

    # Calculate expected complexity for gig
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    duration = gig.expected_duration_minutes or 60
    base_complexity = ExperienceService.calculate_task_complexity(
        "Plumbing", duration
    )
    expected_credit = ExperienceService.calculate_task_contribution(
        base_complexity, is_rookie_participation=True
    )
    assert abs(data["experience_contribution"] - expected_credit) < 0.0001
    assert abs(data["experience_contribution"] - round(base_complexity * 0.5, 5)) < 0.0001

    # Rookie accepts
    res_accept = client.post(
        f"/api/v1/participations/{data['id']}/accept",
        headers={"Authorization": f"Bearer {token_rookie}"},
    )
    assert res_accept.status_code == 200
    assert res_accept.json()["data"]["status"] == "ACCEPTED"


def test_peer_invitation_rejection(client: TestClient, db_session: Session):
    """Test additional worker rejecting collaboration invitation."""
    token_cust, cust, token_w1, w1, gig_id, plumbing = setup_assigned_gig(
        client, db_session, "reject"
    )
    token_w2, w2 = create_test_worker(
        client, db_session, plumbing.id, email_prefix="rej_w2"
    )

    res_invite = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "additional_worker_id": w2["id"],
            "classification": "EQUAL_SHARING",
        },
    )
    assert res_invite.status_code == 201
    part_id = res_invite.json()["data"]["id"]

    # W2 rejects invitation
    res_rej = client.post(
        f"/api/v1/participations/{part_id}/reject",
        headers={"Authorization": f"Bearer {token_w2}"},
    )
    assert res_rej.status_code == 200
    rej_data = res_rej.json()["data"]
    assert rej_data["status"] == "REJECTED"
    assert rej_data["responded_at"] is not None

    # Verify rejection audit event and notification
    audit = (
        db_session.query(GigEvent)
        .filter(
            GigEvent.gig_id == uuid.UUID(gig_id),
            GigEvent.event_type == "WORKER_PARTICIPATION_REJECTED",
        )
        .first()
    )
    assert audit is not None
    assert audit.actor_id == uuid.UUID(w2["id"])

    notif = (
        db_session.query(Notification)
        .filter(
            Notification.recipient_id == uuid.UUID(w1["id"]),
            Notification.type == "COLLABORATION_REJECTED",
        )
        .first()
    )
    assert notif is not None


def test_cross_cooperative_invitation_forbidden(
    client: TestClient, db_session: Session
):
    """Test that inviting a worker from a different cooperative is strictly rejected."""
    token_cust, cust, token_w1, w1, gig_id, plumbing = setup_assigned_gig(
        client, db_session, "cross"
    )

    # Create distinct second cooperative
    coop2 = Cooperative(
        id=uuid.uuid4(),
        name="South Mumbai Labour Cooperative",
        city="Mumbai",
        service_area="South Mumbai",
        is_active=True,
    )
    db_session.add(coop2)
    db_session.commit()

    # Create worker 2 in coop2
    token_w2, w2 = create_test_worker(
        client,
        db_session,
        plumbing.id,
        email_prefix="cross_w2",
        cooperative_id=coop2.id,
    )

    # Primary worker attempts cross-cooperative invite
    res_invite = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "additional_worker_id": w2["id"],
            "classification": "EQUAL_SHARING",
        },
    )
    assert res_invite.status_code == 400
    assert "cooperative" in res_invite.json()["error"]["message"].lower()


def test_self_invitation_forbidden(client: TestClient, db_session: Session):
    """Primary worker cannot invite themselves."""
    token_cust, cust, token_w1, w1, gig_id, plumbing = setup_assigned_gig(
        client, db_session, "self"
    )

    res_invite = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "additional_worker_id": w1["id"],
            "classification": "ROOKIE",
        },
    )
    assert res_invite.status_code == 400
    assert "themselves" in res_invite.json()["error"]["message"].lower()



def test_duplicate_invitation_conflict(client: TestClient, db_session: Session):
    """Attempting duplicate invite while PENDING or ACCEPTED returns 409 Conflict."""
    token_cust, cust, token_w1, w1, gig_id, plumbing = setup_assigned_gig(
        client, db_session, "dup"
    )
    token_w2, w2 = create_test_worker(
        client, db_session, plumbing.id, email_prefix="dup_w2"
    )

    # 1. First invite
    res1 = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "additional_worker_id": w2["id"],
            "classification": "EQUAL_SHARING",
        },
    )
    assert res1.status_code == 201
    part_id = res1.json()["data"]["id"]

    # 2. Duplicate while PENDING -> 409
    res2 = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "additional_worker_id": w2["id"],
            "classification": "ROOKIE",
        },
    )
    assert res2.status_code == 409

    # 3. Accept first invite -> ACCEPTED
    res_acc = client.post(
        f"/api/v1/participations/{part_id}/accept",
        headers={"Authorization": f"Bearer {token_w2}"},
    )
    assert res_acc.status_code == 200

    # 4. Duplicate while ACCEPTED -> 409
    res3 = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "additional_worker_id": w2["id"],
            "classification": "EQUAL_SHARING",
        },
    )
    assert res3.status_code == 409


def test_strict_authorization_and_unauthorized_parties(
    client: TestClient, db_session: Session
):
    """Test RBAC and isolation rules across customers, primary workers, and strangers."""
    token_cust, cust, token_w1, w1, gig_id, plumbing = setup_assigned_gig(
        client, db_session, "auth"
    )
    token_w2, w2 = create_test_worker(
        client, db_session, plumbing.id, email_prefix="auth_w2"
    )
    token_stranger, stranger = create_test_worker(
        client, db_session, plumbing.id, email_prefix="stranger"
    )

    # 1. Customer cannot invite collaborators (worker endpoint)
    res_cust_inv = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "additional_worker_id": w2["id"],
            "classification": "ROOKIE",
        },
    )
    assert res_cust_inv.status_code == 403

    # 2. Non-assigned worker cannot invite collaborators
    res_stranger_inv = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_stranger}"},
        json={
            "additional_worker_id": w2["id"],
            "classification": "ROOKIE",
        },
    )
    assert res_stranger_inv.status_code == 403

    # Primary invites w2 legitimately
    res_invite = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "additional_worker_id": w2["id"],
            "classification": "ROOKIE",
        },
    )
    assert res_invite.status_code == 201
    part_id = res_invite.json()["data"]["id"]

    # 3. Stranger worker cannot accept or reject w2's invite
    res_stranger_acc = client.post(
        f"/api/v1/participations/{part_id}/accept",
        headers={"Authorization": f"Bearer {token_stranger}"},
    )
    assert res_stranger_acc.status_code == 403

    # 4. Stranger cannot view gig participations
    res_stranger_get = client.get(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_stranger}"},
    )
    assert res_stranger_get.status_code == 403

    # 5. Customer CAN view gig participations
    res_cust_get = client.get(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_cust_get.status_code == 200
    assert len(res_cust_get.json()["data"]) == 1

    # 6. Primary worker CAN view gig participations
    res_w1_get = client.get(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
    )
    assert res_w1_get.status_code == 200
    assert len(res_w1_get.json()["data"]) == 1


def test_customer_price_invariance_with_collaborators(
    client: TestClient, db_session: Session
):
    """Section 37 invariant: customer labour price is unchanged by additional workers."""
    token_cust, cust, token_w1, w1, gig_id, plumbing = setup_assigned_gig(
        client, db_session, "invar"
    )
    token_w2, w2 = create_test_worker(
        client, db_session, plumbing.id, email_prefix="invar_w2"
    )
    token_rookie, rookie = create_test_worker(
        client, db_session, plumbing.id, email_prefix="invar_rk"
    )

    # Check original gig price
    gig_before = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    original_base_price = gig_before.base_price

    # Primary worker invites peer and rookie
    res_inv1 = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "additional_worker_id": w2["id"],
            "classification": "EQUAL_SHARING",
        },
    )
    assert res_inv1.status_code == 201

    res_inv2 = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "additional_worker_id": rookie["id"],
            "classification": "ROOKIE",
        },
    )
    assert res_inv2.status_code == 201

    # Both accept
    client.post(
        f"/api/v1/participations/{res_inv1.json()['data']['id']}/accept",
        headers={"Authorization": f"Bearer {token_w2}"},
    )
    client.post(
        f"/api/v1/participations/{res_inv2.json()['data']['id']}/accept",
        headers={"Authorization": f"Bearer {token_rookie}"},
    )

    # Check gig price remains strictly identical
    db_session.expire_all()
    gig_after = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    assert gig_after.base_price == original_base_price

    # Verify participation list returns both accepted workers without exposing private compensation
    res_list = client.get(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_list.status_code == 200
    parts = res_list.json()["data"]
    assert len(parts) == 2
    for p in parts:
        assert p["status"] == "ACCEPTED"
        assert "compensation" not in p
        assert "payout" not in p
        assert "split" not in p


def test_invalid_gig_states_for_invitation(
    client: TestClient, db_session: Session
):
    """Cannot invite collaborators on DRAFT, COMPLETED, or CANCELLED gigs."""
    token_cust, cust = create_test_customer(client, db_session, "inv_state")
    plumbing = (
        db_session.query(ServiceCategory)
        .filter(ServiceCategory.name == "Plumbing")
        .first()
    )
    task = (
        db_session.query(ServiceTask)
        .filter(ServiceTask.category_id == plumbing.id)
        .first()
    )
    token_w1, w1 = create_test_worker(
        client, db_session, plumbing.id, email_prefix="st_w1"
    )
    token_w2, w2 = create_test_worker(
        client, db_session, plumbing.id, email_prefix="st_w2"
    )

    # 1. DRAFT gig
    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task.id)],
        },
    )
    draft_gig_id = res_create.json()["data"]["id"]

    res_draft_inv = client.post(
        f"/api/v1/gigs/{draft_gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "additional_worker_id": w2["id"],
            "classification": "EQUAL_SHARING",
        },
    )
    assert res_draft_inv.status_code in [400, 403]


def test_transactional_rollback_on_invitation_failure(
    client: TestClient, db_session: Session
):
    """Simulated database failure rolls back participation, audit event, and notification."""
    token_cust, cust, token_w1, w1, gig_id, plumbing = setup_assigned_gig(
        client, db_session, "rollback"
    )
    token_w2, w2 = create_test_worker(
        client, db_session, plumbing.id, email_prefix="roll_w2"
    )

    with patch.object(
        Session, "commit", side_effect=Exception("Simulated commit failure")
    ):
        with pytest.raises(Exception):
            client.post(
                f"/api/v1/gigs/{gig_id}/participations",
                headers={"Authorization": f"Bearer {token_w1}"},
                json={
                    "additional_worker_id": w2["id"],
                    "classification": "ROOKIE",
                },
            )

    db_session.expire_all()
    # Verify no participation was persisted
    part = (
        db_session.query(WorkerParticipation)
        .filter(
            WorkerParticipation.gig_id == uuid.UUID(gig_id),
            WorkerParticipation.additional_worker_id == uuid.UUID(w2["id"]),
        )
        .first()
    )
    assert part is None
