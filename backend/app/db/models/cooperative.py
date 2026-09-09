import uuid
from typing import List, TYPE_CHECKING
from sqlalchemy import String, Text, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import BaseModel

if TYPE_CHECKING:
    from app.db.models.user import User
    from app.db.models.gig import Gig


class Cooperative(BaseModel):
    """Cooperative entity representing the labour cooperative.

    From 04_DATABASE_DESIGN.md (Section 5).
    """

    __tablename__ = "cooperatives"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    city: Mapped[str] = mapped_column(String(100), nullable=False)
    service_area: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Relationships
    users: Mapped[List["User"]] = relationship("User", back_populates="cooperative")
    gigs: Mapped[List["Gig"]] = relationship("Gig", back_populates="cooperative")
