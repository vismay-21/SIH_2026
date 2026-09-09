import os
from app.core.config import Settings, settings


def test_wage_premium_and_visitation_defaults():
    """Verify that wage premium and visitation fee are properly defined in settings."""
    assert hasattr(settings, "WAGE_PREMIUM_MAX_FACTOR")
    assert settings.WAGE_PREMIUM_MAX_FACTOR == 0.30

    assert hasattr(settings, "VISITATION_FEE")
    assert settings.VISITATION_FEE == 100.00


def test_wage_premium_and_visitation_configurable():
    """Verify that WAGE_PREMIUM_MAX_FACTOR and VISITATION_FEE can be configured dynamically."""
    custom_settings = Settings(
        WAGE_PREMIUM_MAX_FACTOR=0.45,
        VISITATION_FEE=150.00,
    )
    assert custom_settings.WAGE_PREMIUM_MAX_FACTOR == 0.45
    assert custom_settings.VISITATION_FEE == 150.00
