"""Experience, Complexity, and Rating Aggregation Service.

Conforms to WAGES.md (Sections 2, 3, 4).
"""

import math
from typing import List, Tuple
from app.core.config import settings
from app.core.catalogue_data import CATEGORY_COMPLEXITY_BOUNDS


class ExperienceService:
    @staticmethod
    def get_category_bounds(category_name: str) -> Tuple[int, int]:
        """Return (t_min, t_max) in minutes for a given service category."""
        return CATEGORY_COMPLEXITY_BOUNDS.get(category_name, (15, 300))

    @staticmethod
    def calculate_task_complexity(category_name: str, duration_minutes: int) -> float:
        """Calculate normalized task complexity score (0.0 to 1.0) per WAGES.md Section 2.

        Formula:
            complexity = (ln(t) - ln(t_min)) / (ln(t_max) - ln(t_min))
        """
        t_min, t_max = ExperienceService.get_category_bounds(category_name)
        t = max(1, duration_minutes)

        if t <= t_min:
            return 0.00000
        if t >= t_max:
            return 1.00000

        ln_min = math.log(t_min)
        ln_max = math.log(t_max)
        raw_complexity = (math.log(t) - ln_min) / (ln_max - ln_min)
        clamped = max(0.0, min(1.0, raw_complexity))
        return round(clamped, 5)

    @staticmethod
    def get_complexity_bucket(complexity_score: float) -> str:
        """Categorize complexity score into standard buckets per WAGES.md Section 2.

        Buckets:
            0.00 – 0.33: LOW
            0.34 – 0.66: MID
            0.67 – 1.00: HIGH
        """
        score = round(float(complexity_score), 2)
        if score <= 0.33:
            return "LOW"
        elif score <= 0.66:
            return "MID"
        else:
            return "HIGH"

    @staticmethod
    def calculate_task_contribution(complexity: float, is_rookie_participation: bool = False) -> float:
        """Calculate single-job contribution to the rolling experience score (WAGES.md Section 3).

        - Standard / Primary completion: 1.0 * complexity
        - Rookie Mentorship participation: 0.5 * complexity
        """
        multiplier = 0.5 if is_rookie_participation else 1.0
        return round(float(complexity) * multiplier, 5)

    @staticmethod
    def calculate_experience_score(complexities: List[float], window_n: int = None) -> float:
        """Calculate rolling experience score (0.0 to 1.0) per WAGES.md Section 3.

        Formula:
            experience_score = (Σ complexity_i) / N

        Uses strictly the rolling window of the last N=50 completed jobs with no artificial
        decay factors. Rookie job contributions are weighted at 0.5x complexity.
        """
        if not complexities:
            return 0.00000

        n = window_n or settings.EXPERIENCE_WINDOW_N
        # Use the most recent N completed job complexities
        recent = complexities[-n:]
        score = sum(recent) / float(n)
        return round(max(0.0, min(1.0, score)), 5)

    @staticmethod
    def normalize_single_rating(r1: float, r2: float, r3: float, r4: float) -> float:
        """Normalize a 4-category 1-to-5 star rating into a 0.0-to-1.0 score (WAGES.md Section 4).

        avg_rating = (R1 + R2 + R3 + R4) / 4
        rating_score = (avg_rating - 1) / 4  (1★ -> 0.0, 5★ -> 1.0)
        """
        avg = (float(r1) + float(r2) + float(r3) + float(r4)) / 4.0
        normalized = (avg - 1.0) / 4.0
        return round(max(0.0, min(1.0, normalized)), 5)

    @staticmethod
    def calculate_bayesian_score(
        normalized_ratings: List[float],
        prior_mean: float = None,
        confidence_c: float = None,
    ) -> float:
        """Compute Bayesian rating score across all reviews (0.0 to 1.0) per WAGES.md Section 4.

        Formula:
            bayesian_score = (C * m + Σ rating_score_i) / (C + n)
        """
        m = prior_mean if prior_mean is not None else settings.BAYESIAN_PRIOR_MEAN
        c = confidence_c if confidence_c is not None else settings.BAYESIAN_CONFIDENCE_C
        n = len(normalized_ratings)

        score = (c * m + sum(normalized_ratings)) / (c + n)
        return round(max(0.0, min(1.0, score)), 5)
