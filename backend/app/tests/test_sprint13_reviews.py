import uuid
from typing import Tuple
from unittest.mock import patch
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.db.models.user import User, WorkerProfile, WorkerMetric
from app.db.models.service import ServiceCategory, ServiceTask, WorkerCategory
from app.db.models.gig import Gig, GigTask, GigWorkerOpportunity
from app.db.models.review import Review, ReviewQuestion, ReviewAnswer
from app.db.models.multi_worker import WorkerParticipation
from app.db.models.communication import GigEvent, Notification
from app.db.models.enums import (
    GigStatus,
    GigType,
    MaterialProcurementMode,
    OpportunityStatus,
    ReviewerRole,
    WorkerParticipationStatus,
    WorkerParticipationClassification,
)
from app.services.catalogue_service import CatalogueService
from app.services.review_service import ReviewService
from app.schemas.review import ReviewCreateRequest, ReviewAnswerItem


@pytest.fixture(autouse=True)
def seed_catalog_and_reviews_fixture(db_session: Session):
    """Ensure service catalogue and review questions are populated."""
    CatalogueService.seed_catalogue_if_empty(db_session)
    ReviewService.seed_review_questions_if_empty(db_session)


def create_test_customer(
    client: TestClient, db_session: Session, email_prefix: str = "cust13"
) -> Tuple[str, dict]:
    """Helper to initialize a customer and return (jwt_token, user_dict)."""
    sub = str(uuid.uuid4())
    token = create_access_token(
        {"sub": sub, "email": f"{email_prefix}_{sub[:8]}@sahakaar.org"}
    )
    res = client.post(
        "/api/v1/me/initialize",
        headers={"Authorization": f"Bearer {token}"},
        json={"role": "CUSTOMER", "full_name": f"Customer {sub[:6]}"},
    )
    assert res.status_code == 201
    return token, res.json()["data"]


def create_test_worker(
    client: TestClient,
    db_session: Session,
    category_id: uuid.UUID,
    email_prefix: str = "w13",
) -> Tuple[str, dict]:
    """Helper to initialize a worker with category and return (jwt_token, user_dict)."""
    sub = str(uuid.uuid4())
    token = create_access_token(
        {"sub": sub, "email": f"{email_prefix}_{sub[:8]}@sahakaar.org"}
    )
    res = client.post(
        "/api/v1/me/initialize",
        headers={"Authorization": f"Bearer {token}"},
        json={"role": "WORKER", "full_name": f"Worker {sub[:6]}"},
    )
    assert res.status_code == 201
    worker_data = res.json()["data"]

    res_cat = client.put(
        "/api/v1/worker/categories",
        headers={"Authorization": f"Bearer {token}"},
        json={"category_ids": [str(category_id)]},
    )
    assert res_cat.status_code == 200

    return token, worker_data


def setup_completed_gig(
    client: TestClient,
    db_session: Session,
    prefix: str = "rev13",
) -> Tuple[str, dict, str, dict, str]:
    """Helper to create a gig in COMPLETED status with assigned worker."""
    token_cust, cust = create_test_customer(
        client, db_session, email_prefix=f"c_{prefix}"
    )
    plumbing = (
        db_session.query(ServiceCategory)
        .filter(ServiceCategory.name == "Plumbing")
        .first()
    )
    task = (
        db_session.query(ServiceTask)
        .filter(ServiceTask.category_id == plumbing.id)
        .first()
    )

    token_w, w = create_test_worker(
        client, db_session, plumbing.id, email_prefix=f"w_{prefix}"
    )

    # 1. Create gig
    res_gig = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task.id)],
            "scheduled_date": "2026-10-15",
            "scheduled_start_time": "10:00:00",
            "address": "45 Review Test St",
            "latitude": 12.9716,
            "longitude": 77.5946,
            "material_procurement_mode": "CUSTOMER_PURCHASES",
        },
    )
    assert res_gig.status_code == 201
    gig_id = res_gig.json()["data"]["id"]

    # 2. Post gig
    res_post = client.post(
        f"/api/v1/gigs/{gig_id}/post",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_post.status_code == 200

    # 3. Worker accepts opportunity
    res_opps = client.get(
        "/api/v1/worker/opportunities",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    assert res_opps.status_code == 200
    opp_id = res_opps.json()["data"][0]["id"]

    res_acc = client.post(
        f"/api/v1/worker/opportunities/{opp_id}/accept",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    assert res_acc.status_code == 200

    # 4. Customer selects worker
    res_sel = client.post(
        f"/api/v1/gigs/{gig_id}/select-worker",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"worker_id": w["id"]},
    )
    assert res_sel.status_code == 200

    # 5. Fast-forward to COMPLETED status for review testing
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    gig.status = GigStatus.COMPLETED
    db_session.commit()

    return token_cust, cust, token_w, w, gig_id


def test_review_questions_seeding_and_filtering(client: TestClient, db_session: Session):
    """Verify active questions seeding, filtering by target role, and ordering."""
    token, _ = create_test_customer(client, db_session, email_prefix="q_cust")

    # Fetch all questions
    res = client.get(
        "/api/v1/review-questions",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert res.status_code == 200
    all_q = res.json()["data"]
    assert len(all_q) == 7

    # Filter by WORKER target role (questions about worker)
    res_w = client.get(
        "/api/v1/review-questions?target_role=WORKER",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert res_w.status_code == 200
    w_q = res_w.json()["data"]
    assert len(w_q) == 4
    for q in w_q:
        assert q["target_role"] == "WORKER"
        assert q["is_active"] is True
    # Verify display order is sorted
    orders = [q["display_order"] for q in w_q]
    assert orders == sorted(orders)
    texts = [q["question_text"] for q in w_q]
    assert "Work Quality & Completion" in texts
    assert "Reliability & Punctuality" in texts
    assert "Professionalism & Behavior" in texts
    assert "Communication & Transparency" in texts

    # Filter by CUSTOMER target role (questions about customer)
    res_c = client.get(
        "/api/v1/review-questions?target_role=CUSTOMER",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert res_c.status_code == 200
    c_q = res_c.json()["data"]
    assert len(c_q) == 3
    for q in c_q:
        assert q["target_role"] == "CUSTOMER"
        assert q["is_active"] is True
    c_texts = [q["question_text"] for q in c_q]
    assert "Work Area Preparation & Safety" in c_texts
    assert "Gig Description Accuracy" in c_texts
    assert "Customer Communication & Respect" in c_texts


def test_customer_reviews_worker_success(client: TestClient, db_session: Session):
    """Customer submits 4-MCQ structured review for worker on completed gig."""
    token_cust, cust, token_w, w, gig_id = setup_completed_gig(client, db_session, prefix="c_rev")

    # Get questions for worker
    res_q = client.get(
        "/api/v1/review-questions?target_role=WORKER",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    questions = res_q.json()["data"]

    # Submit review with ratings 5, 4, 5, 4 -> average = 4.5
    answers = [
        {"question_id": questions[0]["id"], "answer_value": 5},
        {"question_id": questions[1]["id"], "answer_value": 4},
        {"question_id": questions[2]["id"], "answer_value": 5},
        {"question_id": questions[3]["id"], "answer_value": 4},
    ]
    res_sub = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "reviewee_id": w["id"],
            "answers": answers,
        },
    )
    assert res_sub.status_code == 201
    data = res_sub.json()["data"]
    assert data["gig_id"] == gig_id
    assert data["reviewer_id"] == cust["id"]
    assert data["reviewee_id"] == w["id"]
    assert data["reviewer_role"] == "CUSTOMER"
    assert data["overall_rating"] == 4.5
    assert len(data["answers"]) == 4

    # Verify Review and ReviewAnswer records in database
    rev_db = db_session.query(Review).filter(Review.id == uuid.UUID(data["id"])).first()
    assert rev_db is not None
    assert rev_db.overall_rating == 4.5
    assert len(rev_db.answers) == 4

    # Verify GigEvent
    event = (
        db_session.query(GigEvent)
        .filter(GigEvent.gig_id == uuid.UUID(gig_id), GigEvent.event_type == "REVIEW_SUBMITTED")
        .first()
    )
    assert event is not None
    assert event.actor_id == uuid.UUID(cust["id"])
    assert event.metadata_json["overall_rating"] == "4.50"

    # Verify Notification for worker
    notif = (
        db_session.query(Notification)
        .filter(Notification.gig_id == uuid.UUID(gig_id), Notification.type == "REVIEW_RECEIVED")
        .first()
    )
    assert notif is not None
    assert notif.recipient_id == uuid.UUID(w["id"])


def test_worker_metric_bayesian_and_final_score_update(client: TestClient, db_session: Session):
    """Verify Bayesian score and final score calculate deterministically per WAGES.md."""
    token_cust, cust, token_w, w, gig_id1 = setup_completed_gig(client, db_session, prefix="w_bay1")

    res_q = client.get(
        "/api/v1/review-questions?target_role=WORKER",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    questions = res_q.json()["data"]

    # 1. First review: 5, 5, 5, 5 -> avg = 5.0 -> rating_score = 1.0
    answers1 = [{"question_id": q["id"], "answer_value": 5} for q in questions]
    res1 = client.post(
        f"/api/v1/gigs/{gig_id1}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reviewee_id": w["id"], "answers": answers1},
    )
    assert res1.status_code == 201

    metric = db_session.query(WorkerMetric).filter(WorkerMetric.worker_id == uuid.UUID(w["id"])).first()
    assert metric.rating_count == 1
    assert float(metric.rating_average) == 5.000
    # Bayesian: (C * m + score1) / (C + 1) = (10 * 0.7 + 1.0) / 11 = 8.0 / 11 = 0.72727
    expected_b1 = round(8.0 / 11.0, 5)
    assert float(metric.bayesian_score) == expected_b1
    # Final score: 0.5 * B + 0.5 * E = 0.5 * 0.72727 + 0.0 = 0.36364
    assert float(metric.final_score) == round(0.5 * expected_b1, 5)

    # 2. Second review on another completed gig: 3, 3, 3, 3 -> avg = 3.0 -> rating_score = (3-1)/4 = 0.5
    # Create second gig for the same worker
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    task = db_session.query(ServiceTask).filter(ServiceTask.category_id == plumbing.id).first()

    res_gig2 = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task.id)],
            "scheduled_date": "2026-10-16",
            "scheduled_start_time": "14:00:00",
            "address": "46 Review Test St",
            "latitude": 12.9716,
            "longitude": 77.5946,
            "material_procurement_mode": "CUSTOMER_PURCHASES",
        },
    )
    gig_id2 = res_gig2.json()["data"]["id"]
    client.post(f"/api/v1/gigs/{gig_id2}/post", headers={"Authorization": f"Bearer {token_cust}"})

    res_opps = client.get("/api/v1/worker/opportunities", headers={"Authorization": f"Bearer {token_w}"})
    opp_id2 = next(o["id"] for o in res_opps.json()["data"] if o["gig_id"] == gig_id2)
    client.post(f"/api/v1/worker/opportunities/{opp_id2}/accept", headers={"Authorization": f"Bearer {token_w}"})
    client.post(
        f"/api/v1/gigs/{gig_id2}/select-worker",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"worker_id": w["id"]},
    )
    gig2 = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id2)).first()
    gig2.status = GigStatus.COMPLETED
    db_session.commit()

    answers2 = [{"question_id": q["id"], "answer_value": 3} for q in questions]
    res2 = client.post(
        f"/api/v1/gigs/{gig_id2}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reviewee_id": w["id"], "answers": answers2},
    )
    assert res2.status_code == 201

    db_session.refresh(metric)
    assert metric.rating_count == 2
    assert float(metric.rating_average) == 4.000  # (5.0 + 3.0) / 2
    # Bayesian: (10 * 0.7 + 1.0 + 0.5) / (10 + 2) = 8.5 / 12 = 0.70833
    expected_b2 = round(8.5 / 12.0, 5)
    assert float(metric.bayesian_score) == expected_b2
    assert float(metric.final_score) == round(0.5 * expected_b2, 5)


def test_worker_reviews_customer_success(client: TestClient, db_session: Session):
    """Worker submits 3-MCQ structured review for customer on completed gig."""
    token_cust, cust, token_w, w, gig_id = setup_completed_gig(client, db_session, prefix="w_rev_c")

    # Get questions for customer
    res_q = client.get(
        "/api/v1/review-questions?target_role=CUSTOMER",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    questions = res_q.json()["data"]
    assert len(questions) == 3

    # Worker submits review: 5, 4, 5 -> avg = 4.67
    answers = [
        {"question_id": questions[0]["id"], "answer_value": 5},
        {"question_id": questions[1]["id"], "answer_value": 4},
        {"question_id": questions[2]["id"], "answer_value": 5},
    ]
    res_sub = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_w}"},
        json={
            "reviewee_id": cust["id"],
            "answers": answers,
        },
    )
    assert res_sub.status_code == 201
    data = res_sub.json()["data"]
    assert data["reviewer_role"] == "WORKER"
    assert data["reviewer_id"] == w["id"]
    assert data["reviewee_id"] == cust["id"]
    assert data["overall_rating"] == 4.67

    # Customer notification
    notif = (
        db_session.query(Notification)
        .filter(Notification.gig_id == uuid.UUID(gig_id), Notification.recipient_id == uuid.UUID(cust["id"]))
        .first()
    )
    assert notif is not None
    assert notif.type == "REVIEW_RECEIVED"


def test_reviews_gated_on_completed_gig(client: TestClient, db_session: Session):
    """Submitting review before COMPLETED status returns 409 GIG_NOT_COMPLETED."""
    token_cust, cust, token_w, w, gig_id = setup_completed_gig(client, db_session, prefix="gate_rev")

    res_q = client.get(
        "/api/v1/review-questions?target_role=WORKER",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    questions = res_q.json()["data"]
    answers = [{"question_id": q["id"], "answer_value": 5} for q in questions]

    # Revert gig to IN_PROGRESS
    gig = db_session.query(Gig).filter(Gig.id == uuid.UUID(gig_id)).first()
    gig.status = GigStatus.IN_PROGRESS
    db_session.commit()

    res = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reviewee_id": w["id"], "answers": answers},
    )
    assert res.status_code == 409
    assert res.json()["error"]["code"] == "GIG_NOT_COMPLETED"

    # Revert to PAYMENT_CUSTOMER_PAID
    gig.status = GigStatus.PAYMENT_CUSTOMER_PAID
    db_session.commit()

    res_pay = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reviewee_id": w["id"], "answers": answers},
    )
    assert res_pay.status_code == 409
    assert res_pay.json()["error"]["code"] == "GIG_NOT_COMPLETED"


def test_duplicate_review_rejected(client: TestClient, db_session: Session):
    """Exactly one review per direction per gig; duplicates return 409 REVIEW_ALREADY_EXISTS."""
    token_cust, cust, token_w, w, gig_id = setup_completed_gig(client, db_session, prefix="dup_rev")

    res_q = client.get(
        "/api/v1/review-questions?target_role=WORKER",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    questions = res_q.json()["data"]
    answers = [{"question_id": q["id"], "answer_value": 5} for q in questions]

    # 1. First submission succeeds
    res1 = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reviewee_id": w["id"], "answers": answers},
    )
    assert res1.status_code == 201

    # 2. Duplicate submission returns 409
    res2 = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reviewee_id": w["id"], "answers": answers},
    )
    assert res2.status_code == 409
    assert res2.json()["error"]["code"] == "REVIEW_ALREADY_EXISTS"


def test_participant_authorization_isolation(client: TestClient, db_session: Session):
    """Only gig participants can submit reviews; third parties return 403 Forbidden."""
    token_cust, cust, token_w, w, gig_id = setup_completed_gig(client, db_session, prefix="iso_rev")

    # Third party customer
    token_other_c, other_c = create_test_customer(client, db_session, email_prefix="other_c")
    # Third party worker
    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    token_other_w, other_w = create_test_worker(client, db_session, plumbing.id, email_prefix="other_w")

    res_q = client.get(
        "/api/v1/review-questions?target_role=WORKER",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    w_questions = res_q.json()["data"]
    answers = [{"question_id": q["id"], "answer_value": 5} for q in w_questions]

    # Third party customer attempts to review worker
    res_bad_c = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_other_c}"},
        json={"reviewee_id": w["id"], "answers": answers},
    )
    assert res_bad_c.status_code == 403
    assert res_bad_c.json()["error"]["code"] == "FORBIDDEN"

    # Third party worker attempts to review customer
    res_q_c = client.get(
        "/api/v1/review-questions?target_role=CUSTOMER",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    c_questions = res_q_c.json()["data"]
    c_answers = [{"question_id": q["id"], "answer_value": 5} for q in c_questions]

    res_bad_w = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_other_w}"},
        json={"reviewee_id": cust["id"], "answers": c_answers},
    )
    assert res_bad_w.status_code == 403
    assert res_bad_w.json()["error"]["code"] == "FORBIDDEN"

    # Customer attempts to review another customer
    res_cust_to_cust = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reviewee_id": other_c["id"], "answers": answers},
    )
    assert res_cust_to_cust.status_code == 400
    assert res_cust_to_cust.json()["error"]["code"] == "INVALID_REVIEWEE"

    # Worker attempts to review another worker
    res_w_to_w = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_w}"},
        json={"reviewee_id": other_w["id"], "answers": c_answers},
    )
    assert res_w_to_w.status_code == 400
    assert res_w_to_w.json()["error"]["code"] == "INVALID_REVIEWEE"


def test_invalid_question_and_answer_validation(client: TestClient, db_session: Session):
    """Validation checks for question target role, duplicate questions, and answer values."""
    token_cust, cust, token_w, w, gig_id = setup_completed_gig(client, db_session, prefix="val_rev")

    res_q_w = client.get(
        "/api/v1/review-questions?target_role=WORKER",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    w_questions = res_q_w.json()["data"]

    res_q_c = client.get(
        "/api/v1/review-questions?target_role=CUSTOMER",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    c_questions = res_q_c.json()["data"]

    # 1. Customer submits customer-targeted question instead of worker-targeted question
    res_wrong_role = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "reviewee_id": w["id"],
            "answers": [{"question_id": c_questions[0]["id"], "answer_value": 5}],
        },
    )
    assert res_wrong_role.status_code == 400
    assert res_wrong_role.json()["error"]["code"] == "QUESTION_ROLE_MISMATCH"

    # 2. Duplicate question answers in payload
    res_dup_q = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "reviewee_id": w["id"],
            "answers": [
                {"question_id": w_questions[0]["id"], "answer_value": 5},
                {"question_id": w_questions[0]["id"], "answer_value": 4},
            ],
        },
    )
    assert res_dup_q.status_code == 400
    assert res_dup_q.json()["error"]["code"] == "DUPLICATE_QUESTION_ANSWER"

    # 3. Non-existent question UUID
    res_fake_q = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "reviewee_id": w["id"],
            "answers": [{"question_id": str(uuid.uuid4()), "answer_value": 5}],
        },
    )
    assert res_fake_q.status_code == 400
    assert res_fake_q.json()["error"]["code"] == "INVALID_REVIEW_QUESTION"

    # 4. Answer value out of range (0 or 6)
    res_zero = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "reviewee_id": w["id"],
            "answers": [{"question_id": w_questions[0]["id"], "answer_value": 0}],
        },
    )
    assert res_zero.status_code in (400, 422)

    res_six = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "reviewee_id": w["id"],
            "answers": [{"question_id": w_questions[0]["id"], "answer_value": 6}],
        },
    )
    assert res_six.status_code in (400, 422)


def test_overall_rating_validation_and_calculation(client: TestClient, db_session: Session):
    """Client overall_rating must match calculated average; mismatch is rejected."""
    token_cust, cust, token_w, w, gig_id = setup_completed_gig(client, db_session, prefix="rating_calc")

    res_q = client.get(
        "/api/v1/review-questions?target_role=WORKER",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    questions = res_q.json()["data"]

    # Average of 5, 5, 5, 5 is 5.0. Client claims 3.0 -> rejected
    res_mismatch = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "reviewee_id": w["id"],
            "overall_rating": 3.0,
            "answers": [{"question_id": q["id"], "answer_value": 5} for q in questions],
        },
    )
    assert res_mismatch.status_code == 400
    assert res_mismatch.json()["error"]["code"] == "RATING_MISMATCH"

    # Client supplies exact matching rating (5.0) -> accepted
    res_match = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "reviewee_id": w["id"],
            "overall_rating": 5.0,
            "answers": [{"question_id": q["id"], "answer_value": 5} for q in questions],
        },
    )
    assert res_match.status_code == 201
    assert res_match.json()["data"]["overall_rating"] == 5.0


def test_get_gig_reviews_privacy_and_response(client: TestClient, db_session: Session):
    """Participants can view reviews; non-participants are rejected with 403 Forbidden."""
    token_cust, cust, token_w, w, gig_id = setup_completed_gig(client, db_session, prefix="get_rev")

    res_q = client.get(
        "/api/v1/review-questions?target_role=WORKER",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    questions = res_q.json()["data"]
    answers = [{"question_id": q["id"], "answer_value": 5} for q in questions]

    # Customer submits review
    client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reviewee_id": w["id"], "answers": answers},
    )

    # 1. Customer can view
    res_c_view = client.get(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_c_view.status_code == 200
    reviews = res_c_view.json()["data"]
    assert len(reviews) == 1
    assert reviews[0]["reviewer_role"] == "CUSTOMER"
    assert len(reviews[0]["answers"]) == 4

    # 2. Worker can view
    res_w_view = client.get(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_w}"},
    )
    assert res_w_view.status_code == 200
    assert len(res_w_view.json()["data"]) == 1

    # 3. Third-party is blocked
    token_other, _ = create_test_customer(client, db_session, email_prefix="third_party")
    res_third = client.get(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_other}"},
    )
    assert res_third.status_code == 403
    assert res_third.json()["error"]["code"] == "FORBIDDEN"


def test_get_worker_public_metrics(client: TestClient, db_session: Session):
    """Verify GET /workers/{worker_id}/metrics returns public fields without leakage."""
    token_cust, cust, token_w, w, gig_id = setup_completed_gig(client, db_session, prefix="pub_met")

    res_q = client.get(
        "/api/v1/review-questions?target_role=WORKER",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    questions = res_q.json()["data"]
    answers = [{"question_id": q["id"], "answer_value": 4} for q in questions]

    client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reviewee_id": w["id"], "answers": answers},
    )

    # Fetch public metrics
    res_m = client.get(
        f"/api/v1/workers/{w['id']}/metrics",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_m.status_code == 200
    m_data = res_m.json()["data"]
    assert m_data["worker_id"] == w["id"]
    assert m_data["rating_count"] == 1
    assert m_data["rating_average"] == 4.0
    assert "completed_jobs_count" in m_data
    assert "final_score" in m_data
    # Ensure internal or private fields are NOT exposed
    assert "phone" not in m_data
    assert "aadhaar_document_url" not in m_data
    assert "bayesian_score" not in m_data

    # Querying non-existent worker returns 404
    fake_id = str(uuid.uuid4())
    res_fake = client.get(
        f"/api/v1/workers/{fake_id}/metrics",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_fake.status_code == 404
    assert res_fake.json()["error"]["code"] == "WORKER_NOT_FOUND"


def test_transactional_rollback_on_failure(client: TestClient, db_session: Session):
    """Simulated failure during metric update rolls back review insertion cleanly."""
    token_cust, cust, token_w, w, gig_id = setup_completed_gig(client, db_session, prefix="roll_rev")

    res_q = client.get(
        "/api/v1/review-questions?target_role=WORKER",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    questions = res_q.json()["data"]
    answers = [{"question_id": q["id"], "answer_value": 5} for q in questions]

    # Patch compute_final_score to raise an exception simulating runtime failure
    with patch("app.services.review_service.compute_final_score", side_effect=RuntimeError("Simulated calculation crash")):
        with pytest.raises(RuntimeError):
            ReviewService.submit_review(
                db=db_session,
                current_user=db_session.query(User).filter(User.id == uuid.UUID(cust["id"])).first(),
                gig_id=uuid.UUID(gig_id),
                payload=ReviewCreateRequest(
                    reviewee_id=uuid.UUID(w["id"]),
                    answers=[ReviewAnswerItem(question_id=uuid.UUID(q["id"]), answer_value=5) for q in questions],
                ),
            )

    # Verify no review was committed
    reviews_count = db_session.query(Review).filter(Review.gig_id == uuid.UUID(gig_id)).count()
    assert reviews_count == 0


def test_collaborator_can_be_reviewed_and_review_customer(client: TestClient, db_session: Session):
    """Accepted collaborator can review customer, and customer can review collaborator."""
    token_cust, cust, token_w1, w1, gig_id = setup_completed_gig(client, db_session, prefix="collab_rev")

    plumbing = db_session.query(ServiceCategory).filter(ServiceCategory.name == "Plumbing").first()
    token_w2, w2 = create_test_worker(client, db_session, plumbing.id, email_prefix="w2_rev")

    # Add collaborator with ACCEPTED status
    participation = WorkerParticipation(
        id=uuid.uuid4(),
        gig_id=uuid.UUID(gig_id),
        inviting_worker_id=uuid.UUID(w1["id"]),
        additional_worker_id=uuid.UUID(w2["id"]),
        status=WorkerParticipationStatus.ACCEPTED,
        classification=WorkerParticipationClassification.EQUAL_SHARING,
        experience_contribution=0.50000,
    )
    db_session.add(participation)
    db_session.commit()

    # 1. Collaborator reviews customer
    res_q_c = client.get(
        "/api/v1/review-questions?target_role=CUSTOMER",
        headers={"Authorization": f"Bearer {token_w2}"},
    )
    c_questions = res_q_c.json()["data"]
    c_answers = [{"question_id": q["id"], "answer_value": 5} for q in c_questions]

    res_w2_sub = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_w2}"},
        json={"reviewee_id": cust["id"], "answers": c_answers},
    )
    assert res_w2_sub.status_code == 201
    assert res_w2_sub.json()["data"]["reviewer_id"] == w2["id"]

    # 2. Customer reviews collaborator
    res_q_w = client.get(
        "/api/v1/review-questions?target_role=WORKER",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    w_questions = res_q_w.json()["data"]
    w_answers = [{"question_id": q["id"], "answer_value": 5} for q in w_questions]

    res_cust_to_w2 = client.post(
        f"/api/v1/gigs/{gig_id}/reviews",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reviewee_id": w2["id"], "answers": w_answers},
    )
    assert res_cust_to_w2.status_code == 201
    assert res_cust_to_w2.json()["data"]["reviewee_id"] == w2["id"]
