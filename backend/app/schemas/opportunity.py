import uuid
from datetime import date, time, datetime
from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict

from app.db.models.enums import GigType, OpportunityStatus, MaterialProcurementMode
from app.schemas.gig import GigTaskItemResponse


class OpportunityGigResponse(BaseModel):
    """Gig details nested within a worker opportunity."""

    id: uuid.UUID
    category_id: uuid.UUID
    category_name: str
    gig_type: GigType
    description: Optional[str] = None
    instructions: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    scheduled_date: Optional[date] = None
    scheduled_start_time: Optional[time] = None
    scheduled_end_time: Optional[time] = None
    expected_duration_minutes: Optional[int] = None
    is_emergency: bool = False
    material_procurement_mode: MaterialProcurementMode
    acceptance_deadline: Optional[datetime] = None
    tasks: List[GigTaskItemResponse] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)


class OpportunityResponse(BaseModel):
    """Worker opportunity response matching 05_API_DESIGN.md Section 15.

    Includes immutable pricing and wage snapshots determined at offer creation.
    """

    id: uuid.UUID
    gig_id: uuid.UUID
    worker_id: uuid.UUID
    status: OpportunityStatus
    base_price: float = Field(description="Base labour price snapshot for the gig")
    base_price_snapshot: float
    final_score_snapshot: float
    premium_percentage: float
    exact_wage: float = Field(description="Exact guaranteed cooperative wage before acceptance")
    offered_at: datetime
    responded_at: Optional[datetime] = None
    gig: OpportunityGigResponse

    model_config = ConfigDict(from_attributes=True)
