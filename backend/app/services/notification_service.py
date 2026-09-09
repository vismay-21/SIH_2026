"""Notification Service for Sahakaar Seva.

Handles in-app notification querying, filtering, pagination, and read status management per:
- docs/06_BACKEND_SPRINTS.md (Section 37)
- docs/05_API_DESIGN.md (Section 30)
- docs/04_DATABASE_DESIGN.md (Section 49)
"""

import uuid
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy.orm import Session

from app.core.exceptions import ForbiddenException, NotFoundException
from app.db.models.communication import Notification
from app.db.models.user import User
from app.schemas.notification import (
    NotificationListResponse,
    NotificationReadAllResponse,
    NotificationResponse,
)


class NotificationService:
    """Service managing user notifications and read receipts."""

    @classmethod
    def get_user_notifications(
        cls,
        db: Session,
        current_user: User,
        is_read: Optional[bool] = None,
        notif_type: Optional[str] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> NotificationListResponse:
        """Fetch notifications for the authenticated user with optional status/type filters."""
        base_query = db.query(Notification).filter(Notification.recipient_id == current_user.id)

        if is_read is not None:
            base_query = base_query.filter(Notification.is_read == is_read)

        if notif_type:
            base_query = base_query.filter(Notification.type == notif_type)

        total = base_query.count()

        # Unread count across all notifications for this user
        unread_count = (
            db.query(Notification)
            .filter(
                Notification.recipient_id == current_user.id,
                Notification.is_read == False,
            )
            .count()
        )

        notifications = (
            base_query.order_by(Notification.created_at.desc())
            .offset(offset)
            .limit(limit)
            .all()
        )

        items = [NotificationResponse.model_validate(n) for n in notifications]

        return NotificationListResponse(
            items=items,
            total=total,
            unread_count=unread_count,
            limit=limit,
            offset=offset,
        )

    @classmethod
    def mark_notification_as_read(
        cls,
        db: Session,
        current_user: User,
        notification_id: uuid.UUID,
    ) -> NotificationResponse:
        """Mark a single notification as read if owned by current user."""
        notification = db.query(Notification).filter(Notification.id == notification_id).first()
        if not notification:
            raise NotFoundException(
                f"Notification with id {notification_id} not found.",
                code="NOTIFICATION_NOT_FOUND",
            )

        if notification.recipient_id != current_user.id:
            raise ForbiddenException(
                "You do not have permission to view or modify this notification.",
                code="FORBIDDEN",
            )

        if not notification.is_read:
            notification.is_read = True
            notification.read_at = datetime.now(timezone.utc)
            db.commit()
            db.refresh(notification)

        return NotificationResponse.model_validate(notification)

    @classmethod
    def mark_all_notifications_as_read(
        cls,
        db: Session,
        current_user: User,
    ) -> NotificationReadAllResponse:
        """Mark all unread notifications for the authenticated user as read."""
        unread_query = db.query(Notification).filter(
            Notification.recipient_id == current_user.id,
            Notification.is_read == False,
        )

        unread_count = unread_query.count()
        now_utc = datetime.now(timezone.utc)

        unread_query.update(
            {"is_read": True, "read_at": now_utc},
            synchronize_session=False,
        )
        db.commit()

        return NotificationReadAllResponse(marked_read_count=unread_count)
