"""Chat API endpoints for job-scoped conversations and messages."""

import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.models.user import User
from app.db.session import get_db
from app.schemas.common import ResponseEnvelope
from app.schemas.chat import (
    ConversationMessagesResponse,
    ConversationResponse,
    MessageCreateRequest,
    MessageResponse,
)
from app.services.chat_service import ChatService

router = APIRouter()


@router.get(
    "/gigs/{gig_id}/conversation",
    response_model=ResponseEnvelope[ConversationResponse],
    summary="Get or initialize job-scoped conversation",
    description="Retrieve the conversation thread for an authorized customer or selected worker on a gig.",
)
def get_conversation(
    gig_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    conv = ChatService.get_or_create_conversation(db, current_user, gig_id)
    return ResponseEnvelope(data=conv)


@router.post(
    "/gigs/{gig_id}/conversation/messages",
    response_model=ResponseEnvelope[MessageResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Send message in gig conversation",
    description="Send a text message in the gig conversation thread. Only authorized participants may send messages.",
)
def send_message(
    gig_id: uuid.UUID,
    payload: MessageCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    msg = ChatService.send_message(db, current_user, gig_id, payload)
    return ResponseEnvelope(data=msg, message="Message sent successfully.")


@router.get(
    "/gigs/{gig_id}/conversation/messages",
    response_model=ResponseEnvelope[ConversationMessagesResponse],
    summary="Get messages in gig conversation",
    description="Retrieve chronological messages for a gig conversation. Supports pagination via before cursor or offset.",
)
def get_conversation_messages(
    gig_id: uuid.UUID,
    limit: int = Query(default=50, ge=1, le=100, description="Max messages to return"),
    before: Optional[uuid.UUID] = Query(default=None, description="Message ID cursor for pagination"),
    offset: int = Query(default=0, ge=0, description="Offset pagination"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    messages_resp = ChatService.get_conversation_messages(
        db=db,
        current_user=current_user,
        gig_id=gig_id,
        limit=limit,
        before=before,
        offset=offset,
    )
    return ResponseEnvelope(data=messages_resp)
