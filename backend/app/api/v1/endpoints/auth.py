"""Development-only authentication endpoints for Flutter integration and testing.

Strictly enabled only in non-production environments (development, test, local).
Uses the EXACT same Supabase JWT secret, HS256 algorithm, claims (sub, email, role),
and token creation mechanism as the rest of the backend architecture.
"""

import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import ConflictException, ForbiddenException
from app.core.security import create_access_token
from app.db.session import get_db
from app.db.models.user import User
from app.db.models.enums import UserRole
from app.db.models.service import ServiceCategory, WorkerCategory
from app.schemas.auth import DevLoginRequest, DevLoginResponse, DemoUserItem
from app.schemas.common import ResponseEnvelope
from app.schemas.user import UserResponse, UserInitializeRequest
from app.services.user_service import UserService

router = APIRouter(prefix="/auth", tags=["Development Authentication"])


def _ensure_dev_environment():
    if settings.ENVIRONMENT.lower() not in {"development", "dev", "test", "local"}:
        raise ForbiddenException(
            message="Development authentication endpoints are disabled in non-development environments.",
            code="DEV_ENDPOINT_DISABLED",
        )


@router.post(
    "/login",
    response_model=ResponseEnvelope[DevLoginResponse],
    status_code=status.HTTP_200_OK,
    summary="Development login & JWT generation",
)
def dev_login(
    request: DevLoginRequest,
    db: Session = Depends(get_db),
) -> ResponseEnvelope[DevLoginResponse]:
    """Login or initialize a user in development, returning a signed Supabase-compatible JWT."""
    _ensure_dev_environment()

    user = db.query(User).filter(User.email == request.email).first()
    if user:
        if user.role != request.role:
            raise ConflictException(
                message=f"User already initialized with role '{user.role.value}', cannot login as '{request.role.value}'.",
                code="ROLE_IMMUTABLE",
            )
        if not user.is_active:
            raise ForbiddenException(
                message="User account is deactivated or inactive.",
                code="USER_INACTIVE",
            )
    else:
        # Auto-initialize user for development / test
        new_id = uuid.uuid4()
        full_name = request.full_name or (
            "Demo Customer" if request.role == UserRole.CUSTOMER else "Demo Worker"
        )
        init_req = UserInitializeRequest(
            role=request.role,
            full_name=full_name,
            phone="9876543210",
        )
        user = UserService.initialize_user(
            db=db,
            user_id=new_id,
            email=request.email,
            data=init_req,
        )

        # If worker, ensure at least one category is linked for seamless matching
        if user.role == UserRole.WORKER:
            category = db.query(ServiceCategory).filter(ServiceCategory.is_active == True).first()
            if category:
                db.add(WorkerCategory(worker_id=user.id, category_id=category.id))
                db.commit()

    # Generate token using authoritative backend security utility
    token = create_access_token(
        data={"sub": str(user.id), "email": user.email, "role": user.role.value}
    )

    return ResponseEnvelope(
        data=DevLoginResponse(
            access_token=token,
            token_type="bearer",
            user=UserResponse.model_validate(user),
        )
    )


@router.get(
    "/demo-users",
    response_model=ResponseEnvelope[List[DemoUserItem]],
    summary="List demo users for quick development selection",
)
def get_demo_users(
    db: Session = Depends(get_db),
) -> ResponseEnvelope[List[DemoUserItem]]:
    """Return available active demo users for quick testing (development only)."""
    _ensure_dev_environment()

    users = db.query(User).filter(User.is_active == True).limit(20).all()
    if not users:
        # Auto-seed a default customer and worker for seamless out-of-the-box demoing
        try:
            cust_id = uuid.uuid4()
            UserService.initialize_user(
                db=db,
                user_id=cust_id,
                email="customer@example.com",
                data=UserInitializeRequest(
                    role=UserRole.CUSTOMER,
                    full_name="Demo Customer",
                    phone="9876543210",
                ),
            )
            worker_id = uuid.uuid4()
            worker = UserService.initialize_user(
                db=db,
                user_id=worker_id,
                email="worker@example.com",
                data=UserInitializeRequest(
                    role=UserRole.WORKER,
                    full_name="Demo Worker",
                    phone="9876543211",
                ),
            )
            category = db.query(ServiceCategory).filter(ServiceCategory.is_active == True).first()
            if category:
                db.add(WorkerCategory(worker_id=worker.id, category_id=category.id))
                db.commit()
            users = db.query(User).filter(User.is_active == True).limit(20).all()
        except Exception:
            pass

    items = [
        DemoUserItem(
            id=u.id,
            email=u.email or f"user_{str(u.id)[:8]}@sahakaar.org",
            full_name=u.full_name or f"User {str(u.id)[:6]}",
            role=u.role,
        )
        for u in users
    ]
    return ResponseEnvelope(data=items)
