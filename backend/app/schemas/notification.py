import uuid
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict


class NotificationResponse(BaseModel):
    """Notification response entity per 05_API_DESIGN.md Section 30."""

    id: uuid.UUID
    recipient_id: uuid.UUID
    gig_id: Optional[uuid.UUID] = None
    type: str
    title: str
    body: str
    action_url: Optional[str] = None
    is_read: bool
    created_at: datetime
    read_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class NotificationListResponse(BaseModel):
    """Notifications collection with unread metrics."""

    items: List[NotificationResponse]
    total: int
    unread_count: int
    limit: int
    offset: int


class NotificationReadAllResponse(BaseModel):
    """Result of marking all notifications as read."""

    marked_read_count: int
