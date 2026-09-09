"""Multi-Worker Collaboration & Mentorship Service.

Implements Sprint 10 requirements per:
- docs/06_BACKEND_SPRINTS.md (Section 33: Sprint 10)
- docs/05_API_DESIGN.md (Section 20: Multi-Worker APIs)
- docs/04_DATABASE_DESIGN.md (Sections 34–37: Multi-Worker Participation & Payment)
- docs/WAGES.md (Sections 2, 3: Task complexity, rookie 0.5x contribution)
"""

import uuid
from datetime import datetime, timezone
from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.db.models.user import User, WorkerProfile
from app.db.models.gig import Gig
from app.db.models.service import ServiceCategory
from app.db.models.multi_worker import WorkerParticipation
from app.db.models.communication import GigEvent, Notification
from app.db.models.enums import (
    UserRole,
    GigStatus,
    WorkerParticipationStatus,
    WorkerParticipationClassification,
)
from app.schemas.multi_worker import (
    WorkerParticipationCreateRequest,
    WorkerParticipationResponse,
)
from app.services.experience_service import ExperienceService


class MultiWorkerService:
    @staticmethod
    def _format_participation(
        participation: WorkerParticipation,
    ) -> WorkerParticipationResponse:
        inviting_name = (
            participation.inviting_worker.full_name
            if participation.inviting_worker
            else None
        )
        additional_name = (
            participation.additional_worker.full_name
            if participation.additional_worker
            else None
        )
        exp_val = (
            float(participation.experience_contribution)
            if participation.experience_contribution is not None
            else None
        )

        return WorkerParticipationResponse(
            id=participation.id,
            gig_id=participation.gig_id,
            inviting_worker_id=participation.inviting_worker_id,
            inviting_worker_name=inviting_name,
            additional_worker_id=participation.additional_worker_id,
            additional_worker_name=additional_name,
            status=participation.status,
            classification=participation.classification,
            experience_contribution=exp_val,
            created_at=participation.created_at,
            responded_at=participation.responded_at,
        )

    @staticmethod
    def invite_worker(
        inviting_worker: User,
        gig_id: uuid.UUID,
        payload: WorkerParticipationCreateRequest,
        db: Session,
    ) -> WorkerParticipationResponse:
        """Primary worker invites another verified cooperative worker.

        Rules:
        1. Only the assigned primary worker can invite.
        2. Allowed gig states: WORKER_SELECTED, SCHEDULED, IN_PROGRESS.
        3. Inviting worker cannot invite themselves.
        4. Additional worker must exist, be an active WORKER with an active WorkerProfile.
        5. Both workers must belong to the same cooperative society.
        6. Additional worker cannot have an existing PENDING or ACCEPTED invitation for this gig.
        7. Experience contribution calculated via WAGES.md formula:
           - ROOKIE: 0.5 * complexity
           - EQUAL_SHARING: 1.0 * complexity
        8. Creates audit event and actionable in-app notification.
        """
        # 1. Fetch and validate gig
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Gig {gig_id} not found.",
            )

        if gig.selected_worker_id != inviting_worker.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the assigned primary worker can invite collaborators to this gig.",
            )

        allowed_states = [
            GigStatus.WORKER_SELECTED,
            GigStatus.SCHEDULED,
            GigStatus.IN_PROGRESS,
        ]
        if gig.status not in allowed_states:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot invite collaborators when gig status is '{gig.status.value}'. "
                f"Allowed states: {[s.value for s in allowed_states]}.",
            )

        # 2. Self-invitation check
        if payload.additional_worker_id == inviting_worker.id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Primary worker cannot invite themselves as an additional worker.",
            )

        # 3. Fetch and validate additional worker
        additional_worker = (
            db.query(User).filter(User.id == payload.additional_worker_id).first()
        )
        if not additional_worker:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Additional worker {payload.additional_worker_id} not found.",
            )

        if additional_worker.role != UserRole.WORKER or not additional_worker.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invited user is not an active worker.",
            )

        # 4. Same cooperative validation (Section 20 of 05_API_DESIGN.md & Section 33 of 06_BACKEND_SPRINTS.md)
        if additional_worker.cooperative_id != inviting_worker.cooperative_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Both workers must belong to the same cooperative society. Cross-cooperative collaboration is forbidden.",
            )

        # 5. Active worker profile check
        worker_profile = (
            db.query(WorkerProfile)
            .filter(WorkerProfile.user_id == additional_worker.id)
            .first()
        )
        if not worker_profile or not worker_profile.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invited worker does not have an active verified profile.",
            )

        # 6. Duplicate active/pending invitation check
        existing = (
            db.query(WorkerParticipation)
            .filter(
                WorkerParticipation.gig_id == gig.id,
                WorkerParticipation.additional_worker_id == additional_worker.id,
                WorkerParticipation.status.in_(
                    [WorkerParticipationStatus.PENDING, WorkerParticipationStatus.ACCEPTED]
                ),
            )
            .first()
        )
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Worker already has a {existing.status.value} invitation for this gig.",
            )

        # 7. Calculate experience contribution
        category_name = "Plumbing"
        if gig.category:
            category_name = gig.category.name
        else:
            cat = (
                db.query(ServiceCategory)
                .filter(ServiceCategory.id == gig.category_id)
                .first()
            )
            if cat:
                category_name = cat.name

        duration_minutes = gig.expected_duration_minutes or 60
        complexity = ExperienceService.calculate_task_complexity(
            category_name, duration_minutes
        )
        is_rookie = (
            payload.classification == WorkerParticipationClassification.ROOKIE
        )
        experience_contribution = ExperienceService.calculate_task_contribution(
            complexity, is_rookie_participation=is_rookie
        )

        # 8. Create participation record
        participation = WorkerParticipation(
            id=uuid.uuid4(),
            gig_id=gig.id,
            inviting_worker_id=inviting_worker.id,
            additional_worker_id=additional_worker.id,
            status=WorkerParticipationStatus.PENDING,
            classification=payload.classification,
            experience_contribution=experience_contribution,
        )
        db.add(participation)

        # 9. Audit event log
        audit = GigEvent(
            id=uuid.uuid4(),
            gig_id=gig.id,
            actor_id=inviting_worker.id,
            event_type="WORKER_PARTICIPATION_INVITED",
            metadata_json={
                "participation_id": str(participation.id),
                "additional_worker_id": str(additional_worker.id),
                "classification": payload.classification.value,
                "experience_contribution": float(experience_contribution),
            },
        )
        db.add(audit)

        # 10. Actionable notification
        notification = Notification(
            id=uuid.uuid4(),
            recipient_id=additional_worker.id,
            gig_id=gig.id,
            type="COLLABORATION_INVITED",
            title="New Collaboration Invitation",
            body=(
                f"You have been invited by {inviting_worker.full_name} to collaborate on gig "
                f"as {payload.classification.value}."
            ),
        )
        db.add(notification)

        db.commit()
        db.refresh(participation)
        return MultiWorkerService._format_participation(participation)

    @staticmethod
    def get_gig_participations(
        user: User,
        gig_id: uuid.UUID,
        db: Session,
    ) -> List[WorkerParticipationResponse]:
        """Return participation records visible to authorized participants or customer.

        Rules:
        - Visible to customer, primary worker, or any invited additional worker.
        - Other users receive 403 Forbidden.
        - Does NOT expose private worker-to-worker compensation.
        """
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Gig {gig_id} not found.",
            )

        participations = (
            db.query(WorkerParticipation)
            .filter(WorkerParticipation.gig_id == gig_id)
            .order_by(WorkerParticipation.created_at.asc())
            .all()
        )

        # Check authorization
        is_customer = user.id == gig.customer_id
        is_primary_worker = user.id == gig.selected_worker_id
        is_invited_worker = any(
            p.additional_worker_id == user.id for p in participations
        )

        if not (is_customer or is_primary_worker or is_invited_worker):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not authorized to view participations for this gig.",
            )

        return [
            MultiWorkerService._format_participation(p) for p in participations
        ]

    @staticmethod
    def accept_invitation(
        worker: User,
        participation_id: uuid.UUID,
        db: Session,
    ) -> WorkerParticipationResponse:
        """Additional worker accepts the explicit collaboration invitation.

        Rules:
        1. Caller must be the invited additional worker.
        2. Status must be PENDING.
        3. Gig must not be CANCELLED or COMPLETED.
        4. Transitions to ACCEPTED, records responded_at, logs audit event, notifies inviter.
        """
        participation = (
            db.query(WorkerParticipation)
            .filter(WorkerParticipation.id == participation_id)
            .first()
        )
        if not participation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Participation invitation {participation_id} not found.",
            )

        if participation.additional_worker_id != worker.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the invited additional worker can accept this invitation.",
            )

        if participation.status != WorkerParticipationStatus.PENDING:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invitation cannot be accepted because status is '{participation.status.value}'.",
            )

        gig = db.query(Gig).filter(Gig.id == participation.gig_id).first()
        if not gig or gig.status in [GigStatus.CANCELLED, GigStatus.COMPLETED]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot accept invitation for an inactive or completed gig.",
            )

        participation.status = WorkerParticipationStatus.ACCEPTED
        participation.responded_at = datetime.now(timezone.utc)

        # Audit event
        audit = GigEvent(
            id=uuid.uuid4(),
            gig_id=participation.gig_id,
            actor_id=worker.id,
            event_type="WORKER_PARTICIPATION_ACCEPTED",
            metadata_json={
                "participation_id": str(participation.id),
                "additional_worker_id": str(worker.id),
                "classification": participation.classification.value,
            },
        )
        db.add(audit)

        # Notify inviter
        notification = Notification(
            id=uuid.uuid4(),
            recipient_id=participation.inviting_worker_id,
            gig_id=participation.gig_id,
            type="COLLABORATION_ACCEPTED",
            title="Collaboration Invitation Accepted",
            body=f"{worker.full_name} accepted your collaboration invitation.",
        )
        db.add(notification)

        db.commit()
        db.refresh(participation)
        return MultiWorkerService._format_participation(participation)

    @staticmethod
    def reject_invitation(
        worker: User,
        participation_id: uuid.UUID,
        db: Session,
    ) -> WorkerParticipationResponse:
        """Additional worker declines the collaboration invitation.

        Rules:
        1. Caller must be the invited additional worker.
        2. Status must be PENDING.
        3. Transitions to REJECTED, records responded_at, logs audit event, notifies inviter.
        """
        participation = (
            db.query(WorkerParticipation)
            .filter(WorkerParticipation.id == participation_id)
            .first()
        )
        if not participation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Participation invitation {participation_id} not found.",
            )

        if participation.additional_worker_id != worker.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the invited additional worker can reject this invitation.",
            )

        if participation.status != WorkerParticipationStatus.PENDING:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invitation cannot be rejected because status is '{participation.status.value}'.",
            )

        participation.status = WorkerParticipationStatus.REJECTED
        participation.responded_at = datetime.now(timezone.utc)

        # Audit event
        audit = GigEvent(
            id=uuid.uuid4(),
            gig_id=participation.gig_id,
            actor_id=worker.id,
            event_type="WORKER_PARTICIPATION_REJECTED",
            metadata_json={
                "participation_id": str(participation.id),
                "additional_worker_id": str(worker.id),
            },
        )
        db.add(audit)

        # Notify inviter
        notification = Notification(
            id=uuid.uuid4(),
            recipient_id=participation.inviting_worker_id,
            gig_id=participation.gig_id,
            type="COLLABORATION_REJECTED",
            title="Collaboration Invitation Declined",
            body=f"{worker.full_name} declined your collaboration invitation.",
        )
        db.add(notification)

        db.commit()
        db.refresh(participation)
        return MultiWorkerService._format_participation(participation)
