import os
import tempfile
import pytest
from sqlalchemy import create_engine, inspect
from sqlalchemy.dialects import postgresql
from sqlalchemy.schema import CreateTable
from alembic.config import Config
from alembic import command

from app.db.base import Base
import app.db.models as models
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


def test_enum_values_match_srs_and_db_design():
    """Item 1: Compare every enum in models with 04_DATABASE_DESIGN.md exact values."""
    enum_specs = {
        UserRole: ["CUSTOMER", "WORKER"],
        GigType: ["NORMAL", "VISITATION"],
        GigStatus: [
            "DRAFT",
            "POSTED",
            "ACCEPTANCE_OPEN",
            "WORKER_SELECTED",
            "SCHEDULED",
            "IN_PROGRESS",
            "COMPLETION_SUBMITTED",
            "CUSTOMER_CONFIRMED",
            "PAYMENT_PENDING",
            "PAYMENT_CUSTOMER_PAID",
            "PAYMENT_WORKER_CONFIRMED",
            "COMPLETED",
            "CANCELLED",
        ],
        MaterialProcurementMode: ["CUSTOMER_PURCHASES", "WORKER_PURCHASES"],
        OpportunityStatus: ["PENDING", "ACCEPTED", "REJECTED", "EXPIRED", "NOT_SELECTED"],
        ParticipationType: ["PRIMARY_COMPLETION", "ROOKIE_PARTICIPATION"],
        WorkerParticipationClassification: ["ROOKIE", "EQUAL_SHARING"],
        WorkerParticipationStatus: ["PENDING", "ACCEPTED", "REJECTED"],
        ReviewerRole: ["CUSTOMER", "WORKER"],
        PaymentMethod: ["CASH", "UPI"],
        PaymentStatus: ["PENDING", "CUSTOMER_PAID", "WORKER_CONFIRMED"],
        VisitationProposalStatus: ["PENDING", "ACCEPTED", "REJECTED"],
        RescheduleStatus: ["REQUESTED", "ACCEPTED", "REJECTED", "ALTERNATIVE_PROPOSED"],
        PreviousWorkerRequestStatus: [
            "REQUESTED",
            "ACCEPTED",
            "REJECTED",
            "RESCHEDULE_REQUESTED",
            "EXPIRED",
        ],
    }

    for enum_cls, expected_vals in enum_specs.items():
        actual_vals = [e.value for e in enum_cls]
        assert (
            actual_vals == expected_vals
        ), f"Mismatch in {enum_cls.__name__}: {actual_vals} != {expected_vals}"


def test_constraints_and_indexes_match_section_55_and_56():
    """Item 2: Verify foreign keys, unique constraints, and required indexes."""
    tables = Base.metadata.tables

    # Unique constraints
    assert "uq_worker_category" in [
        uc.name for uc in tables["worker_categories"].constraints if uc.name
    ]
    assert "uq_gig_task" in [
        uc.name for uc in tables["gig_tasks"].constraints if uc.name
    ]
    assert "uq_gig_worker_opportunity" in [
        uc.name for uc in tables["gig_worker_opportunities"].constraints if uc.name
    ]
    assert "uq_review_direction" in [
        uc.name for uc in tables["reviews"].constraints if uc.name
    ]

    # Required indexes from Section 56
    required_indexes = [
        ("users", "ix_users_role"),
        ("users", "ix_users_cooperative_id"),
        ("worker_categories", "ix_worker_categories_worker_id"),
        ("worker_categories", "ix_worker_categories_category_id"),
        ("service_tasks", "ix_service_tasks_category_id"),
        ("gigs", "ix_gigs_customer_id"),
        ("gigs", "ix_gigs_cooperative_id"),
        ("gigs", "ix_gigs_category_id"),
        ("gigs", "ix_gigs_status"),
        ("gigs", "ix_gigs_scheduled_date"),
        ("gigs", "ix_gigs_selected_worker_id"),
        ("gig_tasks", "ix_gig_tasks_gig_id"),
        ("gig_tasks", "ix_gig_tasks_task_id"),
        ("gig_worker_opportunities", "ix_gig_worker_opportunities_gig_id"),
        ("gig_worker_opportunities", "ix_gig_worker_opportunities_worker_id"),
        ("gig_worker_opportunities", "ix_gig_worker_opportunities_status"),
        ("worker_availability", "ix_worker_availability_lookup"),
        ("worker_experience_records", "ix_worker_exp_lookup"),
        ("reviews", "ix_reviews_reviewee"),
        ("reviews", "ix_reviews_gig_id"),
        ("payments", "ix_payments_gig_id"),
        ("payments", "ix_payments_worker_id"),
        ("payments", "ix_payments_status"),
        ("messages", "ix_messages_thread"),
        ("notifications", "ix_notifications_user_read"),
        ("gig_events", "ix_gig_events_timeline"),
    ]

    for tbl, idx_name in required_indexes:
        table_indexes = [idx.name for idx in tables[tbl].indexes]
        assert (
            idx_name in table_indexes
        ), f"Missing index {idx_name} on {tbl}: found {table_indexes}"


def test_clean_database_migration_recreation():
    """Item 3: Test that a completely clean database is migrated successfully to head."""
    temp_db = os.path.join(tempfile.gettempdir(), f"clean_test_{os.getpid()}.db")
    if os.path.exists(temp_db):
        os.remove(temp_db)

    try:
        alembic_cfg = Config("alembic.ini")
        alembic_cfg.set_main_option("sqlalchemy.url", f"sqlite:///{temp_db}")
        command.upgrade(alembic_cfg, "head")

        clean_engine = create_engine(f"sqlite:///{temp_db}")
        insp = inspect(clean_engine)
        live_tables = sorted(insp.get_table_names())
        assert len(live_tables) == 32
        assert "alembic_version" in live_tables
        assert "gigs" in live_tables
        assert "users" in live_tables
        clean_engine.dispose()
    finally:
        if os.path.exists(temp_db):
            try:
                os.remove(temp_db)
            except Exception:
                pass


def test_postgresql_ddl_and_enum_check_constraints():
    """Item 4: Verify native_enum=False creates strict SQL CHECK constraints in PostgreSQL DDL."""
    pg_dialect = postgresql.dialect()
    checked_count = 0

    for table in Base.metadata.tables.values():
        ddl = str(CreateTable(table).compile(dialect=pg_dialect))
        for col in table.columns:
            if hasattr(col.type, "enums"):
                expected_vals = col.type.enums
                # Must contain SQL CHECK constraint
                assert f"CHECK ({col.name} IN" in ddl, (
                    f"PostgreSQL DDL for {table.name}.{col.name} lacks CHECK constraint"
                )
                for val in expected_vals:
                    val_str = "'" + val + "'"
                    assert val_str in ddl, (
                        f"PostgreSQL DDL for {table.name}.{col.name} missing value {val}"
                    )
                checked_count += 1

    assert checked_count >= 14, f"Expected at least 14 enum columns, checked {checked_count}"


def test_snapshot_fields_match_db_design():
    """Item 5: Verify immutable pricing and wage snapshot fields match approved design."""
    tables = Base.metadata.tables
    snapshot_specs = {
        "gigs": [
            "base_price",
            "minimum_billable_minutes_snapshot",
            "base_rate_per_minute_snapshot",
        ],
        "gig_tasks": [
            "standard_duration_minutes_snapshot",
            "base_price_snapshot",
        ],
        "gig_worker_opportunities": [
            "base_price_snapshot",
            "final_score_snapshot",
            "premium_percentage",
            "exact_wage",
        ],
        "visitation_proposal_tasks": [
            "standard_duration_minutes_snapshot",
            "base_price_snapshot",
        ],
    }

    for tbl, expected_cols in snapshot_specs.items():
        actual_cols = [c.name for c in tables[tbl].columns]
        for col in expected_cols:
            assert col in actual_cols, f"Missing snapshot field {col} on {tbl}"
