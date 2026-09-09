import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models.user import User
from app.db.models.enums import UserRole
from app.core.security import get_current_active_user, require_role
from app.schemas.common import ResponseEnvelope
from app.schemas.pricing import PricePreviewRequest, PricePreviewResponse
from app.schemas.gig import GigCreateRequest, GigResponse
from app.schemas.candidate import (
    GigCandidateResponse,
    SelectWorkerRequest,
    SelectWorkerResponse,
)
from app.schemas.completion import (
    CompletionSubmissionRequest,
    CompletionSubmissionResponse,
    CompletionConfirmationRequest,
    CompletionConfirmationResponse,
    StartWorkResponse,
    GigCompletionDetailResponse,
)
from app.schemas.payment import (
    PaymentCreateRequest,
    PaymentReceiptConfirmRequest,
    PaymentResponse,
)
from app.schemas.visitation import (
    VisitationProposalCreateRequest,
    VisitationProposalResponse,
    VisitationResponse,
)
from app.services.pricing_service import PricingService
from app.services.gig_service import GigService
from app.services.completion_service import CompletionService
from app.services.payment_service import PaymentService
from app.services.visitation_service import VisitationService

router = APIRouter()


@router.post(
    "/gigs/price-preview",
    response_model=ResponseEnvelope[PricePreviewResponse],
    summary="Preview gig pricing and worker wage range",
)
async def get_price_preview(
    request: PricePreviewRequest,
    db: Session = Depends(get_db),
) -> ResponseEnvelope[PricePreviewResponse]:
    """Calculate standard duration, minimum billable duration, base labour price, and worker wage range.

    Enforces 06_BACKEND_SPRINTS.md and WAGES.md rules:
    - 15-minute task -> 45-minute minimum
    - 20 + 25 minutes -> 45 minutes
    - 75-minute total -> 75 minutes
    - Rejects tasks from different categories
    """
    preview = PricingService.calculate_gig_pricing(
        db=db,
        category_id=request.category_id,
        task_ids=request.task_ids,
    )
    return ResponseEnvelope(data=preview)


@router.post(
    "/gigs",
    response_model=ResponseEnvelope[GigResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create a new customer gig",
)
async def create_gig(
    request: GigCreateRequest,
    current_user: User = Depends(require_role(UserRole.CUSTOMER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[GigResponse]:
    """Create a new gig in DRAFT status with immutable pricing snapshots, tasks, and audit log.

    Conforms to 05_API_DESIGN.md Section 11 and 06_BACKEND_SPRINTS.md Section 27.
    """
    gig = GigService.create_gig(
        customer_user=current_user,
        payload=request,
        db=db,
    )
    return ResponseEnvelope(data=gig)


@router.get(
    "/gigs/{gig_id}",
    response_model=ResponseEnvelope[GigResponse],
    summary="Retrieve gig details by ID",
)
async def get_gig(
    gig_id: uuid.UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[GigResponse]:
    """Retrieve detailed gig view with role-based access authorization."""
    gig = GigService.get_gig_by_id(
        current_user=current_user,
        gig_id=gig_id,
        db=db,
    )
    return ResponseEnvelope(data=gig)


@router.post(
    "/gigs/{gig_id}/post",
    response_model=ResponseEnvelope[GigResponse],
    summary="Post a draft gig to seeking workers status",
)
async def post_gig(
    gig_id: uuid.UUID,
    current_user: User = Depends(require_role(UserRole.CUSTOMER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[GigResponse]:
    """Transition a customer's gig from DRAFT to POSTED status and record audit event."""
    gig = GigService.post_gig(
        customer_user=current_user,
        gig_id=gig_id,
        db=db,
    )
    return ResponseEnvelope(data=gig)


@router.get(
    "/gigs/{gig_id}/candidates",
    response_model=ResponseEnvelope[List[GigCandidateResponse]],
    summary="List accepted worker candidates for gig",
)
async def get_gig_candidates(
    gig_id: uuid.UUID,
    current_user: User = Depends(require_role(UserRole.CUSTOMER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[List[GigCandidateResponse]]:
    """Retrieve accepted worker candidates with transparent metrics and exact wages.

    Conforms to 05_API_DESIGN.md Section 16 & 06_BACKEND_SPRINTS.md Section 29.
    """
    candidates = GigService.get_candidates(
        customer_user=current_user,
        gig_id=gig_id,
        db=db,
    )
    return ResponseEnvelope(data=candidates)


@router.post(
    "/gigs/{gig_id}/select-worker",
    response_model=ResponseEnvelope[SelectWorkerResponse],
    summary="Customer selects one accepted candidate worker",
)
async def select_worker_for_gig(
    gig_id: uuid.UUID,
    request: SelectWorkerRequest,
    current_user: User = Depends(require_role(UserRole.CUSTOMER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[SelectWorkerResponse]:
    """Select a candidate worker for the gig.

    Conforms to 05_API_DESIGN.md Section 17 & 06_BACKEND_SPRINTS.md Section 29.
    Atomically updates gig state to WORKER_SELECTED, closes other candidates as NOT_SELECTED,
    writes audit event, and dispatches actionable notifications.
    """
    result = GigService.select_worker(
        customer_user=current_user,
        gig_id=gig_id,
        worker_id=request.worker_id,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.post(
    "/gigs/{gig_id}/start",
    response_model=ResponseEnvelope[StartWorkResponse],
    summary="Worker marks work as started ('Arrived & Start Work')",
)
async def start_gig_work(
    gig_id: uuid.UUID,
    current_user: User = Depends(require_role(UserRole.WORKER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[StartWorkResponse]:
    """Assigned worker starts work on the gig, moving it from WORKER_SELECTED or SCHEDULED to IN_PROGRESS."""
    result = CompletionService.start_work(
        worker_user=current_user,
        gig_id=gig_id,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.post(
    "/gigs/{gig_id}/completion",
    response_model=ResponseEnvelope[CompletionSubmissionResponse],
    summary="Worker submits work completion evidence",
)
async def submit_gig_completion(
    gig_id: uuid.UUID,
    request: CompletionSubmissionRequest,
    current_user: User = Depends(require_role(UserRole.WORKER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[CompletionSubmissionResponse]:
    """Assigned worker submits completion notes and evidence files."""
    result = CompletionService.submit_completion(
        worker_user=current_user,
        gig_id=gig_id,
        request=request,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.get(
    "/gigs/{gig_id}/completion",
    response_model=ResponseEnvelope[GigCompletionDetailResponse],
    summary="Get gig completion details and evidence",
)
async def get_gig_completion(
    gig_id: uuid.UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[GigCompletionDetailResponse]:
    """Retrieve completion submission, evidence photos, and confirmation status for customer or assigned worker."""
    result = CompletionService.get_completion(
        user=current_user,
        gig_id=gig_id,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.post(
    "/gigs/{gig_id}/completion/confirm",
    response_model=ResponseEnvelope[CompletionConfirmationResponse],
    summary="Customer confirms completion or requests rework",
)
async def confirm_gig_completion(
    gig_id: uuid.UUID,
    request: CompletionConfirmationRequest,
    current_user: User = Depends(require_role(UserRole.CUSTOMER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[CompletionConfirmationResponse]:
    """Customer approves completion (transitioning gig to CUSTOMER_CONFIRMED) or requests rework (returning gig to IN_PROGRESS)."""
    result = CompletionService.confirm_completion(
        customer_user=current_user,
        gig_id=gig_id,
        request=request,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.get(
    "/gigs/{gig_id}/payment",
    response_model=ResponseEnvelope[PaymentResponse],
    summary="Get payment details and status for gig",
)
async def get_gig_payment(
    gig_id: uuid.UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[PaymentResponse]:
    """Retrieve payment details, authoritative amount, status, and UPI deep-link for customer or assigned worker."""
    result = PaymentService.get_payment_status(
        user=current_user,
        gig_id=gig_id,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.post(
    "/gigs/{gig_id}/payment",
    response_model=ResponseEnvelope[PaymentResponse],
    summary="Customer records payment (CASH or UPI)",
)
async def record_gig_payment(
    gig_id: uuid.UUID,
    request: PaymentCreateRequest,
    current_user: User = Depends(require_role(UserRole.CUSTOMER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[PaymentResponse]:
    """Customer records payment execution. Method is immutable once paid; retries with same method are idempotent."""
    result = PaymentService.record_payment(
        customer_user=current_user,
        gig_id=gig_id,
        request=request,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.post(
    "/gigs/{gig_id}/payment/confirm-receipt",
    response_model=ResponseEnvelope[PaymentResponse],
    summary="Worker confirms receipt of payment",
)
async def confirm_gig_payment_receipt(
    gig_id: uuid.UUID,
    request: PaymentReceiptConfirmRequest = PaymentReceiptConfirmRequest(),
    current_user: User = Depends(require_role(UserRole.WORKER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[PaymentResponse]:
    """Assigned worker acknowledges receipt of payment, transitioning gig to fully COMPLETED. Idempotent on retries."""
    result = PaymentService.confirm_receipt(
        worker_user=current_user,
        gig_id=gig_id,
        request=request,
        db=db,
    )
    return ResponseEnvelope(data=result)


# ============================================================================
# SPRINT 9: VISITATION DIAGNOSTICS & PROPOSALS
# ============================================================================


@router.post(
    "/gigs/{gig_id}/visitation/request",
    response_model=ResponseEnvelope[VisitationResponse],
    summary="Customer requests visitation inspection",
)
async def request_visitation(
    gig_id: uuid.UUID,
    current_user: User = Depends(require_role(UserRole.CUSTOMER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[VisitationResponse]:
    """Customer opens/converts gig to VISITATION workflow with fixed ₹100 visitation charge."""
    result = VisitationService.request_visitation(
        customer=current_user,
        gig_id=gig_id,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.get(
    "/gigs/{gig_id}/visitation",
    response_model=ResponseEnvelope[VisitationResponse],
    summary="Retrieve visitation state and proposal history",
)
async def get_visitation(
    gig_id: uuid.UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[VisitationResponse]:
    """Inspect visitation diagnostics, proposed tasks, and caller capabilities."""
    result = VisitationService.get_visitation_details(
        user=current_user,
        gig_id=gig_id,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.post(
    "/gigs/{gig_id}/visitation/proposals",
    response_model=ResponseEnvelope[VisitationProposalResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Worker submits task proposal following visitation inspection",
)
async def submit_visitation_proposal(
    gig_id: uuid.UUID,
    payload: VisitationProposalCreateRequest,
    current_user: User = Depends(require_role(UserRole.WORKER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[VisitationProposalResponse]:
    """Assigned worker submits itemized catalogue tasks within category. Backend computes authoritative price."""
    result = VisitationService.submit_proposal(
        worker=current_user,
        gig_id=gig_id,
        payload=payload,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.post(
    "/gigs/{gig_id}/visitation/proposals/{proposal_id}/accept",
    response_model=ResponseEnvelope[VisitationProposalResponse],
    summary="Customer accepts worker proposal",
)
async def accept_visitation_proposal(
    gig_id: uuid.UUID,
    proposal_id: uuid.UUID,
    current_user: User = Depends(require_role(UserRole.CUSTOMER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[VisitationProposalResponse]:
    """Customer accepts proposal. ₹100 visitation charge is absorbed into final work payment (Section 43)."""
    result = VisitationService.accept_proposal(
        customer=current_user,
        gig_id=gig_id,
        proposal_id=proposal_id,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.post(
    "/gigs/{gig_id}/visitation/proposals/{proposal_id}/reject",
    response_model=ResponseEnvelope[VisitationProposalResponse],
    summary="Customer rejects worker proposal",
)
async def reject_visitation_proposal(
    gig_id: uuid.UUID,
    proposal_id: uuid.UUID,
    current_user: User = Depends(require_role(UserRole.CUSTOMER)),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[VisitationProposalResponse]:
    """Customer rejects proposal. Fixed ₹100 visitation charge remains payable; no work payment created (Section 43)."""
    result = VisitationService.reject_proposal(
        customer=current_user,
        gig_id=gig_id,
        proposal_id=proposal_id,
        db=db,
    )
    return ResponseEnvelope(data=result)




