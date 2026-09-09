import uuid
from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.common import ResponseEnvelope
from app.schemas.catalogue import ServiceCategoryResponse, ServiceTaskResponse
from app.services.catalogue_service import CatalogueService

router = APIRouter()


@router.get(
    "/service-categories",
    response_model=ResponseEnvelope[List[ServiceCategoryResponse]],
    summary="Get active service categories",
)
async def get_service_categories(
    db: Session = Depends(get_db),
) -> ResponseEnvelope[List[ServiceCategoryResponse]]:
    """Return list of active service categories and their base rates (05_API_DESIGN.md Section 8)."""
    categories = CatalogueService.get_service_categories(db=db)
    return ResponseEnvelope(data=categories)


@router.get(
    "/service-categories/{category_id}/tasks",
    response_model=ResponseEnvelope[List[ServiceTaskResponse]],
    summary="Get active tasks for a category",
)
async def get_category_tasks(
    category_id: uuid.UUID,
    db: Session = Depends(get_db),
) -> ResponseEnvelope[List[ServiceTaskResponse]]:
    """Return active tasks for the specified category with durations, base prices, and complexities."""
    tasks = CatalogueService.get_category_tasks(db=db, category_id=category_id)
    return ResponseEnvelope(data=tasks)
