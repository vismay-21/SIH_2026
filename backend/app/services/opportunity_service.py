import uuid
from datetime import date, time, datetime, timezone, timedelta
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.core.config import settings
from app.core.exceptions import (
    NotFoundException,
    BadRequestException,
    ForbiddenException,
)
from app.db.models.user import User, WorkerProfile, WorkerMetric
from app.db.models.service import ServiceCategory, ServiceTask, WorkerCategory, WorkerAvailability
from app.db.models.gig import Gig, GigTask, GigWorkerOpportunity
from app.db.models.communication import GigEvent
from app.db.models.enums import GigStatus, OpportunityStatus, UserRole
from app.schemas.opportunity import OpportunityResponse, OpportunityGigResponse
from app.schemas.gig import GigTaskItemResponse
from app.schemas.common import PaginatedResponse, PaginationMeta
from app.services.wage_service import WageService


class OpportunityService:
    @staticmethod
    def _map_to_response(opp: GigWorkerOpportunity) -> OpportunityResponse:
        """Helper to convert a GigWorkerOpportunity ORM model to OpportunityResponse."""
        gig = opp.gig
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

        gig_brief = OpportunityGigResponse(
            id=gig.id,
            category_id=gig.category_id,
            category_name=gig.category.name if gig.category else "Unknown Category",
            gig_type=gig.gig_type,
            description=gig.description,
            instructions=gig.instructions,
            address=gig.address,
            latitude=float(gig.latitude) if gig.latitude is not None else None,
            longitude=float(gig.longitude) if gig.longitude is not None else None,
            scheduled_date=gig.scheduled_date,
            scheduled_start_time=gig.scheduled_start_time,
            scheduled_end_time=gig.scheduled_end_time,
            expected_duration_minutes=gig.expected_duration_minutes,
            is_emergency=gig.is_emergency,
            material_procurement_mode=gig.material_procurement_mode,
            acceptance_deadline=gig.acceptance_deadline,
            tasks=tasks,
        )

        return OpportunityResponse(
            id=opp.id,
            gig_id=opp.gig_id,
            worker_id=opp.worker_id,
            status=opp.status,
            base_price=float(opp.base_price_snapshot),
            base_price_snapshot=float(opp.base_price_snapshot),
            final_score_snapshot=float(opp.final_score_snapshot),
            premium_percentage=float(opp.premium_percentage),
            exact_wage=float(opp.exact_wage),
            offered_at=opp.offered_at,
            responded_at=opp.responded_at,
            gig=gig_brief,
        )

    @staticmethod
    def check_schedule_conflict(worker_id: uuid.UUID, gig: Gig, db: Session) -> bool:
        """Check if worker has any confirmed gig overlapping with the given gig.

        Conforms to 05_API_DESIGN.md Section 15:
        ANY overlap with an existing confirmed gig (WORKER_SELECTED, SCHEDULED, IN_PROGRESS)
        prevents acceptance.
        """
        if not gig.scheduled_date:
            return False

        if not gig.scheduled_start_time:
            # If no start time on gig, any confirmed gig on same date conflicts
            return (
                db.query(Gig)
                .filter(
                    Gig.selected_worker_id == worker_id,
                    Gig.scheduled_date == gig.scheduled_date,
                    Gig.status.in_([GigStatus.WORKER_SELECTED, GigStatus.SCHEDULED, GigStatus.IN_PROGRESS]),
                    Gig.id != gig.id,
                )
                .first()
                is not None
            )

        start_a = gig.scheduled_start_time
        if gig.scheduled_end_time:
            end_a = gig.scheduled_end_time
        else:
            duration_mins = gig.expected_duration_minutes or 60
            dt_start_a = datetime.combine(date.min, start_a)
            end_a = (dt_start_a + timedelta(minutes=duration_mins)).time()

        return OpportunityService.check_schedule_conflict_for_slot(
            worker_id=worker_id,
            target_date=gig.scheduled_date,
            start_time=start_a,
            end_time=end_a,
            exclude_gig_id=gig.id,
            db=db,
        )

    @staticmethod
    def check_schedule_conflict_for_slot(
        worker_id: uuid.UUID,
        target_date: date,
        start_time: time,
        end_time: time,
        exclude_gig_id: Optional[uuid.UUID],
        db: Session,
    ) -> bool:
        """Check if worker has any confirmed gig overlapping with the given date and time range."""
        query = db.query(Gig).filter(
            Gig.selected_worker_id == worker_id,
            Gig.scheduled_date == target_date,
            Gig.status.in_([GigStatus.WORKER_SELECTED, GigStatus.SCHEDULED, GigStatus.IN_PROGRESS]),
        )
        if exclude_gig_id:
            query = query.filter(Gig.id != exclude_gig_id)
        confirmed_gigs = query.all()

        for other in confirmed_gigs:
            if not other.scheduled_start_time:
                return True
            start_b = other.scheduled_start_time
            if other.scheduled_end_time:
                end_b = other.scheduled_end_time
            else:
                duration_mins_b = other.expected_duration_minutes or 60
                dt_start_b = datetime.combine(date.min, start_b)
                end_b = (dt_start_b + timedelta(minutes=duration_mins_b)).time()

            if max(start_time, start_b) < min(end_time, end_b):
                return True
        return False

    @staticmethod
    def check_worker_availability(worker_profile: WorkerProfile, gig: Gig) -> bool:
        """Check worker's weekly recurring availability for the gig's scheduled date and time."""
        if not gig.scheduled_date or not gig.scheduled_start_time:
            return True

        start_a = gig.scheduled_start_time
        if gig.scheduled_end_time:
            end_a = gig.scheduled_end_time
        else:
            duration_mins = gig.expected_duration_minutes or 60
            dt_start_a = datetime.combine(date.min, start_a)
            end_a = (dt_start_a + timedelta(minutes=duration_mins)).time()

        return OpportunityService.check_worker_availability_for_slot(
            worker_profile=worker_profile,
            target_date=gig.scheduled_date,
            start_time=start_a,
            end_time=end_a,
        )

    @staticmethod
    def check_worker_availability_for_slot(
        worker_profile: WorkerProfile,
        target_date: date,
        start_time: time,
        end_time: time,
    ) -> bool:
        """Check worker's weekly recurring availability for a specific date and time range."""
        day_num = target_date.weekday()
        slots = [a for a in worker_profile.availabilities if a.day_of_week == day_num]
        if not slots:
            # If no slots set, worker is generally available in MVP
            return True

        for slot in slots:
            if slot.is_available and slot.start_time <= start_time and slot.end_time >= end_time:
                return True

        return False

    @staticmethod
    def get_worker_final_score(worker_user: User) -> float:
        """Fetch worker's final score, defaulting to configured rookie score."""
        if worker_user.worker_profile and worker_user.worker_profile.metrics:
            return float(worker_user.worker_profile.metrics.final_score)
        return float(settings.ROOKIE_FINAL_SCORE)

    @staticmethod
    def generate_opportunities_for_gig(
        gig: Gig,
        db: Session,
    ) -> List[GigWorkerOpportunity]:
        """Generate personalized opportunities for all eligible workers in the cooperative.

        Checks:
        - worker active
        - worker category eligibility
        - same cooperative
        - availability
        - schedule conflict
        - gig state (POSTED / ACCEPTANCE_OPEN)

        Does NOT check:
        - distance / GPS / radius / nearest worker (per 06_BACKEND_SPRINTS.md Section 28)
        """
        if gig.status not in (GigStatus.POSTED, GigStatus.ACCEPTANCE_OPEN):
            return []

        # Find candidate workers matching cooperative and category
        candidates = (
            db.query(User)
            .join(WorkerProfile, WorkerProfile.user_id == User.id)
            .join(WorkerCategory, WorkerCategory.worker_id == WorkerProfile.user_id)
            .filter(
                User.role == UserRole.WORKER,
                User.cooperative_id == gig.cooperative_id,
                User.is_active == True,
                WorkerProfile.is_active == True,
                WorkerCategory.category_id == gig.category_id,
            )
            .all()
        )

        created_opportunities = []
        for worker in candidates:
            # Check availability
            if not OpportunityService.check_worker_availability(worker.worker_profile, gig):
                continue

            # Check schedule conflict
            if OpportunityService.check_schedule_conflict(worker.id, gig, db):
                continue

            # Check if opportunity already exists
            existing = (
                db.query(GigWorkerOpportunity)
                .filter(
                    GigWorkerOpportunity.gig_id == gig.id,
                    GigWorkerOpportunity.worker_id == worker.id,
                )
                .first()
            )
            if existing:
                continue

            # Calculate personalized wage snapshot
            final_score = OpportunityService.get_worker_final_score(worker)
            wage_calc = WageService.calculate_worker_wage(
                base_price=float(gig.base_price),
                final_score=final_score,
            )

            # Store immutable offer snapshots
            opp = GigWorkerOpportunity(
                id=uuid.uuid4(),
                gig_id=gig.id,
                worker_id=worker.id,
                status=OpportunityStatus.PENDING,
                base_price_snapshot=gig.base_price,
                final_score_snapshot=wage_calc.final_score,
                premium_percentage=round(wage_calc.premium_percentage * 100, 3),
                exact_wage=wage_calc.exact_wage,
                offered_at=datetime.now(timezone.utc),
            )
            db.add(opp)

            # Audit event
            audit_event = GigEvent(
                gig_id=gig.id,
                actor_id=worker.id,
                event_type="OPPORTUNITY_CREATED",
                metadata_json={
                    "worker_id": str(worker.id),
                    "base_price": float(gig.base_price),
                    "final_score": float(opp.final_score_snapshot),
                    "premium_percentage": float(opp.premium_percentage),
                    "exact_wage": float(opp.exact_wage),
                },
            )
            db.add(audit_event)
            created_opportunities.append(opp)

        if created_opportunities:
            db.flush()

        return created_opportunities

    @staticmethod
    def sync_opportunities_for_worker(
        worker_user: User,
        db: Session,
    ) -> None:
        """Ensure all posted gigs in the worker's category and cooperative generate opportunities if eligible."""
        if not worker_user.worker_profile or not worker_user.worker_profile.is_active:
            return

        worker_cat_ids = [wc.category_id for wc in worker_user.worker_profile.categories]
        if not worker_cat_ids:
            return

        # Query all active posted gigs in worker's categories and cooperative
        posted_gigs = (
            db.query(Gig)
            .filter(
                Gig.cooperative_id == worker_user.cooperative_id,
                Gig.category_id.in_(worker_cat_ids),
                Gig.status.in_([GigStatus.POSTED, GigStatus.ACCEPTANCE_OPEN]),
                Gig.selected_worker_id.is_(None),
            )
            .all()
        )

        for gig in posted_gigs:
            # Check if deadline passed
            if gig.acceptance_deadline and datetime.now(timezone.utc) > gig.acceptance_deadline:
                continue

            # Check if opportunity already exists
            existing = (
                db.query(GigWorkerOpportunity)
                .filter(
                    GigWorkerOpportunity.gig_id == gig.id,
                    GigWorkerOpportunity.worker_id == worker_user.id,
                )
                .first()
            )
            if existing:
                continue

            # Check availability & conflict
            if not OpportunityService.check_worker_availability(worker_user.worker_profile, gig):
                continue
            if OpportunityService.check_schedule_conflict(worker_user.id, gig, db):
                continue

            # Calculate wage snapshot
            final_score = OpportunityService.get_worker_final_score(worker_user)
            wage_calc = WageService.calculate_worker_wage(
                base_price=float(gig.base_price),
                final_score=final_score,
            )

            opp = GigWorkerOpportunity(
                id=uuid.uuid4(),
                gig_id=gig.id,
                worker_id=worker_user.id,
                status=OpportunityStatus.PENDING,
                base_price_snapshot=gig.base_price,
                final_score_snapshot=wage_calc.final_score,
                premium_percentage=round(wage_calc.premium_percentage * 100, 3),
                exact_wage=wage_calc.exact_wage,
                offered_at=datetime.now(timezone.utc),
            )
            db.add(opp)

            audit_event = GigEvent(
                gig_id=gig.id,
                actor_id=worker_user.id,
                event_type="OPPORTUNITY_CREATED",
                metadata_json={
                    "worker_id": str(worker_user.id),
                    "base_price": float(gig.base_price),
                    "final_score": float(opp.final_score_snapshot),
                    "premium_percentage": float(opp.premium_percentage),
                    "exact_wage": float(opp.exact_wage),
                },
            )
            db.add(audit_event)

        db.commit()

    @staticmethod
    def get_worker_opportunities(
        worker_user: User,
        category_id: Optional[uuid.UUID] = None,
        scheduled_date: Optional[date] = None,
        is_emergency: Optional[bool] = None,
        status: Optional[OpportunityStatus] = None,
        page: int = 1,
        page_size: int = 20,
        db: Session = None,
    ) -> PaginatedResponse[OpportunityResponse]:
        """Fetch opportunities available to the authenticated worker with filtering and pagination."""
        # 1. Sync any new opportunities
        OpportunityService.sync_opportunities_for_worker(worker_user, db)

        # 2. Build filtered query
        query = (
            db.query(GigWorkerOpportunity)
            .join(Gig, Gig.id == GigWorkerOpportunity.gig_id)
            .filter(GigWorkerOpportunity.worker_id == worker_user.id)
        )

        if category_id:
            query = query.filter(Gig.category_id == category_id)

        if scheduled_date:
            query = query.filter(Gig.scheduled_date == scheduled_date)

        if is_emergency is not None:
            query = query.filter(Gig.is_emergency == is_emergency)

        if status:
            query = query.filter(GigWorkerOpportunity.status == status)

        total = query.count()
        offset = (page - 1) * page_size
        opportunities = (
            query.order_by(GigWorkerOpportunity.offered_at.desc())
            .offset(offset)
            .limit(page_size)
            .all()
        )

        total_pages = (total + page_size - 1) // page_size if total > 0 else 0

        items = [OpportunityService._map_to_response(opp) for opp in opportunities]

        return PaginatedResponse(
            data=items,
            pagination=PaginationMeta(
                total=total,
                page=page,
                page_size=page_size,
                total_pages=total_pages,
            ),
        )

    @staticmethod
    def get_opportunity_by_id(
        worker_user: User,
        opportunity_id: uuid.UUID,
        db: Session,
    ) -> OpportunityResponse:
        """Retrieve complete opportunity details with authorization check."""
        opp = db.query(GigWorkerOpportunity).filter(GigWorkerOpportunity.id == opportunity_id).first()
        if not opp:
            raise NotFoundException("Opportunity not found", code="OPPORTUNITY_NOT_FOUND")

        if opp.worker_id != worker_user.id:
            raise ForbiddenException("You do not have access to this opportunity", code="FORBIDDEN")

        return OpportunityService._map_to_response(opp)

    @staticmethod
    def accept_opportunity(
        worker_user: User,
        opportunity_id: uuid.UUID,
        db: Session,
    ) -> OpportunityResponse:
        """Atomically accept an opportunity.

        Conforms to 05_API_DESIGN.md Section 15 and 06_BACKEND_SPRINTS.md Section 28.
        """
        try:
            opp = (
                db.query(GigWorkerOpportunity)
                .filter(GigWorkerOpportunity.id == opportunity_id)
                .with_for_update()
                .first()
            )
            if not opp:
                raise NotFoundException("Opportunity not found", code="OPPORTUNITY_NOT_FOUND")

            # 1. Worker ownership check
            if opp.worker_id != worker_user.id:
                raise ForbiddenException("You do not have access to this opportunity", code="FORBIDDEN")

            # 2. Opportunity status check
            if opp.status == OpportunityStatus.REJECTED:
                raise BadRequestException("A rejected opportunity cannot be accepted", code="ALREADY_REJECTED")
            if opp.status == OpportunityStatus.ACCEPTED:
                raise BadRequestException("Opportunity has already been accepted", code="ALREADY_ACCEPTED")
            if opp.status != OpportunityStatus.PENDING:
                raise BadRequestException(
                    f"Opportunity cannot be accepted from current status '{opp.status.value}'",
                    code="INVALID_OPPORTUNITY_STATE",
                )

            # Lock the associated gig row as well to prevent race conditions on gig status/worker selection
            gig = (
                db.query(Gig)
                .filter(Gig.id == opp.gig_id)
                .with_for_update()
                .first()
            )

            # 3. Gig status check
            if gig.status not in (GigStatus.POSTED, GigStatus.ACCEPTANCE_OPEN):
                raise BadRequestException(
                    f"Gig is no longer accepting workers (current status: '{gig.status.value}')",
                    code="GIG_NOT_ACCEPTING",
                )

            if gig.selected_worker_id is not None:
                raise BadRequestException(
                    "Gig has already selected a worker",
                    code="WORKER_ALREADY_SELECTED",
                )

            # 4. Acceptance deadline check
            if gig.acceptance_deadline and datetime.now(timezone.utc) > gig.acceptance_deadline:
                raise BadRequestException(
                    "Opportunity acceptance deadline has expired",
                    code="DEADLINE_EXPIRED",
                )

            # 5. Worker active / available & cooperative check
            if not worker_user.is_active or not worker_user.worker_profile.is_active:
                raise BadRequestException("Worker is unavailable or account is inactive", code="WORKER_UNAVAILABLE")

            if worker_user.cooperative_id != gig.cooperative_id:
                raise ForbiddenException("Worker does not belong to the gig cooperative", code="COOPERATIVE_MISMATCH")

            # 6. Worker category eligibility check
            has_cat = any(wc.category_id == gig.category_id for wc in worker_user.worker_profile.categories)
            if not has_cat:
                raise BadRequestException("Worker is not registered for this service category", code="CATEGORY_INELIGIBLE")

            # 7. Worker weekly recurring availability check
            if not OpportunityService.check_worker_availability(worker_user.worker_profile, gig):
                raise BadRequestException(
                    "Worker is not available during scheduled gig hours",
                    code="WORKER_NOT_AVAILABLE",
                )

            # 8. Schedule conflict check with confirmed gigs
            if OpportunityService.check_schedule_conflict(worker_user.id, gig, db):
                raise BadRequestException(
                    "Worker has a conflicting confirmed gig at this scheduled time",
                    code="SCHEDULE_CONFLICT",
                )

            # 8. State transition
            opp.status = OpportunityStatus.ACCEPTED
            opp.responded_at = datetime.now(timezone.utc)

            # 9. Audit event
            audit_event = GigEvent(
                gig_id=gig.id,
                actor_id=worker_user.id,
                event_type="OPPORTUNITY_ACCEPTED",
                metadata_json={
                    "opportunity_id": str(opp.id),
                    "worker_id": str(worker_user.id),
                    "exact_wage": float(opp.exact_wage),
                    "premium_percentage": float(opp.premium_percentage),
                    "accepted_at": opp.responded_at.isoformat(),
                },
            )
            db.add(audit_event)

            db.commit()
            db.refresh(opp)
            return OpportunityService._map_to_response(opp)
        except Exception:
            db.rollback()
            raise

    @staticmethod
    def reject_opportunity(
        worker_user: User,
        opportunity_id: uuid.UUID,
        db: Session,
    ) -> OpportunityResponse:
        """Atomically reject an opportunity.

        Conforms to 05_API_DESIGN.md Section 15:
        Only opportunity owner can reject. Rejection is final for that opportunity.
        """
        try:
            opp = (
                db.query(GigWorkerOpportunity)
                .filter(GigWorkerOpportunity.id == opportunity_id)
                .with_for_update()
                .first()
            )
            if not opp:
                raise NotFoundException("Opportunity not found", code="OPPORTUNITY_NOT_FOUND")

            if opp.worker_id != worker_user.id:
                raise ForbiddenException("You do not have access to this opportunity", code="FORBIDDEN")

            if opp.status != OpportunityStatus.PENDING:
                raise BadRequestException(
                    f"Opportunity cannot be rejected from current status '{opp.status.value}'",
                    code="INVALID_OPPORTUNITY_STATE",
                )

            opp.status = OpportunityStatus.REJECTED
            opp.responded_at = datetime.now(timezone.utc)

            audit_event = GigEvent(
                gig_id=opp.gig_id,
                actor_id=worker_user.id,
                event_type="OPPORTUNITY_REJECTED",
                metadata_json={
                    "opportunity_id": str(opp.id),
                    "worker_id": str(worker_user.id),
                    "rejected_at": opp.responded_at.isoformat(),
                },
            )
            db.add(audit_event)

            db.commit()
            db.refresh(opp)
            return OpportunityService._map_to_response(opp)
        except Exception:
            db.rollback()
            raise
