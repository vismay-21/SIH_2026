import os
from typing import List, Union
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "Sahakaar Seva API"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    API_V1_STR: str = "/api/v1"

    # Database Configuration
    DATABASE_URL: str = "sqlite:///./sahakaar_seva.db"

    # Supabase Configuration
    SUPABASE_URL: str = ""
    SUPABASE_KEY: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str = ""
    SUPABASE_JWT_SECRET: str = ""

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
