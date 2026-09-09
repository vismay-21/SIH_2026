import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, Body
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models.user import User
from app.db.models.enums import UserRole
from app.core.security import get_current_active_user, require_role
from app.schemas.common import ResponseEnvelope
from app.schemas.cancellation import (
    GigCancelRequest,
    GigCancelResponse,
    GigReopenResponse,
    RescheduleRequestCreate,
    RescheduleAlternativeRequest,
    RescheduleRequestResponse,
)
from app.services.cancellation_service import CancellationService

router = APIRouter()


@router.post(
    "/gigs/{gig_id}/cancel",
    response_model=ResponseEnvelope[GigCancelResponse],
    summary="Cancel an active gig",
)
async def cancel_gig(
    gig_id: uuid.UUID,
    payload: GigCancelRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[GigCancelResponse]:
    """Cancel a gig with authoritative fee calculation and opportunity expiration.

    - Customer cancellation after worker selection charges ₹50.00 cancellation fee.
    - Customer cancellation before worker selection charges ₹0.00.
    - Worker cancellation charges ₹0.00.
    """
    result = CancellationService.cancel_gig(
        user=current_user,
        gig_id=gig_id,
        reason=payload.reason,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.post(
    "/gigs/{gig_id}/reopen",
    response_model=ResponseEnvelope[GigReopenResponse],
    summary="Reopen a worker-cancelled gig",
)
async def reopen_gig(
    gig_id: uuid.UUID,
    current_user: User = Depends(require_role(UserRole.CUSTOMER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[GigReopenResponse]:
    """Customer reopens a gig that was previously cancelled by the worker.

    Fails if:
    - The gig was cancelled by the customer rather than worker.
    - An outstanding cancellation fee on the gig is unsettled.
    """
    result = CancellationService.reopen_gig(
        user=current_user,
        gig_id=gig_id,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.post(
    "/gigs/{gig_id}/reschedule",
    response_model=ResponseEnvelope[RescheduleRequestResponse],
    summary="Initiate a reschedule request",
)
async def create_reschedule_request(
    gig_id: uuid.UUID,
    payload: RescheduleRequestCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[RescheduleRequestResponse]:
    """Propose a new schedule for an agreed gig (WORKER_SELECTED or SCHEDULED)."""
    result = CancellationService.create_reschedule_request(
        user=current_user,
        gig_id=gig_id,
        payload=payload,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.get(
    "/gigs/{gig_id}/reschedule",
    response_model=ResponseEnvelope[List[RescheduleRequestResponse]],
    summary="Get all reschedule requests for a gig",
)
async def get_reschedule_requests(
    gig_id: uuid.UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[List[RescheduleRequestResponse]]:
    """List historical and active reschedule negotiations for this gig."""
    result = CancellationService.get_reschedule_requests(
        user=current_user,
        gig_id=gig_id,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.post(
    "/gigs/{gig_id}/reschedule/{request_id}/accept",
    response_model=ResponseEnvelope[RescheduleRequestResponse],
    summary="Accept a reschedule request",
)
async def accept_reschedule_request(
    gig_id: uuid.UUID,
    request_id: uuid.UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[RescheduleRequestResponse]:
    """Counterparty accepts the proposed schedule, updating the gig schedule."""
    result = CancellationService.accept_reschedule_request(
        user=current_user,
        gig_id=gig_id,
        request_id=request_id,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.post(
    "/gigs/{gig_id}/reschedule/{request_id}/reject",
    response_model=ResponseEnvelope[RescheduleRequestResponse],
    summary="Reject a reschedule request",
)
async def reject_reschedule_request(
    gig_id: uuid.UUID,
    request_id: uuid.UUID,
    reason: Optional[str] = Body(None, embed=True),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[RescheduleRequestResponse]:
    """Counterparty rejects the proposed schedule. Current gig schedule remains active."""
    result = CancellationService.reject_reschedule_request(
        user=current_user,
        gig_id=gig_id,
        request_id=request_id,
        reason=reason,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.post(
    "/gigs/{gig_id}/reschedule/{request_id}/alternative",
    response_model=ResponseEnvelope[RescheduleRequestResponse],
    summary="Propose an alternative schedule",
)
async def propose_reschedule_alternative(
    gig_id: uuid.UUID,
    request_id: uuid.UUID,
    payload: RescheduleAlternativeRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[RescheduleRequestResponse]:
    """Counterparty proposes an alternative date/time slot."""
    result = CancellationService.propose_reschedule_alternative(
        user=current_user,
        gig_id=gig_id,
        request_id=request_id,
        payload=payload,
        db=db,
    )
    return ResponseEnvelope(data=result)
