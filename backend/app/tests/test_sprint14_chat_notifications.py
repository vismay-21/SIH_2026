"""Sprint 14 Integration & Regression Tests: Chat + Notifications.

Covers:
1. Conversation lazy initialization
2. Chat availability gating before worker selection (409 CHAT_NOT_AVAILABLE)
3. Participant authorization and isolation (403 NOT_GIG_PARTICIPANT)
4. Customer <-> worker messaging
5. Accepted collaborator chat behavior (shared gig-scoped conversation)
6. CHAT_MESSAGE notification generation
7. Empty/whitespace/oversized message validation
8. Message pagination and chronological ordering
9. Read receipt behavior
10. Notification retrieval, filtering (is_read, type), and unread count
11. Single notification mark as read (POST /notifications/{id}/read)
12. Mark all notifications as read (POST /notifications/read-all)
13. Notification ownership isolation (403/404 on other user's notification)
14. Lifecycle notifications (NEW_OPPORTUNITY, WORKER_ACCEPTED, REVIEW_AVAILABLE)
15. Duplicate/idempotency protection for lifecycle notifications
"""

import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import Tuple, Dict, Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.db.models.communication import Conversation, GigEvent, Message, Notification
from app.db.models.enums import (
    GigStatus,
    OpportunityStatus,
    PaymentMethod,
    PaymentStatus,
    UserRole,
    WorkerParticipationStatus,
)
from app.db.models.gig import Gig, GigWorkerOpportunity
from app.db.models.multi_worker import WorkerParticipation
from app.db.models.payment import Payment
from app.db.models.service import ServiceCategory, ServiceTask, WorkerCategory
from app.db.models.user import User, WorkerMetric, WorkerProfile
from app.services.catalogue_service import CatalogueService


@pytest.fixture(autouse=True)
def seed_catalog_fixture(db_session: Session):
    """Ensure service catalogue is populated for every test."""
    CatalogueService.seed_catalogue_if_empty(db_session)


def create_test_customer(
    client: TestClient,
    db_session: Session,
    email_prefix: str = "cust14",
) -> Tuple[str, Dict[str, Any]]:
    """Initialize a customer user and return (token, user_dict)."""
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
    email_prefix: str = "w14",
) -> Tuple[str, Dict[str, Any]]:
    """Initialize a worker user with category and return (token, user_dict)."""
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

    res_cat = client.put(
        "/api/v1/worker/categories",
        headers={"Authorization": f"Bearer {token}"},
        json={"category_ids": [str(category_id)]},
    )
    assert res_cat.status_code == 200

    return token, worker_data


def setup_gig_environment(
    client: TestClient,
    db: Session,
    prefix: str = "chat",
    advance_to_selection: bool = True,
):
    plumbing = db.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    token_cust, cust = create_test_customer(client, db, email_prefix=f"c_{prefix}")
    token_w, w = create_test_worker(client, db, plumbing.id, email_prefix=f"w_{prefix}")

    res_gig = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task.id)],
            "scheduled_date": "2026-11-10",
            "scheduled_start_time": "10:00:00",
            "address": "123 Chat Way, Bangalore",
            "latitude": 12.9716,
            "longitude": 77.5946,
            "material_procurement_mode": "CUSTOMER_PURCHASES",
        },
    )
    assert res_gig.status_code == 201
    gig_id = res_gig.json()["data"]["id"]

    res_post = client.post(
        f"/api/v1/gigs/{gig_id}/post",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_post.status_code == 200

    if not advance_to_selection:
        return token_cust, cust, token_w, w, gig_id, plumbing.id

    res_opps = client.get(
        "/api/v1/worker/opportunities",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    assert res_opps.status_code == 200
    opp_id = res_opps.json()["data"][0]["id"]

    res_acc = client.post(
        f"/api/v1/worker/opportunities/{opp_id}/accept",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    assert res_acc.status_code == 200

    res_sel = client.post(
        f"/api/v1/gigs/{gig_id}/select-worker",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"worker_id": w["id"]},
    )
    assert res_sel.status_code == 200

    return token_cust, cust, token_w, w, gig_id, plumbing.id


# ==============================================================================
# 1. Chat Availability & Lazy Initialization Tests
# ==============================================================================

def test_chat_availability_before_worker_selection(client: TestClient, db_session: Session):
    """Attempting chat operations prior to worker selection returns 409 CHAT_NOT_AVAILABLE."""
    token_cust, cust, token_w, w, gig_id, _ = setup_gig_environment(
        client, db_session, prefix="avail", advance_to_selection=False
    )

    # 1. Customer attempts to access conversation
    res_conv = client.get(
        f"/api/v1/gigs/{gig_id}/conversation",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_conv.status_code == 409
    assert res_conv.json()["error"]["code"] == "CHAT_NOT_AVAILABLE"

    # 2. Worker attempts to send message
    res_msg = client.post(
        f"/api/v1/gigs/{gig_id}/conversation/messages",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"message_text": "Hello, I can help!"},
    )
    assert res_msg.status_code == 409
    assert res_msg.json()["error"]["code"] == "CHAT_NOT_AVAILABLE"

    # 3. Customer attempts to get messages
    res_get = client.get(
        f"/api/v1/gigs/{gig_id}/conversation/messages",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_get.status_code == 409
    assert res_get.json()["error"]["code"] == "CHAT_NOT_AVAILABLE"


def test_conversation_lazy_initialization(client: TestClient, db_session: Session):
    """Once worker is selected, accessing conversation lazily creates the record."""
    token_cust, cust, token_w, w, gig_id, _ = setup_gig_environment(
        client, db_session, prefix="lazy", advance_to_selection=True
    )

    # Confirm conversation does not exist in DB yet
    conv_before = db_session.query(Conversation).filter(Conversation.gig_id == uuid.UUID(gig_id)).first()
    assert conv_before is None

    # Customer gets conversation
    res = client.get(
        f"/api/v1/gigs/{gig_id}/conversation",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res.status_code == 200
    data = res.json()["data"]
    assert data["gig_id"] == gig_id
    assert data["customer_id"] == cust["id"]
    assert data["worker_id"] == w["id"]
    assert data["unread_count"] == 0
    assert data["last_message"] is None

    # Confirm conversation was created in DB
    conv_after = db_session.query(Conversation).filter(Conversation.gig_id == uuid.UUID(gig_id)).first()
    assert conv_after is not None
    assert str(conv_after.id) == data["id"]


# ==============================================================================
# 2. Participant Isolation & Authorization Tests
# ==============================================================================

def test_participant_authorization_and_isolation(client: TestClient, db_session: Session):
    """Non-participants cannot view conversation or send messages (403 NOT_GIG_PARTICIPANT)."""
    token_cust, cust, token_w, w, gig_id, cat_id = setup_gig_environment(
        client, db_session, prefix="iso", advance_to_selection=True
    )

    token_other, _ = create_test_customer(client, db_session, email_prefix="intruder_cust")
    token_other_w, _ = create_test_worker(client, db_session, cat_id, email_prefix="intruder_w")

    for intruder_token in (token_other, token_other_w):
        # 1. View conversation
        res_conv = client.get(
            f"/api/v1/gigs/{gig_id}/conversation",
            headers={"Authorization": f"Bearer {intruder_token}"},
        )
        assert res_conv.status_code == 403
        assert res_conv.json()["error"]["code"] == "NOT_GIG_PARTICIPANT"

        # 2. Send message
        res_send = client.post(
            f"/api/v1/gigs/{gig_id}/conversation/messages",
            headers={"Authorization": f"Bearer {intruder_token}"},
            json={"message_text": "Spam message from outsider"},
        )
        assert res_send.status_code == 403
        assert res_send.json()["error"]["code"] == "NOT_GIG_PARTICIPANT"

        # 3. Read messages
        res_msgs = client.get(
            f"/api/v1/gigs/{gig_id}/conversation/messages",
            headers={"Authorization": f"Bearer {intruder_token}"},
        )
        assert res_msgs.status_code == 403
        assert res_msgs.json()["error"]["code"] == "NOT_GIG_PARTICIPANT"


# ==============================================================================
# 3. Bilateral Messaging, Notifications, & Audit Events
# ==============================================================================

def test_customer_worker_messaging_and_notifications(client: TestClient, db_session: Session):
    """Customer sends message to worker; worker replies; notifications and audit events are generated."""
    token_cust, cust, token_w, w, gig_id, _ = setup_gig_environment(
        client, db_session, prefix="msg", advance_to_selection=True
    )

    # 1. Customer sends message
    res_c_msg = client.post(
        f"/api/v1/gigs/{gig_id}/conversation/messages",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"message_text": "Hello, when can you arrive today?"},
    )
    assert res_c_msg.status_code == 201
    c_msg_data = res_c_msg.json()["data"]
    assert c_msg_data["message_text"] == "Hello, when can you arrive today?"
    assert c_msg_data["sender_id"] == cust["id"]
    assert c_msg_data["is_read"] is False

    # Verify notification generated for worker
    worker_notifs = (
        db_session.query(Notification)
        .filter(
            Notification.recipient_id == uuid.UUID(w["id"]),
            Notification.type == "CHAT_MESSAGE",
        )
        .all()
    )
    assert len(worker_notifs) >= 1
    latest_w_notif = worker_notifs[-1]
    assert "Hello, when can you arrive today?" in latest_w_notif.body

    # Verify audit event emitted
    event = (
        db_session.query(GigEvent)
        .filter(
            GigEvent.gig_id == uuid.UUID(gig_id),
            GigEvent.event_type == "CHAT_MESSAGE_SENT",
            GigEvent.actor_id == uuid.UUID(cust["id"]),
        )
        .first()
    )
    assert event is not None

    # 2. Worker sends reply message
    res_w_msg = client.post(
        f"/api/v1/gigs/{gig_id}/conversation/messages",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"message_text": "I will arrive by 10:15 AM with tools."},
    )
    assert res_w_msg.status_code == 201
    w_msg_data = res_w_msg.json()["data"]
    assert w_msg_data["message_text"] == "I will arrive by 10:15 AM with tools."
    assert w_msg_data["sender_id"] == w["id"]

    # Verify notification generated for customer
    cust_notifs = (
        db_session.query(Notification)
        .filter(
            Notification.recipient_id == uuid.UUID(cust["id"]),
            Notification.type == "CHAT_MESSAGE",
        )
        .all()
    )
    assert len(cust_notifs) >= 1
    assert "I will arrive by 10:15 AM" in cust_notifs[-1].body


def test_empty_and_oversized_message_validation(client: TestClient, db_session: Session):
    """Empty, whitespace-only, or messages exceeding 2000 chars are rejected."""
    token_cust, cust, token_w, w, gig_id, _ = setup_gig_environment(
        client, db_session, prefix="val", advance_to_selection=True
    )

    # Empty string
    res_empty = client.post(
        f"/api/v1/gigs/{gig_id}/conversation/messages",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"message_text": ""},
    )
    assert res_empty.status_code == 422

    # Whitespace only
    res_ws = client.post(
        f"/api/v1/gigs/{gig_id}/conversation/messages",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"message_text": "     \n\t   "},
    )
    assert res_ws.status_code == 422

    # Oversized (>2000 chars)
    oversized = "x" * 2001
    res_big = client.post(
        f"/api/v1/gigs/{gig_id}/conversation/messages",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"message_text": oversized},
    )
    assert res_big.status_code == 422


# ==============================================================================
# 4. Message Pagination, Chronology, & Read Receipts
# ==============================================================================

def test_message_pagination_chronology_and_read_receipts(client: TestClient, db_session: Session):
    """Messages are returned in ascending chronological order; read receipts mark retrieved messages."""
    token_cust, cust, token_w, w, gig_id, _ = setup_gig_environment(
        client, db_session, prefix="page", advance_to_selection=True
    )

    # Send 4 sequential messages (2 from customer, 2 from worker)
    for i in range(1, 3):
        client.post(
            f"/api/v1/gigs/{gig_id}/conversation/messages",
            headers={"Authorization": f"Bearer {token_cust}"},
            json={"message_text": f"Customer msg {i}"},
        )
        client.post(
            f"/api/v1/gigs/{gig_id}/conversation/messages",
            headers={"Authorization": f"Bearer {token_w}"},
            json={"message_text": f"Worker msg {i}"},
        )

    # Worker checks unread count in conversation overview before retrieving messages
    res_conv_w = client.get(
        f"/api/v1/gigs/{gig_id}/conversation",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    assert res_conv_w.status_code == 200
    # Customer sent 2 messages
    assert res_conv_w.json()["data"]["unread_count"] == 2

    # Worker retrieves messages (should mark customer's messages as read)
    res_msgs = client.get(
        f"/api/v1/gigs/{gig_id}/conversation/messages?limit=10",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    assert res_msgs.status_code == 200
    messages = res_msgs.json()["data"]["messages"]
    assert len(messages) == 4
    assert res_msgs.json()["data"]["total"] == 4

    # Check chronological ordering (oldest first)
    assert messages[0]["message_text"] == "Customer msg 1"
    assert messages[1]["message_text"] == "Worker msg 1"
    assert messages[2]["message_text"] == "Customer msg 2"
    assert messages[3]["message_text"] == "Worker msg 2"

    # Verify customer messages are marked as read in database
    c_msgs_in_db = (
        db_session.query(Message)
        .filter(Message.sender_id == uuid.UUID(cust["id"]))
        .all()
    )
    assert all(m.is_read for m in c_msgs_in_db)

    # Worker's unread count should now be 0
    res_conv_w_after = client.get(
        f"/api/v1/gigs/{gig_id}/conversation",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    assert res_conv_w_after.json()["data"]["unread_count"] == 0

    # Customer unread count should still be 2 (customer has not retrieved worker's messages yet)
    res_conv_c = client.get(
        f"/api/v1/gigs/{gig_id}/conversation",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_conv_c.json()["data"]["unread_count"] == 2

    # Customer retrieves only 1 message via limit=1
    res_c_paged = client.get(
        f"/api/v1/gigs/{gig_id}/conversation/messages?limit=1",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_c_paged.status_code == 200
    assert len(res_c_paged.json()["data"]["messages"]) == 1


# ==============================================================================
# 5. Accepted Collaborator Chat Access
# ==============================================================================

def test_accepted_collaborator_chat_access(client: TestClient, db_session: Session):
    """Accepted collaborator shares the single job conversation; unaccepted cannot."""
    token_cust, cust, token_w, w, gig_id, cat_id = setup_gig_environment(
        client, db_session, prefix="collab", advance_to_selection=True
    )

    # Create secondary worker (peer)
    token_peer, peer = create_test_worker(client, db_session, cat_id, email_prefix="peer14")

    # Invite peer
    res_inv = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w}"},
        json={
            "additional_worker_id": peer["id"],
            "classification": "EQUAL_SHARING",
        },
    )
    assert res_inv.status_code == 201
    part_id = res_inv.json()["data"]["id"]

    # Before accepting: peer cannot access conversation
    res_block = client.get(
        f"/api/v1/gigs/{gig_id}/conversation",
        headers={"Authorization": f"Bearer {token_peer}"},
    )
    assert res_block.status_code == 403
    assert res_block.json()["error"]["code"] == "NOT_GIG_PARTICIPANT"

    # Peer accepts invitation
    res_acc = client.post(
        f"/api/v1/participations/{part_id}/accept",
        headers={"Authorization": f"Bearer {token_peer}"},
    )
    assert res_acc.status_code == 200

    # Peer can now access conversation
    res_peer_conv = client.get(
        f"/api/v1/gigs/{gig_id}/conversation",
        headers={"Authorization": f"Bearer {token_peer}"},
    )
    assert res_peer_conv.status_code == 200
    assert res_peer_conv.json()["data"]["gig_id"] == gig_id

    # Peer can send a message
    res_peer_msg = client.post(
        f"/api/v1/gigs/{gig_id}/conversation/messages",
        headers={"Authorization": f"Bearer {token_peer}"},
        json={"message_text": "Hello, I have joined to assist the primary worker."},
    )
    assert res_peer_msg.status_code == 201
    assert res_peer_msg.json()["data"]["sender_id"] == peer["id"]


# ==============================================================================
# 6. Notifications API: Retrieval, Filtering, Read, Read-All, Ownership
# ==============================================================================

def test_notification_retrieval_filtering_and_marking_read(client: TestClient, db_session: Session):
    """Tests GET /notifications with filters, POST /notifications/{id}/read, and POST /notifications/read-all."""
    token_user, user = create_test_customer(client, db_session, email_prefix="notif_user")
    u_id = uuid.UUID(user["id"])

    # Seed 3 notifications for user: 2 unread, 1 read
    n1 = Notification(
        id=uuid.uuid4(),
        recipient_id=u_id,
        type="TYPE_A",
        title="Title 1",
        body="Body 1",
        is_read=False,
    )
    n2 = Notification(
        id=uuid.uuid4(),
        recipient_id=u_id,
        type="TYPE_A",
        title="Title 2",
        body="Body 2",
        is_read=False,
    )
    n3 = Notification(
        id=uuid.uuid4(),
        recipient_id=u_id,
        type="TYPE_B",
        title="Title 3",
        body="Body 3",
        is_read=True,
        read_at=datetime.now(timezone.utc),
    )
    db_session.add_all([n1, n2, n3])
    db_session.commit()

    # 1. Retrieve all notifications
    res_all = client.get(
        "/api/v1/notifications",
        headers={"Authorization": f"Bearer {token_user}"},
    )
    assert res_all.status_code == 200
    data_all = res_all.json()["data"]
    assert data_all["total"] == 3
    assert data_all["unread_count"] == 2

    # 2. Filter by is_read=false
    res_unread = client.get(
        "/api/v1/notifications?is_read=false",
        headers={"Authorization": f"Bearer {token_user}"},
    )
    assert res_unread.status_code == 200
    assert res_unread.json()["data"]["total"] == 2

    # 3. Filter by type=TYPE_B
    res_type = client.get(
        "/api/v1/notifications?type=TYPE_B",
        headers={"Authorization": f"Bearer {token_user}"},
    )
    assert res_type.status_code == 200
    assert res_type.json()["data"]["total"] == 1

    # 4. Mark single notification as read (n1)
    res_read = client.post(
        f"/api/v1/notifications/{n1.id}/read",
        headers={"Authorization": f"Bearer {token_user}"},
    )
    assert res_read.status_code == 200
    assert res_read.json()["data"]["is_read"] is True
    assert res_read.json()["data"]["read_at"] is not None

    # Unread count now 1
    res_after_single = client.get(
        "/api/v1/notifications",
        headers={"Authorization": f"Bearer {token_user}"},
    )
    assert res_after_single.json()["data"]["unread_count"] == 1

    # 5. Mark all as read
    res_read_all = client.post(
        "/api/v1/notifications/read-all",
        headers={"Authorization": f"Bearer {token_user}"},
    )
    assert res_read_all.status_code == 200
    assert res_read_all.json()["data"]["marked_read_count"] == 1

    # Unread count now 0
    res_final = client.get(
        "/api/v1/notifications",
        headers={"Authorization": f"Bearer {token_user}"},
    )
    assert res_final.json()["data"]["unread_count"] == 0


def test_notification_ownership_isolation(client: TestClient, db_session: Session):
    """User cannot read or mark another user's notification (403 FORBIDDEN)."""
    token_a, user_a = create_test_customer(client, db_session, email_prefix="user_a")
    token_b, user_b = create_test_customer(client, db_session, email_prefix="user_b")

    notif_a = Notification(
        id=uuid.uuid4(),
        recipient_id=uuid.UUID(user_a["id"]),
        type="SECURITY_ALERT",
        title="Private Alert",
        body="Secret Info",
        is_read=False,
    )
    db_session.add(notif_a)
    db_session.commit()

    # User B attempts to mark User A's notification as read
    res_hack = client.post(
        f"/api/v1/notifications/{notif_a.id}/read",
        headers={"Authorization": f"Bearer {token_b}"},
    )
    assert res_hack.status_code == 403
    assert res_hack.json()["error"]["code"] == "FORBIDDEN"

    # Verify it remains unread
    db_session.refresh(notif_a)
    assert notif_a.is_read is False


# ==============================================================================
# 7. Lifecycle Notifications & Idempotency Tests
# ==============================================================================

def test_lifecycle_notifications_opportunity_and_acceptance(client: TestClient, db_session: Session):
    """Verifies NEW_OPPORTUNITY on gig post and WORKER_ACCEPTED on worker acceptance."""
    token_cust, cust, token_w, w, gig_id, _ = setup_gig_environment(
        client, db_session, prefix="lifec", advance_to_selection=False
    )

    # 1. When gig was posted, worker should have received a NEW_OPPORTUNITY notification
    w_notifs = (
        db_session.query(Notification)
        .filter(
            Notification.recipient_id == uuid.UUID(w["id"]),
            Notification.type == "NEW_OPPORTUNITY",
            Notification.gig_id == uuid.UUID(gig_id),
        )
        .all()
    )
    assert len(w_notifs) >= 1

    # 2. Worker accepts opportunity
    res_opps = client.get(
        "/api/v1/worker/opportunities",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    opp_id = res_opps.json()["data"][0]["id"]
    res_acc = client.post(
        f"/api/v1/worker/opportunities/{opp_id}/accept",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    assert res_acc.status_code == 200

    # 3. Customer should have received a WORKER_ACCEPTED notification
    c_notifs = (
        db_session.query(Notification)
        .filter(
            Notification.recipient_id == uuid.UUID(cust["id"]),
            Notification.type == "WORKER_ACCEPTED",
            Notification.gig_id == uuid.UUID(gig_id),
        )
        .all()
    )
    assert len(c_notifs) == 1
    assert "accepted the opportunity" in c_notifs[0].body


def test_lifecycle_notifications_review_available_and_idempotency(client: TestClient, db_session: Session):
    """Verifies REVIEW_AVAILABLE notification triggers on gig completion and repeated confirmations are idempotent."""
    token_cust, cust, token_w, w, gig_id, _ = setup_gig_environment(
        client, db_session, prefix="revnotif", advance_to_selection=True
    )

    # Move gig through execution lifecycle to payment confirmation
    client.post(f"/api/v1/gigs/{gig_id}/start", headers={"Authorization": f"Bearer {token_w}"})
    client.post(
        f"/api/v1/gigs/{gig_id}/completion",
        headers={"Authorization": f"Bearer {token_w}"},
        json={
            "description": "All tap repairs done.",
            "evidence_items": [
                {"file_url": "https://storage/after.jpg", "file_type": "image/jpeg"}
            ],
        },
    )
    client.post(
        f"/api/v1/gigs/{gig_id}/completion/confirm",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"confirmed": True, "response_note": "Great work!"},
    )
    client.post(
        f"/api/v1/gigs/{gig_id}/payment",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"payment_method": "CASH"},
    )

    # Worker confirms payment receipt -> moves gig to COMPLETED
    res_conf = client.post(
        f"/api/v1/gigs/{gig_id}/payment/confirm-receipt",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"confirmed": True},
    )
    assert res_conf.status_code == 200

    # Verify REVIEW_AVAILABLE notifications for customer and worker
    c_rev = (
        db_session.query(Notification)
        .filter(
            Notification.recipient_id == uuid.UUID(cust["id"]),
            Notification.type == "REVIEW_AVAILABLE",
            Notification.gig_id == uuid.UUID(gig_id),
        )
        .all()
    )
    assert len(c_rev) == 1

    w_rev = (
        db_session.query(Notification)
        .filter(
            Notification.recipient_id == uuid.UUID(w["id"]),
            Notification.type == "REVIEW_AVAILABLE",
            Notification.gig_id == uuid.UUID(gig_id),
        )
        .all()
    )
    assert len(w_rev) == 1

    # Idempotency check: Repeat confirmation call
    res_repeat = client.post(
        f"/api/v1/gigs/{gig_id}/payment/confirm-receipt",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"confirmed": True},
    )
    assert res_repeat.status_code == 200

    # Verify count of REVIEW_AVAILABLE did NOT increase
    c_rev_after = (
        db_session.query(Notification)
        .filter(
            Notification.recipient_id == uuid.UUID(cust["id"]),
            Notification.type == "REVIEW_AVAILABLE",
            Notification.gig_id == uuid.UUID(gig_id),
        )
        .all()
    )
    assert len(c_rev_after) == 1
