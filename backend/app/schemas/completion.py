import uuid
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field


class CompletionEvidenceCreate(BaseModel):
    """Evidence file item to attach to a completion submission."""

    file_url: str = Field(..., description="Public or signed storage URL for the completion image")
    file_type: str = Field(default="image/jpeg", description="MIME type of the evidence file")


class CompletionEvidenceResponse(BaseModel):
    """Evidence file attached to a completion submission."""

    id: uuid.UUID
    submission_id: uuid.UUID
    file_url: str
    file_type: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CompletionSubmissionRequest(BaseModel):
    """Worker request payload to submit completion evidence conforming to 05_API_DESIGN.md Section 22."""

    description: Optional[str] = Field(default=None, description="Worker completion notes and explanation of work done")
    evidence_items: List[CompletionEvidenceCreate] = Field(
        ...,
        min_length=1,
        description="List of photo evidence files (at least 1 required for MVP verification)",
    )


class CompletionSubmissionResponse(BaseModel):
    """Response returned upon successfully submitting completion evidence."""

    id: uuid.UUID
    gig_id: uuid.UUID
    worker_id: uuid.UUID
    description: Optional[str] = None
    submitted_at: datetime
    evidence_files: List[CompletionEvidenceResponse] = []

    model_config = ConfigDict(from_attributes=True)


class CompletionConfirmationRequest(BaseModel):
    """Customer request payload to confirm or reject work completion."""

    confirmed: bool = Field(..., description="True if customer approves completion; False if rework requested")
    response_note: Optional[str] = Field(default=None, description="Optional customer feedback note or rework instructions")


class CompletionConfirmationResponse(BaseModel):
    """Confirmation record created by customer review."""

    id: uuid.UUID
    gig_id: uuid.UUID
    customer_id: uuid.UUID
    confirmed: bool
    response_note: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class StartWorkResponse(BaseModel):
    """Response returned when worker starts work on a gig."""

    gig_id: uuid.UUID
    status: str
    message: str = "Work started successfully."

    model_config = ConfigDict(from_attributes=True)


class GigCompletionDetailResponse(BaseModel):
    """Comprehensive completion details including submission, attached evidence, and review confirmation."""

    gig_id: uuid.UUID
    status: str
    submission: Optional[CompletionSubmissionResponse] = None
    confirmation: Optional[CompletionConfirmationResponse] = None

    model_config = ConfigDict(from_attributes=True)
