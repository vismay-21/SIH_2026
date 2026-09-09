import uuid
from decimal import Decimal
from datetime import datetime, timezone, timedelta, date, time
from typing import List, Optional
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import (
    NotFoundException,
    BadRequestException,
    ForbiddenException,
    ConflictException,
    StateConflictException,
)
from app.db.models.user import User
from app.db.models.gig import Gig, GigWorkerOpportunity
from app.db.models.cancellation import GigCancellation, RescheduleRequest
from app.db.models.payment import Payment
from app.db.models.communication import GigEvent, Notification
from app.db.models.enums import (
    GigStatus,
    OpportunityStatus,
    RescheduleStatus,
    PaymentStatus,
    PaymentType,
    PaymentMethod,
)
from app.schemas.cancellation import (
    GigCancelResponse,
    GigReopenResponse,
    RescheduleRequestCreate,
    RescheduleAlternativeRequest,
    RescheduleRequestResponse,
)
from app.services.opportunity_service import OpportunityService


class CancellationService:
    """Orchestrates cancellation, reopening, and rescheduling policies."""

    @classmethod
    def cancel_gig(
        cls,
        user: User,
        gig_id: uuid.UUID,
        reason: str,
        db: Session,
    ) -> GigCancelResponse:
        """Cancel a gig with authoritative fee calculation, opportunity expiration, and audit trail."""
        try:
            gig = db.query(Gig).filter(Gig.id == gig_id).with_for_update().first()
            if not gig:
                raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

            # 1. Authorization: Only customer or assigned worker can cancel
            is_customer = user.id == gig.customer_id
            is_selected_worker = (gig.selected_worker_id is not None) and (user.id == gig.selected_worker_id)
            if not is_customer and not is_selected_worker:
                raise ForbiddenException("Only the gig customer or selected worker can cancel this gig", code="FORBIDDEN")

            # 2. State Validation: Can only cancel before execution has commenced
            cancellable_states = {
                GigStatus.DRAFT,
                GigStatus.POSTED,
                GigStatus.ACCEPTANCE_OPEN,
                GigStatus.WORKER_SELECTED,
                GigStatus.SCHEDULED,
            }
            if gig.status not in cancellable_states:
                raise StateConflictException(
                    f"Cannot cancel gig in state '{gig.status.value}'. In-progress, completed, or already cancelled gigs cannot be cancelled.",
                    code="GIG_CANNOT_BE_CANCELLED",
                )

            # 3. Server-Authoritative Fee Calculation
            # Customer cancels after worker selection: ₹50.00
            # Otherwise (customer before selection, or worker cancellation): ₹0.00
            fee_amount = Decimal("0.00")
            if is_customer:
                if gig.selected_worker_id is not None or gig.status in (GigStatus.WORKER_SELECTED, GigStatus.SCHEDULED):
                    fee_amount = settings.CANCELLATION_FEE_AFTER_SELECTION
                else:
                    fee_amount = settings.CANCELLATION_FEE_BEFORE_SELECTION

            # 4. Atomic Transitions
            now_utc = datetime.now(timezone.utc)
            gig.status = GigStatus.CANCELLED

            # Expire pending opportunities for this gig
            db.query(GigWorkerOpportunity).filter(
                GigWorkerOpportunity.gig_id == gig.id,
                GigWorkerOpportunity.status.in_([OpportunityStatus.PENDING, OpportunityStatus.ACCEPTED]),
            ).update({GigWorkerOpportunity.status: OpportunityStatus.EXPIRED}, synchronize_session=False)

            # Invalidate any active reschedule requests
            db.query(RescheduleRequest).filter(
                RescheduleRequest.gig_id == gig.id,
                RescheduleRequest.status.in_([RescheduleStatus.REQUESTED, RescheduleStatus.ALTERNATIVE_PROPOSED]),
            ).update({RescheduleRequest.status: RescheduleStatus.REJECTED}, synchronize_session=False)

            # Create cancellation audit record
            cancellation = GigCancellation(
                gig_id=gig.id,
                cancelled_by=user.id,
                reason=reason,
                fee_amount=fee_amount,
            )
            db.add(cancellation)
            db.flush()

            # Create cancellation payment obligation if fee > 0
            cancellation_payment = None
            if fee_amount > Decimal("0.00"):
                cancellation_payment = Payment(
                    gig_id=gig.id,
                    customer_id=gig.customer_id,
                    worker_id=gig.selected_worker_id,
                    amount=fee_amount,
                    payment_method=PaymentMethod.UPI,
                    payment_type=PaymentType.CANCELLATION,
                    cancellation_id=cancellation.id,
                    status=PaymentStatus.PENDING,
                )
                db.add(cancellation_payment)

            # Audit event
            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=user.id,
                    event_type="GIG_CANCELLED",
                    metadata_json={
                        "cancelled_by": str(user.id),
                        "cancelled_by_role": user.role.value,
                        "reason": reason,
                        "fee_amount": str(fee_amount),
                        "cancellation_id": str(cancellation.id),
                    },
                )
            )

            # Notification to counterparty
            if is_customer and gig.selected_worker_id:
                db.add(
                    Notification(
                        recipient_id=gig.selected_worker_id,
                        gig_id=gig.id,
                        type="GIG_CANCELLED",
                        title="Gig Cancelled",
                        body=f"Customer cancelled gig {gig.id}. Cancellation fee of ₹{fee_amount:.2f} applies.",
                    )
                )
            elif is_selected_worker:
                db.add(
                    Notification(
                        recipient_id=gig.customer_id,
                        gig_id=gig.id,
                        type="GIG_CANCELLED",
                        title="Gig Cancelled by Worker",
                        body=f"Worker cancelled gig {gig.id}. Reason: {reason}. You may reopen the gig.",
                    )
                )

            db.commit()
            db.refresh(cancellation)

            return GigCancelResponse(
                gig_id=gig.id,
                status=gig.status,
                cancelled_by=user.id,
                cancellation_reason=reason,
                fee_amount=fee_amount,
                cancelled_at=cancellation.created_at,
                payment_status=cancellation_payment.status if cancellation_payment else None,
                payment_required=(fee_amount > Decimal("0.00")),
                cancellation_id=cancellation.id,
            )
        except Exception:
            db.rollback()
            raise

    @classmethod
    def reopen_gig(
        cls,
        user: User,
        gig_id: uuid.UUID,
        db: Session,
    ) -> GigReopenResponse:
        """Reopen a worker-cancelled gig for matching."""
        try:
            gig = db.query(Gig).filter(Gig.id == gig_id).with_for_update().first()
            if not gig:
                raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

            if gig.customer_id != user.id:
                raise ForbiddenException("Only the gig customer can reopen the gig", code="FORBIDDEN")

            if gig.status != GigStatus.CANCELLED:
                raise StateConflictException(
                    f"Only cancelled gigs can be reopened. Current status is '{gig.status.value}'",
                    code="INVALID_GIG_STATE",
                )

            # Reopen Guard 1: Verify the cancellation was worker-initiated
            latest_cancellation = (
                db.query(GigCancellation)
                .filter(GigCancellation.gig_id == gig.id)
                .order_by(GigCancellation.created_at.desc())
                .first()
            )
            if not latest_cancellation or latest_cancellation.cancelled_by == gig.customer_id:
                raise BadRequestException(
                    "Only gigs cancelled by the worker can be reopened. Customer-cancelled gigs cannot be reopened.",
                    code="CUSTOMER_CANCELLATION_CANNOT_REOPEN",
                )

            # Reopen Guard 2: Verify no unsettled cancellation payments on this gig
            unsettled_cancellation_payment = (
                db.query(Payment)
                .filter(
                    Payment.gig_id == gig.id,
                    Payment.payment_type == PaymentType.CANCELLATION,
                    Payment.status != PaymentStatus.WORKER_CONFIRMED,
                )
                .first()
            )
            if unsettled_cancellation_payment:
                raise ConflictException(
                    "Cannot reopen gig while cancellation fee remains unsettled",
                    code="CANCELLATION_PAYMENT_REQUIRED",
                )

            now_utc = datetime.now(timezone.utc)
            gig.selected_worker_id = None
            gig.status = GigStatus.POSTED
            gig.acceptance_deadline = now_utc + timedelta(minutes=15)

            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=user.id,
                    event_type="GIG_REOPENED",
                    metadata_json={
                        "reopened_at": now_utc.isoformat(),
                        "new_status": GigStatus.POSTED.value,
                    },
                )
            )

            db.commit()
            db.refresh(gig)

            return GigReopenResponse(
                gig_id=gig.id,
                status=gig.status,
                reopened_at=now_utc,
                acceptance_deadline=gig.acceptance_deadline,
            )
        except Exception:
            db.rollback()
            raise

    # ---------------- Rescheduling Operations ----------------

    @staticmethod
    def _validate_slot(proposed_date: date, start_time: time, end_time: time):
        """Validate proposed date and time bounds."""
        now_date = datetime.now(timezone.utc).date()
        if proposed_date < now_date:
            raise BadRequestException("Proposed date cannot be in the past", code="INVALID_DATE")

        if start_time >= end_time:
            raise BadRequestException("Start time must precede end time", code="INVALID_TIME_RANGE")

    @classmethod
    def create_reschedule_request(
        cls,
        user: User,
        gig_id: uuid.UUID,
        payload: RescheduleRequestCreate,
        db: Session,
    ) -> RescheduleRequestResponse:
        """Initiate a rescheduling request for an agreed gig with slot and conflict revalidation."""
        try:
            gig = db.query(Gig).filter(Gig.id == gig_id).with_for_update().first()
            if not gig:
                raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

            is_customer = user.id == gig.customer_id
            is_worker = (gig.selected_worker_id is not None) and (user.id == gig.selected_worker_id)
            if not is_customer and not is_worker:
                raise ForbiddenException("Only the gig customer or selected worker can propose rescheduling", code="FORBIDDEN")

            if gig.status not in (GigStatus.WORKER_SELECTED, GigStatus.SCHEDULED):
                raise StateConflictException(
                    f"Rescheduling is only permitted in WORKER_SELECTED or SCHEDULED state, current is '{gig.status.value}'",
                    code="INVALID_RESCHEDULE_STATE",
                )

            cls._validate_slot(payload.proposed_date, payload.proposed_start_time, payload.proposed_end_time)

            # Check for existing active negotiation
            active_request = (
                db.query(RescheduleRequest)
                .filter(
                    RescheduleRequest.gig_id == gig.id,
                    RescheduleRequest.status.in_([RescheduleStatus.REQUESTED, RescheduleStatus.ALTERNATIVE_PROPOSED]),
                )
                .first()
            )
            if active_request:
                raise ConflictException(
                    "An active reschedule negotiation is already in progress for this gig",
                    code="ACTIVE_RESCHEDULE_IN_PROGRESS",
                )

            # Validate worker availability & conflicts for the proposed slot
            worker = db.query(User).filter(User.id == gig.selected_worker_id).first()
            if worker and worker.worker_profile:
                if not OpportunityService.check_worker_availability_for_slot(
                    worker.worker_profile,
                    payload.proposed_date,
                    payload.proposed_start_time,
                    payload.proposed_end_time,
                ):
                    raise BadRequestException(
                        "Worker has no recurring availability defined for the proposed slot",
                        code="WORKER_NOT_AVAILABLE",
                    )

            if OpportunityService.check_schedule_conflict_for_slot(
                worker_id=gig.selected_worker_id,
                target_date=payload.proposed_date,
                start_time=payload.proposed_start_time,
                end_time=payload.proposed_end_time,
                exclude_gig_id=gig.id,
                db=db,
            ):
                raise ConflictException(
                    "Worker has an overlapping confirmed gig during the proposed slot",
                    code="WORKER_SCHEDULE_CONFLICT",
                )

            reschedule_req = RescheduleRequest(
                gig_id=gig.id,
                requested_by=user.id,
                proposed_date=payload.proposed_date,
                proposed_start_time=payload.proposed_start_time,
                proposed_end_time=payload.proposed_end_time,
                reason=payload.reason,
                status=RescheduleStatus.REQUESTED,
            )
            db.add(reschedule_req)

            # Audit event
            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=user.id,
                    event_type="RESCHEDULE_REQUESTED",
                    metadata_json={
                        "proposed_date": payload.proposed_date.isoformat(),
                        "proposed_start_time": payload.proposed_start_time.isoformat(),
                        "proposed_end_time": payload.proposed_end_time.isoformat(),
                        "reason": payload.reason,
                    },
                )
            )

            # Notification to counterparty
            counterparty_id = gig.selected_worker_id if is_customer else gig.customer_id
            db.add(
                Notification(
                    recipient_id=counterparty_id,
                    gig_id=gig.id,
                    type="RESCHEDULE_REQUESTED",
                    title="Reschedule Requested",
                    body=f"A new schedule was proposed for gig {gig.id}: {payload.proposed_date} at {payload.proposed_start_time.strftime('%H:%M')}.",
                )
            )

            db.commit()
            db.refresh(reschedule_req)

            return RescheduleRequestResponse.model_validate(reschedule_req)
        except Exception:
            db.rollback()
            raise

    @classmethod
    def get_reschedule_requests(
        cls,
        user: User,
        gig_id: uuid.UUID,
        db: Session,
    ) -> List[RescheduleRequestResponse]:
        """Fetch negotiation history for a gig."""
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

        if user.id != gig.customer_id and user.id != gig.selected_worker_id:
            raise ForbiddenException("You do not have access to this gig's reschedule requests", code="FORBIDDEN")

        requests = (
            db.query(RescheduleRequest)
            .filter(RescheduleRequest.gig_id == gig.id)
            .order_by(RescheduleRequest.created_at.desc())
            .all()
        )
        return [RescheduleRequestResponse.model_validate(r) for r in requests]

    @classmethod
    def accept_reschedule_request(
        cls,
        user: User,
        gig_id: uuid.UUID,
        request_id: uuid.UUID,
        db: Session,
    ) -> RescheduleRequestResponse:
        """Accept proposed reschedule request, update gig schedule, and move to SCHEDULED."""
        try:
            gig = db.query(Gig).filter(Gig.id == gig_id).with_for_update().first()
            if not gig:
                raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

            reschedule_req = (
                db.query(RescheduleRequest)
                .filter(
                    RescheduleRequest.id == request_id,
                    RescheduleRequest.gig_id == gig.id,
                )
                .with_for_update()
                .first()
            )
            if not reschedule_req:
                raise NotFoundException("Reschedule request not found", code="REQUEST_NOT_FOUND")

            if reschedule_req.status not in (RescheduleStatus.REQUESTED, RescheduleStatus.ALTERNATIVE_PROPOSED):
                raise StateConflictException(
                    f"Reschedule request is not in a respondable state (status: '{reschedule_req.status.value}')",
                    code="INVALID_RESCHEDULE_STATUS",
                )

            # Counterparty check: cannot accept your own request
            if reschedule_req.requested_by == user.id:
                raise ForbiddenException("You cannot accept your own reschedule request", code="CANNOT_ACCEPT_OWN_REQUEST")

            is_customer = user.id == gig.customer_id
            is_worker = (gig.selected_worker_id is not None) and (user.id == gig.selected_worker_id)
            if not is_customer and not is_worker:
                raise ForbiddenException("Only authorized participants can accept reschedule requests", code="FORBIDDEN")

            # Re-verify worker availability & conflict atomically inside the lock
            worker = db.query(User).filter(User.id == gig.selected_worker_id).first()
            if worker and worker.worker_profile:
                if not OpportunityService.check_worker_availability_for_slot(
                    worker.worker_profile,
                    reschedule_req.proposed_date,
                    reschedule_req.proposed_start_time,
                    reschedule_req.proposed_end_time,
                ):
                    raise BadRequestException(
                        "Worker does not have recurring availability for this slot",
                        code="WORKER_NOT_AVAILABLE",
                    )

            if OpportunityService.check_schedule_conflict_for_slot(
                worker_id=gig.selected_worker_id,
                target_date=reschedule_req.proposed_date,
                start_time=reschedule_req.proposed_start_time,
                end_time=reschedule_req.proposed_end_time,
                exclude_gig_id=gig.id,
                db=db,
            ):
                raise ConflictException(
                    "Worker has an overlapping confirmed gig during the proposed slot",
                    code="WORKER_SCHEDULE_CONFLICT",
                )

            now_utc = datetime.now(timezone.utc)
            reschedule_req.status = RescheduleStatus.ACCEPTED
            reschedule_req.responded_by = user.id
            reschedule_req.responded_at = now_utc

            # Update gig schedule
            gig.scheduled_date = reschedule_req.proposed_date
            gig.scheduled_start_time = reschedule_req.proposed_start_time
            gig.scheduled_end_time = reschedule_req.proposed_end_time
            gig.status = GigStatus.SCHEDULED

            # Audit event
            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=user.id,
                    event_type="RESCHEDULE_ACCEPTED",
                    metadata_json={
                        "request_id": str(reschedule_req.id),
                        "new_date": reschedule_req.proposed_date.isoformat(),
                        "new_start_time": reschedule_req.proposed_start_time.isoformat(),
                        "new_end_time": reschedule_req.proposed_end_time.isoformat(),
                    },
                )
            )

            # Notification to requester
            db.add(
                Notification(
                    recipient_id=reschedule_req.requested_by,
                    gig_id=gig.id,
                    type="RESCHEDULE_ACCEPTED",
                    title="Reschedule Accepted",
                    body=f"Your reschedule request for gig {gig.id} was accepted. New time: {reschedule_req.proposed_date} at {reschedule_req.proposed_start_time.strftime('%H:%M')}.",
                )
            )

            db.commit()
            db.refresh(reschedule_req)

            return RescheduleRequestResponse.model_validate(reschedule_req)
        except Exception:
            db.rollback()
            raise

    @classmethod
    def reject_reschedule_request(
        cls,
        user: User,
        gig_id: uuid.UUID,
        request_id: uuid.UUID,
        reason: Optional[str],
        db: Session,
    ) -> RescheduleRequestResponse:
        """Reject reschedule request. Gig schedule and status remain unchanged."""
        try:
            gig = db.query(Gig).filter(Gig.id == gig_id).with_for_update().first()
            if not gig:
                raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

            reschedule_req = (
                db.query(RescheduleRequest)
                .filter(
                    RescheduleRequest.id == request_id,
                    RescheduleRequest.gig_id == gig.id,
                )
                .with_for_update()
                .first()
            )
            if not reschedule_req:
                raise NotFoundException("Reschedule request not found", code="REQUEST_NOT_FOUND")

            if reschedule_req.status not in (RescheduleStatus.REQUESTED, RescheduleStatus.ALTERNATIVE_PROPOSED):
                raise StateConflictException(
                    f"Reschedule request is not in a respondable state (status: '{reschedule_req.status.value}')",
                    code="INVALID_RESCHEDULE_STATUS",
                )

            # Counterparty check
            if reschedule_req.requested_by == user.id:
                raise ForbiddenException("You cannot reject your own reschedule request", code="CANNOT_REJECT_OWN_REQUEST")

            is_customer = user.id == gig.customer_id
            is_worker = (gig.selected_worker_id is not None) and (user.id == gig.selected_worker_id)
            if not is_customer and not is_worker:
                raise ForbiddenException("Only authorized participants can reject reschedule requests", code="FORBIDDEN")

            now_utc = datetime.now(timezone.utc)
            reschedule_req.status = RescheduleStatus.REJECTED
            reschedule_req.responded_by = user.id
            reschedule_req.responded_at = now_utc

            # Audit event
            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=user.id,
                    event_type="RESCHEDULE_REJECTED",
                    metadata_json={
                        "request_id": str(reschedule_req.id),
                        "reason": reason,
                    },
                )
            )

            # Notification to requester
            db.add(
                Notification(
                    recipient_id=reschedule_req.requested_by,
                    gig_id=gig.id,
                    type="RESCHEDULE_REJECTED",
                    title="Reschedule Rejected",
                    body=f"Your reschedule request for gig {gig.id} was rejected. The original schedule remains active.",
                )
            )

            db.commit()
            db.refresh(reschedule_req)

            return RescheduleRequestResponse.model_validate(reschedule_req)
        except Exception:
            db.rollback()
            raise

    @classmethod
    def propose_reschedule_alternative(
        cls,
        user: User,
        gig_id: uuid.UUID,
        request_id: uuid.UUID,
        payload: RescheduleAlternativeRequest,
        db: Session,
    ) -> RescheduleRequestResponse:
        """Counter-propose a new schedule, marking the existing request ALTERNATIVE_PROPOSED and creating a new negotiation request."""
        try:
            gig = db.query(Gig).filter(Gig.id == gig_id).with_for_update().first()
            if not gig:
                raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

            reschedule_req = (
                db.query(RescheduleRequest)
                .filter(
                    RescheduleRequest.id == request_id,
                    RescheduleRequest.gig_id == gig.id,
                )
                .with_for_update()
                .first()
            )
            if not reschedule_req:
                raise NotFoundException("Reschedule request not found", code="REQUEST_NOT_FOUND")

            if reschedule_req.status not in (RescheduleStatus.REQUESTED, RescheduleStatus.ALTERNATIVE_PROPOSED):
                raise StateConflictException(
                    f"Reschedule request is not in an active negotiation state (status: '{reschedule_req.status.value}')",
                    code="INVALID_RESCHEDULE_STATUS",
                )

            # Counterparty check
            if reschedule_req.requested_by == user.id:
                raise ForbiddenException("You cannot propose an alternative to your own request", code="CANNOT_COUNTER_OWN_REQUEST")

            cls._validate_slot(payload.proposed_date, payload.proposed_start_time, payload.proposed_end_time)

            # Validate worker availability & conflicts for the alternative slot
            worker = db.query(User).filter(User.id == gig.selected_worker_id).first()
            if worker and worker.worker_profile:
                if not OpportunityService.check_worker_availability_for_slot(
                    worker.worker_profile,
                    payload.proposed_date,
                    payload.proposed_start_time,
                    payload.proposed_end_time,
                ):
                    raise BadRequestException(
                        "Worker has no recurring availability defined for the counter-proposed slot",
                        code="WORKER_NOT_AVAILABLE",
                    )

            if OpportunityService.check_schedule_conflict_for_slot(
                worker_id=gig.selected_worker_id,
                target_date=payload.proposed_date,
                start_time=payload.proposed_start_time,
                end_time=payload.proposed_end_time,
                exclude_gig_id=gig.id,
                db=db,
            ):
                raise ConflictException(
                    "Worker has an overlapping confirmed gig during the counter-proposed slot",
                    code="WORKER_SCHEDULE_CONFLICT",
                )

            now_utc = datetime.now(timezone.utc)
            # Mark old request as superseded with alternative proposed
            reschedule_req.status = RescheduleStatus.ALTERNATIVE_PROPOSED
            reschedule_req.responded_by = user.id
            reschedule_req.responded_at = now_utc

            # Create new linked counter request
            counter_req = RescheduleRequest(
                gig_id=gig.id,
                requested_by=user.id,
                proposed_date=payload.proposed_date,
                proposed_start_time=payload.proposed_start_time,
                proposed_end_time=payload.proposed_end_time,
                reason=payload.reason,
                status=RescheduleStatus.REQUESTED,
            )
            db.add(counter_req)

            # Audit event
            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=user.id,
                    event_type="RESCHEDULE_ALTERNATIVE_PROPOSED",
                    metadata_json={
                        "superseded_request_id": str(reschedule_req.id),
                        "counter_proposed_date": payload.proposed_date.isoformat(),
                        "counter_proposed_start_time": payload.proposed_start_time.isoformat(),
                        "counter_proposed_end_time": payload.proposed_end_time.isoformat(),
                        "reason": payload.reason,
                    },
                )
            )

            # Notification to previous requester
            db.add(
                Notification(
                    recipient_id=reschedule_req.requested_by,
                    gig_id=gig.id,
                    type="RESCHEDULE_ALTERNATIVE_PROPOSED",
                    title="Reschedule Counter-Proposal",
                    body=f"An alternative time was proposed for gig {gig.id}: {payload.proposed_date} at {payload.proposed_start_time.strftime('%H:%M')}.",
                )
            )

            db.commit()
            db.refresh(counter_req)

            return RescheduleRequestResponse.model_validate(counter_req)
        except Exception:
            db.rollback()
            raise
