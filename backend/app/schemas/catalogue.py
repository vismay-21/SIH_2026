import uuid
from typing import Optional
from pydantic import BaseModel, ConfigDict


class ServiceCategoryResponse(BaseModel):
    """Service category schema conforming to 05_API_DESIGN.md Section 8."""

    id: uuid.UUID
    name: str
    description: Optional[str] = None
    base_rate_per_minute: float
    minimum_billable_minutes: int
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class ServiceTaskResponse(BaseModel):
    """Service task catalogue schema with complexity metrics from WAGES.md."""

    id: uuid.UUID
    category_id: uuid.UUID
    name: str
    description: Optional[str] = None
    standard_duration_minutes: int
    base_price: float
    complexity_score: float
    complexity_bucket: str  # "LOW", "MID", "HIGH"
    is_active: bool

    model_config = ConfigDict(from_attributes=True)
