import uuid
from datetime import datetime
from typing import Any
from sqlalchemy import DateTime, Uuid, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy declarative models."""

    pass


class BaseModel(Base):
    """Abstract base model with standard UUID primary key and timestamp fields.

    Matches requirements from 04_DATABASE_DESIGN.md:
    - UUID primary keys
    - created_at TIMESTAMPTZ
    - updated_at TIMESTAMPTZ
    """

    __abstract__ = True

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        index=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    def to_dict(self) -> dict[str, Any]:
        """Convert model attributes to dictionary."""
        return {
            c.name: getattr(self, c.name)
            for c in self.__table__.columns
        }
