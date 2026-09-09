"""Job-Scoped Chat Service for Sahakaar Seva.

Implements customer-worker bilateral messaging, participant authorization,
read receipts, and notification generation conforming to:
- docs/06_BACKEND_SPRINTS.md (Section 37)
- docs/05_API_DESIGN.md (Section 29)
- docs/04_DATABASE_DESIGN.md (Section 48)
- docs/SRS_Final.md (Section 26)
- docs/FRONTEND_DEVELOPMENT_ROADMAP.md (Section 15.10)
"""

import uuid
from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session, joinedload

from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    ForbiddenException,
    NotFoundException,
)
from app.db.models.enums import UserRole, WorkerParticipationStatus
from app.db.models.gig import Gig
from app.db.models.user import User
from app.db.models.communication import Conversation, Message, Notification, GigEvent
from app.db.models.multi_worker import WorkerParticipation
from app.schemas.chat import (
    ConversationMessagesResponse,
    ConversationResponse,
    MessageCreateRequest,
    MessageResponse,
)


class ChatService:
    """Service handling job-scoped conversations, messages, and read receipts."""

    @classmethod
    def _verify_participant_access(
        cls,
        db: Session,
        gig: Gig,
        current_user: User,
    ) -> None:
        """Verify that the authenticated user is an authorized participant in the gig.

        Authorized participants:
        1. Gig customer (gig.customer_id == current_user.id)
        2. Selected primary worker (gig.selected_worker_id == current_user.id)
        3. Accepted collaborator (WorkerParticipation.status == ACCEPTED)
        """
        # 1. Customer check
        if gig.customer_id == current_user.id:
            return

        # 2. Primary worker check
        if gig.selected_worker_id == current_user.id:
            return

        # 3. Accepted collaborator check
        is_collab = (
            db.query(WorkerParticipation)
            .filter(
                WorkerParticipation.gig_id == gig.id,
                WorkerParticipation.additional_worker_id == current_user.id,
                WorkerParticipation.status == WorkerParticipationStatus.ACCEPTED,
            )
            .first()
        )
        if is_collab:
            return

        raise ForbiddenException(
            "You are not an authorized participant in this gig conversation.",
            code="NOT_GIG_PARTICIPANT",
        )

    @classmethod
    def _verify_chat_availability(cls, gig: Gig) -> None:
        """Enforce that chat is available only once a worker has been selected."""
        if gig.selected_worker_id is None:
            raise ConflictException(
                "Chat is not available before a worker has been selected for this gig.",
                code="CHAT_NOT_AVAILABLE",
            )

    @classmethod
    def get_or_create_conversation(
        cls,
        db: Session,
        current_user: User,
        gig_id: uuid.UUID,
    ) -> ConversationResponse:
        """Retrieve or lazily initialize the single job-scoped conversation for a gig."""
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise NotFoundException(f"Gig with id {gig_id} not found.", code="GIG_NOT_FOUND")

        cls._verify_chat_availability(gig)
        cls._verify_participant_access(db, gig, current_user)

        conv = (
            db.query(Conversation)
            .options(
                joinedload(Conversation.customer),
                joinedload(Conversation.worker),
            )
            .filter(Conversation.gig_id == gig.id)
            .first()
        )

        if not conv:
            conv = Conversation(
                id=uuid.uuid4(),
                gig_id=gig.id,
                customer_id=gig.customer_id,
                worker_id=gig.selected_worker_id,
            )
            db.add(conv)
            db.commit()
            db.refresh(conv)

        # Calculate unread count for current user
        unread_count = (
            db.query(Message)
            .filter(
                Message.conversation_id == conv.id,
                Message.sender_id != current_user.id,
                Message.is_read == False,
            )
            .count()
        )

        # Get latest message
        latest_msg = (
            db.query(Message)
            .options(joinedload(Message.sender))
            .filter(Message.conversation_id == conv.id)
            .order_by(Message.created_at.desc())
            .first()
        )

        last_message_response = None
        if latest_msg:
            last_message_response = MessageResponse(
                id=latest_msg.id,
                conversation_id=latest_msg.conversation_id,
                sender_id=latest_msg.sender_id,
                sender_name=latest_msg.sender.full_name if latest_msg.sender else None,
                sender_role=latest_msg.sender.role.value if latest_msg.sender and latest_msg.sender.role else None,
                message_text=latest_msg.message_text,
                is_read=latest_msg.is_read,
                created_at=latest_msg.created_at,
            )

        customer_user = db.query(User).filter(User.id == conv.customer_id).first()
        worker_user = db.query(User).filter(User.id == conv.worker_id).first()

        return ConversationResponse(
            id=conv.id,
            gig_id=conv.gig_id,
            customer_id=conv.customer_id,
            worker_id=conv.worker_id,
            customer_name=customer_user.full_name if customer_user else None,
            worker_name=worker_user.full_name if worker_user else None,
            unread_count=unread_count,
            last_message=last_message_response,
            created_at=conv.created_at,
            updated_at=conv.updated_at,
        )

    @classmethod
    def send_message(
        cls,
        db: Session,
        current_user: User,
        gig_id: uuid.UUID,
        payload: MessageCreateRequest,
    ) -> MessageResponse:
        """Send a message in the gig conversation, notify counterparty, and emit audit event."""
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise NotFoundException(f"Gig with id {gig_id} not found.", code="GIG_NOT_FOUND")

        cls._verify_chat_availability(gig)
        cls._verify_participant_access(db, gig, current_user)

        text = payload.message_text.strip()
        if not text:
            raise BadRequestException("Message text cannot be empty.", code="INVALID_MESSAGE_TEXT")

        # Get or lazily initialize conversation
        conv = db.query(Conversation).filter(Conversation.gig_id == gig.id).first()
        if not conv:
            conv = Conversation(
                id=uuid.uuid4(),
                gig_id=gig.id,
                customer_id=gig.customer_id,
                worker_id=gig.selected_worker_id,
            )
            db.add(conv)
            db.flush()

        # Create message
        msg_id = uuid.uuid4()
        message = Message(
            id=msg_id,
            conversation_id=conv.id,
            sender_id=current_user.id,
            message_text=text,
            is_read=False,
        )
        db.add(message)

        # Update conversation updated_at
        conv.updated_at = datetime.now(timezone.utc)

        # Determine notification recipients
        recipient_ids: List[uuid.UUID] = []
        if current_user.id == gig.customer_id:
            # Customer sent: notify primary selected worker and any accepted collaborators
            if gig.selected_worker_id:
                recipient_ids.append(gig.selected_worker_id)
            collabs = (
                db.query(WorkerParticipation)
                .filter(
                    WorkerParticipation.gig_id == gig.id,
                    WorkerParticipation.status == WorkerParticipationStatus.ACCEPTED,
                )
                .all()
            )
            for c in collabs:
                if c.additional_worker_id not in recipient_ids and c.additional_worker_id != current_user.id:
                    recipient_ids.append(c.additional_worker_id)
        elif current_user.id == gig.selected_worker_id:
            # Primary worker sent: notify customer and any accepted collaborators
            recipient_ids.append(gig.customer_id)
            collabs = (
                db.query(WorkerParticipation)
                .filter(
                    WorkerParticipation.gig_id == gig.id,
                    WorkerParticipation.status == WorkerParticipationStatus.ACCEPTED,
                )
                .all()
            )
            for c in collabs:
                if c.additional_worker_id not in recipient_ids and c.additional_worker_id != current_user.id:
                    recipient_ids.append(c.additional_worker_id)
        else:
            # Collaborator sent: notify customer and primary selected worker
            recipient_ids.append(gig.customer_id)
            if gig.selected_worker_id and gig.selected_worker_id != current_user.id:
                recipient_ids.append(gig.selected_worker_id)

        sender_label = current_user.full_name or ("Customer" if current_user.role == UserRole.CUSTOMER else "Worker")
        for r_id in recipient_ids:
            if r_id and r_id != current_user.id:
                db.add(
                    Notification(
                        recipient_id=r_id,
                        gig_id=gig.id,
                        type="CHAT_MESSAGE",
                        title=f"New message from {sender_label}",
                        body=text[:100],
                        action_url=f"/gigs/{gig.id}/conversation",
                    )
                )

        # Audit Event
        db.add(
            GigEvent(
                gig_id=gig.id,
                actor_id=current_user.id,
                event_type="CHAT_MESSAGE_SENT",
                metadata_json={
                    "message_id": str(message.id),
                    "conversation_id": str(conv.id),
                    "sender_id": str(current_user.id),
                    "character_count": len(text),
                },
            )
        )

        db.commit()
        db.refresh(message)

        return MessageResponse(
            id=message.id,
            conversation_id=message.conversation_id,
            sender_id=message.sender_id,
            sender_name=current_user.full_name,
            sender_role=current_user.role.value if current_user.role else None,
            message_text=message.message_text,
            is_read=message.is_read,
            created_at=message.created_at,
        )

    @classmethod
    def get_conversation_messages(
        cls,
        db: Session,
        current_user: User,
        gig_id: uuid.UUID,
        limit: int = 50,
        before: Optional[uuid.UUID] = None,
        offset: int = 0,
    ) -> ConversationMessagesResponse:
        """Fetch messages chronologically, supporting cursor/offset pagination and marking unread messages as read."""
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise NotFoundException(f"Gig with id {gig_id} not found.", code="GIG_NOT_FOUND")

        cls._verify_chat_availability(gig)
        cls._verify_participant_access(db, gig, current_user)

        conv = db.query(Conversation).filter(Conversation.gig_id == gig.id).first()
        if not conv:
            # Conversation does not exist yet; lazily initialize it
            conv = Conversation(
                id=uuid.uuid4(),
                gig_id=gig.id,
                customer_id=gig.customer_id,
                worker_id=gig.selected_worker_id,
            )
            db.add(conv)
            db.commit()
            db.refresh(conv)

        # Base query for messages in conversation
        query = (
            db.query(Message)
            .options(joinedload(Message.sender))
            .filter(Message.conversation_id == conv.id)
        )

        total = query.count()

        if before:
            cursor_msg = db.query(Message).filter(Message.id == before).first()
            if cursor_msg:
                query = query.filter(Message.created_at < cursor_msg.created_at)

        # Order by newest first to fetch the correct window, then return ascending chronological
        paged_messages = (
            query.order_by(Message.created_at.desc())
            .offset(offset if not before else 0)
            .limit(limit)
            .all()
        )

        # Reverse back to ascending (oldest to newest)
        chronological_messages = list(reversed(paged_messages))

        # Mark unread counterparty messages that were retrieved as read
        unread_to_update = [
            m for m in chronological_messages
            if m.sender_id != current_user.id and not m.is_read
        ]
        if unread_to_update:
            for m in unread_to_update:
                m.is_read = True
            db.commit()

        has_more = (offset + limit < total) if not before else (len(paged_messages) == limit)

        items = [
            MessageResponse(
                id=m.id,
                conversation_id=m.conversation_id,
                sender_id=m.sender_id,
                sender_name=m.sender.full_name if m.sender else None,
                sender_role=m.sender.role.value if m.sender and m.sender.role else None,
                message_text=m.message_text,
                is_read=m.is_read,
                created_at=m.created_at,
            )
            for m in chronological_messages
        ]

        return ConversationMessagesResponse(
            conversation_id=conv.id,
            messages=items,
            total=total,
            has_more=has_more,
        )
