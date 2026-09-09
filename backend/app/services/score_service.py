"""Centralized scoring logic and algorithmic score computation.

Conforms to WAGES.md (Section 3) and 06_BACKEND_SPRINTS.md.
"""

from typing import Dict, Any
from app.core.config import settings


def compute_final_score(bayesian_score: float, experience_score: float) -> float:
    """Calculate combined final score per WAGES.md.

    Formula: W = 0.5 * B + 0.5 * E
    """
    return round(0.5 * float(bayesian_score) + 0.5 * float(experience_score), 5)


def get_rookie_initial_metrics() -> Dict[str, Any]:
    """Provide centralized initial metric defaults for newly registered workers.

    These values serve as baseline initialization ONLY. Subsequent scores
    are dynamically calculated by the Bayesian & Experience engines upon job completions.
    """
    bayesian = float(settings.BAYESIAN_PRIOR_MEAN)
    experience = float(settings.ROOKIE_EXPERIENCE_SCORE)
    final = compute_final_score(bayesian, experience)
    return {
        "completed_jobs_count": 0,
        "rating_average": 0.000,
        "rating_count": 0,
        "bayesian_score": bayesian,
        "experience_score": experience,
        "final_score": final,
    }
