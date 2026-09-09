import uuid
from decimal import Decimal
from datetime import date, time, datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field

from app.db.models.enums import GigStatus, RescheduleStatus, PaymentStatus


class GigCancelRequest(BaseModel):
    """Payload to cancel an active gig."""

    reason: str = Field(
        ...,
        min_length=5,
        max_length=500,
        description="Detailed reason explaining why the gig is being cancelled",
    )


class GigCancelResponse(BaseModel):
    """Response returned upon successful gig cancellation."""

    gig_id: uuid.UUID
    status: GigStatus
    cancelled_by: uuid.UUID
    cancellation_reason: str
    fee_amount: Decimal
    cancelled_at: datetime
    payment_status: Optional[PaymentStatus] = None
    payment_required: bool = False
    cancellation_id: uuid.UUID

    model_config = ConfigDict(from_attributes=True)


class GigReopenResponse(BaseModel):
    """Response returned upon successful gig reopening."""

    gig_id: uuid.UUID
    status: GigStatus
    reopened_at: datetime
    acceptance_deadline: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class RescheduleRequestCreate(BaseModel):
    """Payload to propose a new schedule for an agreed gig."""

    proposed_date: date = Field(..., description="Proposed new date for the gig")
    proposed_start_time: time = Field(..., description="Proposed new start time")
    proposed_end_time: time = Field(..., description="Proposed new end time")
    reason: Optional[str] = Field(None, max_length=500, description="Optional explanation for reschedule")


class RescheduleAlternativeRequest(BaseModel):
    """Payload to counter-propose a new schedule."""

    proposed_date: date = Field(..., description="Counter-proposed new date")
    proposed_start_time: time = Field(..., description="Counter-proposed new start time")
    proposed_end_time: time = Field(..., description="Counter-proposed new end time")
    reason: Optional[str] = Field(None, max_length=500, description="Optional explanation for counter proposal")


class RescheduleRequestResponse(BaseModel):
    """Full detail of a rescheduling negotiation record."""

    id: uuid.UUID
    gig_id: uuid.UUID
    requested_by: uuid.UUID
    proposed_date: date
    proposed_start_time: time
    proposed_end_time: time
    reason: Optional[str] = None
    status: RescheduleStatus
    responded_by: Optional[uuid.UUID] = None
    responded_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
