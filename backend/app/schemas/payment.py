import uuid
from decimal import Decimal
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field

from app.db.models.enums import PaymentMethod, PaymentStatus, PaymentType


class PaymentCreateRequest(BaseModel):
    """Customer request payload to record payment conforming to 05_API_DESIGN.md Section 24.

    Authoritative amount is strictly determined by the backend from the immutable
    GigWorkerOpportunity.exact_wage snapshot; client cannot provide an amount.
    """

    payment_method: PaymentMethod = Field(
        ...,
        description="Selected payment method: CASH or UPI",
    )


class PaymentReceiptConfirmRequest(BaseModel):
    """Worker request payload to confirm receipt of payment."""

    confirmed: bool = Field(
        default=True,
        description="True to confirm receipt of payment from customer",
    )


class PaymentResponse(BaseModel):
    """Payment record response model with precise decimal amount and action flags."""

    id: uuid.UUID
    gig_id: uuid.UUID
    customer_id: uuid.UUID
    worker_id: uuid.UUID
    amount: Decimal = Field(
        description="Authoritative decimal payment amount matching exact agreed wage snapshot"
    )
    payment_method: Optional[PaymentMethod] = None
    payment_type: PaymentType = PaymentType.LABOUR
    status: PaymentStatus
    upi_deeplink: Optional[str] = None
    paid_at: Optional[datetime] = None
    worker_confirmed_at: Optional[datetime] = None
    can_pay: bool = Field(
        default=False,
        description="Server-derived flag indicating if caller can execute payment action",
    )
    can_confirm: bool = Field(
        default=False,
        description="Server-derived flag indicating if caller can execute receipt confirmation",
    )
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
