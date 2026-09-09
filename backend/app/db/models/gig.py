import uuid
from datetime import date, time, datetime
from typing import List, Optional, TYPE_CHECKING
from sqlalchemy import (
    String,
    Text,
    Boolean,
    ForeignKey,
    Integer,
    Numeric,
    Date,
    Time,
    DateTime,
    Enum as SQLEnum,
    UniqueConstraint,
    Index,
    func,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import BaseModel
from app.db.models.enums import (
    GigType,
    GigStatus,
    MaterialProcurementMode,
    OpportunityStatus,
)

if TYPE_CHECKING:
    from app.db.models.user import User
    from app.db.models.cooperative import Cooperative
    from app.db.models.service import ServiceCategory, ServiceTask
    from app.db.models.completion import CompletionSubmission, CompletionConfirmation
    from app.db.models.payment import Payment, MaterialReceipt
    from app.db.models.review import Review
    from app.db.models.visitation import VisitationProposal
    from app.db.models.cancellation import GigCancellation, RescheduleRequest, PreviousWorkerRequest
    from app.db.models.communication import Conversation, GigEvent


class Gig(BaseModel):
    """Central transactional entity for customer household gigs.

    Matches 04_DATABASE_DESIGN.md (Section 12 & Section 13).
    """

    __tablename__ = "gigs"

    customer_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    cooperative_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("cooperatives.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    category_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("service_categories.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    gig_type: Mapped[GigType] = mapped_column(
        SQLEnum(GigType, native_enum=False, create_constraint=True, length=20),
        default=GigType.NORMAL,
        nullable=False,
    )
    status: Mapped[GigStatus] = mapped_column(
        SQLEnum(GigStatus, native_enum=False, create_constraint=True, length=30),
        default=GigStatus.DRAFT,
        nullable=False,
        index=True,
    )
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    instructions: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    address: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    latitude: Mapped[Optional[float]] = mapped_column(Numeric(10, 7), nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Numeric(10, 7), nullable=True)
    google_maps_link: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    scheduled_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True, index=True)
    scheduled_start_time: Mapped[Optional[time]] = mapped_column(Time, nullable=True)
    scheduled_end_time: Mapped[Optional[time]] = mapped_column(Time, nullable=True)
    expected_duration_minutes: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    is_emergency: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    acceptance_deadline: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    material_procurement_mode: Mapped[MaterialProcurementMode] = mapped_column(
        SQLEnum(MaterialProcurementMode, native_enum=False, create_constraint=True, length=30),
        default=MaterialProcurementMode.CUSTOMER_PURCHASES,
        nullable=False,
    )

    # Immutable pricing snapshots calculated at gig creation / posting
    base_price: Mapped[float] = mapped_column(Numeric(10, 2), default=0.00, nullable=False)
    minimum_billable_minutes_snapshot: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    base_rate_per_minute_snapshot: Mapped[Optional[float]] = mapped_column(
        Numeric(10, 2), nullable=True
    )

    selected_worker_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    # Relationships
    customer: Mapped["User"] = relationship("User", foreign_keys=[customer_id])
    selected_worker: Mapped[Optional["User"]] = relationship(
        "User", foreign_keys=[selected_worker_id]
    )
    cooperative: Mapped["Cooperative"] = relationship("Cooperative", back_populates="gigs")
    category: Mapped["ServiceCategory"] = relationship("ServiceCategory", back_populates="gigs")
    gig_tasks: Mapped[List["GigTask"]] = relationship(
        "GigTask", back_populates="gig", cascade="all, delete-orphan"
    )
    opportunities: Mapped[List["GigWorkerOpportunity"]] = relationship(
        "GigWorkerOpportunity", back_populates="gig", cascade="all, delete-orphan"
    )
    completion_submissions: Mapped[List["CompletionSubmission"]] = relationship(
        "CompletionSubmission", back_populates="gig", cascade="all, delete-orphan"
    )
    completion_confirmations: Mapped[List["CompletionConfirmation"]] = relationship(
        "CompletionConfirmation", back_populates="gig", cascade="all, delete-orphan"
    )
    payments: Mapped[List["Payment"]] = relationship(
        "Payment", back_populates="gig", cascade="all, delete-orphan"
    )
    material_receipts: Mapped[List["MaterialReceipt"]] = relationship(
        "MaterialReceipt", back_populates="gig", cascade="all, delete-orphan"
    )
    reviews: Mapped[List["Review"]] = relationship(
        "Review", back_populates="gig", cascade="all, delete-orphan"
    )
    visitation_proposals: Mapped[List["VisitationProposal"]] = relationship(
        "VisitationProposal", back_populates="gig", cascade="all, delete-orphan"
    )
    cancellations: Mapped[List["GigCancellation"]] = relationship(
        "GigCancellation", back_populates="gig", cascade="all, delete-orphan"
    )
    reschedule_requests: Mapped[List["RescheduleRequest"]] = relationship(
        "RescheduleRequest", back_populates="gig", cascade="all, delete-orphan"
    )
    previous_worker_requests: Mapped[List["PreviousWorkerRequest"]] = relationship(
        "PreviousWorkerRequest", back_populates="gig", cascade="all, delete-orphan"
    )
    conversation: Mapped[Optional["Conversation"]] = relationship(
        "Conversation", back_populates="gig", uselist=False, cascade="all, delete-orphan"
    )
    events: Mapped[List["GigEvent"]] = relationship(
        "GigEvent", back_populates="gig", cascade="all, delete-orphan"
    )


class GigTask(BaseModel):
    """Many-to-many relationship linking a gig to selected service tasks.

    Matches 04_DATABASE_DESIGN.md (Section 14.1).
    """

    __tablename__ = "gig_tasks"

    gig_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("gigs.id", ondelete="CASCADE"),
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

    __table_args__ = (
        UniqueConstraint("gig_id", "task_id", name="uq_gig_task"),
    )

    gig: Mapped["Gig"] = relationship("Gig", back_populates="gig_tasks")
    task: Mapped["ServiceTask"] = relationship("ServiceTask", back_populates="gig_tasks")


class GigWorkerOpportunity(BaseModel):
    """An individual worker opportunity record for a gig.

    Matches 04_DATABASE_DESIGN.md (Section 18.1 & Section 21).
    Preserves immutable wage and final_score snapshot.
    """

    __tablename__ = "gig_worker_opportunities"

    gig_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("gigs.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    worker_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    status: Mapped[OpportunityStatus] = mapped_column(
        SQLEnum(OpportunityStatus, native_enum=False, length=20, create_constraint=True),
        default=OpportunityStatus.PENDING,
        nullable=False,
        index=True,
    )

    # Immutable historical offer snapshots
    base_price_snapshot: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    final_score_snapshot: Mapped[float] = mapped_column(Numeric(6, 5), nullable=False)
    premium_percentage: Mapped[float] = mapped_column(Numeric(6, 3), nullable=False)
    exact_wage: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)

    offered_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    responded_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    __table_args__ = (
        UniqueConstraint("gig_id", "worker_id", name="uq_gig_worker_opportunity"),
    )

    gig: Mapped["Gig"] = relationship("Gig", back_populates="opportunities")
    worker: Mapped["User"] = relationship("User")
