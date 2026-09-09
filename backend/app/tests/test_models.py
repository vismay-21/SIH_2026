import uuid
from datetime import date, time, datetime, timezone
import pytest
from sqlalchemy.orm import Session
from sqlalchemy import select

from app.db.base import Base
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
from app.db.models import (
    Cooperative,
    User,
    CustomerProfile,
    WorkerProfile,
    WorkerMetric,
    ServiceCategory,
    ServiceTask,
    WorkerCategory,
    WorkerAvailability,
    Gig,
    GigTask,
    GigWorkerOpportunity,
    WorkerExperienceRecord,
    Review,
    ReviewQuestion,
    ReviewAnswer,
    CompletionSubmission,
    CompletionEvidence,
    CompletionConfirmation,
    Payment,
    MaterialReceipt,
    WorkerParticipation,
    VisitationProposal,
    VisitationProposalTask,
    GigCancellation,
    RescheduleRequest,
    PreviousWorkerRequest,
    Conversation,
    Message,
    Notification,
    GigEvent,
)


def test_all_models_registered_on_metadata():
    """Verify that exactly 31 MVP tables from 04_DATABASE_DESIGN.md are registered on Base."""
    expected_tables = {
        "cooperatives",
        "users",
        "customer_profiles",
        "worker_profiles",
        "worker_metrics",
        "service_categories",
        "service_tasks",
        "worker_categories",
        "worker_availability",
        "gigs",
        "gig_tasks",
        "gig_worker_opportunities",
        "worker_experience_records",
        "reviews",
        "review_questions",
        "review_answers",
        "completion_submissions",
        "completion_evidence",
        "completion_confirmations",
        "payments",
        "material_receipts",
        "worker_participations",
        "visitation_proposals",
        "visitation_proposal_tasks",
        "gig_cancellations",
        "reschedule_requests",
        "previous_worker_requests",
        "conversations",
        "messages",
        "notifications",
        "gig_events",
    }
    actual_tables = set(Base.metadata.tables.keys())
    assert expected_tables.issubset(actual_tables)
    assert len(expected_tables) == 31


def test_create_cooperative_and_users(db_session: Session):
    """Test creating Cooperative, Customer User, and Worker User with 1-to-1 profile and metric tables."""
    coop = Cooperative(
        name="Bangalore Household Artisans Cooperative",
        city="Bengaluru",
        service_area="Bangalore Urban",
    )
    db_session.add(coop)
    db_session.flush()

    # Create Customer User
    customer = User(
        role=UserRole.CUSTOMER,
        cooperative_id=coop.id,
        full_name="Ananya Sharma",
        phone="+919876543210",
        email="ananya@example.com",
    )
    db_session.add(customer)
    db_session.flush()

    customer_profile = CustomerProfile(
        user_id=customer.id,
        address="123 Palm Grove, Indiranagar, Bengaluru",
    )
    db_session.add(customer_profile)
    db_session.flush()

    # Create Worker User
    worker = User(
        role=UserRole.WORKER,
        cooperative_id=coop.id,
        full_name="Ramesh Kumar",
        phone="+919876543211",
        email="ramesh@example.com",
    )
    db_session.add(worker)
    db_session.flush()

    worker_profile = WorkerProfile(
        user_id=worker.id,
        address="45 Artisan Colony, Bengaluru",
        city="Bengaluru",
        aadhaar_document_url="https://storage.supabase.co/aadhaar/ramesh.pdf",
        aadhaar_uploaded_at=datetime.now(timezone.utc),
    )
    db_session.add(worker_profile)
    db_session.flush()

    worker_metric = WorkerMetric(
        worker_id=worker.id,
        completed_jobs_count=5,
        rating_average=4.8,
        rating_count=5,
        bayesian_score=0.75,
        experience_score=0.40,
        final_score=0.575,
    )
    db_session.add(worker_metric)
    db_session.commit()

    # Verify query
    fetched_user = db_session.get(User, customer.id)
    assert fetched_user is not None
    assert fetched_user.customer_profile is not None
    assert fetched_user.customer_profile.address == "123 Palm Grove, Indiranagar, Bengaluru"

    fetched_worker = db_session.get(User, worker.id)
    assert fetched_worker is not None
    assert fetched_worker.worker_profile is not None
    assert float(fetched_worker.worker_profile.metrics.final_score) == pytest.approx(0.575)


def test_service_categories_and_tasks(db_session: Session):
    """Test creating ServiceCategory, ServiceTask, WorkerCategory, and WorkerAvailability."""
    cat = ServiceCategory(
        name="Plumbing",
        description="Pipes, taps, fixtures, unclogging",
        base_rate_per_minute=5.00,
        minimum_billable_minutes=45,
    )
    db_session.add(cat)
    db_session.flush()

    task1 = ServiceTask(
        category_id=cat.id,
        name="Leaking tap repair",
        standard_duration_minutes=20,
        base_price=100.00,
    )
    task2 = ServiceTask(
        category_id=cat.id,
        name="Pipe leakage fix",
        standard_duration_minutes=30,
        base_price=150.00,
    )
    db_session.add_all([task1, task2])
    db_session.commit()

    fetched_cat = db_session.get(ServiceCategory, cat.id)
    assert fetched_cat is not None
    assert len(fetched_cat.tasks) == 2
    assert fetched_cat.minimum_billable_minutes == 45


def test_gig_lifecycle_and_opportunity_snapshots(db_session: Session):
    """Test Gig creation, GigTask snapshotting, and GigWorkerOpportunity immutable wage snapshots."""
    coop = Cooperative(name="Coop Test", city="Bengaluru")
    db_session.add(coop)
    db_session.flush()

    cat = ServiceCategory(name="Carpentry", base_rate_per_minute=4.70, minimum_billable_minutes=45)
    db_session.add(cat)
    db_session.flush()

    task = ServiceTask(
        category_id=cat.id,
        name="Door repair",
        standard_duration_minutes=30,
        base_price=140.00,
    )
    db_session.add(task)
    db_session.flush()

    cust = User(role=UserRole.CUSTOMER, cooperative_id=coop.id, full_name="Customer Test")
    worker = User(role=UserRole.WORKER, cooperative_id=coop.id, full_name="Worker Test")
    db_session.add_all([cust, worker])
    db_session.flush()

    gig = Gig(
        customer_id=cust.id,
        cooperative_id=coop.id,
        category_id=cat.id,
        gig_type=GigType.NORMAL,
        status=GigStatus.POSTED,
        description="Fix loose front door hinge",
        address="10 Main St",
        latitude=12.9716,
        longitude=77.5946,
        scheduled_date=date(2026, 9, 15),
        scheduled_start_time=time(10, 0),
        expected_duration_minutes=30,
        base_price=211.50,  # 45 min floor * 4.70
        minimum_billable_minutes_snapshot=45,
        base_rate_per_minute_snapshot=4.70,
    )
    db_session.add(gig)
    db_session.flush()

    gig_task = GigTask(
        gig_id=gig.id,
        task_id=task.id,
        standard_duration_minutes_snapshot=30,
        base_price_snapshot=140.00,
    )
    db_session.add(gig_task)

    opportunity = GigWorkerOpportunity(
        gig_id=gig.id,
        worker_id=worker.id,
        status=OpportunityStatus.PENDING,
        base_price_snapshot=211.50,
        final_score_snapshot=0.60000,
        premium_percentage=18.000,
        exact_wage=249.57,
    )
    db_session.add(opportunity)
    db_session.commit()

    fetched_gig = db_session.get(Gig, gig.id)
    assert fetched_gig is not None
    assert fetched_gig.status == GigStatus.POSTED
    assert len(fetched_gig.opportunities) == 1
    opp = fetched_gig.opportunities[0]
    assert float(opp.exact_wage) == pytest.approx(249.57)
    assert float(opp.final_score_snapshot) == pytest.approx(0.60000)


def test_completion_and_payment_records(db_session: Session):
    """Test CompletionSubmission, Evidence, Confirmation, and Payment chain."""
    coop = Cooperative(name="Coop Test 2", city="Mysuru")
    cat = ServiceCategory(name="Painter", base_rate_per_minute=4.20)
    db_session.add_all([coop, cat])
    db_session.flush()

    cust = User(role=UserRole.CUSTOMER, cooperative_id=coop.id, full_name="Buyer")
    worker = User(role=UserRole.WORKER, cooperative_id=coop.id, full_name="Painter Worker")
    db_session.add_all([cust, worker])
    db_session.flush()

    gig = Gig(
        customer_id=cust.id,
        cooperative_id=coop.id,
        category_id=cat.id,
        status=GigStatus.SCHEDULED,
        selected_worker_id=worker.id,
    )
    db_session.add(gig)
    db_session.flush()

    # Submission & Evidence
    sub = CompletionSubmission(
        gig_id=gig.id,
        worker_id=worker.id,
        description="Repainting of accent wall finished and clean.",
    )
    db_session.add(sub)
    db_session.flush()

    evidence = CompletionEvidence(
        submission_id=sub.id,
        file_url="https://supabase.co/storage/photos/accent_wall.jpg",
        file_type="image/jpeg",
    )
    db_session.add(evidence)

    # Customer Confirmation
    confirmation = CompletionConfirmation(
        gig_id=gig.id,
        customer_id=cust.id,
        confirmed=True,
        response_note="Work completed cleanly.",
    )
    db_session.add(confirmation)

    # Payment
    payment = Payment(
        gig_id=gig.id,
        customer_id=cust.id,
        worker_id=worker.id,
        amount=550.00,
        payment_method=PaymentMethod.UPI,
        status=PaymentStatus.CUSTOMER_PAID,
        paid_at=datetime.now(timezone.utc),
    )
    db_session.add(payment)
    db_session.commit()

    fetched_payment = db_session.get(Payment, payment.id)
    assert fetched_payment is not None
    assert fetched_payment.status == PaymentStatus.CUSTOMER_PAID
    assert float(fetched_payment.amount) == pytest.approx(550.00)


def test_conversations_and_notifications(db_session: Session):
    """Test Conversation, Message, Notification, and GigEvent models."""
    coop = Cooperative(name="Coop Test 3", city="Bengaluru")
    cat = ServiceCategory(name="House Help", base_rate_per_minute=3.30)
    db_session.add_all([coop, cat])
    db_session.flush()

    cust = User(role=UserRole.CUSTOMER, cooperative_id=coop.id, full_name="User Chat 1")
    worker = User(role=UserRole.WORKER, cooperative_id=coop.id, full_name="User Chat 2")
    db_session.add_all([cust, worker])
    db_session.flush()

    gig = Gig(
        customer_id=cust.id,
        cooperative_id=coop.id,
        category_id=cat.id,
        status=GigStatus.SCHEDULED,
        selected_worker_id=worker.id,
    )
    db_session.add(gig)
    db_session.flush()

    conv = Conversation(gig_id=gig.id, customer_id=cust.id, worker_id=worker.id)
    db_session.add(conv)
    db_session.flush()

    msg = Message(
        conversation_id=conv.id,
        sender_id=cust.id,
        message_text="Hello, I will be home at 10 AM.",
    )
    db_session.add(msg)

    notif = Notification(
        recipient_id=worker.id,
        gig_id=gig.id,
        type="NEW_MESSAGE",
        title="New message from customer",
        body="Hello, I will be home at 10 AM.",
    )
    db_session.add(notif)

    event = GigEvent(
        gig_id=gig.id,
        actor_id=cust.id,
        event_type="MESSAGE_SENT",
        metadata_json={"msg_length": len(msg.message_text)},
    )
    db_session.add(event)
    db_session.commit()

    fetched_conv = db_session.get(Conversation, conv.id)
    assert fetched_conv is not None
    assert len(fetched_conv.messages) == 1
    assert fetched_conv.messages[0].message_text == "Hello, I will be home at 10 AM."

    fetched_notif = db_session.get(Notification, notif.id)
    assert fetched_notif is not None
    assert fetched_notif.is_read is False

    fetched_event = db_session.get(GigEvent, event.id)
    assert fetched_event is not None
    assert fetched_event.event_type == "MESSAGE_SENT"
