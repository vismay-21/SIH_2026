import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.security import get_current_active_user
from app.db.models.enums import ReviewerRole
from app.db.models.user import User
from app.db.session import get_db
from app.schemas.common import ResponseEnvelope
from app.schemas.review import (
    ReviewCreateRequest,
    ReviewQuestionResponse,
    ReviewResponse,
    WorkerPublicMetricsResponse,
)
from app.services.review_service import ReviewService

router = APIRouter()


@router.get(
    "/review-questions",
    response_model=ResponseEnvelope[List[ReviewQuestionResponse]],
    summary="Get active structured review questions",
)
async def get_review_questions(
    target_role: Optional[ReviewerRole] = Query(
        default=None,
        description="Filter questions by target role (CUSTOMER or WORKER)",
    ),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> ResponseEnvelope[List[ReviewQuestionResponse]]:
    """Retrieve active structured MCQ review questions.

    Conforms to 05_API_DESIGN.md Section 27 and 06_BACKEND_SPRINTS.md Section 36.
    """
    questions = ReviewService.get_review_questions(db=db, target_role=target_role)
    return ResponseEnvelope(data=questions)


@router.post(
    "/gigs/{gig_id}/reviews",
    response_model=ResponseEnvelope[ReviewResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Submit a structured review for a completed gig",
)
async def submit_review(
    gig_id: uuid.UUID,
    request: ReviewCreateRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[ReviewResponse]:
    """Submit a structured two-way review for a completed gig.

    Enforces:
    - Gig must be in COMPLETED status (returns 409 if not).
    - Caller must be an authenticated participant (customer or assigned/collaborating worker).
    - Reviewee must be the valid counterparty.
    - Exactly one review per direction per gig (returns 409 on duplicate).
    - Question targets must match reviewee role, and answers must be between 1 and 5.
    - Automatically updates WorkerMetric and Bayesian rating signals when customer reviews worker.
    """
    review = ReviewService.submit_review(
        db=db,
        current_user=current_user,
        gig_id=gig_id,
        payload=request,
    )
    return ResponseEnvelope(data=review)


@router.get(
    "/gigs/{gig_id}/reviews",
    response_model=ResponseEnvelope[List[ReviewResponse]],
    summary="Retrieve reviews for a completed gig",
)
async def get_gig_reviews(
    gig_id: uuid.UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[List[ReviewResponse]]:
    """Retrieve reviews for a gig, restricted to authenticated gig participants."""
    reviews = ReviewService.get_gig_reviews(
        db=db,
        current_user=current_user,
        gig_id=gig_id,
    )
    return ResponseEnvelope(data=reviews)


@router.get(
    "/workers/{worker_id}/metrics",
    response_model=ResponseEnvelope[WorkerPublicMetricsResponse],
    summary="Get customer-facing worker performance metrics",
)
async def get_worker_metrics(
    worker_id: uuid.UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[WorkerPublicMetricsResponse]:
    """Retrieve public performance and rating metrics for a worker per 05_API_DESIGN.md Section 28."""
    metrics = ReviewService.get_worker_metrics(db=db, worker_id=worker_id)
    return ResponseEnvelope(data=metrics)
