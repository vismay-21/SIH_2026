import uuid
from typing import Optional
from sqlalchemy.orm import Session

from app.db.models.payment import Payment
from app.db.models.enums import PaymentStatus, PaymentType


class CustomerFinancialGuard:
    """Financial integrity guard enforcing settlement of obligations before new actions."""

    @staticmethod
    def has_outstanding_cancellation_payment(customer_id: uuid.UUID, db: Session) -> bool:
        """Returns True if the customer has any unsettled cancellation fee obligations.
        
        A cancellation payment is considered unsettled if its status != WORKER_CONFIRMED.
        """
        unsettled = (
            db.query(Payment)
            .filter(
                Payment.customer_id == customer_id,
                Payment.payment_type == PaymentType.CANCELLATION,
                Payment.status != PaymentStatus.WORKER_CONFIRMED,
            )
            .first()
        )
        return unsettled is not None

    @staticmethod
    def get_outstanding_cancellation_payment(
        customer_id: uuid.UUID, db: Session
    ) -> Optional[Payment]:
        """Returns the first unsettled cancellation fee payment record for the customer, if any."""
        return (
            db.query(Payment)
            .filter(
                Payment.customer_id == customer_id,
                Payment.payment_type == PaymentType.CANCELLATION,
                Payment.status != PaymentStatus.WORKER_CONFIRMED,
            )
            .first()
        )
