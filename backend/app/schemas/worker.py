import uuid
from datetime import datetime, time
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field


class WorkerMetricResponse(BaseModel):
    """Worker ratings and algorithmic scores (read-only for clients)."""

    completed_jobs_count: int
    rating_average: float
    rating_count: int
    bayesian_score: float
    experience_score: float
    final_score: float

    model_config = ConfigDict(from_attributes=True)


class WorkerProfileResponse(BaseModel):
    """Worker profile payload conforming to 05_API_DESIGN.md Section 7."""

    user_id: uuid.UUID
    full_name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    profile_photo_url: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    aadhaar_document_url: Optional[str] = None
    aadhaar_uploaded_at: Optional[datetime] = None
    is_active: bool
    metrics: Optional[WorkerMetricResponse] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class WorkerProfileUpdateRequest(BaseModel):
    """Fields workers are allowed to edit on their profile.

    Does NOT allow tampering with scores, metrics, or verification status.
    """

    full_name: Optional[str] = Field(default=None, min_length=1, max_length=255)
    phone: Optional[str] = Field(default=None, max_length=20)
    address: Optional[str] = None
    city: Optional[str] = Field(default=None, max_length=100)
    profile_photo_url: Optional[str] = None


class AadhaarUploadRequest(BaseModel):
    """Aadhaar document reference upload payload."""

    document_url: str = Field(min_length=5, description="Storage URL or reference to Aadhaar document")


class AadhaarUploadResponse(BaseModel):
    """Response confirming storage of Aadhaar document reference."""

    aadhaar_document_url: str
    aadhaar_uploaded_at: datetime
    message: str = "Aadhaar document reference stored successfully. Pending verification."


class WorkerCategoryResponse(BaseModel):
    """Service category linked to a worker."""

    id: uuid.UUID
    name: str
    description: Optional[str] = None
    base_rate_per_minute: float
    minimum_billable_minutes: int

    model_config = ConfigDict(from_attributes=True)


class WorkerCategorySelectionRequest(BaseModel):
    """Request payload to replace worker's active categories."""

    category_ids: List[uuid.UUID] = Field(
        min_length=1,
        description="List of active service category UUIDs for this worker",
    )


class WorkerAvailabilitySlot(BaseModel):
    """Weekly recurring availability slot."""

    day_of_week: int = Field(ge=0, le=6, description="0=Monday, 6=Sunday")
    start_time: time
    end_time: time
    is_available: bool = True

    model_config = ConfigDict(from_attributes=True)


class WorkerAvailabilityUpdateRequest(BaseModel):
    """Request payload to update or replace weekly recurring availability slots."""

    slots: List[WorkerAvailabilitySlot] = Field(
        default_factory=list,
        description="List of recurring availability windows",
    )


class WorkerAvailabilityResponse(BaseModel):
    """Availability slot item returned to client."""

    id: uuid.UUID
    day_of_week: int
    start_time: time
    end_time: time
    is_available: bool

    model_config = ConfigDict(from_attributes=True)
