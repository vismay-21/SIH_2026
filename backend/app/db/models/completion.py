import uuid
from datetime import datetime
from typing import List, Optional, TYPE_CHECKING
from sqlalchemy import (
    String,
    Text,
    Boolean,
    ForeignKey,
    DateTime,
    func,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import BaseModel

if TYPE_CHECKING:
    from app.db.models.user import User
    from app.db.models.gig import Gig


class CompletionSubmission(BaseModel):
    """Worker completion submission containing notes and photo evidence.

    Matches 04_DATABASE_DESIGN.md (Section 28.1).
    """

    __tablename__ = "completion_submissions"

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
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    submitted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    gig: Mapped["Gig"] = relationship("Gig", back_populates="completion_submissions")
    worker: Mapped["User"] = relationship("User")
    evidence_files: Mapped[List["CompletionEvidence"]] = relationship(
        "CompletionEvidence", back_populates="submission", cascade="all, delete-orphan"
    )


class CompletionEvidence(BaseModel):
    """Photo evidence attached to a completion submission.

    Matches 04_DATABASE_DESIGN.md (Section 28.2).
    """

    __tablename__ = "completion_evidence"

    submission_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("completion_submissions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    file_url: Mapped[str] = mapped_column(Text, nullable=False)
    file_type: Mapped[str] = mapped_column(String(50), nullable=False)

    submission: Mapped["CompletionSubmission"] = relationship(
        "CompletionSubmission", back_populates="evidence_files"
    )


class CompletionConfirmation(BaseModel):
    """Customer approval or rejection of submitted work completion.

    Matches 04_DATABASE_DESIGN.md (Section 29.1).
    """

    __tablename__ = "completion_confirmations"

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
    confirmed: Mapped[bool] = mapped_column(Boolean, nullable=False)
    response_note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    gig: Mapped["Gig"] = relationship("Gig", back_populates="completion_confirmations")
    customer: Mapped["User"] = relationship("User")
