import uuid
from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.security import require_customer
from app.db.session import get_db
from app.db.models.user import User
from app.db.models.enums import GigStatus
from app.schemas.common import ResponseEnvelope, PaginatedResponse
from app.schemas.user import (
    CustomerProfileResponse,
    CustomerProfileUpdateRequest,
)
from app.schemas.gig import GigResponse
from app.services.user_service import UserService
from app.services.gig_service import GigService

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


@router.get(
    "/customer/gigs",
    response_model=PaginatedResponse[GigResponse],
    summary="List authenticated customer's gigs",
)
async def get_customer_gigs(
    status: Optional[GigStatus] = None,
    category_id: Optional[uuid.UUID] = None,
    scheduled_date: Optional[date] = None,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: User = Depends(require_customer),
    db: Session = Depends(get_db),
) -> PaginatedResponse[GigResponse]:
    """Retrieve customer's posted and draft gigs with status, category, date filters, and pagination."""
    return GigService.get_customer_gigs(
        customer_user=current_user,
        status=status,
        category_id=category_id,
        scheduled_date=scheduled_date,
        page=page,
        page_size=page_size,
        db=db,
    )

