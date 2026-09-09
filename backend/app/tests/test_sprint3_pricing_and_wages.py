import uuid
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.models.service import ServiceCategory, ServiceTask
from app.services.catalogue_service import CatalogueService
from app.services.pricing_service import PricingService
from app.services.wage_service import WageService
from app.services.experience_service import ExperienceService


@pytest.fixture(autouse=True)
def seed_test_catalogue(db_session: Session):
    """Ensure catalog is seeded before tests run."""
    CatalogueService.seed_catalogue_if_empty(db_session)


# --- 1. Catalogue Endpoints Tests ---

def test_get_service_categories(client: TestClient):
    """GET /api/v1/service-categories returns all 5 active service categories."""
    res = client.get("/api/v1/service-categories")
    assert res.status_code == 200
    categories = res.json()["data"]
    assert len(categories) == 5

    names = {c["name"] for c in categories}
    assert names == {"Plumbing", "Carpentry", "Electrician", "Painter", "House Help"}

    plumbing = next(c for c in categories if c["name"] == "Plumbing")
    assert plumbing["base_rate_per_minute"] == 5.0
    assert plumbing["minimum_billable_minutes"] == 45


def test_get_category_tasks(client: TestClient, db_session: Session):
    """GET /api/v1/service-categories/{category_id}/tasks returns tasks with complexity metrics."""
    category = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    assert category is not None

    res = client.get(f"/api/v1/service-categories/{category.id}/tasks")
    assert res.status_code == 200
    tasks = res.json()["data"]
    assert len(tasks) >= 20

    first_task = tasks[0]
    assert "complexity_score" in first_task
    assert "complexity_bucket" in first_task
    assert first_task["complexity_bucket"] in {"LOW", "MID", "HIGH"}
    assert 0.0 <= first_task["complexity_score"] <= 1.0


def test_get_category_tasks_not_found(client: TestClient):
    """Non-existent category ID returns 404 CATEGORY_NOT_FOUND."""
    fake_id = str(uuid.uuid4())
    res = client.get(f"/api/v1/service-categories/{fake_id}/tasks")
    assert res.status_code == 404
    assert res.json()["error"]["code"] == "CATEGORY_NOT_FOUND"


# --- 2. Pricing Tests (06_BACKEND_SPRINTS.md Section 881-897) ---

def test_pricing_15_minute_task_enforces_45_minute_minimum(client: TestClient, db_session: Session):
    """Pricing Test 1: 15-minute task -> 45-minute minimum billable duration."""
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task_15 = (
        db_session.query(ServiceTask)
        .filter(ServiceTask.category_id == plumbing.id, ServiceTask.standard_duration_minutes == 15)
        .first()
    )
    assert task_15 is not None

    res = client.post(
        "/api/v1/gigs/price-preview",
        json={"category_id": str(plumbing.id), "task_ids": [str(task_15.id)]},
    )
    assert res.status_code == 200
    data = res.json()["data"]

    assert data["total_standard_duration_minutes"] == 15
    assert data["billable_duration_minutes"] == 45  # Enforced 45-min minimum
    # Base price: 45 min * 5.00/min = 225.00
    assert data["base_price"] == 225.00


def test_pricing_20_plus_25_minutes_equals_45_minutes(client: TestClient, db_session: Session):
    """Pricing Test 2: 20 + 25 minutes -> 45 minutes billable duration."""
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task_20 = (
        db_session.query(ServiceTask)
        .filter(ServiceTask.category_id == plumbing.id, ServiceTask.standard_duration_minutes == 20)
        .first()
    )
    task_25 = (
        db_session.query(ServiceTask)
        .filter(ServiceTask.category_id == plumbing.id, ServiceTask.standard_duration_minutes == 25)
        .first()
    )
    assert task_20 is not None and task_25 is not None

    res = client.post(
        "/api/v1/gigs/price-preview",
        json={"category_id": str(plumbing.id), "task_ids": [str(task_20.id), str(task_25.id)]},
    )
    assert res.status_code == 200
    data = res.json()["data"]

    assert data["total_standard_duration_minutes"] == 45
    assert data["billable_duration_minutes"] == 45
    assert data["base_price"] == 225.00  # 45 min * 5.00 = 225.00


def test_pricing_75_minute_total_equals_75_minutes(client: TestClient, db_session: Session):
    """Pricing Test 3: 75-minute total -> 75 minutes billable duration (exceeds 45 min min)."""
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task_45 = (
        db_session.query(ServiceTask)
        .filter(ServiceTask.category_id == plumbing.id, ServiceTask.standard_duration_minutes == 45)
        .first()
    )
    task_30 = (
        db_session.query(ServiceTask)
        .filter(ServiceTask.category_id == plumbing.id, ServiceTask.standard_duration_minutes == 30)
        .first()
    )
    assert task_45 is not None and task_30 is not None

    res = client.post(
        "/api/v1/gigs/price-preview",
        json={"category_id": str(plumbing.id), "task_ids": [str(task_45.id), str(task_30.id)]},
    )
    assert res.status_code == 200
    data = res.json()["data"]

    assert data["total_standard_duration_minutes"] == 75
    assert data["billable_duration_minutes"] == 75  # Greater than 45 min min
    assert data["base_price"] == 375.00  # 75 min * 5.00 = 375.00


def test_pricing_rejects_tasks_from_different_categories(client: TestClient, db_session: Session):
    """Reject: tasks from different categories must be rejected with 400 Bad Request."""
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    electrician = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Electrician").first()

    plumbing_task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()
    electrician_task = db_session.query(ServiceTask).filter(ServiceTask.category_id == electrician.id).first()

    res = client.post(
        "/api/v1/gigs/price-preview",
        json={"category_id": str(plumbing.id), "task_ids": [str(plumbing_task.id), str(electrician_task.id)]},
    )
    assert res.status_code == 400
    assert res.json()["error"]["code"] == "CATEGORY_TASK_MISMATCH"


def test_pricing_rejects_empty_or_invalid_task_ids(client: TestClient, db_session: Session):
    """Reject empty task selection or invalid task UUIDs."""
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()

    # Empty task_ids
    res1 = client.post(
        "/api/v1/gigs/price-preview",
        json={"category_id": str(plumbing.id), "task_ids": []},
    )
    assert res1.status_code == 422  # Pydantic validation error

    # Non-existent task ID
    res2 = client.post(
        "/api/v1/gigs/price-preview",
        json={"category_id": str(plumbing.id), "task_ids": [str(uuid.uuid4())]},
    )
    assert res2.status_code == 400
    assert res2.json()["error"]["code"] == "TASK_NOT_FOUND"


# --- 3. Wage Engine Tests (WAGES.md Section 6 & 06_BACKEND_SPRINTS.md Section 898-910) ---

def test_wage_calculation_minimum_score_worker():
    """Minimum-score worker (final_score = 0.0) receives 0% premium and exact base price."""
    base_price = 225.00
    res = WageService.calculate_worker_wage(base_price=base_price, final_score=0.00000)
    assert res.base_price == 225.00
    assert res.final_score == 0.00000
    assert res.premium_percentage == 0.00000
    assert res.exact_wage == 225.00  # 225 * (1 + 0.0)


def test_wage_calculation_maximum_score_worker():
    """Maximum-score worker (final_score = 1.0) receives 30% premium."""
    base_price = 225.00
    res = WageService.calculate_worker_wage(base_price=base_price, final_score=1.00000)
    assert res.base_price == 225.00
    assert res.final_score == 1.00000
    assert res.premium_percentage == 0.30000  # 1.0 * 0.30 = 30%
    assert res.exact_wage == 292.50  # 225 * 1.30 = 292.50


def test_wage_calculation_intermediate_score_worker():
    """Intermediate-score worker (final_score = 0.50) receives 15% premium."""
    base_price = 200.00
    res = WageService.calculate_worker_wage(base_price=base_price, final_score=0.50000)
    assert res.base_price == 200.00
    assert res.final_score == 0.50000
    assert res.premium_percentage == 0.15000  # 0.50 * 0.30 = 15%
    assert res.exact_wage == 230.00  # 200 * 1.15 = 230.00


def test_wage_calculation_rookie_worker():
    """Rookie worker baseline (final_score = 0.35) receives 10.5% premium."""
    base_price = 1000.00
    res = WageService.calculate_worker_wage(base_price=base_price, final_score=0.35000)
    assert res.base_price == 1000.00
    assert res.final_score == 0.35000
    assert res.premium_percentage == 0.10500  # 0.35 * 0.30 = 10.5%
    assert res.exact_wage == 1105.00  # 1000 * 1.105 = 1105.00


def test_wage_calculation_premium_boundaries():
    """Scores outside [0.0, 1.0] are strictly clamped to boundary limits."""
    # Negative score
    res_neg = WageService.calculate_worker_wage(base_price=100.00, final_score=-0.50000)
    assert res_neg.final_score == 0.00000
    assert res_neg.premium_percentage == 0.00000
    assert res_neg.exact_wage == 100.00

    # Score exceeding 1.0
    res_high = WageService.calculate_worker_wage(base_price=100.00, final_score=1.85000)
    assert res_high.final_score == 1.00000
    assert res_high.premium_percentage == 0.30000
    assert res_high.exact_wage == 130.00


def test_wage_calculation_rounding():
    """Verify rounding precision to 2 decimal places."""
    base_price = 145.75
    res = WageService.calculate_worker_wage(base_price=base_price, final_score=0.37891)
    # premium_pct = round(0.37891 * 0.30, 5) = 0.11367
    # raw = 145.75 * 1.11367 = 162.3174... -> round(..., 2) = 162.32
    assert res.exact_wage == round(145.75 * (1 + 0.11367), 2)


# --- 4. Experience & Complexity Engine Tests (WAGES.md Sections 2, 3, 4) ---

def test_task_complexity_normalization_bounds():
    """Verify complexity normalization bounds for all categories per WAGES.md Section 2."""
    # Plumbing: 15 to 180 min
    assert ExperienceService.calculate_task_complexity("Plumbing", 15) == 0.00000
    assert ExperienceService.calculate_task_complexity("Plumbing", 180) == 1.00000
    mid_plumb = ExperienceService.calculate_task_complexity("Plumbing", 45)
    assert 0.0 < mid_plumb < 1.0

    # Carpentry: 20 to 300 min
    assert ExperienceService.calculate_task_complexity("Carpentry", 20) == 0.00000
    assert ExperienceService.calculate_task_complexity("Carpentry", 300) == 1.00000

    # Electrician: 15 to 480 min
    assert ExperienceService.calculate_task_complexity("Electrician", 15) == 0.00000
    assert ExperienceService.calculate_task_complexity("Electrician", 480) == 1.00000

    # Painter: 30 to 960 min
    assert ExperienceService.calculate_task_complexity("Painter", 30) == 0.00000
    assert ExperienceService.calculate_task_complexity("Painter", 960) == 1.00000

    # House Help: 20 to 300 min
    assert ExperienceService.calculate_task_complexity("House Help", 20) == 0.00000
    assert ExperienceService.calculate_task_complexity("House Help", 300) == 1.00000


def test_experience_score_rolling_window():
    """Verify rolling experience score over window N=50."""
    # Empty -> 0.0
    assert ExperienceService.calculate_experience_score([]) == 0.00000

    # 50 jobs with complexity 0.50 -> 0.50
    complexities = [0.50] * 50
    assert ExperienceService.calculate_experience_score(complexities) == 0.50000

    # 10 jobs with complexity 1.0 -> 10/50 = 0.20
    assert ExperienceService.calculate_experience_score([1.0] * 10) == 0.20000


def test_bayesian_rating_aggregation():
    """Verify 4-factor review normalization and Bayesian score calculation."""
    # 5 stars across all 4 factors -> normalized score 1.0
    norm_5star = ExperienceService.normalize_single_rating(5, 5, 5, 5)
    assert norm_5star == 1.00000

    # 1 star across all 4 factors -> normalized score 0.0
    norm_1star = ExperienceService.normalize_single_rating(1, 1, 1, 1)
    assert norm_1star == 0.00000

    # 0 reviews -> Bayesian prior mean 0.70
    assert ExperienceService.calculate_bayesian_score([]) == 0.70000

    # 10 reviews of 5-star (1.0): (10*0.7 + 10*1.0) / 20 = 17 / 20 = 0.85
    assert ExperienceService.calculate_bayesian_score([1.0] * 10) == 0.85000


def test_complexity_bucket_exact_boundaries():
    """Verify complexity bucket boundaries match WAGES.md Section 2 exactly:
    LOW = 0–0.33
    MID = 0.34–0.66
    HIGH = 0.67–1.0
    Boundary tests: 0.0, 0.33, 0.34, 0.66, 0.67, 1.0.
    """
    # 0.0 -> LOW
    assert ExperienceService.get_complexity_bucket(0.0) == "LOW"
    assert ExperienceService.get_complexity_bucket(0.20) == "LOW"
    
    # Boundary 0.33 -> LOW
    assert ExperienceService.get_complexity_bucket(0.33) == "LOW"
    
    # Boundary 0.34 -> MID
    assert ExperienceService.get_complexity_bucket(0.34) == "MID"
    assert ExperienceService.get_complexity_bucket(0.50) == "MID"
    
    # Boundary 0.66 -> MID
    assert ExperienceService.get_complexity_bucket(0.66) == "MID"
    
    # Boundary 0.67 -> HIGH
    assert ExperienceService.get_complexity_bucket(0.67) == "HIGH"
    assert ExperienceService.get_complexity_bucket(0.90) == "HIGH"
    assert ExperienceService.get_complexity_bucket(1.0) == "HIGH"


def test_rookie_task_contribution_and_no_decay():
    """Verify rookie experience contribution is strictly 0.5x normal complexity without decay."""
    # Standard task complexity contribution
    standard_contrib = ExperienceService.calculate_task_contribution(0.80, is_rookie_participation=False)
    assert standard_contrib == 0.80000

    # Rookie task complexity contribution (0.5x)
    rookie_contrib = ExperienceService.calculate_task_contribution(0.80, is_rookie_participation=True)
    assert rookie_contrib == 0.40000

    # Rolling window across N=50 with no decay parameters
    # 50 jobs with 0.40 rookie contribution -> (50 * 0.40) / 50 = 0.40
    complexities = [rookie_contrib] * 50
    assert ExperienceService.calculate_experience_score(complexities) == 0.40000


def test_wage_premium_max_factor_is_configurable():
    """Verify that WAGE_PREMIUM_MAX_FACTOR is truly configurable and not hardcoded."""
    base_price = 1000.0
    final_score = 1.0

    # Default configuration: 0.30 -> 30% premium -> ₹1300.00
    res_default = WageService.calculate_worker_wage(base_price=base_price, final_score=final_score)
    assert res_default.premium_percentage == 0.30000
    assert res_default.exact_wage == 1300.00

    # Dynamic factor override: 0.45 -> 45% premium -> ₹1450.00
    res_custom = WageService.calculate_worker_wage(
        base_price=base_price,
        final_score=final_score,
        max_premium_factor=0.45,
    )
    assert res_custom.premium_percentage == 0.45000
    assert res_custom.exact_wage == 1450.00

    # Dynamic factor in estimated wage range
    ranges = WageService.estimate_wage_range(base_price=base_price, max_premium_factor=0.20)
    assert ranges["min_wage"] == 1000.00  # 0% premium
    assert ranges["max_wage"] == 1200.00  # 20% premium

