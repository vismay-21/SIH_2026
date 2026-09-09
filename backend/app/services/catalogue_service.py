import uuid
from typing import List, Optional
from sqlalchemy.orm import Session

from app.core.exceptions import NotFoundException
from app.core.catalogue_data import CATALOGUE_DATA
from app.db.models.service import ServiceCategory, ServiceTask
from app.schemas.catalogue import ServiceCategoryResponse, ServiceTaskResponse
from app.services.experience_service import ExperienceService


class CatalogueService:
    @staticmethod
    def seed_catalogue_if_empty(db: Session) -> None:
        """Seed all 5 official service categories and their tasks from WAGES.md if not present."""
        # 1. Quick check: if tasks are already populated, skip
        existing_task_count = db.query(ServiceTask).count()
        if existing_task_count >= 100:
            return

        # 2. Fetch existing categories in bulk
        existing_categories = {c.name: c for c in db.query(ServiceCategory).all()}
        
        # 3. Create missing categories
        for cat_info in CATALOGUE_DATA:
            if cat_info["name"] not in existing_categories:
                category = ServiceCategory(
                    name=cat_info["name"],
                    description=cat_info["description"],
                    base_rate_per_minute=cat_info["base_rate_per_minute"],
                    minimum_billable_minutes=cat_info["minimum_billable_minutes"],
                    is_active=True,
                )
                db.add(category)
                db.flush()
                existing_categories[category.name] = category

        # 4. Fetch all existing task keys (category_id, name) in 1 query
        existing_task_keys = set(
            (t.category_id, t.name)
            for t in db.query(ServiceTask.category_id, ServiceTask.name).all()
        )

        # 5. Add any missing tasks
        for cat_info in CATALOGUE_DATA:
            category = existing_categories[cat_info["name"]]
            for task_info in cat_info["tasks"]:
                if (category.id, task_info["name"]) not in existing_task_keys:
                    task = ServiceTask(
                        category_id=category.id,
                        name=task_info["name"],
                        description=f"Standard {task_info['name']} under {category.name}",
                        standard_duration_minutes=task_info["duration"],
                        base_price=task_info["base_price"],
                        is_active=True,
                    )
                    db.add(task)
                    existing_task_keys.add((category.id, task_info["name"]))

        db.commit()

    @staticmethod
    def get_service_categories(
        db: Session,
        active_only: bool = True,
    ) -> List[ServiceCategoryResponse]:
        """Fetch all service categories."""
        query = db.query(ServiceCategory)
        if active_only:
            query = query.filter(ServiceCategory.is_active == True)

        categories = query.order_by(ServiceCategory.name).all()
        return [
            ServiceCategoryResponse(
                id=c.id,
                name=c.name,
                description=c.description,
                base_rate_per_minute=float(c.base_rate_per_minute),
                minimum_billable_minutes=c.minimum_billable_minutes,
                is_active=c.is_active,
            )
            for c in categories
        ]

    @staticmethod
    def get_category_tasks(
        db: Session,
        category_id: uuid.UUID,
        active_only: bool = True,
    ) -> List[ServiceTaskResponse]:
        """Fetch all tasks under a specific category, attaching complexity scores."""
        category = (
            db.query(ServiceCategory)
            .filter(ServiceCategory.id == category_id)
            .first()
        )
        if not category:
            raise NotFoundException(
                message=f"Service category with ID '{category_id}' was not found",
                code="CATEGORY_NOT_FOUND",
            )

        query = db.query(ServiceTask).filter(ServiceTask.category_id == category_id)
        if active_only:
            query = query.filter(ServiceTask.is_active == True)

        tasks = query.order_by(ServiceTask.standard_duration_minutes, ServiceTask.name).all()

        result = []
        for t in tasks:
            complexity = ExperienceService.calculate_task_complexity(
                category_name=category.name,
                duration_minutes=t.standard_duration_minutes,
            )
            bucket = ExperienceService.get_complexity_bucket(complexity)
            result.append(
                ServiceTaskResponse(
                    id=t.id,
                    category_id=t.category_id,
                    name=t.name,
                    description=t.description,
                    standard_duration_minutes=t.standard_duration_minutes,
                    base_price=float(t.base_price),
                    complexity_score=complexity,
                    complexity_bucket=bucket,
                    is_active=t.is_active,
                )
            )

        return result
