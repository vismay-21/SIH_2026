from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.security import require_customer
from app.db.session import get_db
from app.db.models.user import User
from app.schemas.common import ResponseEnvelope
from app.schemas.user import (
    CustomerProfileResponse,
    CustomerProfileUpdateRequest,
)
from app.services.user_service import UserService

router = APIRouter()


@router.get(
    "/customer/profile",
    response_model=ResponseEnvelope[CustomerProfileResponse],
    summary="Get customer profile",
)
async def get_customer_profile(
    current_user: User = Depends(require_customer),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[CustomerProfileResponse]:
    """Retrieve profile of the authenticated customer."""
    profile = UserService.get_customer_profile(db=db, user=current_user)
    return ResponseEnvelope(data=profile)


@router.patch(
    "/customer/profile",
    response_model=ResponseEnvelope[CustomerProfileResponse],
    summary="Update customer profile",
)
async def update_customer_profile(
    request: CustomerProfileUpdateRequest,
    current_user: User = Depends(require_customer),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[CustomerProfileResponse]:
    """Update profile attributes for the authenticated customer."""
    updated_profile = UserService.update_customer_profile(
        db=db,
        user=current_user,
        data=request,
    )
    return ResponseEnvelope(data=updated_profile)
