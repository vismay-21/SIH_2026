import uuid
from datetime import time, datetime
from typing import List, Optional, TYPE_CHECKING
from sqlalchemy import (
    String,
    Text,
    Boolean,
    ForeignKey,
    Integer,
    Numeric,
    SmallInteger,
    Time,
    DateTime,
    UniqueConstraint,
    Index,
    func,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import BaseModel

if TYPE_CHECKING:
    from app.db.models.user import WorkerProfile
    from app.db.models.gig import Gig, GigTask


class ServiceCategory(BaseModel):
    """Service Category catalog entry.

    Matches 04_DATABASE_DESIGN.md (Section 9.1).
    """

    __tablename__ = "service_categories"

    name: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    base_rate_per_minute: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    minimum_billable_minutes: Mapped[int] = mapped_column(Integer, default=45, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Relationships
    tasks: Mapped[List["ServiceTask"]] = relationship(
        "ServiceTask", back_populates="category", cascade="all, delete-orphan"
    )
    worker_categories: Mapped[List["WorkerCategory"]] = relationship(
        "WorkerCategory", back_populates="category", cascade="all, delete-orphan"
    )
    gigs: Mapped[List["Gig"]] = relationship("Gig", back_populates="category")


class ServiceTask(BaseModel):
    """Service Task catalog entry derived from WAGES.md.

    Matches 04_DATABASE_DESIGN.md (Section 10.1).
    """

    __tablename__ = "service_tasks"

    category_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("service_categories.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    standard_duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    base_price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Relationships
    category: Mapped["ServiceCategory"] = relationship("ServiceCategory", back_populates="tasks")
    gig_tasks: Mapped[List["GigTask"]] = relationship("GigTask", back_populates="task")


class WorkerCategory(BaseModel):
    """Many-to-many link between workers and service categories.

    Matches 04_DATABASE_DESIGN.md (Section 9.2).
    """

    __tablename__ = "worker_categories"

    worker_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("worker_profiles.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    category_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("service_categories.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    __table_args__ = (
        UniqueConstraint("worker_id", "category_id", name="uq_worker_category"),
    )

    worker_profile: Mapped["WorkerProfile"] = relationship("WorkerProfile", back_populates="categories")
    category: Mapped["ServiceCategory"] = relationship("ServiceCategory", back_populates="worker_categories")


class WorkerAvailability(BaseModel):
    """Weekly recurring availability window for workers.

    Matches 04_DATABASE_DESIGN.md (Section 11.1).
    """

    __tablename__ = "worker_availability"

    worker_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("worker_profiles.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    day_of_week: Mapped[int] = mapped_column(
        SmallInteger, nullable=False, index=True
    )  # 0=Monday ... 6=Sunday
    start_time: Mapped[time] = mapped_column(Time, nullable=False)
    end_time: Mapped[time] = mapped_column(Time, nullable=False)
    is_available: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    __table_args__ = (
        Index("ix_worker_availability_lookup", "worker_id", "day_of_week"),
    )

    worker_profile: Mapped["WorkerProfile"] = relationship(
        "WorkerProfile", back_populates="availabilities"
    )
