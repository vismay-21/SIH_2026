import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict

from app.db.models.enums import (
    WorkerParticipationStatus,
    WorkerParticipationClassification,
)


class WorkerParticipationCreateRequest(BaseModel):
    """Payload submitted by the primary worker to invite a cooperative peer."""

    additional_worker_id: uuid.UUID = Field(
        ..., description="UUID of the additional worker to invite"
    )
    classification: WorkerParticipationClassification = Field(
        ..., description="Classification: ROOKIE or EQUAL_SHARING"
    )

    model_config = ConfigDict(extra="ignore")


class WorkerParticipationResponse(BaseModel):
    """Worker participation details."""

    id: uuid.UUID
    gig_id: uuid.UUID
    inviting_worker_id: uuid.UUID
    inviting_worker_name: Optional[str] = None
    additional_worker_id: uuid.UUID
    additional_worker_name: Optional[str] = None
    status: WorkerParticipationStatus
    classification: WorkerParticipationClassification
    experience_contribution: Optional[float] = None
    created_at: datetime
    responded_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
