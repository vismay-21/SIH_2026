from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.security import require_worker
from app.db.session import get_db
from app.db.models.user import User
from app.schemas.common import ResponseEnvelope
from app.schemas.worker import (
    WorkerProfileResponse,
    WorkerProfileUpdateRequest,
    AadhaarUploadRequest,
    AadhaarUploadResponse,
    WorkerCategoryResponse,
    WorkerCategorySelectionRequest,
    WorkerAvailabilityResponse,
    WorkerAvailabilityUpdateRequest,
)
from app.services.worker_service import WorkerService

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
