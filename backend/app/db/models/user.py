import uuid
from datetime import datetime
from typing import List, Optional, TYPE_CHECKING
from sqlalchemy import String, Text, Boolean, DateTime, ForeignKey, Enum as SQLEnum, Integer, Numeric, func, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, BaseModel
from app.db.models.enums import UserRole

if TYPE_CHECKING:
    from app.db.models.cooperative import Cooperative
    from app.db.models.service import WorkerCategory, WorkerAvailability
    from app.db.models.gig import Gig, GigWorkerOpportunity


class User(BaseModel):
    """Application-level user record.

    Matches 04_DATABASE_DESIGN.md (Section 4).
    The id matches Supabase Auth user UUID.
    """

    __tablename__ = "users"

    role: Mapped[UserRole] = mapped_column(
        SQLEnum(UserRole, native_enum=False, create_constraint=True, length=20),
        nullable=False,
        index=True,
    )
    cooperative_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("cooperatives.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    phone: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    email: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    profile_photo_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Relationships
    cooperative: Mapped["Cooperative"] = relationship("Cooperative", back_populates="users")
    customer_profile: Mapped[Optional["CustomerProfile"]] = relationship(
        "CustomerProfile", back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    worker_profile: Mapped[Optional["WorkerProfile"]] = relationship(
        "WorkerProfile", back_populates="user", uselist=False, cascade="all, delete-orphan"
    )


class CustomerProfile(Base):
    """One-to-one extension of a customer user.

    Matches 04_DATABASE_DESIGN.md (Section 6).
    """

    __tablename__ = "customer_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    address: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    user: Mapped["User"] = relationship("User", back_populates="customer_profile")


class WorkerProfile(Base):
    """One-to-one extension of a worker user.

    Matches 04_DATABASE_DESIGN.md (Section 7).
    """

    __tablename__ = "worker_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    address: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    city: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    aadhaar_document_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    aadhaar_uploaded_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    user: Mapped["User"] = relationship("User", back_populates="worker_profile")
    metrics: Mapped[Optional["WorkerMetric"]] = relationship(
        "WorkerMetric", back_populates="worker_profile", uselist=False, cascade="all, delete-orphan"
    )
    categories: Mapped[List["WorkerCategory"]] = relationship(
        "WorkerCategory", back_populates="worker_profile", cascade="all, delete-orphan"
    )
    availabilities: Mapped[List["WorkerAvailability"]] = relationship(
        "WorkerAvailability", back_populates="worker_profile", cascade="all, delete-orphan"
    )


class WorkerMetric(Base):
    """One-to-one performance and rating metrics table for workers.

    Matches 04_DATABASE_DESIGN.md (Section 8).
    """

    __tablename__ = "worker_metrics"

    worker_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("worker_profiles.user_id", ondelete="CASCADE"),
        primary_key=True,
    )
    completed_jobs_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    rating_average: Mapped[float] = mapped_column(Numeric(4, 3), default=0.000, nullable=False)
    rating_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    bayesian_score: Mapped[float] = mapped_column(Numeric(6, 5), default=0.70000, nullable=False)
    experience_score: Mapped[float] = mapped_column(Numeric(6, 5), default=0.00000, nullable=False)
    final_score: Mapped[float] = mapped_column(Numeric(6, 5), default=0.35000, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    worker_profile: Mapped["WorkerProfile"] = relationship("WorkerProfile", back_populates="metrics")
