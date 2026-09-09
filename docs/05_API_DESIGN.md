05 — API DESIGN

SIH26089 — Cooperative Gig Services Platform

Document Type: MVP REST API Contract
Status: Implementation Baseline
Backend: FastAPI
Database: PostgreSQL / Supabase PostgreSQL
Authentication: Supabase Auth + application users table
ORM/Migrations: SQLAlchemy + Alembic
Primary Roles: Customer, Worker
Prototype Scope: One Cooperative / One City-Service Area

1. Purpose

This document defines the REST API contract for the SIH26089 MVP.

It translates the approved database design and product decisions into:

API modules;

endpoint responsibilities;

request/response structures;

authentication and authorization rules;

lifecycle/state rules;

validation rules;

error handling;

pagination/filtering conventions;

file-upload boundaries;

frontend/backend integration expectations.

The SRS remains the formal requirements reference.
04_DATABASE_DESIGN.md is the database source of truth.
This document is the API source of truth.

The API must expose business operations without moving critical business rules into Flutter.

2. API Design Principles

2.1 REST API

Use a versioned REST API:

/api/v1/...

Example:

GET /api/v1/gigs
POST /api/v1/gigs
GET /api/v1/gigs/{gig_id}

2.2 Authentication

Authentication is handled by Supabase Auth.

Flutter obtains a Supabase access token and sends:

Authorization: Bearer <access_token>

FastAPI validates the token and resolves the application user from:

Supabase Auth UUID
        ↓
users.id

The backend must not trust a client-supplied user_id when the authenticated identity is already available from the JWT.

2.3 Authorization

Every protected endpoint must determine:

Who is calling?
What role do they have?
Does this resource belong to them?
Is the current gig state valid for this action?

Examples:

Customer A cannot modify Customer B's gig.
Worker A cannot accept Worker B's opportunity.
Customer cannot submit worker payment confirmation.
Worker cannot confirm customer completion.

2.4 Backend owns business rules

Flutter is a client, not the authority.

The backend must enforce:

role restrictions;

one-role-per-user;

one-category-per-gig;

task/category consistency;

pricing;

minimum billable duration;

worker-specific wage calculation;

opportunity state;

rejected-opportunity restriction;

worker selection;

availability conflicts;

completion/payment state transitions;

review eligibility;

multi-worker consent;

same-cooperative worker restrictions;

visitation proposal state;

audit events.

2.5 Deterministic business logic

Critical calculations should be implemented as deterministic backend services.

Examples:

PricingService
AvailabilityService
WageService
ExperienceService
PaymentStateService
GigLifecycleService

Do not calculate final labour prices independently in Flutter.

3. Common API Conventions

3.1 Base URL

The deployment-specific base URL is environment configuration.

The API path begins with:

/api/v1

3.2 Content type

Normal requests:

Content-Type: application/json

File uploads should use:

multipart/form-data

or a signed-storage upload flow where appropriate.

3.3 UUIDs

Resource identifiers use UUID strings.

Example:

{
  "id": "550e8400-e29b-41d4-a716-446655440000"
}

3.4 Timestamps

Use ISO-8601 timestamps.

Example:

2026-09-08T14:30:00Z

The backend should store timestamps consistently as timezone-aware values.

3.5 Pagination

Collection endpoints should support:

?page=1&page_size=20

Recommended limits:

default page_size = 20
maximum page_size = 100

A response may use:

{
  "items": [],
  "page": 1,
  "page_size": 20,
  "total": 0
}

3.6 Common response shape

Successful single-resource responses should return the resource directly or through a consistent envelope.

Recommended:

{
  "data": {}
}

Collection:

{
  "data": [],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 0
  }
}

The implementation team may simplify this convention if FastAPI/Pydantic models remain consistent across the entire API.

4. Error Contract

Use HTTP status codes meaningfully.

Status

Meaning

400

Invalid business/request data

401

Missing/invalid authentication

403

Authenticated but not allowed

404

Resource does not exist or is not visible

409

State conflict / duplicate / concurrent action

422

Request validation error

500

Unexpected server error

Recommended error body:

{
  "error": {
    "code": "GIG_STATE_INVALID",
    "message": "This action is not allowed in the current gig state.",
    "details": {}
  }
}

Error codes should be stable enough for Flutter to react to known business errors without parsing human-readable messages.

5. API Modules

The MVP API is divided into:

1.  Authentication / User
2.  Profile
3.  Categories / Tasks
4.  Worker Availability
5.  Gigs
6.  Pricing
7.  Worker Opportunities
8.  Worker Selection
9.  Visitation
10. Multi-worker / Rookie
11. Previous Worker
12. Completion
13. Materials
14. Payment
15. Cancellation
16. Rescheduling
17. Reviews
18. Chat
19. Notifications
20. Worker Metrics
21. Audit / Internal

The API should not expose future-only modules unless explicitly activated later.

6. Authentication and Current User

Supabase Auth owns login/registration.

The FastAPI backend provides application-user initialization and current-user information.

GET /api/v1/me

Return the authenticated application user.

Response

{
  "data": {
    "id": "uuid",
    "role": "WORKER",
    "cooperative_id": "uuid",
    "full_name": "Worker Name",
    "phone": "string",
    "email": "user@example.com",
    "profile_photo_url": null,
    "is_active": true
  }
}

POST /api/v1/me/initialize

Create or initialize the application-level users record after Supabase authentication.

The server obtains the authenticated Supabase user ID from the JWT.

Request

{
  "role": "WORKER",
  "full_name": "Worker Name",
  "phone": "string"
}

Rules

The role is assigned once.

A user cannot switch to a second role in MVP.

If the application user already exists, do not silently overwrite the role.

7. Profile APIs

Customer

GET /api/v1/customer/profile

Get the authenticated customer's profile.

PATCH /api/v1/customer/profile

Update customer-specific profile information.

Example:

{
  "address": "Customer address"
}

Worker

GET /api/v1/worker/profile

Return worker profile plus relevant public metrics.

PATCH /api/v1/worker/profile

Update worker profile fields that the worker is allowed to edit.

Do not allow the client to directly modify:

final_score
experience_score
bayesian_score
completed_jobs_count
verification status

Those are backend-controlled.

Worker Aadhaar upload

POST /api/v1/worker/profile/aadhaar

Upload/store an Aadhaar document reference.

The MVP only supports document upload.

The API must not turn:

aadhaar_document_url exists

into:

Aadhaar verified

No production Aadhaar integration is part of this endpoint.

8. Categories and Tasks

These are catalogue/read APIs.

GET /api/v1/service-categories

Return active service categories.

Example:

{
  "data": [
    {
      "id": "uuid",
      "name": "Plumbing",
      "base_rate_per_minute": 5.0,
      "minimum_billable_minutes": 45
    }
  ]
}

GET /api/v1/service-categories/{category_id}/tasks

Return active tasks belonging to a category.

Example:

{
  "data": [
    {
      "id": "uuid",
      "name": "Leaking tap repair",
      "standard_duration_minutes": 20
    }
  ]
}

The frontend should use this catalogue rather than hard-coding task IDs or prices.

9. Worker Categories

GET /api/v1/worker/categories

Return the authenticated worker's categories.

PUT /api/v1/worker/categories

Replace the worker's category selection.

Request

{
  "category_ids": [
    "uuid",
    "uuid"
  ]
}

Rules:

Worker may have multiple categories.

Categories must be active.

The worker must belong to the cooperative.

10. Worker Availability

GET /api/v1/worker/availability

Return weekly recurring availability.

PUT /api/v1/worker/availability

Replace/update recurring availability.

Example:

{
  "slots": [
    {
      "day_of_week": 0,
      "start_time": "09:00",
      "end_time": "13:00",
      "is_available": true
    },
    {
      "day_of_week": 0,
      "start_time": "15:00",
      "end_time": "19:00",
      "is_available": true
    }
  ]
}

The convention for day_of_week must be fixed globally and documented in the backend.

PATCH /api/v1/worker/availability/status

Update the simple Available/Unavailable control.

Request

{
  "is_available": true
}

This is distinct from weekly recurring availability.

11. Gig Creation

POST /api/v1/gigs

Create a customer gig.

Request

{
  "category_id": "uuid",
  "gig_type": "NORMAL",
  "task_ids": [
    "uuid",
    "uuid"
  ],
  "description": "Kitchen sink is leaking.",
  "instructions": "Please bring standard tools.",
  "address": "Customer address",
  "latitude": 23.0000,
  "longitude": 72.0000,
  "scheduled_date": "2026-09-10",
  "scheduled_start_time": "15:00",
  "scheduled_end_time": "16:00",
  "expected_duration_minutes": 60,
  "is_emergency": false,
  "acceptance_deadline": null,
  "material_procurement_mode": "CUSTOMER_PURCHASES"
}

Server responsibilities

The backend must:

Verify customer role.

Verify category exists and is active.

Verify every task belongs to that category.

Calculate standard duration.

Apply minimum billable-duration rule.

Calculate base labour price.

Snapshot pricing configuration.

Create the gig and gig-task records.

Write an audit event.

The client must not submit an authoritative base_price.

12. Gig Price Preview

The customer must see the price range before posting.

POST /api/v1/gigs/price-preview

Calculate a preview without creating a gig.

Request

{
  "category_id": "uuid",
  "task_ids": [
    "uuid",
    "uuid"
  ]
}

Response

{
  "data": {
    "total_standard_minutes": 45,
    "billable_minutes": 45,
    "base_price": 225.0,
    "maximum_worker_price": 292.5,
    "currency": "INR"
  }
}

Current MVP interpretation:

minimum = base price
maximum = base price × 1.30

The exact worker wage is calculated later per worker.

13. Gig Retrieval

GET /api/v1/gigs/{gig_id}

Return the gig with relevant information for the authenticated user.

The backend must filter sensitive information according to role and lifecycle state.

GET /api/v1/customer/gigs

Customer's gigs.

Support filters such as:

status
date
category

GET /api/v1/worker/gigs

Worker's relevant gigs.

Support:

upcoming
active
completed
cancelled

14. Posting a Gig

POST /api/v1/gigs/{gig_id}/post

Move a draft gig into the opportunity flow.

Rules

Only the owning customer can post it.

Required data must be valid.

Pricing must already be calculated/snapshotted.

Audit event is written.

The backend then determines which workers should receive opportunities according to the current MVP eligibility rules.

Important MVP rule

Geographic worker eligibility has been removed.

Therefore this API must not filter workers using:

5 km radius
15–20 km radius
worker GPS
nearest worker
distance score
travel compensation

15. Worker Opportunity APIs

GET /api/v1/worker/opportunities

Return opportunities available to the authenticated worker.

Possible filters:

category
date
emergency
status

Each opportunity should include the exact wage.

Example:

{
  "id": "uuid",
  "gig_id": "uuid",
  "status": "PENDING",
  "gig": {
    "category": "Plumbing",
    "description": "Kitchen sink issue",
    "scheduled_date": "2026-09-10",
    "scheduled_start_time": "15:00"
  },
  "base_price": 225.0,
  "exact_wage": 258.75,
  "premium_percentage": 15.0
}

GET /api/v1/worker/opportunities/{opportunity_id}

Return complete opportunity details.

The exact wage must be included before acceptance.

POST /api/v1/worker/opportunities/{opportunity_id}/accept

Accept an opportunity.

Backend checks

Authenticated user is the opportunity's worker.

Opportunity is PENDING.

Acceptance deadline has not passed, if one exists.

Gig is still accepting workers.

Worker is still eligible.

Worker is not unavailable.

Worker does not have any conflicting confirmed gig.

Rejected opportunity cannot be accepted.

Gig has not already selected a worker.

Any other relevant state transition is valid.

Important conflict rule

For MVP:

ANY overlap with an existing confirmed gig
→ worker cannot accept

This includes partial overlap.

POST /api/v1/worker/opportunities/{opportunity_id}/reject

Reject an opportunity.

Rules

Only opportunity owner can reject.

Rejection is final for that opportunity.

The same opportunity cannot later be accepted.

16. Customer Accepted Candidates

GET /api/v1/gigs/{gig_id}/candidates

Return accepted workers for a gig.

Each candidate should contain information appropriate for customer transparency.

Example:

{
  "worker_id": "uuid",
  "name": "Worker Name",
  "exact_wage": 258.75,
  "completed_jobs_count": 24,
  "rating_average": 4.5,
  "rating_count": 18,
  "final_score": 0.58,
  "recommendation": null
}

Recommendation

The immediate MVP does not implement a backend recommendation engine.

Therefore do not expose a fake recommendation result.

Flutter may sort/display accepted workers using available fields such as:

price
completed jobs
rating
final score

If a recommendation engine is activated later, it should be introduced through a versioned backend contract.

17. Customer Worker Selection

POST /api/v1/gigs/{gig_id}/select-worker

Request

{
  "worker_id": "uuid"
}

Rules

Caller must be the gig's customer.

Worker must have an accepted opportunity for the gig.

Gig must be in a selectable state.

Selected worker becomes the gig's selected worker.

Other accepted opportunities become NOT_SELECTED.

Audit event is created.

Notifications are generated.

The customer retains final choice.

The API must never automatically select the recommended worker.

18. Worker-Specific Wage

The wage calculation is a backend service.

Conceptually:

Gig base price
+
Worker final_score
↓
0–30% premium
↓
Exact wage

The opportunity stores:

base_price_snapshot
final_score_snapshot
premium_percentage
exact_wage

The frontend does not submit the final wage.

If the algorithm service changes later, the old opportunity snapshot remains unchanged.

19. Visitation APIs

Visitation is represented by:

gig_type = VISITATION

The customer can request visitation during normal gig creation.

POST /api/v1/gigs/{gig_id}/visitation/request

Create/open the visitation workflow if it was not already created with the gig.

The fixed MVP visitation charge is:

₹100

GET /api/v1/gigs/{gig_id}/visitation

Return visitation state and relevant proposal information.

POST /api/v1/gigs/{gig_id}/visitation/proposals

Worker submits a visitation proposal.

Request

{
  "task_ids": [
    "uuid",
    "uuid"
  ]
}

The backend must:

Verify worker is authorized for the visitation.

Verify all tasks belong to the gig's category.

Calculate the proposed work price.

Snapshot task pricing information.

Store proposal and proposal tasks.

Write an audit event.

Notify the customer.

The client must not submit an authoritative price.

POST /api/v1/gigs/{gig_id}/visitation/proposals/{proposal_id}/accept

Customer accepts the worker proposal.

Rule

The visitation charge is not added again to the accepted work payment.

Example:

Visitation = ₹100
Work = ₹300

Final work payment = ₹300

POST /api/v1/gigs/{gig_id}/visitation/proposals/{proposal_id}/reject

Customer rejects the proposal.

Result:

₹100 visitation charge remains payable
No work payment is created for the rejected work proposal

Only Accept/Reject is supported in MVP.

No negotiation or worker bidding is created.

20. Multi-Worker APIs

POST /api/v1/gigs/{gig_id}/participations

Invite another verified cooperative worker.

Request

{
  "additional_worker_id": "uuid",
  "classification": "ROOKIE"
}

Allowed:

ROOKIE
EQUAL_SHARING

Backend checks

Inviting worker is an authorized participating worker.

Additional worker belongs to the same cooperative.

Additional worker is verified according to the MVP verification rule.

Additional worker is not already participating.

Gig state allows additional workers.

The platform does not calculate private worker compensation.

GET /api/v1/gigs/{gig_id}/participations

Return participation records visible to the authenticated participant/customer as appropriate.

Do not expose private worker-to-worker compensation.

POST /api/v1/participations/{participation_id}/accept

Additional worker accepts.

POST /api/v1/participations/{participation_id}/reject

Additional worker rejects.

The invitation must remain explicit-consent based.

21. Previous Worker Booking

POST /api/v1/gigs/{gig_id}/previous-worker-request

Request

{
  "worker_id": "uuid"
}

Rules:

Worker must have a valid previous relationship with the customer.

Worker receives the request.

Worker may accept, reject, or request rescheduling.

If the customer opens the gig to other workers, normal opportunity flow can begin.

POST /api/v1/previous-worker-requests/{request_id}/accept

Worker accepts.

POST /api/v1/previous-worker-requests/{request_id}/reject

Worker rejects.

POST /api/v1/previous-worker-requests/{request_id}/reschedule

Worker requests rescheduling.

22. Completion APIs

POST /api/v1/gigs/{gig_id}/completion

Worker submits completion.

The request should be multipart/form-data or use previously uploaded file references.

Example metadata:

{
  "description": "Repair completed and tested."
}

Files:

evidence images

Rules

Caller must be an authorized worker participant.

Gig must be in an active state.

Evidence must be stored.

Completion submission is created.

Gig moves to completion-request state.

Customer is notified.

It does not make the gig fully completed.

GET /api/v1/gigs/{gig_id}/completion

Return completion submission/evidence information available to the authenticated parties.

POST /api/v1/gigs/{gig_id}/completion/confirm

Customer confirms completion.

Request

{
  "confirmed": true,
  "response_note": null
}

Rules

Caller must be the customer.

Completion evidence must exist.

The gig must be awaiting customer confirmation.

On confirmation, payment becomes available.

On rejection, the backend must retain the response and return the gig to the defined correction/rework state.

If the MVP does not define a separate rework state, the implementation must not invent one silently; document the chosen transition before coding it.

23. Material APIs

POST /api/v1/gigs/{gig_id}/material-receipts

Worker uploads a material receipt/proof when worker procurement is selected.

Request:

multipart/form-data

Fields:

amount
description
receipt file

Rules:

Only allowed when material_procurement_mode = WORKER_PURCHASES.

Worker must be an authorized participant.

Customer can later view the receipt.

GET /api/v1/gigs/{gig_id}/material-receipts

Return material receipts visible to authorized participants.

Material dispute resolution is outside MVP.

24. Payment APIs

GET /api/v1/gigs/{gig_id}/payment

Return payment status.

POST /api/v1/gigs/{gig_id}/payment

Customer records payment action.

Request

{
  "payment_method": "CASH"
}

or:

{
  "payment_method": "UPI"
}

The backend creates/updates:

PENDING
→ CUSTOMER_PAID

as appropriate.

The exact production payment gateway is outside the current MVP.

For UPI, the Flutter application may launch a UPI deeplink, but the backend must not claim automatic receipt verification.

POST /api/v1/gigs/{gig_id}/payment/confirm-receipt

Worker confirms receipt.

Request

{
  "confirmed": true
}

Rules

Caller must be the selected/authorized worker.

Customer payment must already be recorded.

On confirmation:

payment = WORKER_CONFIRMED
gig = COMPLETED

The gig must not become fully completed before worker payment acknowledgement.

25. Cancellation APIs

POST /api/v1/gigs/{gig_id}/cancel

Customer or worker cancels where the current state permits it.

Request

{
  "reason": "Unable to continue."
}

The backend calculates any applicable cancellation fee using configuration.

The client must not submit the authoritative cancellation fee.

A cancellation record and audit event are created.

Worker cancellation continuation

When the worker cancels, the customer must be able to choose:

Find another worker
OR
Stop

Recommended API:

POST /api/v1/gigs/{gig_id}/reopen

Customer chooses to find another worker.

The same gig is reopened; a new unrelated gig should not be created.

26. Rescheduling APIs

POST /api/v1/gigs/{gig_id}/reschedule-requests

Create a reschedule request.

Request

{
  "proposed_date": "2026-09-12",
  "proposed_start_time": "14:00",
  "proposed_end_time": "15:00",
  "reason": "Need a different time."
}

GET /api/v1/gigs/{gig_id}/reschedule-requests

Return reschedule history/current request.

POST /api/v1/reschedule-requests/{request_id}/accept

Accept.

POST /api/v1/reschedule-requests/{request_id}/reject

Reject.

POST /api/v1/reschedule-requests/{request_id}/alternative

Propose an alternative.

The backend must validate the new schedule against the relevant worker availability and conflict rules before applying an accepted schedule.

27. Reviews

GET /api/v1/review-questions

Return active structured review questions appropriate for the authenticated user's review target.

POST /api/v1/gigs/{gig_id}/reviews

Submit a review.

Request

{
  "reviewee_id": "uuid",
  "overall_rating": 4.5,
  "answers": [
    {
      "question_id": "uuid",
      "answer_value": 5
    },
    {
      "question_id": "uuid",
      "answer_value": 4
    }
  ]
}

Rules

Gig must be fully completed.

Reviewer must be a participant.

Reviewee must be the other participant.

One reviewer/reviewee review per gig.

Questions must be active and applicable.

Review cannot be submitted before completion.

The exact final review questions/scoring remain configurable.

GET /api/v1/gigs/{gig_id}/reviews

Return reviews visible to authorized users.

28. Worker Metrics

GET /api/v1/workers/{worker_id}/metrics

Return customer-visible worker metrics that are allowed by the privacy rules.

Possible fields:

{
  "completed_jobs_count": 24,
  "rating_average": 4.5,
  "rating_count": 18,
  "final_score": 0.58
}

Do not expose internal algorithm implementation details or private worker data unnecessarily.

29. Chat APIs

Chat is job-scoped.

GET /api/v1/gigs/{gig_id}/conversation

Return the conversation for the authenticated customer/selected worker.

POST /api/v1/gigs/{gig_id}/conversation/messages

Send a message.

Request

{
  "message_text": "I will arrive at 3 PM."
}

Rules

Only authorized customer/worker participants can send messages.

Chat availability follows the product lifecycle decision.

MVP does not create public community chat.

GET /api/v1/gigs/{gig_id}/conversation/messages

Return paginated messages.

Recommended:

?before=<message_id>&limit=50

or a timestamp/cursor-based equivalent.

30. Notifications

GET /api/v1/notifications

Return the authenticated user's notifications.

Filters:

is_read
type

POST /api/v1/notifications/{notification_id}/read

Mark one notification as read.

POST /api/v1/notifications/read-all

Mark all relevant notifications as read.

Notifications should be generated from important state changes rather than manually created by Flutter.

31. Audit / Internal APIs

Audit records are primarily backend concerns.

GET /api/v1/gigs/{gig_id}/events

This endpoint may be restricted to development/debugging or future administrative roles.

MVP customers/workers should not automatically receive the complete internal event log.

The backend must still write events for important transitions.

Examples:

GIG_CREATED
GIG_POSTED
WORKER_OPPORTUNITY_CREATED
WORKER_ACCEPTED
WORKER_REJECTED
WORKER_SELECTED
VISITATION_PROPOSED
VISITATION_ACCEPTED
VISITATION_REJECTED
COMPLETION_SUBMITTED
CUSTOMER_CONFIRMED
PAYMENT_CUSTOMER_PAID
PAYMENT_WORKER_CONFIRMED
CANCELLED
RESCHEDULE_REQUESTED
RESCHEDULE_ACCEPTED
RESCHEDULE_REJECTED
REVIEW_SUBMITTED

32. Gig State Machine

The API should enforce lifecycle transitions rather than allowing arbitrary status updates.

Core flow:

DRAFT
  ↓
POSTED / ACCEPTANCE_OPEN
  ↓
WORKERS ACCEPT / REJECT
  ↓
WORKER_SELECTED
  ↓
SCHEDULED
  ↓
IN_PROGRESS
  ↓
COMPLETION_SUBMITTED
  ↓
CUSTOMER_CONFIRMED
  ↓
PAYMENT_PENDING
  ↓
PAYMENT_CUSTOMER_PAID
  ↓
PAYMENT_WORKER_CONFIRMED
  ↓
COMPLETED

Possible alternate states:

CANCELLED
RESCHEDULE_REQUESTED
NO_WORKER_ACCEPTED

The backend must reject illegal transitions with 409 or an equivalent stable business error.

33. Role/Permission Matrix

Operation

Customer

Worker

View own profile

✓

✓

Edit own profile

✓

✓

Manage worker categories

—

✓

Manage availability

—

✓

Create gig

✓

—

Preview price

✓

✓*

Post own gig

✓

—

View own opportunities

—

✓

Accept opportunity

—

✓

Reject opportunity

—

✓

View accepted candidates

✓

—

Select worker

✓

—

Invite additional worker

—

✓

Accept join request

—

✓

Submit completion evidence

—

✓

Confirm completion

✓

—

Record customer payment

✓

—

Confirm payment receipt

—

✓

Cancel own allowed gig

✓

✓

Request reschedule

✓

✓

Review other participant

✓

✓

Send job chat message

✓

✓

View notifications

✓

✓

* Worker price-preview access is optional; the customer-facing price-preview endpoint is the primary MVP use.

34. Important Validation Rules

Authentication

JWT must be valid.
Application user must exist.

Role

Exactly one role.

Gig

Exactly one category.

Tasks

All selected tasks must belong to gig category.

Pricing

Client cannot override calculated base price.

Opportunity

One opportunity per gig/worker.
Rejected opportunity cannot be accepted.

Selection

Only accepted worker can be selected.

Availability

Any overlap with a confirmed gig blocks acceptance.

Multi-worker

Additional worker must be same-cooperative and verified.
Explicit acceptance is required.

Completion

Evidence required before customer confirmation.

Payment

Customer payment precedes worker receipt confirmation.

Reviews

Only after completed gig.
One directional review per participant pair per gig.

Visitation

Same category.
Same task catalogue.
Only Accept/Reject.
Rejected proposal does not create work payment.

35. What the API Must NOT Expose as Client-Controlled Values

The client must not be able to directly set:

worker final_score
experience_score
bayesian_score
completed_jobs_count
base_price
worker exact wage
premium percentage
cancellation fee
payment completion status
gig status
review eligibility
verification status
experience contribution
audit timestamps

The backend calculates or controls these values.

36. File Upload Strategy

The backend should avoid storing large binary files directly inside PostgreSQL.

Recommended architecture:

Flutter
   ↓
Backend upload endpoint / signed upload
   ↓
Supabase Storage
   ↓
Stored file URL/reference
   ↓
PostgreSQL record

Relevant file types include:

Aadhaar document
Completion evidence
Material receipt
Profile photo

Access to sensitive files must be authorization-controlled.

37. API ↔ Database Mapping

The API should map cleanly onto the database design.

Examples:

POST /gigs
        ↓
gigs
gig_tasks
gig_events

worker opportunity
        ↓
gig_worker_opportunities

completion
        ↓
completion_submissions
completion_evidence

payment
        ↓
payments

review
        ↓
reviews
review_answers

chat
        ↓
conversations
messages

notification
        ↓
notifications

The API layer should not bypass the repository/service architecture.

38. Backend Layer Contract

Follow the project's established implementation pattern:

API Router
    ↓
Pydantic Schema
    ↓
Service
    ↓
Repository
    ↓
SQLAlchemy Model
    ↓
PostgreSQL

For algorithmic operations:

API Router
    ↓
Service
    ↓
Pricing / Wage / Availability service
    ↓
Repository

The Student Buddy methodology explicitly used the pattern:

Database Table
↓
SQLAlchemy Model
↓
Pydantic Schema
↓
Repository
↓
Service
↓
API Router
↓
Tests

This project should follow the same bounded, module-by-module approach.

39. API Module Implementation Order

Given the MVP deadline, implement the API in this order.

API Sprint 0 — Backend Foundation

Deliver:

FastAPI project structure

Environment configuration

PostgreSQL connection

SQLAlchemy

Alembic

Base models

Exception handling

API dependency system

Health endpoint

Test setup

API Sprint 1 — Users / Profiles

Deliver:

current user

user initialization

customer profile

worker profile

worker categories

worker availability

API Sprint 2 — Catalogue + Pricing

Deliver:

categories

tasks

price preview

deterministic base-price calculation

pricing snapshots

API Sprint 3 — Gig Creation

Deliver:

create gig

validate tasks/category

post gig

customer gig retrieval

gig details

audit events

API Sprint 4 — Opportunities

Deliver:

opportunity generation

worker opportunity list

opportunity details

accept

reject

availability conflict validation

exact wage snapshot

This is one of the highest-priority MVP sprints.

API Sprint 5 — Selection + Core Lifecycle

Deliver:

accepted candidates

customer worker selection

scheduled/active states

notifications

state transition validation

API Sprint 6 — Completion + Payment

Deliver:

evidence upload

customer confirmation

payment creation

cash/UPI status

worker receipt confirmation

completed state

This completes the main demo lifecycle.

API Sprint 7 — Remaining MVP

Deliver:

visitation

multi-worker

rookie progression

previous worker

cancellation

rescheduling

material receipts

reviews

chat

notifications refinement

40. Testing Contract

Every endpoint must have tests appropriate to its risk.

At minimum:

Authentication

valid token
invalid token
missing token
wrong role

Gig

valid creation
invalid category
task/category mismatch
invalid schedule

Opportunity

accept
reject
double accept
accept after reject
accept after deadline
conflict

Selection

accepted worker selection
non-accepted worker
wrong customer
duplicate selection

Completion

evidence submission
confirmation without evidence
wrong role
wrong state

Payment

customer payment
worker receipt confirmation
confirmation before customer payment
wrong worker

Reviews

before completion
after completion
duplicate review
wrong participant

Multi-worker

same cooperative
different cooperative
verified worker
unverified worker
explicit accept
explicit reject

41. Transaction and Concurrency Rules

State-changing operations should be transactional where multiple records must change together.

Example: selecting a worker should atomically:

1. Verify candidate is accepted.
2. Set gig.selected_worker_id.
3. Mark selected opportunity accordingly.
4. Mark other accepted opportunities NOT_SELECTED.
5. Create audit event.
6. Create notifications.

Do not perform these as unrelated client-driven requests.

The same principle applies to:

payment state transitions
completion confirmation
worker selection
visitation acceptance
reschedule acceptance
worker opportunity acceptance

42. Idempotency

Important state-changing operations should safely handle duplicate client requests.

Examples:

POST accept
POST payment
POST completion
POST review

If Flutter retries because of a network timeout, the backend should not accidentally:

create duplicate payment
create duplicate review
create duplicate opportunity
create duplicate participation

Use unique database constraints and/or idempotency keys where appropriate.

43. Security Rules

At minimum:

Validate Supabase JWTs.

Authorize every resource.

Never trust client user IDs for ownership.

Validate all state transitions server-side.

Validate uploaded file types and sizes.

Protect sensitive document URLs.

Do not expose Aadhaar documents to customers.

Do not expose private worker compensation.

Do not expose unnecessary internal algorithm data.

Do not allow clients to modify audit history.

Do not allow clients to directly modify calculated metrics.

Production security/compliance requirements remain a later detailed stage, but MVP authorization must still be enforced correctly.

44. Frontend Integration Contract

Flutter should communicate through repositories/services.

Recommended:

Screen
  ↓
Riverpod Provider
  ↓
Repository
  ↓
Dio
  ↓
FastAPI

Do not place API calls directly inside UI widgets.

For each endpoint, the frontend team needs:

HTTP method
Path
Authentication requirement
Request model
Response model
Known error codes
Lifecycle prerequisites

The API document is the shared contract between frontend and backend.

45. Algorithm Integration Boundary

The current immediate MVP does not require a backend recommendation engine.

Therefore:

Backend
   ↓
Accepted workers
   +
exact worker wages
   +
worker metrics
   ↓
Flutter

The backend still owns wage calculation.

If/when the recommendation algorithm is activated:

Accepted workers
   ↓
Recommendation service
   ↓
recommended worker + explanation + algorithm version

The recommendation system must remain advisory.

The customer retains final choice.

46. Important MVP Decisions

The following decisions override older SRS wording where they were explicitly finalized during database design:

Geographic eligibility

Removed from MVP.

No worker GPS/radius filtering.

Availability conflicts

Any overlap with an existing confirmed gig blocks acceptance.

Recommendation

Deferred from immediate MVP implementation.

Wage

Base price comes from selected task standard durations and category rate.

Worker-specific wage uses the worker final-score premium model.

Rookie

Rookie participation contributes:

complexity × 0.5

to experience.

Role

One user = one role.

Categories

Worker can have multiple categories.

One gig = one category.

Multiple tasks are allowed within that category.

Visitation

gig_type = VISITATION
visitation charge = ₹100
customer proposal response = Accept / Reject

Accepted work does not add the ₹100 again.

Payment

CUSTOMER_PAID
→ WORKER_CONFIRMED
→ COMPLETED

Location

Customer gig location stores address + map coordinates.

Worker location is not required for MVP matching.

47. API Documentation in FastAPI

FastAPI should expose generated OpenAPI documentation.

Development endpoints:

/docs
/openapi.json

These are implementation/deployment paths rather than product endpoints.

The generated OpenAPI specification should match this document.

If the implementation differs from this contract, update the API document and decision/history documentation rather than silently allowing drift.

48. Definition of Done

An API module is complete when:

Implementation

Router exists.

Pydantic request/response schemas exist.

Service logic exists.

Repository logic exists.

Database models/migrations exist where required.

Validation

Role authorization works.

Resource ownership works.

Business rules are enforced.

Invalid states are rejected.

Testing

Happy path tested.

Invalid input tested.

Unauthorized access tested.

State conflicts tested.

Duplicate/retry behaviour tested where relevant.

Documentation

Endpoint documented.

Request/response documented.

Error codes documented.

Important product decisions recorded.

49. Final Core API Flow

The most important end-to-end API sequence is:

Supabase Auth
    ↓
GET /me
    ↓
POST /gigs/price-preview
    ↓
POST /gigs
    ↓
POST /gigs/{id}/post
    ↓
Backend creates worker opportunities
    ↓
Worker:
GET /worker/opportunities
    ↓
POST /worker/opportunities/{id}/accept
    ↓
Customer:
GET /gigs/{id}/candidates
    ↓
POST /gigs/{id}/select-worker
    ↓
Worker performs job
    ↓
POST /gigs/{id}/completion
    ↓
Customer:
POST /gigs/{id}/completion/confirm
    ↓
POST /gigs/{id}/payment
    ↓
Worker:
POST /gigs/{id}/payment/confirm-receipt
    ↓
Gig = COMPLETED
    ↓
Both:
POST /gigs/{id}/reviews

This is the primary API path that should be made reliable first.

50. Final API Architecture

Flutter
  │
  │ HTTPS + Bearer JWT
  ▼
FastAPI
  │
  ├── Auth/User Service
  ├── Profile Service
  ├── Catalogue Service
  ├── Pricing Service
  ├── Gig Service
  ├── Opportunity Service
  ├── Availability Service
  ├── Wage Service
  ├── Completion Service
  ├── Payment Service
  ├── Review Service
  ├── Chat Service
  ├── Notification Service
  └── Audit/Event Service
  │
  ▼
Repositories
  │
  ▼
SQLAlchemy
  │
  ▼
Supabase PostgreSQL

File uploads
  ↓
Supabase Storage
  ↓
Database file references

The API should remain a thin HTTP boundary around well-defined backend services. Critical business rules belong below the router layer, while Flutter remains responsible for presentation and user interaction.

51. Implementation Rule

Do not implement every endpoint at once.

Follow the project's documented development methodology:

Database table
↓
Model
↓
Schema
↓
Repository
↓
Service
↓
Router
↓
Tests
↓
Verification
↓
Documentation update

Work module-by-module.

The immediate priority is the smallest complete working path:

User
↓
Profile
↓
Catalogue
↓
Pricing
↓
Gig
↓
Opportunity
↓
Accept
↓
Select
↓
Complete
↓
Pay
↓
Review

Once that path is stable, add the remaining MVP flows.

Future features must not become hidden dependencies of this API.