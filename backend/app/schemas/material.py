import uuid
from datetime import datetime
from decimal import Decimal
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field

from app.db.models.enums import MaterialProcurementMode


class MaterialReceiptCreateRequest(BaseModel):
    """Payload for pre-uploaded receipt reference or JSON upload workflow."""

    amount: Decimal = Field(
        ...,
        gt=Decimal("0.00"),
        decimal_places=2,
        description="Exact expense amount for purchased materials",
    )
    receipt_url: str = Field(
        ...,
        min_length=1,
        max_length=2000,
        description="Secure storage URL or object key of the receipt image/document",
    )
    description: Optional[str] = Field(
        default=None,
        max_length=500,
        description="Itemized description or store notes for purchased materials",
    )


class MaterialReceiptResponse(BaseModel):
    """Individual itemized material receipt record."""

    id: uuid.UUID
    gig_id: uuid.UUID
    worker_id: uuid.UUID
    worker_name: Optional[str] = None
    amount: Decimal
    receipt_url: str
    description: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class MaterialReceiptListResponse(BaseModel):
    """Response containing list of material receipts and authoritative calculated total."""

    gig_id: uuid.UUID
    material_procurement_mode: MaterialProcurementMode
    total_material_cost: Decimal
    receipt_count: int
    receipts: List[MaterialReceiptResponse] = []

    model_config = ConfigDict(from_attributes=True)
