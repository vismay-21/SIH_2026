import uuid
from typing import Optional, Any
from pydantic import BaseModel, ConfigDict, Field


class GigCandidateResponse(BaseModel):
    """Candidate representation for customer worker selection conforming to 05_API_DESIGN.md Section 16."""

    worker_id: uuid.UUID
    name: str
    exact_wage: float = Field(description="Guaranteed exact cooperative wage for this worker")
    completed_jobs_count: int = 0
    rating_average: float = 0.0
    rating_count: int = 0
    final_score: float
    profile_photo_url: Optional[str] = None
    recommendation: Optional[Any] = None  # None for MVP (no fake recommendation ranking)

    model_config = ConfigDict(from_attributes=True)


class SelectWorkerRequest(BaseModel):
    """Request payload to select a candidate worker for a gig conforming to 05_API_DESIGN.md Section 17."""

    worker_id: uuid.UUID = Field(description="Selected candidate worker UUID")


class SelectWorkerResponse(BaseModel):
    """Response returned upon successfully selecting a worker."""

    gig_id: uuid.UUID
    selected_worker_id: uuid.UUID
    status: str
    message: str = "Worker selected successfully."

    model_config = ConfigDict(from_attributes=True)
