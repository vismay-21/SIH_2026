import uuid
from datetime import datetime
from typing import Optional, TYPE_CHECKING
from sqlalchemy import (
    ForeignKey,
    Numeric,
    DateTime,
    Enum as SQLEnum,
    func,
    Uuid,
    Index,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import BaseModel
from app.db.models.enums import ParticipationType

if TYPE_CHECKING:
    from app.db.models.user import User
    from app.db.models.gig import Gig


class WorkerExperienceRecord(BaseModel):
    """Historical record of individual job experience contributions.

    Matches 04_DATABASE_DESIGN.md (Section 22.1).
    Used to compute rolling experience score over the last N=50 jobs.
    """

    __tablename__ = "worker_experience_records"

    worker_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    gig_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("gigs.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    participation_type: Mapped[ParticipationType] = mapped_column(
        SQLEnum(ParticipationType, native_enum=False, length=30, create_constraint=True),
        nullable=False,
    )
    complexity_value: Mapped[float] = mapped_column(Numeric(6, 5), nullable=False)
    experience_contribution: Mapped[float] = mapped_column(Numeric(6, 5), nullable=False)

    __table_args__ = (
        Index("ix_worker_exp_lookup", "worker_id", "created_at"),
    )

    worker: Mapped["User"] = relationship("User")
    gig: Mapped["Gig"] = relationship("Gig")
