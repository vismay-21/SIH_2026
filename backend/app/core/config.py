import os
from decimal import Decimal
from typing import List, Union
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "Sahakaar Seva API"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    API_V1_STR: str = "/api/v1"

    # Database Configuration (Supabase PostgreSQL IPv4 pooler default)
    DATABASE_URL: str = (
        "postgresql://postgres.upkxwtnxfnkjuuwrjutk:mWqJ8%2F2-4XTrvqq@aws-0-ap-south-1.pooler.supabase.com:5432/postgres"
    )

    # Supabase Configuration
    SUPABASE_URL: str = "https://upkxwtnxfnkjuuwrjutk.supabase.co"
    SUPABASE_KEY: str = (
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVwa3h3dG54Zm5ranV1d3JqdXRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg5NTE2NzIsImV4cCI6MjEwNDUyNzY3Mn0.tUxZOgkvGx3G5lWF9e9jmDr7rcL6KoarTZgNca5Zd4Y"
    )
    SUPABASE_SERVICE_ROLE_KEY: str = (
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVwa3h3dG54Zm5ranV1d3JqdXRrIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4ODk1MTY3MiwiZXhwIjoyMTA0NTI3NjcyfQ.Irm700H4RNYtJFsnv-BkZCpmH9oCh_YfJChNM2oa76I"
    )
    SUPABASE_JWT_SECRET: str = (
        "cRxE/GJqlOm2EySqZDlcUQhnv06c6BxJK9V1OBx3rsR0VSog2amt1kNIzJ3MFefhxiskh6GdknMRNkpICrzmLw=="
    )

    # CORS Configuration
    CORS_ORIGINS: Union[List[str], str] = ["*"]

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",") if i.strip()]
        elif isinstance(v, list):
            return v
        return ["*"]

    # Pricing & Wage Policy Parameters (configurable as required by WAGES.md & sprint roadmap)
    WAGE_PREMIUM_MAX_FACTOR: float = 0.30
    VISITATION_FEE: float = 100.00
    CANCELLATION_FEE_AFTER_SELECTION: Decimal = Decimal("50.00")
    CANCELLATION_FEE_BEFORE_SELECTION: Decimal = Decimal("0.00")
    BAYESIAN_PRIOR_MEAN: float = 0.70
    BAYESIAN_CONFIDENCE_C: float = 10.0
    EXPERIENCE_WINDOW_N: int = 50
    ROOKIE_EXPERIENCE_SCORE: float = 0.00000

    @property
    def ROOKIE_FINAL_SCORE(self) -> float:
        """Centralized rookie final score: W = 0.5 * B + 0.5 * E (WAGES.md)."""
        return round(0.5 * self.BAYESIAN_PRIOR_MEAN + 0.5 * self.ROOKIE_EXPERIENCE_SCORE, 5)

    # Logging
    LOG_LEVEL: str = "INFO"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )


settings = Settings()
