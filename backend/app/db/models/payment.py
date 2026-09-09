import uuid
from datetime import datetime
from typing import Optional, TYPE_CHECKING
from sqlalchemy import (
    Text,
    ForeignKey,
    Numeric,
    DateTime,
    Enum as SQLEnum,
    Index,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import BaseModel
from app.db.models.enums import PaymentMethod, PaymentStatus

if TYPE_CHECKING:
    from app.db.models.user import User
    from app.db.models.gig import Gig


class Payment(BaseModel):
    """Payment record tracking Cash and UPI deep-link settlements.

    Matches 04_DATABASE_DESIGN.md (Section 30.1).
    Audit trail: PENDING -> CUSTOMER_PAID -> WORKER_CONFIRMED.
    """

    __tablename__ = "payments"

    gig_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("gigs.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    customer_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    worker_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    payment_method: Mapped[PaymentMethod] = mapped_column(
        SQLEnum(PaymentMethod, native_enum=False, length=20, create_constraint=True),
        nullable=False,
    )
    status: Mapped[PaymentStatus] = mapped_column(
        SQLEnum(PaymentStatus, native_enum=False, length=30, create_constraint=True),
        default=PaymentStatus.PENDING,
        nullable=False,
        index=True,
    )
    paid_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    worker_confirmed_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    __table_args__ = (
        Index("ix_payments_lookup", "gig_id", "status"),
    )

    gig: Mapped["Gig"] = relationship("Gig", back_populates="payments")
    customer: Mapped["User"] = relationship("User", foreign_keys=[customer_id])
    worker: Mapped["User"] = relationship("User", foreign_keys=[worker_id])


class MaterialReceipt(BaseModel):
    """Itemized material receipt uploaded by worker when purchasing materials.

    Matches 04_DATABASE_DESIGN.md (Section 33.1).
    """

    __tablename__ = "material_receipts"

    gig_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("gigs.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    worker_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    receipt_url: Mapped[str] = mapped_column(Text, nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    gig: Mapped["Gig"] = relationship("Gig", back_populates="material_receipts")
    worker: Mapped["User"] = relationship("User")
