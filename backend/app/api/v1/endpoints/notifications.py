"""Notifications API endpoints for user in-app notifications."""

import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.models.user import User
from app.db.session import get_db
from app.schemas.common import ResponseEnvelope
from app.schemas.notification import (
    NotificationListResponse,
    NotificationReadAllResponse,
    NotificationResponse,
)
from app.services.notification_service import NotificationService

router = APIRouter()


@router.get(
    "/notifications",
    response_model=ResponseEnvelope[NotificationListResponse],
    summary="Get user notifications",
    description="Retrieve notifications for the authenticated user, sorted newest-first, with optional is_read/type filtering.",
)
def get_notifications(
    is_read: Optional[bool] = Query(default=None, description="Filter by read status"),
    type: Optional[str] = Query(default=None, description="Filter by notification category/type"),
    limit: int = Query(default=50, ge=1, le=100, description="Max notifications to return"),
    offset: int = Query(default=0, ge=0, description="Offset for pagination"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = NotificationService.get_user_notifications(
        db=db,
        current_user=current_user,
        is_read=is_read,
        notif_type=type,
        limit=limit,
        offset=offset,
    )
    return ResponseEnvelope(data=result)


@router.post(
    "/notifications/{notification_id}/read",
    response_model=ResponseEnvelope[NotificationResponse],
    summary="Mark single notification as read",
    description="Mark a specific notification owned by the authenticated user as read.",
)
def mark_notification_read(
    notification_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    notif = NotificationService.mark_notification_as_read(
        db=db,
        current_user=current_user,
        notification_id=notification_id,
    )
    return ResponseEnvelope(data=notif, message="Notification marked as read.")


@router.post(
    "/notifications/read-all",
    response_model=ResponseEnvelope[NotificationReadAllResponse],
    summary="Mark all notifications as read",
    description="Mark all unread notifications for the authenticated user as read.",
)
def mark_all_notifications_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = NotificationService.mark_all_notifications_as_read(
        db=db,
        current_user=current_user,
    )
    return ResponseEnvelope(data=result, message=f"Marked {result.marked_read_count} notifications as read.")
