import uuid
from typing import List
from sqlalchemy.orm import Session

from app.core.exceptions import (
    BadRequestException,
    NotFoundException,
)
from app.db.models.service import ServiceCategory, ServiceTask
from app.schemas.pricing import (
    PricePreviewResponse,
    PricePreviewTaskItem,
    EstimatedWageRange,
)
from app.services.experience_service import ExperienceService
from app.services.wage_service import WageService


class PricingService:
    @staticmethod
    def calculate_gig_pricing(
        db: Session,
        category_id: uuid.UUID,
        task_ids: List[uuid.UUID],
    ) -> PricePreviewResponse:
        """Calculate standard duration, billable duration, and base price for a set of tasks.

        Enforces rules from 06_BACKEND_SPRINTS.md (Sprint 3) and WAGES.md:
        1. All tasks must belong to the same category; reject tasks from different categories.
        2. Total duration T = sum(standard_duration_minutes).
        3. Billable duration = max(T, category.minimum_billable_minutes).
        4. Base price = billable_duration * category.base_rate_per_minute.
        """
        if not task_ids:
            raise BadRequestException(
                message="At least one task must be selected to calculate pricing",
                code="NO_TASKS_SELECTED",
            )

        # 1. Fetch category
        category = (
            db.query(ServiceCategory)
            .filter(ServiceCategory.id == category_id, ServiceCategory.is_active == True)
            .first()
        )
        if not category:
            raise NotFoundException(
                message=f"Service category with ID '{category_id}' was not found or is inactive",
                code="CATEGORY_NOT_FOUND",
            )

        # 2. Fetch tasks
        tasks = (
            db.query(ServiceTask)
            .filter(ServiceTask.id.in_(task_ids), ServiceTask.is_active == True)
            .all()
        )
        found_task_ids = {t.id for t in tasks}

        # Check for missing/invalid task IDs
        missing = [str(tid) for tid in task_ids if tid not in found_task_ids]
        if missing:
            raise BadRequestException(
                message=f"One or more task IDs were not found or are inactive: {', '.join(missing)}",
                code="TASK_NOT_FOUND",
            )

        # 3. Enforce single-category consistency rule: Reject tasks from different categories
        mismatched = [t for t in tasks if t.category_id != category_id]
        if mismatched:
            mismatched_names = [f"'{t.name}' (Category ID: {t.category_id})" for t in mismatched]
            raise BadRequestException(
                message=f"Tasks from different categories cannot be combined in one gig: {', '.join(mismatched_names)}",
                code="CATEGORY_TASK_MISMATCH",
            )

        # 4. Calculate total standard duration
        total_standard_duration = sum(t.standard_duration_minutes for t in tasks)

        # 5. Apply minimum billable duration rule
        billable_duration = max(total_standard_duration, category.minimum_billable_minutes)

        # 6. Calculate base labour price
        base_rate = float(category.base_rate_per_minute)
        base_price = round(billable_duration * base_rate, 2)

        # 7. Calculate estimated worker wage range
        wage_range_dict = WageService.estimate_wage_range(base_price)
        estimated_wage_range = EstimatedWageRange(
            min_wage=wage_range_dict["min_wage"],
            rookie_wage=wage_range_dict["rookie_wage"],
            max_wage=wage_range_dict["max_wage"],
        )

        # 8. Build task items with complexity
        task_items = []
        for t in tasks:
            complexity = ExperienceService.calculate_task_complexity(
                category_name=category.name,
                duration_minutes=t.standard_duration_minutes,
            )
            task_items.append(
                PricePreviewTaskItem(
                    id=t.id,
                    name=t.name,
                    standard_duration_minutes=t.standard_duration_minutes,
                    base_price=float(t.base_price),
                    complexity_score=complexity,
                )
            )

        return PricePreviewResponse(
            category_id=category.id,
            category_name=category.name,
            base_rate_per_minute=base_rate,
            minimum_billable_minutes=category.minimum_billable_minutes,
            total_standard_duration_minutes=total_standard_duration,
            billable_duration_minutes=billable_duration,
            base_price=base_price,
            tasks=task_items,
            estimated_wage_range=estimated_wage_range,
        )
