import uuid
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field

from app.db.models.enums import ReviewerRole


class ReviewQuestionResponse(BaseModel):
    """Structured review question template."""

    id: uuid.UUID
    target_role: ReviewerRole
    question_text: str
    display_order: int
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class ReviewAnswerItem(BaseModel):
    """Answer payload for an individual question."""

    question_id: uuid.UUID
    answer_value: int = Field(..., ge=1, le=5, description="1 to 5 star rating value")


class ReviewCreateRequest(BaseModel):
    """Review submission payload conforming to 05_API_DESIGN.md Section 27."""

    reviewee_id: uuid.UUID
    overall_rating: Optional[float] = Field(
        default=None,
        ge=1.0,
        le=5.0,
        description="Optional client overall rating. If provided, must match calculated average of answers.",
    )
    answers: List[ReviewAnswerItem] = Field(
        ...,
        min_length=1,
        description="List of structured question answers (1-5 each)",
    )


class ReviewAnswerResponse(BaseModel):
    """Answer detail returned in review queries."""

    id: uuid.UUID
    question_id: uuid.UUID
    question_text: str
    answer_value: int

    model_config = ConfigDict(from_attributes=True)


class ReviewResponse(BaseModel):
    """Review detail response."""

    id: uuid.UUID
    gig_id: uuid.UUID
    reviewer_id: uuid.UUID
    reviewee_id: uuid.UUID
    reviewer_role: ReviewerRole
    overall_rating: float
    answers: List[ReviewAnswerResponse]
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class WorkerPublicMetricsResponse(BaseModel):
    """Customer-facing worker performance metrics conforming to 05_API_DESIGN.md Section 28.

    Excludes internal algorithmic debug signals or private financial details.
    """

    worker_id: uuid.UUID
    completed_jobs_count: int
    rating_average: float
    rating_count: int
    final_score: float

    model_config = ConfigDict(from_attributes=True)
