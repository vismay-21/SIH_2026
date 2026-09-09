from datetime import datetime, timezone
from typing import Any, Generic, List, Optional, TypeVar
from pydantic import BaseModel, Field

T = TypeVar("T")


class PaginationMeta(BaseModel):
    page: int = Field(ge=1, default=1, description="Current page number")
    page_size: int = Field(ge=1, le=100, default=20, description="Items per page")
    total: int = Field(ge=0, default=0, description="Total matching items")
    total_pages: int = Field(ge=0, default=0, description="Total pages available")


class ResponseEnvelope(BaseModel, Generic[T]):
    """Standard success response wrapper conforming to 05_API_DESIGN.md."""

    data: T


class PaginatedResponse(BaseModel, Generic[T]):
    """Standard paginated collection response wrapper conforming to 05_API_DESIGN.md."""

    data: List[T]
    pagination: PaginationMeta


class ErrorDetail(BaseModel):
    code: str
    message: str
    details: Optional[dict[str, Any]] = None


class ErrorResponse(BaseModel):
    """Standard error response format."""

    error: ErrorDetail


class HealthData(BaseModel):
    status: str = "ok"
    database: str = "connected"
    environment: str = "development"
    version: str = "0.1.0"
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class HealthResponse(BaseModel):
    data: HealthData
