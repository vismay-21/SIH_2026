"""Security utilities and authentication dependencies.

Validates Supabase Auth JWTs, decodes claims, resolves application users,
and enforces role permissions.
"""

import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional
import jwt
from fastapi import Depends, Header
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import ForbiddenException, UnauthorizedException
from app.db.session import get_db
from app.db.models.user import User
from app.db.models.enums import UserRole


async def get_current_user_token(
    authorization: Optional[str] = Header(None),
) -> str:
    """Extract Bearer token from the Authorization header."""
    if not authorization:
        raise UnauthorizedException(
            message="Authorization header is required",
            code="MISSING_AUTH_HEADER",
        )

    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise UnauthorizedException(
            message="Invalid Authorization header format. Expected 'Bearer <token>'",
            code="INVALID_AUTH_HEADER",
        )

    return parts[1]


def decode_supabase_token(token: str) -> Dict[str, Any]:
    """Decode and cryptographically verify a Supabase JWT token.

    Uses settings.SUPABASE_JWT_SECRET and HS256 algorithm.
    """
    if not settings.SUPABASE_JWT_SECRET:
        raise UnauthorizedException(
            message="JWT authentication secret is not configured on server",
            code="AUTH_CONFIG_ERROR",
        )

    try:
        payload = jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            options={"verify_aud": False},
        )
        sub = payload.get("sub")
        if not sub or not str(sub).strip():
            raise UnauthorizedException(
                message="Token is missing or contains an empty 'sub' subject claim",
                code="INVALID_TOKEN_CLAIMS",
            )

        try:
            uuid.UUID(str(sub))
        except (ValueError, TypeError):
            raise UnauthorizedException(
                message="Invalid user identifier format in token: must be a valid UUID",
                code="INVALID_USER_ID",
            )

        return payload
    except jwt.ExpiredSignatureError:
        raise UnauthorizedException(
            message="Authentication token has expired. Please log in again.",
            code="TOKEN_EXPIRED",
        )
    except jwt.InvalidTokenError as e:
        raise UnauthorizedException(
            message=f"Invalid authentication token: {str(e)}",
            code="INVALID_TOKEN",
        )


async def get_current_token_payload(
    token: str = Depends(get_current_user_token),
) -> Dict[str, Any]:
    """Dependency that returns the verified JWT token claims."""
    return decode_supabase_token(token)


async def get_current_user(
    payload: Dict[str, Any] = Depends(get_current_token_payload),
    db: Session = Depends(get_db),
) -> User:
    """Resolve the authenticated application user from JWT 'sub' claim."""
    sub = payload.get("sub")
    try:
        user_uuid = uuid.UUID(sub)
    except (ValueError, TypeError):
        raise UnauthorizedException(
            message="Invalid user identifier in token",
            code="INVALID_USER_ID",
        )

    user = db.query(User).filter(User.id == user_uuid).first()
    if not user:
        raise UnauthorizedException(
            message="User account not found or not yet initialized. Please initialize account.",
            code="USER_NOT_INITIALIZED",
        )

    return user


async def get_current_active_user(
    current_user: User = Depends(get_current_user),
) -> User:
    """Ensure the authenticated user is currently active."""
    if not current_user.is_active:
        raise ForbiddenException(
            message="User account is deactivated or inactive",
            code="USER_INACTIVE",
        )
    return current_user


def require_role(required_role: UserRole):
    """Dependency factory that enforces a specific UserRole."""
    async def role_checker(
        current_user: User = Depends(get_current_active_user),
    ) -> User:
        if current_user.role != required_role:
            raise ForbiddenException(
                message=f"Access denied. Requires '{required_role.value}' role, but user has '{current_user.role.value}' role.",
                code="FORBIDDEN_ROLE",
                details={
                    "required_role": required_role.value,
                    "current_role": current_user.role.value,
                },
            )
        return current_user

    return role_checker


# Role-specific dependencies
require_customer = require_role(UserRole.CUSTOMER)
require_worker = require_role(UserRole.WORKER)


def create_access_token(
    data: Dict[str, Any],
    expires_delta: Optional[timedelta] = None,
) -> str:
    """Create a signed JWT token for testing and local authentication."""
    to_encode = data.copy()
    now = datetime.now(timezone.utc)
    expire = now + (expires_delta or timedelta(hours=24))
    to_encode.update({"iat": now, "exp": expire})
    return jwt.encode(to_encode, settings.SUPABASE_JWT_SECRET, algorithm="HS256")
