import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field

from app.db.models.enums import UserRole


class UserResponse(BaseModel):
    """User representation conforming to 05_API_DESIGN.md Section 6."""

    id: uuid.UUID
    role: UserRole
    cooperative_id: uuid.UUID
    full_name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    profile_photo_url: Optional[str] = None
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class UserInitializeRequest(BaseModel):
    """Request payload to initialize an application user after Supabase signup.

    Conforms to 05_API_DESIGN.md Section 6.
    """

    role: UserRole
    full_name: str = Field(min_length=1, max_length=255)
    phone: Optional[str] = Field(default=None, max_length=20)
    cooperative_id: Optional[uuid.UUID] = None


class CustomerProfileResponse(BaseModel):
    """Customer profile payload conforming to 05_API_DESIGN.md Section 7."""

    user_id: uuid.UUID
    full_name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    profile_photo_url: Optional[str] = None
    address: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CustomerProfileUpdateRequest(BaseModel):
    """Fields allowed to be updated by a customer."""

    full_name: Optional[str] = Field(default=None, min_length=1, max_length=255)
    phone: Optional[str] = Field(default=None, max_length=20)
    address: Optional[str] = None
    profile_photo_url: Optional[str] = None
