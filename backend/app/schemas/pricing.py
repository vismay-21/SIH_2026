import uuid
from typing import List
from pydantic import BaseModel, Field


class PricePreviewRequest(BaseModel):
    """Request payload to calculate pricing preview for selected tasks."""

    category_id: uuid.UUID = Field(description="Selected service category UUID")
    task_ids: List[uuid.UUID] = Field(min_length=1, description="List of task UUIDs belonging to category")


class PricePreviewTaskItem(BaseModel):
    """Summary of a selected task included in the price preview."""

    id: uuid.UUID
    name: str
    standard_duration_minutes: int
    base_price: float
    complexity_score: float


class EstimatedWageRange(BaseModel):
    """Worker wage estimates based on final score distribution (WAGES.md Section 6)."""

    min_wage: float = Field(description="Minimum wage (final_score = 0.0, 0% premium)")
    rookie_wage: float = Field(description="Rookie baseline wage (final_score = 0.35, 10.5% premium)")
    max_wage: float = Field(description="Maximum wage (final_score = 1.0, 30% premium)")


class PricePreviewResponse(BaseModel):
    """Response payload for POST /api/v1/gigs/price-preview."""

    category_id: uuid.UUID
    category_name: str
    base_rate_per_minute: float
    minimum_billable_minutes: int
    total_standard_duration_minutes: int
    billable_duration_minutes: int
    base_price: float
    tasks: List[PricePreviewTaskItem]
    estimated_wage_range: EstimatedWageRange
