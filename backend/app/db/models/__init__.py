"""SQLAlchemy Models package for Sahakaar Seva.

Implements the complete 04_DATABASE_DESIGN.md schema (31 tables).
"""

from app.db.base import Base, BaseModel
from app.db.models.enums import (
    UserRole,
    GigType,
    GigStatus,
    MaterialProcurementMode,
    OpportunityStatus,
    ParticipationType,
    WorkerParticipationClassification,
    WorkerParticipationStatus,
    ReviewerRole,
    PaymentMethod,
    PaymentStatus,
    VisitationProposalStatus,
    RescheduleStatus,
    PreviousWorkerRequestStatus,
)
from app.db.models.cooperative import Cooperative
from app.db.models.user import User, CustomerProfile, WorkerProfile, WorkerMetric
from app.db.models.service import (
    ServiceCategory,
    ServiceTask,
    WorkerCategory,
    WorkerAvailability,
)
from app.db.models.gig import Gig, GigTask, GigWorkerOpportunity
from app.db.models.experience import WorkerExperienceRecord
from app.db.models.review import Review, ReviewQuestion, ReviewAnswer
from app.db.models.completion import (
    CompletionSubmission,
    CompletionEvidence,
    CompletionConfirmation,
)
from app.db.models.payment import Payment, MaterialReceipt
from app.db.models.multi_worker import WorkerParticipation
from app.db.models.visitation import VisitationProposal, VisitationProposalTask
from app.db.models.cancellation import (
    GigCancellation,
    RescheduleRequest,
    PreviousWorkerRequest,
)
from app.db.models.communication import (
    Conversation,
    Message,
    Notification,
    GigEvent,
)

__all__ = [
    "Base",
    "BaseModel",
    # Enums
    "UserRole",
    "GigType",
    "GigStatus",
    "MaterialProcurementMode",
    "OpportunityStatus",
    "ParticipationType",
    "WorkerParticipationClassification",
    "WorkerParticipationStatus",
    "ReviewerRole",
    "PaymentMethod",
    "PaymentStatus",
    "VisitationProposalStatus",
    "RescheduleStatus",
    "PreviousWorkerRequestStatus",
    # 31 Tables / Models
    "Cooperative",
    "User",
    "CustomerProfile",
    "WorkerProfile",
    "WorkerMetric",
    "ServiceCategory",
    "ServiceTask",
    "WorkerCategory",
    "WorkerAvailability",
    "Gig",
    "GigTask",
    "GigWorkerOpportunity",
    "WorkerExperienceRecord",
    "Review",
    "ReviewQuestion",
    "ReviewAnswer",
    "CompletionSubmission",
    "CompletionEvidence",
    "CompletionConfirmation",
    "Payment",
    "MaterialReceipt",
    "WorkerParticipation",
    "VisitationProposal",
    "VisitationProposalTask",
    "GigCancellation",
    "RescheduleRequest",
    "PreviousWorkerRequest",
    "Conversation",
    "Message",
    "Notification",
    "GigEvent",
]
