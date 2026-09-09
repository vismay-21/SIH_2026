from datetime import datetime, timezone
from fastapi import APIRouter, status
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.db.session import check_db_connection
from app.schemas.common import HealthResponse, HealthData

router = APIRouter()


@router.get(
    "/health",
    response_model=HealthResponse,
    status_code=status.HTTP_200_OK,
    summary="Health Check",
    description="Returns backend and database connectivity status.",
)
async def health_check():
    """Health check endpoint checking application and database connection."""
    db_ok = check_db_connection()

    data = HealthData(
        status="ok" if db_ok else "degraded",
        database="connected" if db_ok else "disconnected",
        environment=settings.ENVIRONMENT,
        version="0.1.0",
        timestamp=datetime.now(timezone.utc),
    )

    if not db_ok:
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={"data": data.model_dump(mode="json")},
        )

    return HealthResponse(data=data)
