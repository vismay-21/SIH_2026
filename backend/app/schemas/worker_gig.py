import uuid
from datetime import date, time, datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class WorkerGigListItem(BaseModel):
    """Worker-facing gig summary item conforming to 05_API_DESIGN.md Section 13."""

    id: uuid.UUID
    category_id: uuid.UUID
    category_name: str
    description: Optional[str] = None
    scheduled_date: Optional[date] = None
    scheduled_start_time: Optional[time] = None
    status: str
    base_price: float
    exact_wage: float = Field(description="Exact agreed/calculated wage snapshot for the worker")
    customer_id: uuid.UUID
    customer_name: Optional[str] = None
    address_line: Optional[str] = None
    emergency: bool = False
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
