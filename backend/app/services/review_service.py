"""Review and Metrics Service for Sahakaar Seva.

Implements two-way structured MCQ reviews, rating aggregation with Bayesian scoring,
final score synchronization, and worker public metrics per:
- docs/06_BACKEND_SPRINTS.md (Section 36)
- docs/05_API_DESIGN.md (Sections 27, 28)
- docs/04_DATABASE_DESIGN.md (Sections 8, 25, 26, 27)
- docs/WAGES.md (Sections 4, 5)
- docs/SRS_Final.md (Section 20)
"""

import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import List, Optional
from sqlalchemy.orm import Session, joinedload

from app.core.config import settings
from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    ForbiddenException,
    NotFoundException,
)
from app.db.models.enums import (
    GigStatus,
    ReviewerRole,
    UserRole,
    WorkerParticipationStatus,
)
from app.db.models.gig import Gig
from app.db.models.user import User, WorkerMetric
from app.db.models.review import Review, ReviewQuestion, ReviewAnswer
from app.db.models.communication import GigEvent, Notification
from app.db.models.multi_worker import WorkerParticipation
from app.schemas.review import (
    ReviewAnswerItem,
    ReviewAnswerResponse,
    ReviewCreateRequest,
    ReviewQuestionResponse,
    ReviewResponse,
    WorkerPublicMetricsResponse,
)
from app.services.experience_service import ExperienceService
from app.services.score_service import compute_final_score, get_rookie_initial_metrics


STANDARD_REVIEW_QUESTIONS = [
    # Customer -> Worker evaluation (target_role = WORKER)
    {
        "target_role": ReviewerRole.WORKER,
        "question_text": "Work Quality & Completion",
        "display_order": 1,
    },
    {
        "target_role": ReviewerRole.WORKER,
        "question_text": "Reliability & Punctuality",
        "display_order": 2,
    },
    {
        "target_role": ReviewerRole.WORKER,
        "question_text": "Professionalism & Behavior",
        "display_order": 3,
    },
    {
        "target_role": ReviewerRole.WORKER,
        "question_text": "Communication & Transparency",
        "display_order": 4,
    },
    # Worker -> Customer evaluation (target_role = CUSTOMER)
    {
        "target_role": ReviewerRole.CUSTOMER,
        "question_text": "Work Area Preparation & Safety",
        "display_order": 1,
    },
    {
        "target_role": ReviewerRole.CUSTOMER,
        "question_text": "Gig Description Accuracy",
        "display_order": 2,
    },
    {
        "target_role": ReviewerRole.CUSTOMER,
        "question_text": "Customer Communication & Respect",
        "display_order": 3,
    },
]


class ReviewService:
    @classmethod
    def seed_review_questions_if_empty(cls, db: Session) -> None:
        """Seed the standard structured MCQ review questions if none exist in the database."""
        count = db.query(ReviewQuestion).count()
        if count == 0:
            for item in STANDARD_REVIEW_QUESTIONS:
                q = ReviewQuestion(
                    id=uuid.uuid4(),
                    target_role=item["target_role"],
                    question_text=item["question_text"],
                    display_order=item["display_order"],
                    is_active=True,
                )
                db.add(q)
            db.commit()

    @classmethod
    def get_review_questions(
        cls,
        db: Session,
        target_role: Optional[ReviewerRole] = None,
    ) -> List[ReviewQuestionResponse]:
        """Fetch active structured review questions ordered by display order."""
        cls.seed_review_questions_if_empty(db)

        query = db.query(ReviewQuestion).filter(ReviewQuestion.is_active == True)
        if target_role:
            query = query.filter(ReviewQuestion.target_role == target_role)

        questions = query.order_by(
            ReviewQuestion.target_role, ReviewQuestion.display_order
        ).all()
        return [ReviewQuestionResponse.model_validate(q) for q in questions]

    @classmethod
    def submit_review(
        cls,
        db: Session,
        current_user: User,
        gig_id: uuid.UUID,
        payload: ReviewCreateRequest,
    ) -> ReviewResponse:
        """Submit a structured two-way review for a completed gig.

        Enforces:
        - Gig must be in COMPLETED status.
        - Caller must be an authenticated participant.
        - Reviewee must be the valid counterparty.
        - Exactly one review per direction per gig.
        - Answers must reference active questions matching the reviewee's target role.
        - Answer values must be 1 to 5.
        - Client overall_rating, if provided, must match calculated average.
        - Updates WorkerMetric and Bayesian rating signals when customer reviews a worker.
        - Dispatches audit event and notification.
        """
        try:
            gig = db.query(Gig).filter(Gig.id == gig_id).first()
            if not gig:
                raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

            # 1. Completion prerequisite
            if gig.status != GigStatus.COMPLETED:
                raise ConflictException(
                    f"Reviews can only be submitted for completed gigs. Current gig status: '{gig.status.value}'.",
                    code="GIG_NOT_COMPLETED",
                )

            # 2. Determine reviewer role and valid reviewees
            is_customer = current_user.id == gig.customer_id
            is_primary_worker = current_user.id == gig.selected_worker_id

            accepted_collaborators = (
                db.query(WorkerParticipation.additional_worker_id)
                .filter(
                    WorkerParticipation.gig_id == gig.id,
                    WorkerParticipation.status == WorkerParticipationStatus.ACCEPTED,
                )
                .all()
            )
            accepted_worker_ids = {r[0] for r in accepted_collaborators}
            if gig.selected_worker_id:
                accepted_worker_ids.add(gig.selected_worker_id)

            is_collaborator = current_user.id in accepted_worker_ids

            if is_customer:
                reviewer_role = ReviewerRole.CUSTOMER
                expected_target_role = ReviewerRole.WORKER
                if payload.reviewee_id not in accepted_worker_ids:
                    raise BadRequestException(
                        "Specified reviewee is not an assigned worker or accepted collaborator on this gig.",
                        code="INVALID_REVIEWEE",
                    )
            elif is_primary_worker or is_collaborator:
                reviewer_role = ReviewerRole.WORKER
                expected_target_role = ReviewerRole.CUSTOMER
                if payload.reviewee_id != gig.customer_id:
                    raise BadRequestException(
                        "Workers can only review the gig customer.",
                        code="INVALID_REVIEWEE",
                    )
            else:
                raise ForbiddenException(
                    "Only gig participants can submit reviews for this gig.",
                    code="FORBIDDEN",
                )

            # 3. Duplicate review check (exactly one review per direction per gig)
            existing_review = (
                db.query(Review)
                .filter(
                    Review.gig_id == gig.id,
                    Review.reviewer_id == current_user.id,
                    Review.reviewee_id == payload.reviewee_id,
                )
                .first()
            )
            if existing_review:
                raise ConflictException(
                    "Review already submitted for this participant on this gig.",
                    code="REVIEW_ALREADY_EXISTS",
                )

            # 4. Validate questions and answers
            cls.seed_review_questions_if_empty(db)
            question_ids = [a.question_id for a in payload.answers]

            # Check for duplicate question answers in payload
            if len(question_ids) != len(set(question_ids)):
                raise BadRequestException(
                    "Duplicate questions found in review answers.",
                    code="DUPLICATE_QUESTION_ANSWER",
                )

            active_questions = (
                db.query(ReviewQuestion)
                .filter(
                    ReviewQuestion.id.in_(question_ids),
                    ReviewQuestion.is_active == True,
                )
                .all()
            )
            questions_by_id = {q.id: q for q in active_questions}

            if len(questions_by_id) != len(question_ids):
                raise BadRequestException(
                    "One or more review questions are invalid, inactive, or do not exist.",
                    code="INVALID_REVIEW_QUESTION",
                )

            for q_id in question_ids:
                q = questions_by_id[q_id]
                if q.target_role != expected_target_role:
                    raise BadRequestException(
                        f"Question '{q.question_text}' is intended for {q.target_role.value} reviews, "
                        f"not {expected_target_role.value}.",
                        code="QUESTION_ROLE_MISMATCH",
                    )

            for a in payload.answers:
                if a.answer_value < 1 or a.answer_value > 5:
                    raise BadRequestException(
                        f"Answer value {a.answer_value} must be between 1 and 5.",
                        code="INVALID_ANSWER_VALUE",
                    )

            # 5. Overall rating calculation & validation
            calculated_overall = round(
                sum(a.answer_value for a in payload.answers) / float(len(payload.answers)),
                2,
            )

            if payload.overall_rating is not None:
                client_rating = round(float(payload.overall_rating), 2)
                if client_rating != calculated_overall:
                    raise BadRequestException(
                        f"Client-supplied overall_rating ({client_rating}) does not match "
                        f"calculated average of answers ({calculated_overall}).",
                        code="RATING_MISMATCH",
                    )
                final_overall_rating = calculated_overall
            else:
                final_overall_rating = calculated_overall

            # 6. Create Review and ReviewAnswer records
            review_id = uuid.uuid4()
            review = Review(
                id=review_id,
                gig_id=gig.id,
                reviewer_id=current_user.id,
                reviewee_id=payload.reviewee_id,
                reviewer_role=reviewer_role,
                overall_rating=final_overall_rating,
            )
            db.add(review)

            for a in payload.answers:
                ans = ReviewAnswer(
                    id=uuid.uuid4(),
                    review_id=review_id,
                    question_id=a.question_id,
                    answer_value=a.answer_value,
                )
                db.add(ans)

            # 7. Update WorkerMetric if customer reviewed a worker
            if reviewer_role == ReviewerRole.CUSTOMER:
                worker_metric = (
                    db.query(WorkerMetric)
                    .filter(WorkerMetric.worker_id == payload.reviewee_id)
                    .with_for_update()
                    .first()
                )
                if not worker_metric:
                    initial_metrics = get_rookie_initial_metrics()
                    worker_metric = WorkerMetric(
                        worker_id=payload.reviewee_id,
                        **initial_metrics,
                    )
                    db.add(worker_metric)
                    db.flush()

                # Flush session so the new review is counted
                db.flush()

                all_worker_reviews = (
                    db.query(Review)
                    .filter(
                        Review.reviewee_id == payload.reviewee_id,
                        Review.reviewer_role == ReviewerRole.CUSTOMER,
                    )
                    .all()
                )
                all_ratings = [float(r.overall_rating) for r in all_worker_reviews]
                worker_metric.rating_count = len(all_ratings)
                worker_metric.rating_average = round(
                    sum(all_ratings) / float(len(all_ratings)), 3
                )

                # Bayesian Score Calculation (WAGES.md Section 4):
                # Normalized per-review score: rating_score = (avg_rating - 1) / 4 (1★->0.0, 5★->1.0)
                normalized_ratings = [(r - 1.0) / 4.0 for r in all_ratings]
                worker_metric.bayesian_score = ExperienceService.calculate_bayesian_score(
                    normalized_ratings,
                    prior_mean=settings.BAYESIAN_PRIOR_MEAN,
                    confidence_c=settings.BAYESIAN_CONFIDENCE_C,
                )

                # Combined Final Score (WAGES.md Section 5):
                # final_score = 0.5 * experience_score + 0.5 * bayesian_score
                worker_metric.final_score = compute_final_score(
                    worker_metric.bayesian_score,
                    float(worker_metric.experience_score),
                )
                worker_metric.updated_at = datetime.now(timezone.utc)

            # 8. Audit Event & Notification
            db.add(
                GigEvent(
                    gig_id=gig.id,
                    actor_id=current_user.id,
                    event_type="REVIEW_SUBMITTED",
                    metadata_json={
                        "review_id": str(review.id),
                        "reviewer_role": reviewer_role.value,
                        "overall_rating": f"{final_overall_rating:.2f}",
                        "reviewee_id": str(payload.reviewee_id),
                    },
                )
            )

            db.add(
                Notification(
                    recipient_id=payload.reviewee_id,
                    gig_id=gig.id,
                    type="REVIEW_RECEIVED",
                    title="Review Received",
                    body=f"You received a {final_overall_rating:.2f}★ review for gig #{gig.id}",
                )
            )

            db.commit()
            db.refresh(review)

            return cls._build_review_response(review, questions_by_id)
        except Exception:
            db.rollback()
            raise

    @classmethod
    def get_gig_reviews(
        cls,
        db: Session,
        current_user: User,
        gig_id: uuid.UUID,
    ) -> List[ReviewResponse]:
        """Retrieve reviews for a gig, gated to authenticated gig participants."""
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

        # Participant Authorization
        accepted_collaborators = (
            db.query(WorkerParticipation.additional_worker_id)
            .filter(
                WorkerParticipation.gig_id == gig.id,
                WorkerParticipation.status == WorkerParticipationStatus.ACCEPTED,
            )
            .all()
        )
        participant_ids = {r[0] for r in accepted_collaborators}
        participant_ids.add(gig.customer_id)
        if gig.selected_worker_id:
            participant_ids.add(gig.selected_worker_id)

        if current_user.id not in participant_ids:
            raise ForbiddenException(
                "Only gig participants can view reviews for this gig.",
                code="FORBIDDEN",
            )

        reviews = (
            db.query(Review)
            .filter(Review.gig_id == gig.id)
            .options(
                joinedload(Review.answers).joinedload(ReviewAnswer.question)
            )
            .order_by(Review.created_at.asc())
            .all()
        )

        response_list = []
        for r in reviews:
            ans_responses = []
            for a in r.answers:
                q_text = a.question.question_text if a.question else "Question"
                ans_responses.append(
                    ReviewAnswerResponse(
                        id=a.id,
                        question_id=a.question_id,
                        question_text=q_text,
                        answer_value=a.answer_value,
                    )
                )
            response_list.append(
                ReviewResponse(
                    id=r.id,
                    gig_id=r.gig_id,
                    reviewer_id=r.reviewer_id,
                    reviewee_id=r.reviewee_id,
                    reviewer_role=r.reviewer_role,
                    overall_rating=float(r.overall_rating),
                    answers=ans_responses,
                    created_at=r.created_at,
                )
            )

        return response_list

    @classmethod
    def get_worker_metrics(
        cls,
        db: Session,
        worker_id: uuid.UUID,
    ) -> WorkerPublicMetricsResponse:
        """Fetch customer-facing worker performance metrics conforming to 05_API_DESIGN.md Section 28."""
        worker = (
            db.query(User)
            .filter(User.id == worker_id, User.role == UserRole.WORKER)
            .first()
        )
        if not worker:
            raise NotFoundException(
                f"Worker {worker_id} not found",
                code="WORKER_NOT_FOUND",
            )

        metric = (
            db.query(WorkerMetric)
            .filter(WorkerMetric.worker_id == worker_id)
            .first()
        )
        if not metric:
            initial = get_rookie_initial_metrics()
            return WorkerPublicMetricsResponse(
                worker_id=worker_id,
                completed_jobs_count=initial["completed_jobs_count"],
                rating_average=float(initial["rating_average"]),
                rating_count=initial["rating_count"],
                final_score=float(initial["final_score"]),
            )

        return WorkerPublicMetricsResponse(
            worker_id=worker_id,
            completed_jobs_count=metric.completed_jobs_count,
            rating_average=float(metric.rating_average),
            rating_count=metric.rating_count,
            final_score=float(metric.final_score),
        )

    @staticmethod
    def _build_review_response(
        review: Review,
        questions_by_id: dict,
    ) -> ReviewResponse:
        ans_responses = []
        for a in review.answers:
            q = questions_by_id.get(a.question_id)
            q_text = q.question_text if q else "Question"
            ans_responses.append(
                ReviewAnswerResponse(
                    id=a.id,
                    question_id=a.question_id,
                    question_text=q_text,
                    answer_value=a.answer_value,
                )
            )
        return ReviewResponse(
            id=review.id,
            gig_id=review.gig_id,
            reviewer_id=review.reviewer_id,
            reviewee_id=review.reviewee_id,
            reviewer_role=review.reviewer_role,
            overall_rating=float(review.overall_rating),
            answers=ans_responses,
            created_at=review.created_at,
        )
