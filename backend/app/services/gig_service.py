import uuid
from datetime import date, datetime
from typing import List, Optional, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.core.exceptions import (
    NotFoundException,
    BadRequestException,
    ForbiddenException,
    ConflictException,
)
from app.db.models.user import User
from app.db.models.service import ServiceCategory, ServiceTask
from app.db.models.gig import Gig, GigTask, GigWorkerOpportunity
from app.db.models.communication import GigEvent, Notification
from app.db.models.enums import GigStatus, OpportunityStatus, UserRole
from app.schemas.gig import GigCreateRequest, GigResponse, GigTaskItemResponse
from app.schemas.candidate import GigCandidateResponse, SelectWorkerResponse
from app.schemas.common import PaginatedResponse, PaginationMeta
from app.services.financial_guard import CustomerFinancialGuard


class GigService:
    @staticmethod
    def _map_to_response(gig: Gig) -> GigResponse:
        """Helper to convert a Gig ORM model to GigResponse."""
        tasks = [
            GigTaskItemResponse(
                id=gt.id,
                task_id=gt.task_id,
                task_name=gt.task.name if gt.task else "Unknown Task",
                standard_duration_minutes_snapshot=gt.standard_duration_minutes_snapshot,
                base_price_snapshot=float(gt.base_price_snapshot),
            )
            for gt in gig.gig_tasks
        ]

        return GigResponse(
            id=gig.id,
            customer_id=gig.customer_id,
            cooperative_id=gig.cooperative_id,
            category_id=gig.category_id,
            category_name=gig.category.name if gig.category else "Unknown Category",
            gig_type=gig.gig_type,
            status=gig.status,
            description=gig.description,
            instructions=gig.instructions,
            address=gig.address,
            latitude=float(gig.latitude) if gig.latitude is not None else None,
            longitude=float(gig.longitude) if gig.longitude is not None else None,
            google_maps_link=gig.google_maps_link,
            scheduled_date=gig.scheduled_date,
            scheduled_start_time=gig.scheduled_start_time,
            scheduled_end_time=gig.scheduled_end_time,
            expected_duration_minutes=gig.expected_duration_minutes,
            is_emergency=gig.is_emergency,
            acceptance_deadline=gig.acceptance_deadline,
            material_procurement_mode=gig.material_procurement_mode,
            base_price=float(gig.base_price),
            minimum_billable_minutes_snapshot=gig.minimum_billable_minutes_snapshot,
            base_rate_per_minute_snapshot=float(gig.base_rate_per_minute_snapshot)
            if gig.base_rate_per_minute_snapshot is not None
            else None,
            selected_worker_id=gig.selected_worker_id,
            tasks=tasks,
            created_at=gig.created_at,
            updated_at=gig.updated_at,
        )

    @staticmethod
    def create_gig(
        customer_user: User,
        payload: GigCreateRequest,
        db: Session,
    ) -> GigResponse:
        """Create a new gig in DRAFT status with immutable pricing snapshots and tasks.

        Performs atomic transaction creating:
        - Gig record with location and pricing snapshots
        - GigTask records
        - GigEvent audit log
        """
        # 0. Check customer financial integrity (unsettled cancellation payments)
        if CustomerFinancialGuard.has_outstanding_cancellation_payment(customer_user.id, db):
            raise ConflictException(
                "You have an outstanding cancellation payment that must be settled before creating new gigs",
                code="OUTSTANDING_CANCELLATION_PAYMENT",
            )

        # 1. Verify category exists and is active
        category = (
            db.query(ServiceCategory)
            .filter(
                ServiceCategory.id == payload.category_id,
                ServiceCategory.is_active == True,
            )
            .first()
        )
        if not category:
            raise NotFoundException(
                f"Active service category {payload.category_id} not found",
                code="CATEGORY_NOT_FOUND",
            )

        # 2. Verify all tasks exist, are active, and belong to the category
        tasks = (
            db.query(ServiceTask)
            .filter(
                ServiceTask.id.in_(payload.task_ids),
                ServiceTask.is_active == True,
            )
            .all()
        )
        if len(tasks) != len(set(payload.task_ids)):
            raise BadRequestException(
                "One or more selected task IDs are invalid or inactive",
                code="INVALID_TASKS",
            )

        for task in tasks:
            if task.category_id != category.id:
                raise BadRequestException(
                    f"Task '{task.name}' does not belong to category '{category.name}'",
                    code="CATEGORY_TASK_MISMATCH",
                )

        # 3. Schedule validation
        if payload.scheduled_date:
            if payload.scheduled_date < date.today():
                raise BadRequestException(
                    "Scheduled date cannot be in the past",
                    code="INVALID_SCHEDULE_DATE",
                )

        if payload.scheduled_start_time and payload.scheduled_end_time:
            if payload.scheduled_end_time <= payload.scheduled_start_time:
                raise BadRequestException(
                    "Scheduled end time must be after start time",
                    code="INVALID_SCHEDULE_TIME",
                )

        # 4. Standard duration and pricing calculation (authoritative: catalogue tasks + category rate)
        total_standard_duration = sum(t.standard_duration_minutes for t in tasks)
        billable_duration = max(total_standard_duration, category.minimum_billable_minutes)
        base_price = round(billable_duration * float(category.base_rate_per_minute), 2)

        # 5. Atomic database transaction: Gig + GigTasks + GigEvent
        try:
            gig = Gig(
                customer_id=customer_user.id,
                cooperative_id=customer_user.cooperative_id,
                category_id=category.id,
                gig_type=payload.gig_type,
                status=GigStatus.DRAFT,
                description=payload.description,
                instructions=payload.instructions,
                address=payload.address,
                latitude=payload.latitude,
                longitude=payload.longitude,
                google_maps_link=payload.google_maps_link,
                scheduled_date=payload.scheduled_date,
                scheduled_start_time=payload.scheduled_start_time,
                scheduled_end_time=payload.scheduled_end_time,
                expected_duration_minutes=payload.expected_duration_minutes or total_standard_duration,
                is_emergency=payload.is_emergency,
                acceptance_deadline=payload.acceptance_deadline,
                material_procurement_mode=payload.material_procurement_mode,
                base_price=base_price,
                minimum_billable_minutes_snapshot=category.minimum_billable_minutes,
                base_rate_per_minute_snapshot=float(category.base_rate_per_minute),
            )
            db.add(gig)
            db.flush()

            for task in tasks:
                gig_task = GigTask(
                    gig_id=gig.id,
                    task_id=task.id,
                    standard_duration_minutes_snapshot=task.standard_duration_minutes,
                    base_price_snapshot=task.base_price,
                )
                db.add(gig_task)

            # Append-only audit event
            audit_event = GigEvent(
                gig_id=gig.id,
                actor_id=customer_user.id,
                event_type="GIG_CREATED",
                metadata_json={
                    "category_id": str(category.id),
                    "category_name": category.name,
                    "task_count": len(tasks),
                    "total_standard_duration_minutes": total_standard_duration,
                    "billable_duration_minutes": billable_duration,
                    "base_price": base_price,
                },
            )
            db.add(audit_event)

            db.commit()
            db.refresh(gig)
        except Exception:
            db.rollback()
            raise

        return GigService._map_to_response(gig)

    @staticmethod
    def post_gig(
        customer_user: User,
        gig_id: uuid.UUID,
        db: Session,
    ) -> GigResponse:
        """Post a draft gig into the opportunity matching pipeline.

        Transitions status from DRAFT -> POSTED and writes GIG_POSTED audit event atomically.
        """
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

        if gig.customer_id != customer_user.id:
            raise ForbiddenException("You do not have permission to post this gig", code="FORBIDDEN")

        if gig.status != GigStatus.DRAFT:
            raise BadRequestException(
                f"Gig cannot be posted from current state '{gig.status.value}'",
                code="INVALID_GIG_STATE",
            )

        try:
            gig.status = GigStatus.POSTED

            audit_event = GigEvent(
                gig_id=gig.id,
                actor_id=customer_user.id,
                event_type="GIG_POSTED",
                metadata_json={
                    "previous_status": "DRAFT",
                    "new_status": "POSTED",
                    "base_price": float(gig.base_price),
                },
            )
            db.add(audit_event)

            # Generate opportunities for eligible cooperative workers
            from app.services.opportunity_service import OpportunityService
            OpportunityService.generate_opportunities_for_gig(gig, db)

            db.commit()
            db.refresh(gig)
        except Exception:
            db.rollback()
            raise

        return GigService._map_to_response(gig)

    @staticmethod
    def get_gig_by_id(
        current_user: User,
        gig_id: uuid.UUID,
        db: Session,
    ) -> GigResponse:
        """Retrieve gig details with authorization checks."""
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

        # Authorization: Customer must own the gig
        if current_user.role == UserRole.CUSTOMER and gig.customer_id != current_user.id:
            raise ForbiddenException("You do not have permission to view this gig", code="FORBIDDEN")

        return GigService._map_to_response(gig)

    @staticmethod
    def get_customer_gigs(
        customer_user: User,
        status: Optional[GigStatus] = None,
        category_id: Optional[uuid.UUID] = None,
        scheduled_date: Optional[date] = None,
        page: int = 1,
        page_size: int = 20,
        db: Session = None,
    ) -> PaginatedResponse[GigResponse]:
        """Fetch customer's gigs with optional filtering and pagination."""
        query = db.query(Gig).filter(Gig.customer_id == customer_user.id)

        if status:
            query = query.filter(Gig.status == status)
        if category_id:
            query = query.filter(Gig.category_id == category_id)
        if scheduled_date:
            query = query.filter(Gig.scheduled_date == scheduled_date)

        total = query.count()
        total_pages = (total + page_size - 1) // page_size if page_size > 0 else 0

        gigs = (
            query.order_by(Gig.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
            .all()
        )

        items = [GigService._map_to_response(g) for g in gigs]

        return PaginatedResponse(
            data=items,
            pagination=PaginationMeta(
                page=page,
                page_size=page_size,
                total=total,
                total_pages=total_pages,
            ),
        )

    @staticmethod
    def get_candidates(
        customer_user: User,
        gig_id: uuid.UUID,
        db: Session,
    ) -> List[GigCandidateResponse]:
        """Fetch accepted worker candidates for a customer's gig.

        Conforms to 05_API_DESIGN.md Section 16 & 06_BACKEND_SPRINTS.md Section 29.
        """
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

        if gig.customer_id != customer_user.id:
            raise ForbiddenException("You do not have permission to view candidates for this gig", code="FORBIDDEN")

        # Query all accepted opportunities for this gig
        accepted_opps = (
            db.query(GigWorkerOpportunity)
            .filter(
                GigWorkerOpportunity.gig_id == gig.id,
                GigWorkerOpportunity.status == OpportunityStatus.ACCEPTED,
            )
            .all()
        )

        candidates = []
        for opp in accepted_opps:
            worker = opp.worker
            metrics = worker.worker_profile.metrics if (worker and worker.worker_profile) else None
            candidates.append(
                GigCandidateResponse(
                    worker_id=worker.id,
                    name=worker.full_name,
                    exact_wage=float(opp.exact_wage),
                    completed_jobs_count=metrics.completed_jobs_count if metrics else 0,
                    rating_average=float(metrics.rating_average) if metrics else 0.0,
                    rating_count=metrics.rating_count if metrics else 0,
                    final_score=float(opp.final_score_snapshot),
                    profile_photo_url=worker.profile_photo_url,
                    recommendation=None,  # No fake recommendation per 05_API_DESIGN.md Section 16
                )
            )

        return candidates

    @staticmethod
    def select_worker(
        customer_user: User,
        gig_id: uuid.UUID,
        worker_id: uuid.UUID,
        db: Session,
    ) -> SelectWorkerResponse:
        """Customer selects one accepted candidate worker for the gig.

        Conforms to 05_API_DESIGN.md Section 17 & 06_BACKEND_SPRINTS.md Section 29.
        Atomic transaction:
        1. Verify caller owns gig.
        2. Verify gig is in selectable state (POSTED or ACCEPTANCE_OPEN).
        3. Verify gig has not already selected a worker.
        4. Verify target worker has an ACCEPTED opportunity for this gig.
        5. Set gig.selected_worker_id and gig.status = WORKER_SELECTED.
        6. Transition other opportunities for this gig to NOT_SELECTED.
        7. Create WORKER_SELECTED audit event.
        8. Create notifications for selected worker and non-selected candidates.
        """
        try:
            gig = db.query(Gig).filter(Gig.id == gig_id).with_for_update().first()
            if not gig:
                raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

            if gig.customer_id != customer_user.id:
                raise ForbiddenException("You do not have permission to select a worker for this gig", code="FORBIDDEN")

            if gig.status not in (GigStatus.POSTED, GigStatus.ACCEPTANCE_OPEN):
                raise BadRequestException(
                    f"Gig cannot select a worker from current status '{gig.status.value}'",
                    code="INVALID_GIG_STATE",
                )

            if gig.selected_worker_id is not None:
                raise BadRequestException("A worker has already been selected for this gig", code="WORKER_ALREADY_SELECTED")

            # Verify target worker has an ACCEPTED opportunity
            selected_opp = (
                db.query(GigWorkerOpportunity)
                .filter(
                    GigWorkerOpportunity.gig_id == gig.id,
                    GigWorkerOpportunity.worker_id == worker_id,
                )
                .with_for_update()
                .first()
            )
            if not selected_opp or selected_opp.status != OpportunityStatus.ACCEPTED:
                raise BadRequestException(
                    "Selected worker has not accepted this gig opportunity",
                    code="WORKER_NOT_ACCEPTED",
                )

            # Update gig
            gig.selected_worker_id = worker_id
            gig.status = GigStatus.WORKER_SELECTED

            # Close other accepted/pending opportunities as NOT_SELECTED
            other_opps = (
                db.query(GigWorkerOpportunity)
                .filter(
                    GigWorkerOpportunity.gig_id == gig.id,
                    GigWorkerOpportunity.worker_id != worker_id,
                    GigWorkerOpportunity.status.in_([OpportunityStatus.ACCEPTED, OpportunityStatus.PENDING]),
                )
                .all()
            )
            for other in other_opps:
                other.status = OpportunityStatus.NOT_SELECTED

            # Audit event
            audit_event = GigEvent(
                gig_id=gig.id,
                actor_id=customer_user.id,
                event_type="WORKER_SELECTED",
                metadata_json={
                    "selected_worker_id": str(worker_id),
                    "exact_wage": float(selected_opp.exact_wage),
                    "base_price": float(gig.base_price),
                },
            )
            db.add(audit_event)

            # Notifications
            # 1. To selected worker
            notif_selected = Notification(
                recipient_id=worker_id,
                gig_id=gig.id,
                type="WORKER_SELECTED",
                title="You've been selected!",
                body=f"Congratulations! You were selected by the customer for gig {gig.id}.",
            )
            db.add(notif_selected)

            # 2. To unselected workers who had accepted/pending
            for other in other_opps:
                notif_unselected = Notification(
                    recipient_id=other.worker_id,
                    gig_id=gig.id,
                    type="NOT_SELECTED",
                    title="Gig filled",
                    body=f"Another worker was selected for gig {gig.id}.",
                )
                db.add(notif_unselected)

            db.commit()
            db.refresh(gig)

            return SelectWorkerResponse(
                gig_id=gig.id,
                selected_worker_id=worker_id,
                status=gig.status.value,
                message="Worker selected successfully.",
            )
        except Exception:
            db.rollback()
            raise

