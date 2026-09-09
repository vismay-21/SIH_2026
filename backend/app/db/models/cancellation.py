import uuid
from datetime import date, time, datetime
from typing import Optional, TYPE_CHECKING
from sqlalchemy import (
    Text,
    ForeignKey,
    Numeric,
    Date,
    Time,
    DateTime,
    Enum as SQLEnum,
    func,
    Uuid,
    Index,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import BaseModel
from app.db.models.enums import RescheduleStatus, PreviousWorkerRequestStatus

if TYPE_CHECKING:
    from app.db.models.user import User
    from app.db.models.gig import Gig
    from app.db.models.payment import Payment


class GigCancellation(BaseModel):
    """Audit record for customer or worker gig cancellations.

    Matches 04_DATABASE_DESIGN.md (Section 44.1).
    """

    __tablename__ = "gig_cancellations"

    gig_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("gigs.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    cancelled_by: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    fee_amount: Mapped[float] = mapped_column(Numeric(10, 2), default=0.00, nullable=False)

    gig: Mapped["Gig"] = relationship("Gig", back_populates="cancellations")
    user: Mapped["User"] = relationship("User")
    payment: Mapped[Optional["Payment"]] = relationship(
        "Payment", back_populates="cancellation", uselist=False
    )


class RescheduleRequest(BaseModel):
    """Rescheduling negotiation record initiated by customer or worker.

    Matches 04_DATABASE_DESIGN.md (Section 46.1).
    """

    __tablename__ = "reschedule_requests"

    gig_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("gigs.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    requested_by: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    proposed_date: Mapped[date] = mapped_column(Date, nullable=False)
    proposed_start_time: Mapped[time] = mapped_column(Time, nullable=False)
    proposed_end_time: Mapped[time] = mapped_column(Time, nullable=False)
    reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    status: Mapped[RescheduleStatus] = mapped_column(
        SQLEnum(RescheduleStatus, native_enum=False, length=30, create_constraint=True),
        default=RescheduleStatus.REQUESTED,
        nullable=False,
        index=True,
    )
    responded_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=True,
    )
    responded_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    gig: Mapped["Gig"] = relationship("Gig", back_populates="reschedule_requests")
    requester: Mapped["User"] = relationship("User", foreign_keys=[requested_by])
    responder: Mapped[Optional["User"]] = relationship("User", foreign_keys=[responded_by])


class PreviousWorkerRequest(BaseModel):
    """Direct booking request to a previously hired worker.

    Matches 04_DATABASE_DESIGN.md (Section 50.1).
    """

    __tablename__ = "previous_worker_requests"

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
    status: Mapped[PreviousWorkerRequestStatus] = mapped_column(
        SQLEnum(PreviousWorkerRequestStatus, native_enum=False, length=30, create_constraint=True),
        default=PreviousWorkerRequestStatus.REQUESTED,
        nullable=False,
        index=True,
    )
    responded_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    gig: Mapped["Gig"] = relationship("Gig", back_populates="previous_worker_requests")
    customer: Mapped["User"] = relationship("User", foreign_keys=[customer_id])
    worker: Mapped["User"] = relationship("User", foreign_keys=[worker_id])
