"""Wage Calculation Engine.

Conforms to WAGES.md (Section 5 & 6) and 06_BACKEND_SPRINTS.md.
"""

from typing import NamedTuple
from app.core.config import settings
from app.services.score_service import compute_final_score


class WageCalculationResult(NamedTuple):
    base_price: float
    final_score: float
    premium_percentage: float
    exact_wage: float


class WageService:
    @staticmethod
    def calculate_worker_wage(
        base_price: float,
        final_score: float,
        max_premium_factor: float = None,
    ) -> WageCalculationResult:
        """Calculate worker-specific wage based on immutable base price and final score.

        Formula:
            worker_wage = base_task_wage * (1 + final_score * WAGE_PREMIUM_MAX_FACTOR)
        """
        factor = max_premium_factor if max_premium_factor is not None else settings.WAGE_PREMIUM_MAX_FACTOR
        base = max(0.0, float(base_price))

        # Enforce boundary clamping on final_score [0.0, 1.0]
        clamped_score = max(0.0, min(1.0, float(final_score)))

        # Premium percentage = clamped_score * factor (e.g. 0.35 * 0.30 = 0.105 = 10.5%)
        premium_pct = round(clamped_score * factor, 5)

        # Exact wage calculation with round(..., 2)
        wage = round(base * (1.0 + premium_pct), 2)

        return WageCalculationResult(
            base_price=round(base, 2),
            final_score=round(clamped_score, 5),
            premium_percentage=premium_pct,
            exact_wage=wage,
        )

    @staticmethod
    def estimate_wage_range(base_price: float, max_premium_factor: float = None) -> dict:
        """Compute estimated worker wage range for a given base price.

        - Min wage: final_score = 0.0 (0% premium)
        - Rookie wage: final_score = settings.ROOKIE_FINAL_SCORE (10.5% premium at default factor)
        - Max wage: final_score = 1.0 (max factor premium)
        """
        min_calc = WageService.calculate_worker_wage(base_price, 0.00000, max_premium_factor)
        rookie_calc = WageService.calculate_worker_wage(base_price, settings.ROOKIE_FINAL_SCORE, max_premium_factor)
        max_calc = WageService.calculate_worker_wage(base_price, 1.00000, max_premium_factor)

        return {
            "min_wage": min_calc.exact_wage,
            "rookie_wage": rookie_calc.exact_wage,
            "max_wage": max_calc.exact_wage,
        }

