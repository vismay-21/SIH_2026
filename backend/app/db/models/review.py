import uuid
from typing import List, Optional, TYPE_CHECKING
from sqlalchemy import (
    String,
    Text,
    Boolean,
    ForeignKey,
    Integer,
    Numeric,
    Enum as SQLEnum,
    UniqueConstraint,
    Index,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import BaseModel
from app.db.models.enums import ReviewerRole

if TYPE_CHECKING:
    from app.db.models.user import User
    from app.db.models.gig import Gig


class Review(BaseModel):
    """Two-way structured review record for completed gigs.

    Matches 04_DATABASE_DESIGN.md (Section 25.1).
    """

    __tablename__ = "reviews"

    gig_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("gigs.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    reviewer_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    reviewee_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    reviewer_role: Mapped[ReviewerRole] = mapped_column(
        SQLEnum(ReviewerRole, native_enum=False, length=20, create_constraint=True),
        nullable=False,
    )
    overall_rating: Mapped[float] = mapped_column(Numeric(3, 2), nullable=False)

    __table_args__ = (
        UniqueConstraint("gig_id", "reviewer_id", "reviewee_id", name="uq_review_direction"),
        Index("ix_reviews_reviewee", "reviewee_id"),
    )

    gig: Mapped["Gig"] = relationship("Gig", back_populates="reviews")
    reviewer: Mapped["User"] = relationship("User", foreign_keys=[reviewer_id])
    reviewee: Mapped["User"] = relationship("User", foreign_keys=[reviewee_id])
    answers: Mapped[List["ReviewAnswer"]] = relationship(
        "ReviewAnswer", back_populates="review", cascade="all, delete-orphan"
    )


class ReviewQuestion(BaseModel):
    """Structured MCQ review question template.

    Matches 04_DATABASE_DESIGN.md (Section 26.1).
    """

    __tablename__ = "review_questions"

    target_role: Mapped[ReviewerRole] = mapped_column(
        SQLEnum(ReviewerRole, native_enum=False, length=20, create_constraint=True),
        nullable=False,
    )
    question_text: Mapped[str] = mapped_column(Text, nullable=False)
    display_order: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    answers: Mapped[List["ReviewAnswer"]] = relationship("ReviewAnswer", back_populates="question")


class ReviewAnswer(BaseModel):
    """Answer value for a specific review question.

    Matches 04_DATABASE_DESIGN.md (Section 26.2).
    """

    __tablename__ = "review_answers"

    review_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("reviews.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    question_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("review_questions.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    answer_value: Mapped[int] = mapped_column(Integer, nullable=False)  # 1 to 5 stars

    review: Mapped["Review"] = relationship("Review", back_populates="answers")
    question: Mapped["ReviewQuestion"] = relationship("ReviewQuestion", back_populates="answers")
