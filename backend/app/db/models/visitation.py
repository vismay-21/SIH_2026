import uuid
from datetime import datetime
from typing import List, Optional, TYPE_CHECKING
from sqlalchemy import (
    ForeignKey,
    Numeric,
    Integer,
    DateTime,
    Enum as SQLEnum,
    func,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import BaseModel
from app.db.models.enums import VisitationProposalStatus

if TYPE_CHECKING:
    from app.db.models.user import User
    from app.db.models.gig import Gig
    from app.db.models.service import ServiceTask


class VisitationProposal(BaseModel):
    """Task proposal submitted by a worker following an in-person visitation.

    Matches 04_DATABASE_DESIGN.md (Section 40.1).
    Fixed ₹100 visitation charge is waived/absorbed if customer accepts.
    """

    __tablename__ = "visitation_proposals"

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
    base_price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    proposed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    status: Mapped[VisitationProposalStatus] = mapped_column(
        SQLEnum(VisitationProposalStatus, native_enum=False, length=20, create_constraint=True),
        default=VisitationProposalStatus.PENDING,
        nullable=False,
        index=True,
    )
    customer_responded_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    gig: Mapped["Gig"] = relationship("Gig", back_populates="visitation_proposals")
    worker: Mapped["User"] = relationship("User")
    proposal_tasks: Mapped[List["VisitationProposalTask"]] = relationship(
        "VisitationProposalTask", back_populates="proposal", cascade="all, delete-orphan"
    )


class VisitationProposalTask(BaseModel):
    """Itemized task included inside a worker's visitation proposal.

    Matches 04_DATABASE_DESIGN.md (Section 41.1).
    """

    __tablename__ = "visitation_proposal_tasks"

    proposal_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("visitation_proposals.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    task_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("service_tasks.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    standard_duration_minutes_snapshot: Mapped[int] = mapped_column(Integer, nullable=False)
    base_price_snapshot: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)

    proposal: Mapped["VisitationProposal"] = relationship(
        "VisitationProposal", back_populates="proposal_tasks"
    )
    task: Mapped["ServiceTask"] = relationship("ServiceTask")
