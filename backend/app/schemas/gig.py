import uuid
from datetime import date, time, datetime
from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict

from app.db.models.enums import GigType, GigStatus, MaterialProcurementMode


class GigTaskItemResponse(BaseModel):
    """Schema for individual task items associated with a gig."""

    id: uuid.UUID
    task_id: uuid.UUID
    task_name: str
    standard_duration_minutes_snapshot: int
    base_price_snapshot: float

    model_config = ConfigDict(from_attributes=True)


class GigCreateRequest(BaseModel):
    """Request payload to create a new customer gig conforming to 05_API_DESIGN.md Section 11."""

    category_id: uuid.UUID = Field(description="Service category UUID")
    task_ids: List[uuid.UUID] = Field(min_length=1, description="List of task UUIDs in the category")
    gig_type: GigType = Field(default=GigType.NORMAL, description="NORMAL or EMERGENCY")
    description: Optional[str] = Field(default=None, max_length=2000, description="Customer task description")
    instructions: Optional[str] = Field(default=None, max_length=2000, description="Special instructions")
    address: Optional[str] = Field(default=None, max_length=500, description="Service address")
    latitude: Optional[float] = Field(default=None, description="Location latitude")
    longitude: Optional[float] = Field(default=None, description="Location longitude")
    google_maps_link: Optional[str] = Field(default=None, max_length=1000, description="Google Maps URL")
    scheduled_date: Optional[date] = Field(default=None, description="Scheduled date of service")
    scheduled_start_time: Optional[time] = Field(default=None, description="Scheduled arrival start time")
    scheduled_end_time: Optional[time] = Field(default=None, description="Scheduled end time")
    expected_duration_minutes: Optional[int] = Field(default=None, ge=15, description="Expected duration")
    is_emergency: bool = Field(default=False, description="Emergency service flag")
    acceptance_deadline: Optional[datetime] = Field(default=None, description="Opportunity acceptance deadline")
    material_procurement_mode: MaterialProcurementMode = Field(
        default=MaterialProcurementMode.CUSTOMER_PURCHASES,
        description="CUSTOMER_PURCHASES or WORKER_PURCHASES",
    )

    model_config = ConfigDict(extra="ignore")


class GigResponse(BaseModel):
    """Complete gig details response conforming to 05_API_DESIGN.md Section 11 & 13."""

    id: uuid.UUID
    customer_id: uuid.UUID
    cooperative_id: uuid.UUID
    category_id: uuid.UUID
    category_name: str
    gig_type: GigType
    status: GigStatus
    description: Optional[str] = None
    instructions: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    google_maps_link: Optional[str] = None
    scheduled_date: Optional[date] = None
    scheduled_start_time: Optional[time] = None
    scheduled_end_time: Optional[time] = None
    expected_duration_minutes: Optional[int] = None
    is_emergency: bool
    acceptance_deadline: Optional[datetime] = None
    material_procurement_mode: MaterialProcurementMode
    base_price: float
    minimum_billable_minutes_snapshot: Optional[int] = None
    base_rate_per_minute_snapshot: Optional[float] = None
    selected_worker_id: Optional[uuid.UUID] = None
    tasks: List[GigTaskItemResponse]
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
