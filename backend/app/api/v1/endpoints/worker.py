import uuid
from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.security import require_worker
from app.db.session import get_db
from app.db.models.user import User
from app.db.models.enums import OpportunityStatus
from app.schemas.common import ResponseEnvelope, PaginatedResponse
from app.schemas.worker import (
    WorkerProfileResponse,
    WorkerProfileUpdateRequest,
    AadhaarUploadRequest,
    AadhaarUploadResponse,
    WorkerCategoryResponse,
    WorkerCategorySelectionRequest,
    WorkerAvailabilityResponse,
    WorkerAvailabilityUpdateRequest,
    WorkerAvailabilityStatusRequest,
    WorkerAvailabilityStatusResponse,
)
from app.schemas.opportunity import OpportunityResponse
from app.schemas.worker_gig import WorkerGigListItem
from app.services.worker_service import WorkerService
from app.services.opportunity_service import OpportunityService
from app.services.completion_service import CompletionService

router = APIRouter()


@router.get(
    "/worker/profile",
    response_model=ResponseEnvelope[WorkerProfileResponse],
    summary="Get worker profile and metrics",
)
async def get_worker_profile(
    current_user: User = Depends(require_worker),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[WorkerProfileResponse]:
    """Retrieve profile and public performance metrics for the authenticated worker."""
    profile = WorkerService.get_worker_profile(db=db, user=current_user)
    return ResponseEnvelope(data=profile)


@router.patch(
    "/worker/profile",
    response_model=ResponseEnvelope[WorkerProfileResponse],
    summary="Update worker editable profile fields",
)
async def update_worker_profile(
    request: WorkerProfileUpdateRequest,
    current_user: User = Depends(require_worker),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[WorkerProfileResponse]:
    """Update allowable profile fields for the authenticated worker.

    Clients cannot alter experience_score, bayesian_score, final_score, or verification status.
    """
    updated = WorkerService.update_worker_profile(
        db=db,
        user=current_user,
        data=request,
    )
    return ResponseEnvelope(data=updated)


@router.post(
    "/worker/profile/aadhaar",
    response_model=ResponseEnvelope[AadhaarUploadResponse],
    summary="Upload/store worker Aadhaar document reference",
)
async def upload_worker_aadhaar(
    request: AadhaarUploadRequest,
    current_user: User = Depends(require_worker),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[AadhaarUploadResponse]:
    """Store an Aadhaar document reference.

    Conforms to 05_API_DESIGN.md Section 7: stores document reference without
    automatically toggling verification flags.
    """
    result = WorkerService.upload_aadhaar_reference(
        db=db,
        user=current_user,
        document_url=request.document_url,
    )
    return ResponseEnvelope(data=result)


@router.get(
    "/worker/categories",
    response_model=ResponseEnvelope[List[WorkerCategoryResponse]],
    summary="Get worker's active service categories",
)
async def get_worker_categories(
    current_user: User = Depends(require_worker),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[List[WorkerCategoryResponse]]:
    """Fetch active service categories associated with this worker."""
    categories = WorkerService.get_worker_categories(db=db, user=current_user)
    return ResponseEnvelope(data=categories)


@router.put(
    "/worker/categories",
    response_model=ResponseEnvelope[List[WorkerCategoryResponse]],
    summary="Replace worker's active service category selections",
)
async def set_worker_categories(
    request: WorkerCategorySelectionRequest,
    current_user: User = Depends(require_worker),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[List[WorkerCategoryResponse]]:
    """Replace all service category associations for the authenticated worker."""
    categories = WorkerService.set_worker_categories(
        db=db,
        user=current_user,
        category_ids=request.category_ids,
    )
    return ResponseEnvelope(data=categories)


@router.get(
    "/worker/availability",
    response_model=ResponseEnvelope[List[WorkerAvailabilityResponse]],
    summary="Get worker's weekly recurring availability",
)
async def get_worker_availability(
    current_user: User = Depends(require_worker),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[List[WorkerAvailabilityResponse]]:
    """Fetch worker's weekly recurring availability slots."""
    slots = WorkerService.get_worker_availability(db=db, user=current_user)
    return ResponseEnvelope(data=slots)


@router.put(
    "/worker/availability",
    response_model=ResponseEnvelope[List[WorkerAvailabilityResponse]],
    summary="Replace worker's weekly recurring availability slots",
)
async def set_worker_availability(
    request: WorkerAvailabilityUpdateRequest,
    current_user: User = Depends(require_worker),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[List[WorkerAvailabilityResponse]]:
    """Replace weekly recurring availability schedule for the authenticated worker."""
    slots = WorkerService.set_worker_availability(
        db=db,
        user=current_user,
        slots=request.slots,
    )
    return ResponseEnvelope(data=slots)


@router.patch(
    "/worker/availability/status",
    response_model=ResponseEnvelope[WorkerAvailabilityStatusResponse],
    summary="Update simple Available/Unavailable control",
)
async def update_worker_availability_status(
    request: WorkerAvailabilityStatusRequest,
    current_user: User = Depends(require_worker),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[WorkerAvailabilityStatusResponse]:
    """Update the simple Available/Unavailable control. Distinct from weekly recurring availability."""
    status = WorkerService.set_worker_availability_status(
        db=db,
        user=current_user,
        is_available=request.is_available,
    )
    return ResponseEnvelope(data=WorkerAvailabilityStatusResponse(is_available=status))


# --- Worker Opportunities (Sprint 5) ---

@router.get(
    "/worker/opportunities",
    response_model=PaginatedResponse[OpportunityResponse],
    summary="List worker opportunities with exact wage",
)
async def get_worker_opportunities(
    category_id: Optional[uuid.UUID] = Query(None, description="Filter by service category"),
    scheduled_date: Optional[date] = Query(None, description="Filter by scheduled date"),
    is_emergency: Optional[bool] = Query(None, description="Filter by emergency gigs"),
    status: Optional[OpportunityStatus] = Query(None, description="Filter by opportunity status"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Page size"),
    current_user: User = Depends(require_worker),
    db: Session = Depends(get_db),
) -> PaginatedResponse[OpportunityResponse]:
    """Retrieve opportunities available to the authenticated worker with their personalized exact guaranteed wage."""
    return OpportunityService.get_worker_opportunities(
        worker_user=current_user,
        category_id=category_id,
        scheduled_date=scheduled_date,
        is_emergency=is_emergency,
        status=status,
        page=page,
        page_size=page_size,
        db=db,
    )


@router.get(
    "/worker/opportunities/{opportunity_id}",
    response_model=ResponseEnvelope[OpportunityResponse],
    summary="Get opportunity details with exact wage",
)
async def get_worker_opportunity_by_id(
    opportunity_id: uuid.UUID,
    current_user: User = Depends(require_worker),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[OpportunityResponse]:
    """Retrieve full details for a specific worker opportunity."""
    opp = OpportunityService.get_opportunity_by_id(
        worker_user=current_user,
        opportunity_id=opportunity_id,
        db=db,
    )
    return ResponseEnvelope(data=opp)


@router.post(
    "/worker/opportunities/{opportunity_id}/accept",
    response_model=ResponseEnvelope[OpportunityResponse],
    summary="Accept gig opportunity",
)
async def accept_worker_opportunity(
    opportunity_id: uuid.UUID,
    current_user: User = Depends(require_worker),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[OpportunityResponse]:
    """Accept an opportunity. Verifies eligibility, active status, deadline, and schedule conflicts."""
    opp = OpportunityService.accept_opportunity(
        worker_user=current_user,
        opportunity_id=opportunity_id,
        db=db,
    )
    return ResponseEnvelope(data=opp)


@router.post(
    "/worker/opportunities/{opportunity_id}/reject",
    response_model=ResponseEnvelope[OpportunityResponse],
    summary="Reject gig opportunity",
)
async def reject_worker_opportunity(
    opportunity_id: uuid.UUID,
    current_user: User = Depends(require_worker),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[OpportunityResponse]:
    """Reject an opportunity. Final for this opportunity; cannot be accepted later."""
    opp = OpportunityService.reject_opportunity(
        worker_user=current_user,
        opportunity_id=opportunity_id,
        db=db,
    )
    return ResponseEnvelope(data=opp)


@router.get(
    "/worker/gigs",
    response_model=PaginatedResponse[WorkerGigListItem],
    summary="Get gigs assigned to worker",
)
async def get_worker_gigs(
    tab: Optional[str] = Query(None, description="Filter by tab: upcoming, active, completed, cancelled"),
    status: Optional[str] = Query(None, description="Direct status filter matching GigStatus enum"),
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=50),
    current_user: User = Depends(require_worker),
    db: Session = Depends(get_db),
) -> PaginatedResponse[WorkerGigListItem]:
    """Retrieve gigs where the authenticated worker is the selected worker."""
    return CompletionService.get_worker_gigs(
        worker_user=current_user,
        tab=tab,
        status=status,
        page=page,
        page_size=page_size,
        db=db,
    )


