import uuid
from typing import Any, Dict
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.exceptions import UnauthorizedException
from app.core.security import (
    get_current_active_user,
    get_current_token_payload,
)
from app.db.session import get_db
from app.db.models.user import User
from app.schemas.common import ResponseEnvelope
from app.schemas.user import UserResponse, UserInitializeRequest
from app.services.user_service import UserService

router = APIRouter()


@router.get(
    "/me",
    response_model=ResponseEnvelope[UserResponse],
    summary="Get current authenticated application user",
)
async def get_me(
    current_user: User = Depends(get_current_active_user),
) -> ResponseEnvelope[UserResponse]:
    """Return the authenticated application user record corresponding to the Supabase identity."""
    return ResponseEnvelope(data=UserResponse.model_validate(current_user))


@router.post(
    "/me/initialize",
    response_model=ResponseEnvelope[UserResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Initialize application user record after Supabase signup",
)
async def initialize_me(
    request: UserInitializeRequest,
    payload: Dict[str, Any] = Depends(get_current_token_payload),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[UserResponse]:
    """Create or initialize the application-level users record after Supabase authentication.

    Resolves user UUID from JWT 'sub' claim and establishes one-role mapping.
    """
    sub = payload.get("sub")
    try:
        user_uuid = uuid.UUID(sub)
    except (ValueError, TypeError):
        raise UnauthorizedException(
            message="Invalid user identifier in token",
            code="INVALID_USER_ID",
        )

    email = payload.get("email")
    user = UserService.initialize_user(
        db=db,
        user_id=user_uuid,
        email=email,
        data=request,
    )
    return ResponseEnvelope(data=UserResponse.model_validate(user))
