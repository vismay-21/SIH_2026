import uuid
import math
from datetime import datetime, timezone
from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.db.models.user import User
from app.db.models.gig import Gig, GigWorkerOpportunity
from app.db.models.completion import (
    CompletionSubmission,
    CompletionEvidence,
    CompletionConfirmation,
)
from app.db.models.communication import GigEvent, Notification
from app.db.models.enums import GigStatus, OpportunityStatus
from app.core.exceptions import (
    NotFoundException,
    BadRequestException,
    ForbiddenException,
)
from app.schemas.worker_gig import WorkerGigListItem
from app.schemas.completion import (
    CompletionSubmissionRequest,
    CompletionSubmissionResponse,
    CompletionEvidenceResponse,
    CompletionConfirmationRequest,
    CompletionConfirmationResponse,
    StartWorkResponse,
    GigCompletionDetailResponse,
)
from app.schemas.common import PaginatedResponse, PaginationMeta


class CompletionService:
    """Core job execution and completion service conforming to 05_API_DESIGN.md Section 22 and 06_BACKEND_SPRINTS.md Section 30."""

    @staticmethod
    def get_worker_gigs(
        worker_user: User,
        tab: Optional[str] = None,
        status: Optional[str] = None,
        page: int = 1,
        page_size: int = 10,
        db: Session = None,
    ) -> PaginatedResponse[WorkerGigListItem]:
        """Fetch gigs assigned to the authenticated worker with lifecycle filtering."""
        query = db.query(Gig).filter(Gig.selected_worker_id == worker_user.id)

        # Tab-based filtering per 05_API_DESIGN.md Section 13
        if tab:
            tab_lower = tab.lower()
            if tab_lower == "upcoming":
                query = query.filter(Gig.status.in_([GigStatus.WORKER_SELECTED, GigStatus.SCHEDULED]))
            elif tab_lower == "active":
                query = query.filter(Gig.status.in_([GigStatus.IN_PROGRESS, GigStatus.COMPLETION_SUBMITTED]))
            elif tab_lower == "completed":
                query = query.filter(
                    Gig.status.in_([
                        GigStatus.CUSTOMER_CONFIRMED,
                        GigStatus.PAYMENT_PENDING,
                        GigStatus.PAYMENT_CUSTOMER_PAID,
                        GigStatus.PAYMENT_WORKER_CONFIRMED,
                        GigStatus.COMPLETED,
                    ])
                )
            elif tab_lower == "cancelled":
                query = query.filter(Gig.status == GigStatus.CANCELLED)

        # Direct status filter override
        if status:
            try:
                gig_status = GigStatus(status)
                query = query.filter(Gig.status == gig_status)
            except ValueError:
                raise BadRequestException(f"Invalid status filter '{status}'", code="INVALID_STATUS")

        total = query.count()
        total_pages = math.ceil(total / page_size) if total > 0 else 0
        offset = (page - 1) * page_size
        gigs = query.order_by(Gig.created_at.desc()).offset(offset).limit(page_size).all()

        items: List[WorkerGigListItem] = []
        for g in gigs:
            # Look up agreed exact wage snapshot from accepted opportunity
            opp = (
                db.query(GigWorkerOpportunity)
                .filter(
                    GigWorkerOpportunity.gig_id == g.id,
                    GigWorkerOpportunity.worker_id == worker_user.id,
                )
                .first()
            )
            exact_wage = float(opp.exact_wage) if opp else float(g.base_price)

            items.append(
                WorkerGigListItem(
                    id=g.id,
                    category_id=g.category_id,
                    category_name=g.category.name if g.category else "",
                    description=g.description,
                    scheduled_date=g.scheduled_date,
                    scheduled_start_time=g.scheduled_start_time,
                    status=g.status.value,
                    base_price=float(g.base_price),
                    exact_wage=exact_wage,
                    customer_id=g.customer_id,
                    customer_name=g.customer.full_name if g.customer else None,
                    address_line=g.address,
                    emergency=g.is_emergency,
                    created_at=g.created_at,
                )
            )

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
    def start_work(
        worker_user: User,
        gig_id: uuid.UUID,
        db: Session,
    ) -> StartWorkResponse:
        """Worker marks the gig as in progress ('Arrived & Start Work' action)."""
        try:
            gig = db.query(Gig).filter(Gig.id == gig_id).with_for_update().first()
            if not gig:
                raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

            if gig.selected_worker_id != worker_user.id:
                raise ForbiddenException("You are not the assigned worker for this gig", code="FORBIDDEN")

            if gig.status not in (GigStatus.WORKER_SELECTED, GigStatus.SCHEDULED):
                raise BadRequestException(
                    f"Cannot start work from current gig status '{gig.status.value}'",
                    code="INVALID_GIG_STATE",
                )

            gig.status = GigStatus.IN_PROGRESS

            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=worker_user.id,
                    event_type="WORK_STARTED",
                    metadata_json={"started_at": datetime.now(timezone.utc).isoformat()},
                )
            )

            db.commit()
            db.refresh(gig)

            return StartWorkResponse(
                gig_id=gig.id,
                status=gig.status.value,
                message="Work started successfully.",
            )
        except Exception:
            db.rollback()
            raise

    @staticmethod
    def submit_completion(
        worker_user: User,
        gig_id: uuid.UUID,
        request: CompletionSubmissionRequest,
        db: Session,
    ) -> CompletionSubmissionResponse:
        """Worker submits work completion notes and evidence files."""
        try:
            gig = db.query(Gig).filter(Gig.id == gig_id).with_for_update().first()
            if not gig:
                raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

            if gig.selected_worker_id != worker_user.id:
                raise ForbiddenException("You are not the assigned worker for this gig", code="FORBIDDEN")

            # Intentional MVP decision: allow completion submission from WORKER_SELECTED, SCHEDULED, or IN_PROGRESS
            if gig.status not in (GigStatus.WORKER_SELECTED, GigStatus.SCHEDULED, GigStatus.IN_PROGRESS):
                raise BadRequestException(
                    f"Completion cannot be submitted from current gig status '{gig.status.value}'",
                    code="INVALID_GIG_STATE",
                )

            if not request.evidence_items:
                raise BadRequestException(
                    "At least one evidence photo must be provided",
                    code="EVIDENCE_REQUIRED",
                )

            submission = CompletionSubmission(
                gig_id=gig.id,
                worker_id=worker_user.id,
                description=request.description,
                submitted_at=datetime.now(timezone.utc),
            )
            db.add(submission)
            db.flush()

            evidence_records = []
            for item in request.evidence_items:
                ev = CompletionEvidence(
                    submission_id=submission.id,
                    file_url=item.file_url,
                    file_type=item.file_type,
                )
                db.add(ev)
                evidence_records.append(ev)

            # Move gig to completion-submitted state
            gig.status = GigStatus.COMPLETION_SUBMITTED

            # Audit event
            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=worker_user.id,
                    event_type="COMPLETION_SUBMITTED",
                    metadata_json={
                        "submission_id": str(submission.id),
                        "evidence_count": len(request.evidence_items),
                    },
                )
            )

            # Notification to customer
            db.add(
                Notification(
                    recipient_id=gig.customer_id,
                    gig_id=gig.id,
                    type="COMPLETION_SUBMITTED",
                    title="Work completion submitted",
                    body=f"Worker has completed work and submitted evidence for gig {gig.id}.",
                )
            )

            db.commit()
            db.refresh(submission)

            return CompletionSubmissionResponse(
                id=submission.id,
                gig_id=submission.gig_id,
                worker_id=submission.worker_id,
                description=submission.description,
                submitted_at=submission.submitted_at,
                evidence_files=[
                    CompletionEvidenceResponse(
                        id=e.id,
                        submission_id=e.submission_id,
                        file_url=e.file_url,
                        file_type=e.file_type,
                        created_at=e.created_at,
                    )
                    for e in submission.evidence_files
                ],
            )
        except Exception:
            db.rollback()
            raise

    @staticmethod
    def get_completion(
        user: User,
        gig_id: uuid.UUID,
        db: Session,
    ) -> GigCompletionDetailResponse:
        """Fetch completion details for authorized participants (customer or selected worker)."""
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

        if user.id != gig.customer_id and user.id != gig.selected_worker_id:
            raise ForbiddenException("You do not have access to view this gig's completion", code="FORBIDDEN")

        latest_submission = (
            db.query(CompletionSubmission)
            .filter(CompletionSubmission.gig_id == gig.id)
            .order_by(CompletionSubmission.submitted_at.desc())
            .first()
        )

        sub_resp = None
        if latest_submission:
            sub_resp = CompletionSubmissionResponse(
                id=latest_submission.id,
                gig_id=latest_submission.gig_id,
                worker_id=latest_submission.worker_id,
                description=latest_submission.description,
                submitted_at=latest_submission.submitted_at,
                evidence_files=[
                    CompletionEvidenceResponse(
                        id=e.id,
                        submission_id=e.submission_id,
                        file_url=e.file_url,
                        file_type=e.file_type,
                        created_at=e.created_at,
                    )
                    for e in latest_submission.evidence_files
                ],
            )

        latest_confirmation = (
            db.query(CompletionConfirmation)
            .filter(CompletionConfirmation.gig_id == gig.id)
            .order_by(CompletionConfirmation.created_at.desc())
            .first()
        )

        conf_resp = None
        if latest_confirmation:
            conf_resp = CompletionConfirmationResponse(
                id=latest_confirmation.id,
                gig_id=latest_confirmation.gig_id,
                customer_id=latest_confirmation.customer_id,
                confirmed=latest_confirmation.confirmed,
                response_note=latest_confirmation.response_note,
                created_at=latest_confirmation.created_at,
            )

        return GigCompletionDetailResponse(
            gig_id=gig.id,
            status=gig.status.value,
            submission=sub_resp,
            confirmation=conf_resp,
        )

    @staticmethod
    def confirm_completion(
        customer_user: User,
        gig_id: uuid.UUID,
        request: CompletionConfirmationRequest,
        db: Session,
    ) -> CompletionConfirmationResponse:
        """Customer approves completion or requests rework."""
        try:
            gig = db.query(Gig).filter(Gig.id == gig_id).with_for_update().first()
            if not gig:
                raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

            if gig.customer_id != customer_user.id:
                raise ForbiddenException("Only the gig customer can confirm completion", code="FORBIDDEN")

            if gig.status != GigStatus.COMPLETION_SUBMITTED:
                raise BadRequestException(
                    f"Gig is not awaiting customer confirmation (current status: '{gig.status.value}')",
                    code="INVALID_GIG_STATE",
                )

            submission = (
                db.query(CompletionSubmission)
                .filter(CompletionSubmission.gig_id == gig.id)
                .first()
            )
            if not submission:
                raise BadRequestException(
                    "No completion submission found for this gig",
                    code="SUBMISSION_NOT_FOUND",
                )

            confirmation = CompletionConfirmation(
                gig_id=gig.id,
                customer_id=customer_user.id,
                confirmed=request.confirmed,
                response_note=request.response_note,
            )
            db.add(confirmation)

            if request.confirmed:
                gig.status = GigStatus.CUSTOMER_CONFIRMED
                event_type = "COMPLETION_CONFIRMED"
                notif_type = "COMPLETION_CONFIRMED"
                notif_title = "Completion Confirmed!"
                notif_body = f"Customer has confirmed completion of work for gig {gig.id}."
            else:
                # Rejection rework loop: return gig to IN_PROGRESS per approved state machine
                gig.status = GigStatus.IN_PROGRESS
                event_type = "COMPLETION_REJECTED"
                notif_type = "COMPLETION_REJECTED"
                notif_title = "Rework Requested"
                notif_body = f"Customer requested rework for gig {gig.id}: {request.response_note or 'Please review work.'}"

            # Audit event
            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=customer_user.id,
                    event_type=event_type,
                    metadata_json={
                        "confirmed": request.confirmed,
                        "response_note": request.response_note,
                    },
                )
            )

            # Notification to worker
            if gig.selected_worker_id:
                db.add(
                    Notification(
                        recipient_id=gig.selected_worker_id,
                        gig_id=gig.id,
                        type=notif_type,
                        title=notif_title,
                        body=notif_body,
                    )
                )

            db.commit()
            db.refresh(confirmation)

            return CompletionConfirmationResponse(
                id=confirmation.id,
                gig_id=confirmation.gig_id,
                customer_id=confirmation.customer_id,
                confirmed=confirmation.confirmed,
                response_note=confirmation.response_note,
                created_at=confirmation.created_at,
            )
        except Exception:
            db.rollback()
            raise
