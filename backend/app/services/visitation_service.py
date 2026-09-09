import uuid
from decimal import Decimal
from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import (
    NotFoundException,
    BadRequestException,
    ForbiddenException,
    ConflictException,
)
from app.db.models.user import User
from app.db.models.gig import Gig, GigTask
from app.db.models.service import ServiceCategory, ServiceTask
from app.db.models.visitation import VisitationProposal, VisitationProposalTask
from app.db.models.communication import GigEvent, Notification
from app.db.models.enums import (
    UserRole,
    GigType,
    GigStatus,
    VisitationProposalStatus,
)
from app.schemas.visitation import (
    VisitationProposalCreateRequest,
    VisitationProposalResponse,
    VisitationProposalTaskItem,
    VisitationResponse,
)


class VisitationService:
    """Service governing the in-person visitation diagnostics and task proposal workflow.

    Conforms to 05_API_DESIGN.md Section 19 and 06_BACKEND_SPRINTS.md Sections 13, 32.
    """

    @classmethod
    def _format_proposal_response(cls, proposal: VisitationProposal) -> VisitationProposalResponse:
        """Helper to build a strongly typed VisitationProposalResponse."""
        tasks = [
            VisitationProposalTaskItem(
                id=pt.id,
                task_id=pt.task_id,
                task_name=pt.task.name if pt.task else "Unknown Task",
                standard_duration_minutes_snapshot=pt.standard_duration_minutes_snapshot,
                base_price_snapshot=Decimal(str(pt.base_price_snapshot)),
            )
            for pt in proposal.proposal_tasks
        ]
        return VisitationProposalResponse(
            id=proposal.id,
            gig_id=proposal.gig_id,
            worker_id=proposal.worker_id,
            base_price=Decimal(str(proposal.base_price)),
            status=proposal.status,
            proposed_at=proposal.proposed_at,
            customer_responded_at=proposal.customer_responded_at,
            tasks=tasks,
        )

    @classmethod
    def request_visitation(
        cls,
        customer: User,
        gig_id: uuid.UUID,
        db: Session,
    ) -> VisitationResponse:
        """Customer opens or converts gig to VISITATION workflow.

        Fixed visitation charge of ₹100 is established.
        """
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

        if customer.id != gig.customer_id:
            raise ForbiddenException("Only the gig customer can request a visitation", code="FORBIDDEN")

        if gig.status in (
            GigStatus.COMPLETED,
            GigStatus.CANCELLED,
            GigStatus.PAYMENT_CUSTOMER_PAID,
            GigStatus.PAYMENT_WORKER_CONFIRMED,
        ):
            raise BadRequestException(
                f"Cannot request visitation on gig with status '{gig.status.value}'",
                code="INVALID_GIG_STATE",
            )

        try:
            gig.gig_type = GigType.VISITATION
            # If no accepted proposal yet, initialize gig base_price to fixed ₹100
            has_accepted_proposal = (
                db.query(VisitationProposal)
                .filter(
                    VisitationProposal.gig_id == gig.id,
                    VisitationProposal.status == VisitationProposalStatus.ACCEPTED,
                )
                .first()
            )
            if not has_accepted_proposal:
                gig.base_price = Decimal(str(settings.VISITATION_FEE))

            # Audit event
            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=customer.id,
                    event_type="VISITATION_REQUESTED",
                    metadata_json={
                        "gig_id": str(gig.id),
                        "visitation_fee": f"{Decimal(str(settings.VISITATION_FEE)):.2f}",
                    },
                )
            )

            # Notify selected worker if one is assigned
            if gig.selected_worker_id:
                db.add(
                    Notification(
                        recipient_id=gig.selected_worker_id,
                        gig_id=gig.id,
                        type="VISITATION_REQUESTED",
                        title="Visitation Requested",
                        body="The customer requested an in-person visitation inspection.",
                    )
                )

            db.commit()
            db.refresh(gig)
        except Exception:
            db.rollback()
            raise

        return cls.get_visitation_details(customer, gig_id, db)

    @classmethod
    def get_visitation_details(
        cls,
        user: User,
        gig_id: uuid.UUID,
        db: Session,
    ) -> VisitationResponse:
        """Fetch visitation state, proposal history, and caller action capabilities."""
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

        if user.id != gig.customer_id and user.id != gig.selected_worker_id:
            raise ForbiddenException("You do not have access to this gig's visitation details", code="FORBIDDEN")

        proposals = (
            db.query(VisitationProposal)
            .filter(VisitationProposal.gig_id == gig.id)
            .order_by(VisitationProposal.proposed_at.desc())
            .all()
        )

        formatted_proposals = [cls._format_proposal_response(p) for p in proposals]
        active_proposal = next((p for p in formatted_proposals if p.status == VisitationProposalStatus.PENDING), None)
        if not active_proposal and formatted_proposals:
            active_proposal = formatted_proposals[0]

        is_visitation = gig.gig_type == GigType.VISITATION
        has_pending = any(p.status == VisitationProposalStatus.PENDING for p in proposals)

        can_propose = (
            is_visitation
            and user.role == UserRole.WORKER
            and user.id == gig.selected_worker_id
            and gig.status in (GigStatus.WORKER_SELECTED, GigStatus.SCHEDULED, GigStatus.IN_PROGRESS)
            and not has_pending
        )

        can_respond = (
            is_visitation
            and user.role == UserRole.CUSTOMER
            and user.id == gig.customer_id
            and has_pending
        )

        return VisitationResponse(
            gig_id=gig.id,
            gig_type=gig.gig_type,
            visitation_fee=Decimal(str(settings.VISITATION_FEE)),
            is_visitation=is_visitation,
            active_proposal=active_proposal,
            proposals=formatted_proposals,
            can_propose=can_propose,
            can_respond=can_respond,
        )

    @classmethod
    def submit_proposal(
        cls,
        worker: User,
        gig_id: uuid.UUID,
        payload: VisitationProposalCreateRequest,
        db: Session,
    ) -> VisitationProposalResponse:
        """Selected worker submits an itemized task proposal following visitation inspection."""
        try:
            # Row lock on Gig to serialize proposal submissions
            gig = db.query(Gig).filter(Gig.id == gig_id).with_for_update().first()
            if not gig:
                raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

            if worker.id != gig.selected_worker_id or worker.role != UserRole.WORKER:
                raise ForbiddenException("Only the assigned worker can submit a visitation proposal", code="FORBIDDEN")

            if gig.gig_type != GigType.VISITATION:
                raise BadRequestException(
                    "Cannot submit a visitation proposal for a non-visitation gig",
                    code="NOT_VISITATION_GIG",
                )

            if gig.status not in (GigStatus.WORKER_SELECTED, GigStatus.SCHEDULED, GigStatus.IN_PROGRESS):
                raise BadRequestException(
                    f"Cannot submit proposal when gig is in '{gig.status.value}' state",
                    code="INVALID_GIG_STATE",
                )

            # Prevent concurrent duplicate PENDING proposals
            existing_pending = (
                db.query(VisitationProposal)
                .filter(
                    VisitationProposal.gig_id == gig.id,
                    VisitationProposal.status == VisitationProposalStatus.PENDING,
                )
                .first()
            )
            if existing_pending:
                raise ConflictException(
                    "A proposal is already pending customer response",
                    code="PROPOSAL_PENDING",
                )

            # Category and task validation
            category = db.query(ServiceCategory).filter(ServiceCategory.id == gig.category_id).first()
            if not category:
                raise NotFoundException("Service category not found", code="CATEGORY_NOT_FOUND")

            tasks = (
                db.query(ServiceTask)
                .filter(
                    ServiceTask.id.in_(payload.task_ids),
                    ServiceTask.is_active == True,
                )
                .all()
            )
            if len(tasks) != len(set(payload.task_ids)):
                raise BadRequestException("One or more task IDs are invalid or inactive", code="INVALID_TASKS")

            for t in tasks:
                if t.category_id != gig.category_id:
                    raise BadRequestException(
                        f"Task '{t.name}' does not belong to the gig category '{category.name}'",
                        code="CATEGORY_TASK_MISMATCH",
                    )

            # Server-calculated proposed work base price (authoritative: catalogue tasks + category rate)
            total_duration = sum(t.standard_duration_minutes for t in tasks)
            billable_duration = max(total_duration, category.minimum_billable_minutes)
            proposed_base_price = Decimal(f"{round(billable_duration * float(category.base_rate_per_minute), 2):.2f}")

            proposal = VisitationProposal(
                id=uuid.uuid4(),
                gig_id=gig.id,
                worker_id=worker.id,
                base_price=proposed_base_price,
                status=VisitationProposalStatus.PENDING,
                proposed_at=datetime.now(timezone.utc),
            )
            db.add(proposal)
            db.flush()

            # Create proposal tasks snapshots
            for t in tasks:
                task_price = Decimal(f"{round(t.standard_duration_minutes * float(category.base_rate_per_minute), 2):.2f}")
                pt = VisitationProposalTask(
                    id=uuid.uuid4(),
                    proposal_id=proposal.id,
                    task_id=t.id,
                    standard_duration_minutes_snapshot=t.standard_duration_minutes,
                    base_price_snapshot=task_price,
                )
                db.add(pt)

            # Audit event
            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=worker.id,
                    event_type="VISITATION_PROPOSED",
                    metadata_json={
                        "proposal_id": str(proposal.id),
                        "proposed_base_price": f"{proposed_base_price:.2f}",
                        "task_count": len(tasks),
                    },
                )
            )

            # Customer notification
            db.add(
                Notification(
                    recipient_id=gig.customer_id,
                    gig_id=gig.id,
                    type="VISITATION_PROPOSAL",
                    title="Work Proposal Received",
                    body="Worker has inspected and submitted a proposal for your approval.",
                )
            )

            db.commit()
            db.refresh(proposal)
            return cls._format_proposal_response(proposal)
        except Exception:
            db.rollback()
            raise

    @classmethod
    def accept_proposal(
        cls,
        customer: User,
        gig_id: uuid.UUID,
        proposal_id: uuid.UUID,
        db: Session,
    ) -> VisitationProposalResponse:
        """Customer accepts worker proposal.

        Rule: ₹100 visitation charge is waived/absorbed into final work payment (Section 43).
        - Proposal becomes ACCEPTED
        - Gig base_price updated to proposed work price
        - Gig tasks replaced with proposal tasks
        - Historical worker opportunity snapshots remain untouched
        """
        try:
            gig = db.query(Gig).filter(Gig.id == gig_id).first()
            if not gig:
                raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

            if customer.id != gig.customer_id or customer.role != UserRole.CUSTOMER:
                raise ForbiddenException("Only the gig customer can accept a proposal", code="FORBIDDEN")

            # Lock proposal row for update
            proposal = (
                db.query(VisitationProposal)
                .filter(
                    VisitationProposal.id == proposal_id,
                    VisitationProposal.gig_id == gig.id,
                )
                .with_for_update()
                .first()
            )
            if not proposal:
                raise NotFoundException(f"Proposal {proposal_id} not found", code="PROPOSAL_NOT_FOUND")

            if proposal.status != VisitationProposalStatus.PENDING:
                raise ConflictException(
                    f"Proposal has already been responded to (status: {proposal.status.value})",
                    code="PROPOSAL_ALREADY_RESPONDED",
                )

            now_utc = datetime.now(timezone.utc)
            proposal.status = VisitationProposalStatus.ACCEPTED
            proposal.customer_responded_at = now_utc

            # Update gig base price to accepted proposal price (₹100 fee absorbed, not added)
            gig.base_price = Decimal(str(proposal.base_price))

            # Replace gig tasks with proposal tasks
            db.query(GigTask).filter(GigTask.gig_id == gig.id).delete()
            for pt in proposal.proposal_tasks:
                gt = GigTask(
                    id=uuid.uuid4(),
                    gig_id=gig.id,
                    task_id=pt.task_id,
                    standard_duration_minutes_snapshot=pt.standard_duration_minutes_snapshot,
                    base_price_snapshot=pt.base_price_snapshot,
                )
                db.add(gt)

            # Ensure gig is in IN_PROGRESS for work execution
            if gig.status in (GigStatus.WORKER_SELECTED, GigStatus.SCHEDULED):
                gig.status = GigStatus.IN_PROGRESS

            # Audit event
            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=customer.id,
                    event_type="VISITATION_ACCEPTED",
                    metadata_json={
                        "proposal_id": str(proposal.id),
                        "final_base_price": f"{Decimal(str(proposal.base_price)):.2f}",
                    },
                )
            )

            # Worker notification
            if gig.selected_worker_id:
                db.add(
                    Notification(
                        recipient_id=gig.selected_worker_id,
                        gig_id=gig.id,
                        type="VISITATION_ACCEPTED",
                        title="Proposal Accepted",
                        body="Customer has accepted your work proposal. You may proceed with the job.",
                    )
                )

            db.commit()
            db.refresh(proposal)
            return cls._format_proposal_response(proposal)
        except Exception:
            db.rollback()
            raise

    @classmethod
    def reject_proposal(
        cls,
        customer: User,
        gig_id: uuid.UUID,
        proposal_id: uuid.UUID,
        db: Session,
    ) -> VisitationProposalResponse:
        """Customer rejects worker proposal.

        Rule: Fixed ₹100 visitation charge remains payable. No work payment created (Section 43).
        - Proposal becomes REJECTED
        - Gig base_price remains fixed at ₹100.00
        - Gig transitions to CUSTOMER_CONFIRMED so payment of ₹100 can proceed
        - Historical worker opportunity snapshots remain untouched
        """
        try:
            gig = db.query(Gig).filter(Gig.id == gig_id).first()
            if not gig:
                raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

            if customer.id != gig.customer_id or customer.role != UserRole.CUSTOMER:
                raise ForbiddenException("Only the gig customer can reject a proposal", code="FORBIDDEN")

            # Lock proposal row for update
            proposal = (
                db.query(VisitationProposal)
                .filter(
                    VisitationProposal.id == proposal_id,
                    VisitationProposal.gig_id == gig.id,
                )
                .with_for_update()
                .first()
            )
            if not proposal:
                raise NotFoundException(f"Proposal {proposal_id} not found", code="PROPOSAL_NOT_FOUND")

            if proposal.status != VisitationProposalStatus.PENDING:
                raise ConflictException(
                    f"Proposal has already been responded to (status: {proposal.status.value})",
                    code="PROPOSAL_ALREADY_RESPONDED",
                )

            now_utc = datetime.now(timezone.utc)
            proposal.status = VisitationProposalStatus.REJECTED
            proposal.customer_responded_at = now_utc

            # Ensure gig base_price is set to fixed visitation fee
            gig.base_price = Decimal(str(settings.VISITATION_FEE))

            # Since visitation inspection is completed and customer rejected extra work,
            # advance gig to CUSTOMER_CONFIRMED so customer can pay the ₹100 visitation fee
            if gig.status in (GigStatus.WORKER_SELECTED, GigStatus.SCHEDULED, GigStatus.IN_PROGRESS):
                gig.status = GigStatus.CUSTOMER_CONFIRMED

            # Audit event
            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=customer.id,
                    event_type="VISITATION_REJECTED",
                    metadata_json={
                        "proposal_id": str(proposal.id),
                        "payable_visitation_fee": f"{Decimal(str(settings.VISITATION_FEE)):.2f}",
                    },
                )
            )

            # Worker notification
            if gig.selected_worker_id:
                db.add(
                    Notification(
                        recipient_id=gig.selected_worker_id,
                        gig_id=gig.id,
                        type="VISITATION_REJECTED",
                        title="Proposal Rejected",
                        body="Customer rejected the work proposal. The fixed ₹100 visitation charge remains payable.",
                    )
                )

            db.commit()
            db.refresh(proposal)
            return cls._format_proposal_response(proposal)
        except Exception:
            db.rollback()
            raise
