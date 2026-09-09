import uuid
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator


class MessageCreateRequest(BaseModel):
    """Payload to send a message in a gig conversation per 05_API_DESIGN.md Section 29."""

    message_text: str = Field(
        ...,
        min_length=1,
        max_length=2000,
        description="The content of the message, 1-2000 characters.",
    )

    @field_validator("message_text")
    @classmethod
    def validate_message_text(cls, v: str) -> str:
        trimmed = v.strip()
        if not trimmed:
            raise ValueError("Message text cannot be empty or whitespace only.")
        return trimmed


class MessageResponse(BaseModel):
    """Message detail within a conversation."""

    id: uuid.UUID
    conversation_id: uuid.UUID
    sender_id: uuid.UUID
    sender_name: Optional[str] = None
    sender_role: Optional[str] = None
    message_text: str
    is_read: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ConversationResponse(BaseModel):
    """Job-scoped conversation thread overview."""

    id: uuid.UUID
    gig_id: uuid.UUID
    customer_id: uuid.UUID
    worker_id: uuid.UUID
    customer_name: Optional[str] = None
    worker_name: Optional[str] = None
    unread_count: int = 0
    last_message: Optional[MessageResponse] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class ConversationMessagesResponse(BaseModel):
    """Paginated list of messages in a conversation."""

    conversation_id: uuid.UUID
    messages: List[MessageResponse]
    total: int
    has_more: bool = False
