import uuid
from decimal import Decimal
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.models.user import User
from app.db.models.gig import Gig, GigWorkerOpportunity
from app.db.models.payment import Payment
from app.db.models.visitation import VisitationProposal
from app.db.models.communication import GigEvent, Notification
from app.db.models.enums import (
    GigType,
    GigStatus,
    PaymentMethod,
    PaymentStatus,
    PaymentType,
    VisitationProposalStatus,
)
from app.core.exceptions import (
    NotFoundException,
    BadRequestException,
    ForbiddenException,
    ConflictException,
)
from app.schemas.payment import (
    PaymentCreateRequest,
    PaymentReceiptConfirmRequest,
    PaymentResponse,
)


class PaymentService:
    """Core financial lifecycle service conforming to 05_API_DESIGN.md Section 24, 06_BACKEND_SPRINTS.md Sections 31 & 34."""

    @classmethod
    def get_authoritative_amount(cls, gig: Gig, db: Session) -> Decimal:
        """Resolve authoritative payable amount.

        - If gig is CANCELLED:
          * If a CANCELLATION payment exists: payment.amount (₹50.00)
          * Otherwise: 0.00
        - For VISITATION gigs:
          * If an ACCEPTED proposal exists: proposal.base_price (e.g. ₹300, ₹100 absorbed)
          * Otherwise (rejected or visit-only): fixed ₹100 visitation charge
        - For NORMAL gigs:
          * Selected worker's immutable GigWorkerOpportunity.exact_wage snapshot
        """
        if gig.status == GigStatus.CANCELLED:
            cancellation_payment = (
                db.query(Payment)
                .filter(
                    Payment.gig_id == gig.id,
                    Payment.payment_type == PaymentType.CANCELLATION,
                )
                .first()
            )
            if cancellation_payment:
                return Decimal(str(cancellation_payment.amount))
            return Decimal(str(settings.CANCELLATION_FEE_BEFORE_SELECTION))

        if gig.gig_type == GigType.VISITATION:
            accepted_proposal = (
                db.query(VisitationProposal)
                .filter(
                    VisitationProposal.gig_id == gig.id,
                    VisitationProposal.status == VisitationProposalStatus.ACCEPTED,
                )
                .first()
            )
            if accepted_proposal:
                return Decimal(str(accepted_proposal.base_price))
            return Decimal(str(settings.VISITATION_FEE))

        # Standard NORMAL gig: immutable opportunity exact_wage
        opp = (
            db.query(GigWorkerOpportunity)
            .filter(
                GigWorkerOpportunity.gig_id == gig.id,
                GigWorkerOpportunity.worker_id == gig.selected_worker_id,
            )
            .first()
        )
        if opp and opp.exact_wage is not None:
            return Decimal(str(opp.exact_wage))
        return Decimal(str(gig.base_price))

    @staticmethod
    def _generate_upi_deeplink(
        worker_id: uuid.UUID,
        worker_name: str,
        gig_id: uuid.UUID,
        amount: Decimal,
    ) -> str:
        """Generate an informational standard UPI deep-link for mobile app dispatch."""
        pa = f"sahakaar.{str(worker_id)[:8]}@upi"
        pn = worker_name.replace(" ", "%20")
        am = f"{amount:.2f}"
        tn = f"Gig-{str(gig_id)[:8]}"
        return f"upi://pay?pa={pa}&pn={pn}&am={am}&cu=INR&tn={tn}"

    @classmethod
    def get_payment_status(
        cls,
        user: User,
        gig_id: uuid.UUID,
        db: Session,
    ) -> PaymentResponse:
        """Fetch current payment record and action capabilities for authorized participants."""
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

        payment = db.query(Payment).filter(Payment.gig_id == gig.id).first()

        authorized_users = {gig.customer_id}
        if gig.selected_worker_id:
            authorized_users.add(gig.selected_worker_id)
        if payment and payment.worker_id:
            authorized_users.add(payment.worker_id)

        if user.id not in authorized_users:
            raise ForbiddenException("You do not have access to this gig's payment details", code="FORBIDDEN")

        worker_id_target = (
            payment.worker_id
            if payment
            else gig.selected_worker_id
        )

        worker_name = "Sahakaar Worker"
        if payment and payment.worker:
            worker_name = payment.worker.full_name
        elif gig.selected_worker:
            worker_name = gig.selected_worker.full_name

        if not payment:
            authoritative_amount = cls.get_authoritative_amount(gig, db)
            can_pay = (
                user.id == gig.customer_id
                and gig.status in (GigStatus.CUSTOMER_CONFIRMED, GigStatus.PAYMENT_PENDING)
                and gig.selected_worker_id is not None
            )
            upi_link = None
            if worker_id_target:
                upi_link = cls._generate_upi_deeplink(
                    worker_id=worker_id_target,
                    worker_name=worker_name,
                    gig_id=gig.id,
                    amount=authoritative_amount,
                )

            return PaymentResponse(
                id=uuid.uuid4(),  # ephemeral ID before record creation
                gig_id=gig.id,
                customer_id=gig.customer_id,
                worker_id=worker_id_target or uuid.UUID(int=0),
                amount=authoritative_amount,
                payment_method=None,
                payment_type=PaymentType.LABOUR,
                status=PaymentStatus.PENDING,
                upi_deeplink=upi_link,
                paid_at=None,
                worker_confirmed_at=None,
                can_pay=can_pay,
                can_confirm=False,
                created_at=None,
                updated_at=None,
            )

        amount_decimal = Decimal(str(payment.amount))
        upi_link = None
        if payment.payment_method == PaymentMethod.UPI and worker_id_target:
            upi_link = cls._generate_upi_deeplink(
                worker_id=worker_id_target,
                worker_name=worker_name,
                gig_id=gig.id,
                amount=amount_decimal,
            )

        if payment.payment_type == PaymentType.CANCELLATION:
            can_pay = (
                user.id == gig.customer_id
                and payment.status == PaymentStatus.PENDING
                and gig.status == GigStatus.CANCELLED
            )
            can_confirm = (
                user.id == worker_id_target
                and payment.status == PaymentStatus.CUSTOMER_PAID
                and gig.status == GigStatus.CANCELLED
            )
        else:
            can_pay = (
                user.id == gig.customer_id
                and payment.status == PaymentStatus.PENDING
                and gig.status in (GigStatus.CUSTOMER_CONFIRMED, GigStatus.PAYMENT_PENDING)
            )
            can_confirm = (
                user.id == worker_id_target
                and payment.status == PaymentStatus.CUSTOMER_PAID
                and gig.status == GigStatus.PAYMENT_CUSTOMER_PAID
            )

        return PaymentResponse(
            id=payment.id,
            gig_id=payment.gig_id,
            customer_id=payment.customer_id,
            worker_id=payment.worker_id,
            amount=amount_decimal,
            payment_method=payment.payment_method,
            payment_type=payment.payment_type,
            status=payment.status,
            upi_deeplink=upi_link,
            paid_at=payment.paid_at,
            worker_confirmed_at=payment.worker_confirmed_at,
            can_pay=can_pay,
            can_confirm=can_confirm,
            created_at=payment.created_at,
            updated_at=payment.updated_at,
        )

    @classmethod
    def record_payment(
        cls,
        customer_user: User,
        gig_id: uuid.UUID,
        request: PaymentCreateRequest,
        db: Session,
    ) -> PaymentResponse:
        """Customer records payment execution (CASH or UPI) with payment-method immutability and idempotency."""
        try:
            gig = db.query(Gig).filter(Gig.id == gig_id).with_for_update().first()
            if not gig:
                raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

            if gig.customer_id != customer_user.id:
                raise ForbiddenException("Only the gig customer can record payment", code="FORBIDDEN")

            payment = db.query(Payment).filter(Payment.gig_id == gig.id).with_for_update().first()

            # Handle Cancellation Payment Flow
            if payment and payment.payment_type == PaymentType.CANCELLATION:
                if payment.status in (PaymentStatus.CUSTOMER_PAID, PaymentStatus.WORKER_CONFIRMED):
                    if payment.payment_method != request.payment_method:
                        raise ConflictException(
                            f"Payment method is immutable once recorded as paid. Existing method: '{payment.payment_method.value}'.",
                            code="PAYMENT_METHOD_IMMUTABLE",
                        )
                    return cls.get_payment_status(customer_user, gig_id, db)

                if gig.status != GigStatus.CANCELLED or payment.status != PaymentStatus.PENDING:
                    raise BadRequestException(
                        f"Cancellation payment cannot be recorded in current gig status '{gig.status.value}' and payment status '{payment.status.value}'",
                        code="INVALID_PAYMENT_STATE",
                    )

                now_utc = datetime.now(timezone.utc)
                payment.payment_method = request.payment_method
                payment.status = PaymentStatus.CUSTOMER_PAID
                payment.paid_at = now_utc

                # GIG STATUS REMAINS CANCELLED - DO NOT MUTATE
                db.add(
                    GigEvent(
                        gig_id=gig.id,
                        actor_id=customer_user.id,
                        event_type="CANCELLATION_PAYMENT_CUSTOMER_PAID",
                        metadata_json={
                            "payment_method": request.payment_method.value,
                            "amount": str(payment.amount),
                            "payment_type": PaymentType.CANCELLATION.value,
                        },
                    )
                )

                db.add(
                    Notification(
                        recipient_id=payment.worker_id,
                        gig_id=gig.id,
                        type="CANCELLATION_PAYMENT_CUSTOMER_PAID",
                        title="Cancellation Fee Paid",
                        body=f"Customer marked {request.payment_method.value} payment of ₹{Decimal(str(payment.amount)):.2f} for cancelled gig. Please confirm receipt.",
                    )
                )

                db.commit()
                db.refresh(payment)
                return cls.get_payment_status(customer_user, gig_id, db)

            # Standard Labour Payment Flow
            if not gig.selected_worker_id:
                raise BadRequestException("Cannot pay for a gig with no selected worker", code="NO_SELECTED_WORKER")

            # Authoritative amount lookup
            authoritative_amount = cls.get_authoritative_amount(gig, db)

            # 1. Idempotency and Payment-Method Immutability
            if payment and payment.status in (PaymentStatus.CUSTOMER_PAID, PaymentStatus.WORKER_CONFIRMED):
                if payment.payment_method != request.payment_method:
                    raise ConflictException(
                        f"Payment method is immutable once recorded as paid. Existing method: '{payment.payment_method.value}'.",
                        code="PAYMENT_METHOD_IMMUTABLE",
                    )
                # Consistent retry: return existing payment safely without duplicate side effects
                return cls.get_payment_status(customer_user, gig_id, db)

            # 2. State Validation: must be CUSTOMER_CONFIRMED or PAYMENT_PENDING
            if gig.status not in (GigStatus.CUSTOMER_CONFIRMED, GigStatus.PAYMENT_PENDING):
                raise BadRequestException(
                    f"Payment cannot be initiated from current gig status '{gig.status.value}'",
                    code="INVALID_GIG_STATE",
                )

            now_utc = datetime.now(timezone.utc)
            if not payment:
                payment = Payment(
                    gig_id=gig.id,
                    customer_id=customer_user.id,
                    worker_id=gig.selected_worker_id,
                    amount=authoritative_amount,
                    payment_method=request.payment_method,
                    payment_type=PaymentType.LABOUR,
                    status=PaymentStatus.CUSTOMER_PAID,
                    paid_at=now_utc,
                )
                db.add(payment)
            else:
                payment.payment_method = request.payment_method
                payment.amount = authoritative_amount
                payment.payment_type = PaymentType.LABOUR
                payment.status = PaymentStatus.CUSTOMER_PAID
                payment.paid_at = now_utc

            # Advance gig state
            gig.status = GigStatus.PAYMENT_CUSTOMER_PAID

            # Audit event with precise decimal string formatting
            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=customer_user.id,
                    event_type="PAYMENT_CUSTOMER_PAID",
                    metadata_json={
                        "payment_method": request.payment_method.value,
                        "amount": str(authoritative_amount),
                    },
                )
            )

            # Notification to worker
            db.add(
                Notification(
                    recipient_id=gig.selected_worker_id,
                    gig_id=gig.id,
                    type="PAYMENT_CUSTOMER_PAID",
                    title="Payment Recorded",
                    body=f"Customer marked {request.payment_method.value} payment of ₹{authoritative_amount:.2f} as paid. Please confirm receipt.",
                )
            )

            db.commit()
            db.refresh(payment)

            return cls.get_payment_status(customer_user, gig_id, db)
        except Exception:
            db.rollback()
            raise

    @classmethod
    def confirm_receipt(
        cls,
        worker_user: User,
        gig_id: uuid.UUID,
        request: PaymentReceiptConfirmRequest,
        db: Session,
    ) -> PaymentResponse:
        """Worker confirms receipt of payment. Idempotent: repeated calls do not create duplicate events or transitions."""
        try:
            gig = db.query(Gig).filter(Gig.id == gig_id).with_for_update().first()
            if not gig:
                raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

            payment = db.query(Payment).filter(Payment.gig_id == gig.id).with_for_update().first()
            if not payment:
                raise BadRequestException(
                    "No payment record found for this gig. Customer must initiate payment first.",
                    code="PAYMENT_NOT_FOUND",
                )

            expected_worker_id = payment.worker_id if payment.worker_id else gig.selected_worker_id
            if expected_worker_id != worker_user.id:
                raise ForbiddenException("Only the designated worker can confirm receipt of payment", code="FORBIDDEN")

            # Handle Cancellation Payment Confirmation
            if payment.payment_type == PaymentType.CANCELLATION:
                if payment.status == PaymentStatus.WORKER_CONFIRMED:
                    return cls.get_payment_status(worker_user, gig_id, db)

                if payment.status != PaymentStatus.CUSTOMER_PAID:
                    raise BadRequestException(
                        f"Cannot confirm receipt when payment status is '{payment.status.value}'",
                        code="INVALID_PAYMENT_STATE",
                    )

                now_utc = datetime.now(timezone.utc)
                payment.status = PaymentStatus.WORKER_CONFIRMED
                payment.worker_confirmed_at = now_utc

                # GIG STATUS REMAINS CANCELLED - NEVER TRANSITION TO COMPLETED
                db.add(
                    GigEvent(
                        gig_id=gig.id,
                        actor_id=worker_user.id,
                        event_type="CANCELLATION_PAYMENT_WORKER_CONFIRMED",
                        metadata_json={
                            "payment_id": str(payment.id),
                            "amount": str(payment.amount),
                            "payment_method": payment.payment_method.value if payment.payment_method else None,
                            "payment_type": PaymentType.CANCELLATION.value,
                        },
                    )
                )

                db.add(
                    Notification(
                        recipient_id=gig.customer_id,
                        gig_id=gig.id,
                        type="CANCELLATION_PAYMENT_WORKER_CONFIRMED",
                        title="Cancellation Fee Confirmed",
                        body=f"Worker confirmed receipt of ₹{Decimal(str(payment.amount)):.2f} cancellation fee. Your account is clear.",
                    )
                )

                db.commit()
                db.refresh(payment)
                return cls.get_payment_status(worker_user, gig_id, db)

            # Standard Labour Payment Confirmation
            # Idempotency: if already confirmed and gig completed, return existing record safely
            if payment.status == PaymentStatus.WORKER_CONFIRMED and gig.status == GigStatus.COMPLETED:
                return cls.get_payment_status(worker_user, gig_id, db)

            # State validation: must be CUSTOMER_PAID
            if payment.status != PaymentStatus.CUSTOMER_PAID or gig.status != GigStatus.PAYMENT_CUSTOMER_PAID:
                raise BadRequestException(
                    f"Cannot confirm receipt when payment status is '{payment.status.value}' and gig status is '{gig.status.value}'",
                    code="INVALID_PAYMENT_STATE",
                )

            now_utc = datetime.now(timezone.utc)
            payment.status = PaymentStatus.WORKER_CONFIRMED
            payment.worker_confirmed_at = now_utc

            # Transition gig to fully COMPLETED
            gig.status = GigStatus.COMPLETED

            # Audit events with precise decimal representation
            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=worker_user.id,
                    event_type="PAYMENT_WORKER_CONFIRMED",
                    metadata_json={
                        "payment_id": str(payment.id),
                        "amount": str(payment.amount),
                        "payment_method": payment.payment_method.value,
                    },
                )
            )

            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=worker_user.id,
                    event_type="GIG_COMPLETED",
                    metadata_json={
                        "completed_at": now_utc.isoformat(),
                        "final_amount": str(payment.amount),
                    },
                )
            )

            # Notification to customer
            db.add(
                Notification(
                    recipient_id=gig.customer_id,
                    gig_id=gig.id,
                    type="GIG_COMPLETED",
                    title="Gig Completed!",
                    body=f"Worker confirmed receipt of payment. Gig {gig.id} is now complete.",
                )
            )

            db.commit()
            db.refresh(payment)

            return cls.get_payment_status(worker_user, gig_id, db)
        except Exception:
            db.rollback()
            raise
