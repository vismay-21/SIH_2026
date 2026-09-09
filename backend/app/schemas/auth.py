import uuid
from typing import Optional, List
from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.db.models.enums import UserRole
from app.schemas.user import UserResponse


class DevLoginRequest(BaseModel):
    """Development login request payload."""
    email: str = Field(..., description="User email address")
    role: UserRole = Field(..., description="CUSTOMER or WORKER role")
    full_name: Optional[str] = Field(None, description="Full name if new user initialization is needed")

    @field_validator("role", mode="before")
    @classmethod
    def normalize_role(cls, v):
        if isinstance(v, str):
            return v.strip().upper()
        return v


class DevLoginResponse(BaseModel):
    """Development login response containing JWT access token and user profile."""
    access_token: str = Field(..., description="Supabase HS256 compatible JWT access token")
    token_type: str = Field(default="bearer", description="Token type")
    user: UserResponse = Field(..., description="Authenticated user profile")

    model_config = ConfigDict(from_attributes=True)


class DemoUserItem(BaseModel):
    """Safe public representation of a demo user account."""
    id: uuid.UUID
    email: str
    full_name: str
    role: UserRole

    model_config = ConfigDict(from_attributes=True)
