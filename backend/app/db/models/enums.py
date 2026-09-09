import enum


class UserRole(str, enum.Enum):
    CUSTOMER = "CUSTOMER"
    WORKER = "WORKER"


class GigType(str, enum.Enum):
    NORMAL = "NORMAL"
    VISITATION = "VISITATION"


class GigStatus(str, enum.Enum):
    DRAFT = "DRAFT"
    POSTED = "POSTED"
    ACCEPTANCE_OPEN = "ACCEPTANCE_OPEN"
    WORKER_SELECTED = "WORKER_SELECTED"
    SCHEDULED = "SCHEDULED"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETION_SUBMITTED = "COMPLETION_SUBMITTED"
    CUSTOMER_CONFIRMED = "CUSTOMER_CONFIRMED"
    PAYMENT_PENDING = "PAYMENT_PENDING"
    PAYMENT_CUSTOMER_PAID = "PAYMENT_CUSTOMER_PAID"
    PAYMENT_WORKER_CONFIRMED = "PAYMENT_WORKER_CONFIRMED"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class MaterialProcurementMode(str, enum.Enum):
    CUSTOMER_PURCHASES = "CUSTOMER_PURCHASES"
    WORKER_PURCHASES = "WORKER_PURCHASES"


class OpportunityStatus(str, enum.Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    REJECTED = "REJECTED"
    EXPIRED = "EXPIRED"
    NOT_SELECTED = "NOT_SELECTED"


class ParticipationType(str, enum.Enum):
    PRIMARY_COMPLETION = "PRIMARY_COMPLETION"
    ROOKIE_PARTICIPATION = "ROOKIE_PARTICIPATION"


class WorkerParticipationClassification(str, enum.Enum):
    ROOKIE = "ROOKIE"
    EQUAL_SHARING = "EQUAL_SHARING"


class WorkerParticipationStatus(str, enum.Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    REJECTED = "REJECTED"


class ReviewerRole(str, enum.Enum):
    CUSTOMER = "CUSTOMER"
    WORKER = "WORKER"


class PaymentMethod(str, enum.Enum):
    CASH = "CASH"
    UPI = "UPI"


class PaymentStatus(str, enum.Enum):
    PENDING = "PENDING"
    CUSTOMER_PAID = "CUSTOMER_PAID"
    WORKER_CONFIRMED = "WORKER_CONFIRMED"


class PaymentType(str, enum.Enum):
    LABOUR = "LABOUR"
    CANCELLATION = "CANCELLATION"



class VisitationProposalStatus(str, enum.Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    REJECTED = "REJECTED"


class RescheduleStatus(str, enum.Enum):
    REQUESTED = "REQUESTED"
    ACCEPTED = "ACCEPTED"
    REJECTED = "REJECTED"
    ALTERNATIVE_PROPOSED = "ALTERNATIVE_PROPOSED"


class PreviousWorkerRequestStatus(str, enum.Enum):
    REQUESTED = "REQUESTED"
    ACCEPTED = "ACCEPTED"
    REJECTED = "REJECTED"
    RESCHEDULE_REQUESTED = "RESCHEDULE_REQUESTED"
    EXPIRED = "EXPIRED"
