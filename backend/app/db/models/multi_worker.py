import uuid
from datetime import datetime
from typing import Optional, TYPE_CHECKING
from sqlalchemy import (
    ForeignKey,
    Numeric,
    DateTime,
    Enum as SQLEnum,
    Uuid,
    Index,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import BaseModel
from app.db.models.enums import WorkerParticipationStatus, WorkerParticipationClassification

if TYPE_CHECKING:
    from app.db.models.user import User
    from app.db.models.gig import Gig


class WorkerParticipation(BaseModel):
    """Multi-worker invitation and participation tracking.

    Matches 04_DATABASE_DESIGN.md (Section 34.1).
    Classifications: ROOKIE (0.5x complexity credit) vs EQUAL_SHARING.
    """

    __tablename__ = "worker_participations"

    gig_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("gigs.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    inviting_worker_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    additional_worker_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    status: Mapped[WorkerParticipationStatus] = mapped_column(
        SQLEnum(WorkerParticipationStatus, native_enum=False, length=20, create_constraint=True),
        default=WorkerParticipationStatus.PENDING,
        nullable=False,
        index=True,
    )
    classification: Mapped[WorkerParticipationClassification] = mapped_column(
        SQLEnum(WorkerParticipationClassification, native_enum=False, length=30, create_constraint=True),
        nullable=False,
    )
    experience_contribution: Mapped[Optional[float]] = mapped_column(
        Numeric(6, 5), nullable=True
    )
    responded_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    __table_args__ = (
        Index("ix_worker_participations_lookup", "gig_id", "additional_worker_id"),
    )

    gig: Mapped["Gig"] = relationship("Gig")
    inviting_worker: Mapped["User"] = relationship("User", foreign_keys=[inviting_worker_id])
    additional_worker: Mapped["User"] = relationship("User", foreign_keys=[additional_worker_id])
