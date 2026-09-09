import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models.user import User
from app.db.models.enums import UserRole
from app.core.security import get_current_active_user, require_role
from app.schemas.common import ResponseEnvelope
from app.schemas.multi_worker import (
    WorkerParticipationCreateRequest,
    WorkerParticipationResponse,
)
from app.services.multi_worker_service import MultiWorkerService

router = APIRouter()


@router.post(
    "/gigs/{gig_id}/participations",
    response_model=ResponseEnvelope[WorkerParticipationResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Primary worker invites another cooperative worker",
)
async def invite_worker_participation(
    gig_id: uuid.UUID,
    payload: WorkerParticipationCreateRequest,
    current_user: User = Depends(require_role(UserRole.WORKER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[WorkerParticipationResponse]:
    """Invite another verified cooperative worker for peer collaboration or rookie mentorship.

    Matches 06_BACKEND_SPRINTS.md (Section 33) & 05_API_DESIGN.md (Section 20).
    """
    result = MultiWorkerService.invite_worker(
        inviting_worker=current_user,
        gig_id=gig_id,
        payload=payload,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.get(
    "/gigs/{gig_id}/participations",
    response_model=ResponseEnvelope[List[WorkerParticipationResponse]],
    summary="List worker participations for a gig",
)
async def get_gig_participations(
    gig_id: uuid.UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[List[WorkerParticipationResponse]]:
    """Return participation records visible to authorized participants or customer.

    Does not expose private worker-to-worker compensation.
    """
    result = MultiWorkerService.get_gig_participations(
        user=current_user,
        gig_id=gig_id,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.post(
    "/participations/{participation_id}/accept",
    response_model=ResponseEnvelope[WorkerParticipationResponse],
    summary="Invited worker accepts collaboration invitation",
)
async def accept_participation_invitation(
    participation_id: uuid.UUID,
    current_user: User = Depends(require_role(UserRole.WORKER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[WorkerParticipationResponse]:
    """Invited additional worker explicitly accepts collaboration."""
    result = MultiWorkerService.accept_invitation(
        worker=current_user,
        participation_id=participation_id,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.post(
    "/participations/{participation_id}/reject",
    response_model=ResponseEnvelope[WorkerParticipationResponse],
    summary="Invited worker declines collaboration invitation",
)
async def reject_participation_invitation(
    participation_id: uuid.UUID,
    current_user: User = Depends(require_role(UserRole.WORKER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[WorkerParticipationResponse]:
    """Invited additional worker explicitly rejects collaboration."""
    result = MultiWorkerService.reject_invitation(
        worker=current_user,
        participation_id=participation_id,
        db=db,
    )
    return ResponseEnvelope(data=result)
