import uuid
from datetime import datetime
from decimal import Decimal
from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict

from app.db.models.enums import GigType, VisitationProposalStatus


class VisitationProposalTaskItem(BaseModel):
    """Snapshot item for a proposed task in a visitation proposal."""

    id: uuid.UUID
    task_id: uuid.UUID
    task_name: str
    standard_duration_minutes_snapshot: int
    base_price_snapshot: Decimal

    model_config = ConfigDict(from_attributes=True)


class VisitationProposalCreateRequest(BaseModel):
    """Payload submitted by worker proposing tasks following inspection."""

    task_ids: List[uuid.UUID] = Field(
        min_length=1,
        description="List of service task UUIDs within the gig's category",
    )

    model_config = ConfigDict(extra="ignore")


class VisitationProposalResponse(BaseModel):
    """Complete detail of a worker's visitation proposal."""

    id: uuid.UUID
    gig_id: uuid.UUID
    worker_id: uuid.UUID
    base_price: Decimal
    status: VisitationProposalStatus
    proposed_at: datetime
    customer_responded_at: Optional[datetime] = None
    tasks: List[VisitationProposalTaskItem]

    model_config = ConfigDict(from_attributes=True)


class VisitationResponse(BaseModel):
    """High-level visitation overview and action capabilities."""

    gig_id: uuid.UUID
    gig_type: GigType
    visitation_fee: Decimal = Field(default=Decimal("100.00"))
    is_visitation: bool
    active_proposal: Optional[VisitationProposalResponse] = None
    proposals: List[VisitationProposalResponse] = Field(default_factory=list)
    can_propose: bool = False
    can_respond: bool = False

    model_config = ConfigDict(from_attributes=True)
