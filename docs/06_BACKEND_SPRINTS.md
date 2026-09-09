06 — BACKEND SPRINTS

SIH26089 — Sahakaar Seva Cooperative Gig Services Platform

Document Type: MVP Backend + Database Implementation Roadmap
Status: Ready for Implementation
Priority: MVP / Hackathon Critical
Backend: FastAPI
Database: PostgreSQL / Supabase PostgreSQL
Authentication: Supabase Auth
ORM: SQLAlchemy
Migrations: Alembic
API: REST /api/v1
Frontend: Flutter + Dio + Riverpod
Algorithm Input: wages.md

1. Purpose

This document converts the approved database design and API design into an implementation plan for the complete MVP backend and database.

The frontend is substantially implemented already. The immediate objective is therefore not to redesign the frontend and not to build future features.

The objective is to make the existing Flutter frontend communicate with a real backend and database through a reliable end-to-end MVP flow.

The implementation team must prioritize a working complete flow over architectural overengineering.

The target critical flow is:

Authentication
    ↓
Profile
    ↓
Service Category / Tasks
    ↓
Price Preview
    ↓
Customer Creates Gig
    ↓
Customer Posts Gig
    ↓
Backend Creates Worker Opportunities
    ↓
Workers Accept / Reject
    ↓
Customer Sees Accepted Workers
    ↓
Customer Selects Worker
    ↓
Worker Performs Job
    ↓
Worker Uploads Completion Evidence
    ↓
Customer Confirms Completion
    ↓
Customer Pays Cash / UPI
    ↓
Worker Confirms Receipt
    ↓
Gig Completed
    ↓
Reviews

This flow is the highest priority.

2. Source-of-Truth Documents

Before implementing anything, the backend team/AI must read these documents completely:

docs/
├── SRS_Final.md
├── WAGES.md
├── 04_DATABASE_DESIGN.md
├── 05_API_DESIGN.md
├── context.md
├── history.md
└── this file: 06_BACKEND_SPRINTS.md

If the actual filenames differ, locate the corresponding documents in the project.

Authority order

When two documents conflict, use this order:

1. Explicit latest project decisions recorded in documentation
2. 04_DATABASE_DESIGN.md
3. 05_API_DESIGN.md
4. WAGES.md for wage/experience algorithm rules
5. SRS_Final.md
6. Older planning/roadmap documents

Do not revive an older feature simply because it appears in the SRS_Final.md if it was explicitly removed from the MVP.

3. Critical MVP Scope

The following are IN scope.

Customer

Registration/login through Supabase Auth

Customer profile

Category selection

Multiple tasks within one category

Gig description/instructions

Address

Map pin/location

Google Maps link/deep-link storage

Date/time scheduling

Duration

Labour price preview

Gig creation/posting

Worker opportunity/candidate viewing

Worker selection

Active job

Completion evidence review

Completion confirmation

Cash payment

UPI deeplink initiation

Payment status

Cancellation

Rescheduling

Material receipt viewing

Chat

Review

Worker

Registration/login

Worker profile

Aadhaar document upload only

Worker category eligibility

Weekly recurring availability

Available/unavailable status

Opportunity list

Opportunity details

Exact worker wage

Accept/reject

Conflict handling

My jobs

Active job

Multi-worker participation

Rookie progression

Material receipt upload

Completion evidence upload

Payment receipt confirmation

Cancellation/rescheduling

Chat

Review

4. Explicit MVP Exclusions

Do NOT spend MVP time implementing:

Worker recommendation algorithm
Geographic matching/radius filtering
Worker GPS tracking
Nearest-worker ranking
Travel-distance compensation
Payment gateway
Automatic payment verification
Aadhaar verification mechanism
Multiple roles per account
Multi-category gig
Multiple independent service categories in one gig
Worker bidding/negotiation
Complex pricing negotiation
Advanced earnings analytics
Guild dividend/patronage calculations unless already required by the finalized database/API
Emergency worker travel optimization
Production-grade KYC integration

The frontend may contain screens/placeholders for some of these concepts. The backend must not accidentally implement them unless explicitly required by the current approved documents.

5. Most Important Product Rules

5.1 One role per user

A user has exactly one role:

CUSTOMER
OR
WORKER

The MVP does not support switching between roles.

5.2 Worker categories

A worker can be eligible for multiple service categories.

Example:

Worker A
    Plumbing
    Electrical

A gig has exactly one category.

5.3 Multiple tasks

A customer can select multiple tasks, but all selected tasks must belong to the gig's single category.

Example:

Category: Plumbing

Task 1: Tap fixing
Task 2: Clog fixing

Valid.

This is invalid:

Plumbing + Electrical

inside the same gig.

6. Pricing and Wages — MUST READ wages.md

The implementation team must read wages.md before writing the wage/pricing service.

Do not hard-code values merely because examples appear in older planning documents.

The algorithm team has provided the authoritative wage/experience rules in wages.md.

The backend must convert those rules into deterministic services.

7. Base Price and Minimum Billable Time

The standard task duration is the duration normally associated with performing the task.

It is not the actual time the worker eventually takes.

For a gig:

total standard task duration
        ↓
minimum billable duration
        ↓
billable minutes
        ↓
category rate per minute
        ↓
base price

Example:

Task A = 20 minutes
Task B = 25 minutes

Total = 45 minutes

Minimum billable duration = 45 minutes

Billable duration = 45 minutes

If:

Category rate = ₹5/minute

then:

Base price = 45 × ₹5
           = ₹225

If tasks total only 15 minutes:

15 minutes < 45-minute minimum

Billable duration = 45 minutes
Base price = 45 × ₹5
           = ₹225

If tasks total 75 minutes:

75 minutes > 45-minute minimum

Billable duration = 75 minutes
Base price = 75 × ₹5
           = ₹375

The backend must calculate this. Flutter must not be the authoritative calculator.

8. Worker-Specific Wage

The customer first sees a price range.

Conceptually:

Base Price
    ↓
Worker experience/final score
    ↓
Worker premium
    ↓
Exact worker wage

The current approved model uses the worker's final_score to determine the premium, with the wage range reaching the maximum premium defined by wages.md.

The worker must see their exact wage before accepting.

The customer must see the exact wage for each worker who accepts.

The selected worker receives the same exact amount that the customer sees.

The full labour amount goes to the worker.

9. Worker Metrics

Every worker has these three important concepts:

1. Ratings
2. Number of jobs done
3. Final score

final_score is the important experience-related value used by the wage model.

Do not replace final score with job count.

A worker can have many jobs of low complexity and therefore not necessarily have the same experience contribution as a worker who has completed fewer but more complex jobs.

10. Rookie Rule

When a worker participates as a rookie/apprentice:

rookie contribution = 0.5 × normal complexity contribution

The backend must apply this rule when calculating the relevant worker experience progression.

Do not interpret rookie participation as receiving the full complexity contribution.

The exact algorithmic inputs/parameters must come from wages.md.

11. Algorithm Integration Strategy

The algorithm team has provided the algorithm in:

wages.md

The backend team must not block the sprint waiting for another algorithm implementation unless wages.md is missing a required rule.

Implementation approach:

wages.md
    ↓
Extract required parameters/rules
    ↓
Document mapping in backend code
    ↓
Create deterministic Wage/Experience service
    ↓
Write unit tests against examples/rules

If the algorithm changes later, update the service/configuration and tests without changing the API contract unnecessarily.

12. Location and Google Maps

The customer must be able to pin the house location using the map integrated into the customer-side gig creation UI.

The backend stores the relevant location information.

Recommended stored information:

address
latitude
longitude
google_maps_link

The worker does not receive an in-app map implementation.

The worker receives the Google Maps link and taps it.

The mobile OS should open the installed Google Maps application where supported.

The backend is responsible for storing and returning the link; it is not responsible for implementing the Google Maps UI.

No worker GPS tracking or geographic eligibility logic is part of MVP.

13. Visitation Rule

A customer may not know which task is required.

The customer can request a visitation.

The fixed visitation charge is:

₹100

The worker can inspect the problem and add the appropriate tasks.

The worker's task proposal is sent to the customer for confirmation.

Only:

ACCEPT
REJECT

are supported in MVP.

If customer accepts:

₹100 visitation charge is not added again.

Example:

Visitation = ₹100
Work proposal = ₹300

Final work charge = ₹300

If customer rejects:

Customer owes ₹100 visitation charge.
No rejected work charge is created.

This flow must be implemented transactionally.

14. Worker Availability

Workers maintain:

weekly recurring availability

for future gigs.

Example:

Monday 09:00–13:00
Monday 15:00–19:00
...
Sunday ...

There is also an availability status/toggle.

The backend must use availability when validating acceptance.

15. Conflict Rule

For MVP:

ANY overlap with an existing confirmed gig
→ worker cannot accept another gig.

This includes partial overlap.

Example:

Existing gig: 10:00–11:00

New gig: 10:30–11:30

Result:
BLOCKED

The backend must enforce this even if the frontend already displays a warning.

16. Future Gig Acceptance Rule

For MVP, the worker must NOT be allowed to accept a gig that violates the finalized future-availability/acceptance restriction documented during database design.

This decision is important because the frontend may visually present future-job availability.

The backend remains authoritative.

If the finalized database/API documents mark a particular future acceptance path as disabled, preserve that restriction even if the frontend contains the corresponding screen.

Do not silently change this rule while implementing.

17. Payment Rule

There is no payment gateway in MVP.

Payment channels:

CASH
UPI

For UPI:

Backend provides the required payment information/link data
        ↓
Flutter launches UPI deeplink
        ↓
Customer completes payment in installed UPI application
        ↓
Worker is asked whether money was received
        ↓
Worker confirms receipt

There is no automatic payment verification mechanism.

Payment lifecycle:

PENDING
    ↓
CUSTOMER_PAID
    ↓
WORKER_CONFIRMED

The gig becomes fully completed only after the worker confirms receipt.

18. Aadhaar Rule

Worker registration contains an Aadhaar document upload.

For MVP:

Upload = supported
Verification = NOT implemented

Do not implement Aadhaar verification APIs, OCR, government verification, or KYC automation.

19. Recommendation and Sorting

The backend does NOT implement the worker recommendation algorithm for MVP.

Backend returns accepted workers.

Flutter may sort them using:

price
number of jobs
rating

The backend must provide the required values but must not decide the customer's final ordering.

The customer chooses the worker.

20. Architecture

Use:

Flutter
   ↓
Dio
   ↓
FastAPI Router
   ↓
Pydantic Schema
   ↓
Service
   ↓
Repository
   ↓
SQLAlchemy Model
   ↓
PostgreSQL / Supabase

For file storage:

Flutter
   ↓
Upload endpoint / signed upload
   ↓
Supabase Storage
   ↓
File reference
   ↓
PostgreSQL

21. Development Rules

Rule 1 — Do not redesign the database during implementation

04_DATABASE_DESIGN.md is already approved.

If an implementation issue genuinely requires a schema change:

Stop.

Explain the issue.

Explain the proposed change.

Update the database design document.

Update API design if affected.

Then implement.

Do not silently modify the schema.

Rule 2 — Do not silently change API contracts

If an endpoint needs to change:

Document the reason
↓
Update 05_API_DESIGN.md
↓
Update implementation

Rule 3 — Ask before severe architectural changes

Do not make unapproved changes to:

authentication architecture
database architecture
API architecture
role model
pricing model
wage algorithm
gig lifecycle
payment lifecycle
storage architecture

Small implementation fixes do not require approval.

Rule 4 — Keep MVP practical

The project has a very short implementation window.

Prefer:

correct + testable + understandable

over:

over-engineered + slow + theoretically perfect

22. Sprint Strategy

The backend should be built in vertical slices.

Do not spend the entire first half of the day creating every repository and every empty router.

Instead:

Database foundation
    ↓
Auth/profile
    ↓
Catalogue/pricing
    ↓
Gig
    ↓
Opportunity
    ↓
Selection
    ↓
Completion
    ↓
Payment

After the core path works, add secondary MVP features.

23. Sprint 0 — Backend Foundation

Goal

Create the backend project and make database connectivity reliable.

Tasks

Create FastAPI application structure.

Configure environment variables.

Configure Supabase/PostgreSQL connection.

Configure SQLAlchemy.

Configure Alembic.

Create base model.

Create database session dependency.

Create API router structure.

Create health endpoint.

Create common response/error utilities.

Configure Pydantic settings.

Configure logging.

Configure CORS for Flutter development.

Create pytest setup.

Create initial migration workflow.

Suggested structure

backend/
├── app/
│   ├── main.py
│   ├── core/
│   │   ├── config.py
│   │   ├── security.py
│   │   └── exceptions.py
│   ├── db/
│   │   ├── session.py
│   │   ├── base.py
│   │   └── models/
│   ├── api/
│   │   └── v1/
│   │       ├── router.py
│   │       └── endpoints/
│   ├── schemas/
│   ├── repositories/
│   ├── services/
│   └── tests/
├── alembic/
├── alembic.ini
├── requirements.txt
└── .env.example

Definition of Done

GET /api/v1/health
→ 200

Database connection
→ works

Alembic migration
→ works

Test suite
→ runs

24. Sprint 1 — Database Schema + Models

Goal

Implement the approved 04_DATABASE_DESIGN.md schema.

Tasks

Translate every approved table into SQLAlchemy models.

Add primary keys.

Add foreign keys.

Add unique constraints.

Add check constraints where practical.

Add indexes.

Add timestamps.

Add enum/state fields.

Add relationship mappings.

Create initial Alembic migration.

Apply migration to development database.

Verify schema.

Important

Do not create a simplified database just to make the API easier.

Implement the approved design.

Definition of Done

All MVP tables exist
Foreign keys work
Constraints work
Indexes exist where required
Migration can recreate schema
Models load successfully

25. Sprint 2 — Authentication + Profiles

Goal

Connect Supabase Auth identities to application users.

Endpoints

GET  /api/v1/me
POST /api/v1/me/initialize

GET  /api/v1/customer/profile
PATCH /api/v1/customer/profile

GET  /api/v1/worker/profile
PATCH /api/v1/worker/profile

POST /api/v1/worker/profile/aadhaar

Also implement

worker categories
worker availability

Tests

valid JWT

invalid JWT

missing JWT

customer authorization

worker authorization

one-role enforcement

profile ownership

Aadhaar upload reference

Definition of Done

A newly authenticated Flutter user can initialize their backend account and retrieve/update the correct profile.

26. Sprint 3 — Catalogue + Wage Engine

Goal

Make service categories, tasks, pricing, and wage calculation real.

Endpoints

GET /api/v1/service-categories
GET /api/v1/service-categories/{category_id}/tasks
POST /api/v1/gigs/price-preview

Services

CatalogueService
PricingService
WageService
ExperienceService

Pricing tests

At minimum test:

15-minute task
→ 45-minute minimum

20 + 25 minutes
→ 45 minutes

75-minute total
→ 75 minutes

Also test multiple tasks under the same category.

Reject:

tasks from different categories

Wage tests

Use the actual examples/rules from wages.md.

Test:

minimum-score worker
maximum-score worker
intermediate-score worker
rookie contribution
premium boundaries
rounding

Definition of Done

The same input always produces the same expected price/wage.

27. Sprint 4 — Customer Gig Creation

Goal

Make customer gig creation/posting functional.

Endpoints

POST /api/v1/gigs
GET  /api/v1/gigs/{gig_id}
GET  /api/v1/customer/gigs
POST /api/v1/gigs/{gig_id}/post

Implement

category validation

task validation

standard duration calculation

minimum billable duration

base price calculation

location storage

Google Maps link storage

schedule validation

material procurement mode

gig creation

audit event

posting state

Transaction

Creating a gig must atomically create:

gig
gig tasks
pricing snapshot
location data
audit event

where applicable according to the approved schema.

Definition of Done

Customer can create and post a gig from Flutter and retrieve it again from the backend.

28. Sprint 5 — Worker Opportunity Engine

Goal

Turn a posted gig into worker opportunities.

Endpoint

GET /api/v1/worker/opportunities
GET /api/v1/worker/opportunities/{opportunity_id}

POST /api/v1/worker/opportunities/{opportunity_id}/accept
POST /api/v1/worker/opportunities/{opportunity_id}/reject

Eligibility

For MVP, check:

worker active
worker category eligibility
same cooperative
required verification/eligibility rule
availability
schedule conflict
gig state

Do NOT check:

distance
GPS
radius
nearest worker
travel compensation

Wage

For every opportunity:

base price snapshot
worker final score snapshot
premium percentage
exact wage

must be determined according to the approved wage rules.

Acceptance transaction

Acceptance must atomically verify:

opportunity is pending
worker is correct worker
worker is eligible
no conflicting confirmed gig
gig still allows acceptance

then change the state.

Definition of Done

Two workers can receive the same gig opportunity and independently accept/reject it, with each seeing their own exact wage.

29. Sprint 6 — Customer Candidate List + Worker Selection

Goal

Allow customer to see accepted workers and choose one.

Endpoints

GET  /api/v1/gigs/{gig_id}/candidates
POST /api/v1/gigs/{gig_id}/select-worker

Candidate response

Must contain the data needed by Flutter for sorting/display:

worker name/profile
rating
rating count
completed jobs
final score if approved for display
exact wage

Do not implement

backend recommendation ranking
automatic selection
distance ranking

Selection transaction

Atomically:

verify customer owns gig
verify worker accepted
set selected worker
close other candidate opportunities appropriately
write audit event
create notifications

Definition of Done

Customer can compare candidates in Flutter and select one.

30. Sprint 7 — Core Job Execution

Goal

Make the selected worker's job lifecycle functional.

Endpoints

GET  /api/v1/worker/gigs
POST /api/v1/gigs/{gig_id}/start
POST /api/v1/gigs/{gig_id}/completion
GET  /api/v1/gigs/{gig_id}/completion
POST /api/v1/gigs/{gig_id}/completion/confirm

Implement

selected worker access

active job state (WORKER_SELECTED, SCHEDULED, IN_PROGRESS)

completion evidence & storage references

worker completion submission

customer review of evidence

customer confirmation (COMPLETION_CONFIRMED) & rejection rework loop (reverts to IN_PROGRESS)

state validation

audit events (WORK_STARTED, COMPLETION_SUBMITTED, COMPLETION_CONFIRMED, COMPLETION_REJECTED)

Definition of Done

Worker can start work, upload evidence, and customer can confirm completion or request rework.

31. Sprint 8 — Payment

Goal

Complete the main financial lifecycle without a payment gateway.

Endpoints

GET  /api/v1/gigs/{gig_id}/payment
POST /api/v1/gigs/{gig_id}/payment
POST /api/v1/gigs/{gig_id}/payment/confirm-receipt

Implement

CASH
UPI

UPI

Store/return the required deeplink/payment information.

Flutter opens the UPI application.

Do not attempt bank-side verification.

State machine

PENDING
↓
CUSTOMER_PAID
↓
WORKER_CONFIRMED
↓
COMPLETED

Important

Worker receipt confirmation must be idempotent.

Repeated requests must not create duplicate payment records or duplicate completion transitions.

Definition of Done

The complete normal gig can reach:

COMPLETED

with either cash or UPI flow.

32. Sprint 9 — Visitation

Goal

Implement the unknown-problem/inspection flow.

Endpoints

POST /api/v1/gigs/{gig_id}/visitation/request
GET  /api/v1/gigs/{gig_id}/visitation
POST /api/v1/gigs/{gig_id}/visitation/proposals
POST /api/v1/gigs/{gig_id}/visitation/proposals/{proposal_id}/accept
POST /api/v1/gigs/{gig_id}/visitation/proposals/{proposal_id}/reject

Implement

₹100 visitation charge
worker task proposal
customer accept/reject
work-price calculation
same-category validation
no duplicate ₹100 on accepted work
₹100 remains payable on rejection

Definition of Done

A customer can request a visit, worker can identify tasks, and customer can accept/reject the resulting work proposal.

33. Sprint 10 — Multi-Worker + Rookie

Goal

Implement cooperative collaboration.

Endpoints

POST /api/v1/gigs/{gig_id}/participations
GET  /api/v1/gigs/{gig_id}/participations

POST /api/v1/participations/{participation_id}/accept
POST /api/v1/participations/{participation_id}/reject

Implement

same cooperative validation
explicit consent
equal sharing
rookie mentorship
rookie 0.5 complexity contribution

Do not expose private worker compensation unnecessarily.

Definition of Done

A primary worker can invite another eligible worker and the invited worker can accept/reject.

34. Sprint 11 — Cancellation + Rescheduling

Goal

Implement lifecycle changes that do not require redesigning the main gig flow.

Endpoints

POST /api/v1/gigs/{gig_id}/cancel
POST /api/v1/gigs/{gig_id}/reopen

POST /api/v1/gigs/{gig_id}/reschedule-requests
GET  /api/v1/gigs/{gig_id}/reschedule-requests

POST /api/v1/reschedule-requests/{request_id}/accept
POST /api/v1/reschedule-requests/{request_id}/reject
POST /api/v1/reschedule-requests/{request_id}/alternative

Implement

role-specific cancellation

cancellation reasons

configured cancellation fee

worker cancellation continuation

find-another-worker/reopen

rescheduling

worker rescheduling

conflict revalidation

availability revalidation

audit events

35. Sprint 12 — Materials

Goal

Implement material procurement evidence.

Endpoints

POST /api/v1/gigs/{gig_id}/material-receipts
GET  /api/v1/gigs/{gig_id}/material-receipts

Implement

worker purchase flow

receipt upload

amount

description

storage reference

customer viewer

No complex dispute system in MVP.

36. Sprint 13 — Reviews + Metrics

Goal

Implement the final trust loop.

Endpoints

GET  /api/v1/review-questions
POST /api/v1/gigs/{gig_id}/reviews
GET  /api/v1/gigs/{gig_id}/reviews

GET /api/v1/workers/{worker_id}/metrics

Implement

customer reviews worker

worker reviews customer

structured questions

one review per direction per gig

completion prerequisite

rating aggregation

worker metrics

final score update according to approved algorithm

Important

Do not simply average thousands of raw ratings at every request.

Use the approved stored/aggregated rating design.

37. Sprint 14 — Chat + Notifications

Goal

Connect the existing frontend communication surfaces.

Endpoints

GET  /api/v1/gigs/{gig_id}/conversation
POST /api/v1/gigs/{gig_id}/conversation/messages
GET  /api/v1/gigs/{gig_id}/conversation/messages

GET  /api/v1/notifications
POST /api/v1/notifications/{notification_id}/read
POST /api/v1/notifications/read-all

Implement

Job-scoped chat only.

Important notifications:

new opportunity
worker accepted
worker selected
visitation proposal
completion submitted
completion confirmed
payment recorded
payment receipt confirmed
cancellation
reschedule
join request
review availability

38. Sprint 15 — Integration Hardening

Goal

Connect the backend to the actual Flutter frontend and remove integration blockers.

Tasks

Configure Dio base URL.

Configure auth token injection.

Implement frontend API repositories.

Map backend response models.

Map stable error codes.

Replace mock data in critical screens.

Verify loading states.

Verify empty states.

Verify error states.

Verify token expiry behaviour.

Verify file uploads.

Verify UPI deeplink data.

Verify Google Maps link opening.

Verify candidate sorting in frontend.

Priority

Do not attempt to connect every screen simultaneously.

Connect the critical path first:

Login
→ Profile
→ Create Gig
→ Price Preview
→ Post
→ Worker Opportunity
→ Accept
→ Candidate List
→ Select
→ Active Job
→ Completion
→ Payment
→ Review

39. Sprint 16 — End-to-End Testing

Goal

Run the full MVP using real database records.

Scenario A — Normal Job

Customer registers
↓
Creates profile
↓
Selects category
↓
Selects tasks
↓
Gets price preview
↓
Creates gig
↓
Posts gig
↓
Worker receives opportunity
↓
Worker accepts
↓
Customer sees worker
↓
Customer selects worker
↓
Worker completes
↓
Worker uploads evidence
↓
Customer confirms
↓
Customer pays
↓
Worker confirms receipt
↓
Gig completes
↓
Both review

Scenario B — Multiple Workers

Two eligible workers receive gig
↓
Both accept
↓
Customer sees both
↓
Frontend sorts
↓
Customer selects one

Verify exact wages remain correct for each worker.

Scenario C — Conflict

Worker has confirmed job 10:00–11:00
↓
New opportunity 10:30–11:30
↓
Accept
↓
Must be rejected by backend

Scenario D — Visitation Accepted

Customer requests visit
↓
₹100 visitation
↓
Worker proposes tasks
↓
Customer accepts
↓
Work price created
↓
₹100 not added again

Scenario E — Visitation Rejected

Customer requests visit
↓
Worker proposes tasks
↓
Customer rejects
↓
Customer owes ₹100 visitation charge
↓
No work charge

Scenario F — Payment

Customer records CASH/UPI payment
↓
CUSTOMER_PAID
↓
Worker confirms receipt
↓
WORKER_CONFIRMED
↓
COMPLETED

Scenario G — Aadhaar

Worker uploads Aadhaar
↓
Document stored
↓
No automatic verification

40. Database Verification Checklist

Before calling the database complete:

All approved tables exist.

All primary keys exist.

Foreign keys exist.

Unique constraints exist.

Required indexes exist.

State constraints exist.

Timestamps are timezone-aware.

Audit/event tables work.

File references work.

Location fields work.

Worker metrics work.

Pricing snapshots work.

Worker wage snapshots work.

Payment states work.

Review constraints work.

Availability records work.

Migration can recreate database.

41. API Verification Checklist

Before calling the API complete:

/api/v1/health

/api/v1/me

profile APIs

category APIs

task APIs

price preview

gig creation

gig posting

worker opportunities

accept/reject

candidates

worker selection

completion

payment

review

visitation

multi-worker

cancellation

rescheduling

materials

chat

notifications

42. Security Checklist

Supabase JWT validation works.

Unauthenticated requests are rejected.

Customer-only endpoints reject workers.

Worker-only endpoints reject customers.

Users cannot access another user's private resources.

Workers cannot access another worker's opportunities.

Customers cannot modify worker metrics.

Clients cannot submit authoritative prices.

Clients cannot submit authoritative wages.

Clients cannot directly set gig status.

Aadhaar files are protected.

Audit records cannot be modified by clients.

File type/size validation exists.

Duplicate state-changing requests are safe.

43. Transaction Checklist

Use database transactions for multi-record state changes.

Mandatory examples:

Gig creation
Worker acceptance
Worker selection
Visitation proposal acceptance
Completion confirmation
Payment confirmation
Review submission
Reschedule acceptance
Multi-worker participation

If an operation fails halfway, the database must not remain in a contradictory state.

44. Concurrency Checklist

Pay particular attention to:

Worker acceptance

Two requests must not allow the same worker to accept overlapping confirmed gigs.

Customer selection

Two simultaneous worker-selection requests must not leave two selected workers.

Payment

Repeated payment confirmation must not create duplicate completion/payment states.

Reviews

Repeated review requests must not create duplicate reviews.

Use:

database constraints
transactions
row-level locking where necessary
unique constraints
idempotency

where appropriate.

45. Recommended Implementation Order Under Severe Time Pressure

If the team has only approximately 1.5 days, do NOT treat every sprint as equal.

Use this priority.

P0 — Absolutely required

Sprint 0
Sprint 1
Sprint 2
Sprint 3
Sprint 4
Sprint 5
Sprint 6
Sprint 7
Sprint 8

These create the core demonstrable platform.

The absolute critical path is:

Auth
→ User
→ Catalogue
→ Pricing
→ Gig
→ Opportunity
→ Accept
→ Select
→ Completion
→ Payment

P1 — Required if time permits

Sprint 9 — Visitation
Sprint 11 — Cancellation/Rescheduling
Sprint 12 — Materials
Sprint 13 — Reviews
Sprint 14 — Chat/Notifications

P2 — Polish / hardening

Sprint 15 — Frontend integration hardening
Sprint 16 — Extended end-to-end testing

Testing of the P0 path is still mandatory even under time pressure.

46. Parallel Work Strategy

If multiple backend developers are available, split work after the foundation.

Developer A — Core Gig

Gig
Pricing
Opportunity
Selection

Developer B — User

Auth
Profiles
Worker categories
Availability

Developer C — Job Completion

Completion
Materials
Payment

Developer D — Secondary Flows

Visitation
Multi-worker
Cancellation
Rescheduling
Reviews
Chat
Notifications

Everyone must use the same:

database schema
API contract
state machine
error contract

Do not create independent interpretations.

47. Git Strategy

Use small focused commits.

Recommended:

feat(db): add initial schema
feat(auth): add authenticated user dependency
feat(profile): add customer and worker profiles
feat(catalogue): add categories and tasks
feat(pricing): add price calculation service
feat(gigs): add gig creation
feat(opportunities): add worker opportunity flow
feat(selection): add customer worker selection
feat(completion): add completion evidence flow
feat(payment): add cash and UPI payment states
feat(reviews): add structured reviews
test(...): add integration tests

Do not combine unrelated modules into one huge commit.

48. Environment Variables

Use environment variables for deployment-specific configuration.

At minimum:

DATABASE_URL
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
JWT configuration as required
STORAGE configuration
CORS origins

Never commit secrets.

Provide:

.env.example

with placeholder values only.

49. Seed Data

Create development seed data for:

one cooperative
service categories
service tasks
wage/rate configuration from wages.md
sample workers
sample customer
sample availability
review questions

The seed data must be clearly development-only.

Do not use fake seed data as a replacement for database constraints or backend logic.

50. API Documentation

FastAPI OpenAPI must remain available during development.

Verify:

/docs
/openapi.json

The generated API must match:

05_API_DESIGN.md

If an endpoint differs from the document, update the document rather than letting implementation drift.

51. Test Pyramid

Prioritize tests in this order.

Unit tests

For:

pricing
wage calculation
final score contribution
rookie contribution
availability overlap
state transitions

Integration tests

For:

database + repository + service

API tests

For:

authentication
authorization
request validation
responses
state transitions

End-to-end tests

For:

complete normal gig

The complete normal gig test is the most important end-to-end test.

52. Definition of MVP Backend Complete

The backend is considered MVP-complete when all of the following are true:

[✓] Database is deployed
[✓] Alembic migrations work
[✓] Authentication works
[✓] Customer profile works
[✓] Worker profile works
[✓] Aadhaar upload works without verification
[✓] Worker categories work
[✓] Worker availability works
[✓] Categories/tasks work
[✓] Pricing works
[✓] wages.md rules are implemented
[✓] Gig creation works
[✓] Location/link storage works
[✓] Gig posting works
[✓] Worker opportunities work
[✓] Worker accept/reject works
[✓] Conflict detection works
[✓] Customer candidate list works
[✓] Frontend sorting can use backend fields
[✓] Worker selection works
[✓] Completion evidence works
[✓] Customer completion confirmation works
[✓] Cash payment works
[✓] UPI deeplink flow works
[✓] Worker payment confirmation works
[✓] Gig reaches COMPLETED
[✓] Reviews work
[✓] Critical authorization works
[✓] Critical state transitions are transactional
[✓] Critical P0 flow has tests

53. Final Implementation Priority

When time becomes extremely limited, use this exact order:

1. Database + migrations
2. Authentication
3. User/profile
4. Categories/tasks
5. Pricing
6. Wage calculation
7. Gig creation
8. Gig posting
9. Worker opportunities
10. Accept/reject
11. Customer candidate list
12. Worker selection
13. Completion
14. Payment
15. End-to-end P0 testing
16. Visitation
17. Cancellation/rescheduling
18. Materials
19. Reviews
20. Chat/notifications
21. Multi-worker/rookie refinement
22. Final integration hardening

If forced to choose between implementing another secondary feature and making the P0 flow reliable, make the P0 flow reliable.

54. Final Backend Architecture

                       Flutter
                          │
                          │ HTTPS
                          ▼
                    ┌───────────┐
                    │  FastAPI  │
                    └─────┬─────┘
                          │
                 ┌────────┴────────┐
                 │                 │
             Routers            Auth
                 │                 │
                 ▼                 ▼
             Schemas         Supabase Auth
                 │
                 ▼
              Services
                 │
        ┌────────┼─────────┐
        │        │         │
     Pricing   Wage    Availability
     Service  Service    Service
        │        │         │
        └────────┼─────────┘
                 ▼
            Repositories
                 │
                 ▼
             SQLAlchemy
                 │
                 ▼
          PostgreSQL / Supabase
                 │
        ┌────────┴─────────┐
        │                  │
   Application Data   Supabase Storage
        │                  │
        └───────┬──────────┘
                ▼
             Flutter

55. Final Working Principle

The backend team should build the system as a series of small, verifiable vertical slices.

For every feature:

Read requirement
    ↓
Check database design
    ↓
Check API design
    ↓
Implement model/migration
    ↓
Implement schema
    ↓
Implement repository
    ↓
Implement service
    ↓
Implement router
    ↓
Write tests
    ↓
Run tests
    ↓
Verify with frontend
    ↓
Update context/history

Do not skip directly from:

requirement
→ router

and put all business logic inside route handlers.

56. Context and History Updates

After each meaningful sprint, update:

context.md
history.md

Record:

what was implemented
what was verified
important decisions
schema changes
API changes
known limitations
next recommended step

Do not overwrite historical decisions.

Add new entries chronologically.

57. Important Final Note

This document is intentionally implementation-focused.

It does not redefine the database schema.

It does not redefine the API contract.

It does not redefine the wage algorithm.

Those responsibilities belong to:

04_DATABASE_DESIGN.md
05_API_DESIGN.md
wages.md

This document tells the implementation team in what order and with what priorities to build the approved system.

The immediate objective is a functioning MVP, not a complete production platform.

Build the core path first.
Test it.
Connect it to Flutter.
Then expand into the remaining MVP flows.