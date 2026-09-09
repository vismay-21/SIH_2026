import uuid
from datetime import datetime, timezone
from typing import List
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.core.exceptions import (
    BadRequestException,
    NotFoundException,
)
from app.db.models.user import User, WorkerProfile, WorkerMetric
from app.db.models.service import (
    ServiceCategory,
    WorkerCategory,
    WorkerAvailability,
)
from app.schemas.worker import (
    WorkerMetricResponse,
    WorkerProfileResponse,
    WorkerProfileUpdateRequest,
    AadhaarUploadResponse,
    WorkerCategoryResponse,
    WorkerAvailabilitySlot,
    WorkerAvailabilityResponse,
)


class WorkerService:
    @staticmethod
    def get_worker_profile(db: Session, user: User) -> WorkerProfileResponse:
        """Fetch worker profile data along with ratings and metrics."""
        profile = (
            db.query(WorkerProfile)
            .filter(WorkerProfile.user_id == user.id)
            .first()
        )
        if not profile:
            profile = WorkerProfile(user_id=user.id, is_active=True)
            db.add(profile)
            db.flush()

        metrics = (
            db.query(WorkerMetric)
            .filter(WorkerMetric.worker_id == user.id)
            .first()
        )
        if not metrics:
            from app.services.score_service import get_rookie_initial_metrics
            metrics = WorkerMetric(
                worker_id=user.id,
                **get_rookie_initial_metrics(),
            )
            db.add(metrics)
            db.commit()
            db.refresh(metrics)

        metrics_response = WorkerMetricResponse(
            completed_jobs_count=metrics.completed_jobs_count,
            rating_average=float(metrics.rating_average),
            rating_count=metrics.rating_count,
            bayesian_score=float(metrics.bayesian_score),
            experience_score=float(metrics.experience_score),
            final_score=float(metrics.final_score),
        )

        return WorkerProfileResponse(
            user_id=user.id,
            full_name=user.full_name,
            phone=user.phone,
            email=user.email,
            profile_photo_url=user.profile_photo_url,
            address=profile.address,
            city=profile.city,
            aadhaar_document_url=profile.aadhaar_document_url,
            aadhaar_uploaded_at=profile.aadhaar_uploaded_at,
            is_active=profile.is_active and user.is_active,
            metrics=metrics_response,
            created_at=profile.created_at,
            updated_at=profile.updated_at,
        )

    @staticmethod
    def update_worker_profile(
        db: Session,
        user: User,
        data: WorkerProfileUpdateRequest,
    ) -> WorkerProfileResponse:
        """Update worker editable fields (excluding internal metrics & scores)."""
        profile = (
            db.query(WorkerProfile)
            .filter(WorkerProfile.user_id == user.id)
            .first()
        )
        if not profile:
            profile = WorkerProfile(user_id=user.id, is_active=True)
            db.add(profile)

        if data.full_name is not None:
            user.full_name = data.full_name
        if data.phone is not None:
            user.phone = data.phone
        if data.profile_photo_url is not None:
            user.profile_photo_url = data.profile_photo_url
        if data.address is not None:
            profile.address = data.address
        if data.city is not None:
            profile.city = data.city

        db.commit()
        db.refresh(user)
        db.refresh(profile)

        return WorkerService.get_worker_profile(db, user)

    @staticmethod
    def upload_aadhaar_reference(
        db: Session,
        user: User,
        document_url: str,
    ) -> AadhaarUploadResponse:
        """Store Aadhaar document upload reference without altering verification flags.

        Conforms strictly to 05_API_DESIGN.md Section 7.
        """
        profile = (
            db.query(WorkerProfile)
            .filter(WorkerProfile.user_id == user.id)
            .first()
        )
        if not profile:
            profile = WorkerProfile(user_id=user.id, is_active=True)
            db.add(profile)

        uploaded_at = datetime.now(timezone.utc)
        profile.aadhaar_document_url = document_url
        profile.aadhaar_uploaded_at = uploaded_at

        db.commit()
        db.refresh(profile)

        return AadhaarUploadResponse(
            aadhaar_document_url=profile.aadhaar_document_url,
            aadhaar_uploaded_at=profile.aadhaar_uploaded_at,
            message="Aadhaar document reference stored successfully. Pending verification.",
        )

    @staticmethod
    def get_worker_categories(
        db: Session,
        user: User,
    ) -> List[WorkerCategoryResponse]:
        """Fetch active service categories selected by the worker."""
        worker_cats = (
            db.query(WorkerCategory)
            .join(ServiceCategory, WorkerCategory.category_id == ServiceCategory.id)
            .filter(
                WorkerCategory.worker_id == user.id,
                ServiceCategory.is_active == True,
            )
            .all()
        )
        return [
            WorkerCategoryResponse(
                id=wc.category.id,
                name=wc.category.name,
                description=wc.category.description,
                base_rate_per_minute=float(wc.category.base_rate_per_minute),
                minimum_billable_minutes=wc.category.minimum_billable_minutes,
            )
            for wc in worker_cats
        ]

    @staticmethod
    def set_worker_categories(
        db: Session,
        user: User,
        category_ids: List[uuid.UUID],
    ) -> List[WorkerCategoryResponse]:
        """Replace the worker's active category selections."""
        # Validate that all requested categories exist and are active
        valid_cats = (
            db.query(ServiceCategory)
            .filter(
                ServiceCategory.id.in_(category_ids),
                ServiceCategory.is_active == True,
            )
            .all()
        )
        valid_cat_ids = {cat.id for cat in valid_cats}

        missing_ids = [str(cid) for cid in category_ids if cid not in valid_cat_ids]
        if missing_ids:
            raise BadRequestException(
                message=f"One or more service categories are invalid or inactive: {', '.join(missing_ids)}",
                code="INVALID_CATEGORY_SELECTION",
            )

        # Clear existing worker category associations
        db.query(WorkerCategory).filter(WorkerCategory.worker_id == user.id).delete(synchronize_session=False)

        # Add new selections
        for cid in category_ids:
            db.add(WorkerCategory(worker_id=user.id, category_id=cid))

        db.commit()
        return WorkerService.get_worker_categories(db, user)

    @staticmethod
    def get_worker_availability(
        db: Session,
        user: User,
    ) -> List[WorkerAvailabilityResponse]:
        """Fetch worker's weekly recurring availability slots."""
        slots = (
            db.query(WorkerAvailability)
            .filter(WorkerAvailability.worker_id == user.id)
            .order_by(WorkerAvailability.day_of_week, WorkerAvailability.start_time)
            .all()
        )
        return [
            WorkerAvailabilityResponse(
                id=s.id,
                day_of_week=s.day_of_week,
                start_time=s.start_time,
                end_time=s.end_time,
                is_available=s.is_available,
            )
            for s in slots
        ]

    @staticmethod
    def set_worker_availability(
        db: Session,
        user: User,
        slots: List[WorkerAvailabilitySlot],
    ) -> List[WorkerAvailabilityResponse]:
        """Replace worker's weekly recurring availability slots."""
        for slot in slots:
            if slot.start_time >= slot.end_time:
                raise BadRequestException(
                    message=f"Slot start time ({slot.start_time}) must be earlier than end time ({slot.end_time}) on day {slot.day_of_week}",
                    code="INVALID_AVAILABILITY_SLOT",
                )

        # Clear existing availability
        db.query(WorkerAvailability).filter(WorkerAvailability.worker_id == user.id).delete(synchronize_session=False)

        # Add new availability slots
        for s in slots:
            db.add(
                WorkerAvailability(
                    worker_id=user.id,
                    day_of_week=s.day_of_week,
                    start_time=s.start_time,
                    end_time=s.end_time,
                    is_available=s.is_available,
                )
            )

        db.commit()
        return WorkerService.get_worker_availability(db, user)

    @staticmethod
    def set_worker_availability_status(
        db: Session,
        user: User,
        is_available: bool,
    ) -> bool:
        """Update the simple Available/Unavailable control.

        Conforms strictly to 05_API_DESIGN.md Section 10 (PATCH /api/v1/worker/availability/status).
        Toggles worker_profile.is_active.
        """
        profile = (
            db.query(WorkerProfile)
            .filter(WorkerProfile.user_id == user.id)
            .first()
        )
        if not profile:
            profile = WorkerProfile(user_id=user.id, is_active=is_available)
            db.add(profile)
        else:
            profile.is_active = is_available

        db.commit()
        db.refresh(profile)
        return profile.is_active

