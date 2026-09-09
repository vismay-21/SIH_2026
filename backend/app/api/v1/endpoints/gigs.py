from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.common import ResponseEnvelope
from app.schemas.pricing import PricePreviewRequest, PricePreviewResponse
from app.services.pricing_service import PricingService

router = APIRouter()


@router.post(
    "/gigs/price-preview",
    response_model=ResponseEnvelope[PricePreviewResponse],
    summary="Preview gig pricing and worker wage range",
)
async def get_price_preview(
    request: PricePreviewRequest,
    db: Session = Depends(get_db),
) -> ResponseEnvelope[PricePreviewResponse]:
    """Calculate standard duration, minimum billable duration, base labour price, and worker wage range.

    Enforces 06_BACKEND_SPRINTS.md and WAGES.md rules:
    - 15-minute task -> 45-minute minimum
    - 20 + 25 minutes -> 45 minutes
    - 75-minute total -> 75 minutes
    - Rejects tasks from different categories
    """
    preview = PricingService.calculate_gig_pricing(
        db=db,
        category_id=request.category_id,
        task_ids=request.task_ids,
    )
    return ResponseEnvelope(data=preview)
