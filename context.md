# SIH 2026 Project Context

## Current State

Sahakaar Seva is a comprehensive Flutter frontend for a cooperative household-services marketplace. The app provides end-to-end, production-ready UI workflows for both Customer and Worker personas, styled authentication/registration flows, role dashboards, customer gig creation & lifecycle tracking, mutual in-app chat, alerts, multi-tier verification, rookie progression, and complete post-completion audit chains.

The implementation is frontend-only and uses Flutter's existing dependencies with zero third-party packages. Mock data models represent real cooperative gig lifecycles, transparent pricing, material bills, worker opportunities, schedule conflicts, multi-worker invitations, and structured evaluations per the System Requirements Specification (SRS).

Latest documented implementation: 2026-09-07, contributor Vismay.

## Design System

- Theme: Material 3 with centralized tokens in `mobile_app/lib/theme/app_theme.dart`.
- Palette: primary cooperative green `#245B52`, dark green `#173B36`, amber `#E8B84A`, warm off-white `#F7F8F5`, white surfaces, dark text `#17211F`, muted text `#737C78`, border `#D8DDDA`, success `#3D8B68`, and danger `#C85C5C`.
- Shared primitives: `BrandMark`, `SurfaceCard`, `SectionTitle`, `StatTile`, `StatusPill`, `PrimaryAction`, shared login layout, and shared registration layout in `mobile_app/lib/widgets/common/shared_widgets.dart`.
- Action buttons: filled/elevated/outlined Material action buttons use the cooperative square white button treatment with black border, square corners, and hard black offset shadow (`boxShadow: [BoxShadow(color: Colors.black, offset: Offset(3, 3))]`).
- Navigation Shells: Both `CustomerMainScreen` and `WorkerMainScreen` implement persistent bottom navigation using per-tab nested `Navigator` widgets inside an `IndexedStack`. Sub-screens push within the active tab's viewport, keeping the bottom `NavigationBar` permanently visible at all times.

## Implemented User Flows

### App entry and roles

```text
Splash
  -> Role Selection
     -> Customer Login -> Customer Main (Persistent Bottom Nav)
        -> Home | My Gigs | Alerts | Profile
     -> Worker Login -> Worker Main (Persistent Bottom Nav)
        -> Home | Opportunities | My Jobs | Profile
```

Login and registration actions are demo navigation, not real authentication.

### Customer gig creation & management

- Gig details form with category, work description, location, required date/time, duration, emergency status toggle, photo placeholders, instructions, and materials.
- Material choice: Customer purchases materials vs Worker purchases materials. Labour is shown separately from materials (`₹550 – ₹800` cooperative example range).
- Emergency status is configured via toggle inside `CreateGigScreen`.
- Fallback tipping incentive (SRS 18.1): When a posted gig has no accepting workers, `GigDetailsScreen` displays a fallback banner allowing the customer to add a voluntary tip incentive (100% direct worker payout) and re-notify nearby workers.
- My Gigs tabbed tracker: Seeking Workers -> Workers Responding -> Accepted Candidates -> Worker Selected -> Scheduled -> Active -> Completion Requested -> Payment -> Completed.
- Sub-screens: `WaitingForCandidatesScreen`, `ReviewWorkerScreen` (structured 3–4 MCQs), `CancelGigScreen`, `RescheduleGigScreen`, `EmergencyTipScreen`, `PaymentScreen`, and `MaterialBillViewerScreen`.

### Worker opportunities & schedule conflict detection

```text
Worker Home / Opportunities Tab
  -> Opportunity Details Screen
     -> Fixed Guaranteed Wage (No worker bidding per SRS)
     -> Distance, location, instructions, material preference
     -> Conflict Detection Check (SRS 10.3)
        -> [If schedule conflict] Conflict Warning Dialog (SRS 10.3)
     -> Accept Gig -> Active Job Workspace
```

- Worker opportunities list with filters: "All", "Emergency", "Conflicts".
- Exact guaranteed cooperative wage shown before acceptance; worker bidding is strictly prohibited to eliminate predatory undercutting.
- Conflict Detection (SRS 10.3): Opportunities that overlap with existing jobs or off-duty hours trigger `ConflictWarningDialog`.

### Worker active job execution & audit chain

```text
Worker Active Job Workspace
  ├── Invite Co-Worker (SRS 16.2) -> MultiWorkerInviteScreen (Rookie vs Equal Sharing)
  ├── Material Bill (SRS 7.2) -> MaterialBillUploadScreen (Itemized receipts)
  ├── Reschedule / Cancel (SRS 21) -> WorkerCancelRescheduleScreen
  ├── Chat -> Common ChatScreen
  └── Job Progression Lifecycle:
        [Accepted / Scheduled] -> "Arrived & Start Work"
        -> [In Progress] -> "Complete Work & Submit Evidence" (SRS 19)
        -> CompletionEvidenceUploadScreen (Photo proof + work notes)
        -> WaitingConfirmationScreen (Awaiting customer review)
        -> WorkerPaymentConfirmationScreen (SRS 19.1: UPI Direct / Cash in Hand)
        -> ReviewCustomerScreen (SRS 20: Structured 3–4 MCQs)
        -> Return to My Jobs (Completed)
```

- Multi-Worker Collaboration (SRS 16): Lead technicians can invite verified colleagues as either "Equal Sharing" (50/50 split) or "Rookie Mentorship" (0.5 job credits).
- Incoming Join Requests (SRS 16.1): Invited workers inspect join invitations, role classification, and inviter notes on `IncomingJoinRequestScreen`.
- Rookie Progression (SRS 15.2): Apprentices track their progression towards full independent certification (0.5 credit per shadowed gig, mentor ratings & feedback notes) on `RookieProgressionScreen`.
- Material Cost Transparency (SRS 7.2): Itemized material entry with receipts attached on `MaterialBillUploadScreen`.
- Completion Evidence (SRS 19): Photo proof of completed work and cleaned work area with audit trail on `CompletionEvidenceUploadScreen`.
- Customer Evaluation (SRS 20): Objective 3–4 MCQ ratings on `ReviewCustomerScreen` covering area safety, job description accuracy, and communication.

### Worker profile & weekly availability

- Weekly Availability Scheduler (SRS 10.1): Mon–Sun recurring schedule editor with day-by-day availability toggles, start/end time pickers, and presets ("Mon–Fri Standard", "All 7 Days", "Weekend Only") on `WorkerAvailabilityScreen`.
- Multi-Tier Verification (SRS 22): Tier 1 (Aadhaar KYC), Tier 2 (Trade Guild Assessment), Tier 3 (Cooperative Society Shareholder), and Tier 4 (Police Antecedents) on `WorkerVerificationScreen`.
- Cooperative Tariff Guidelines modal detailing base guild tariffs, emergency floors, and zero platform deductions.

### Shared common screens

- `screens/common/splash_screen.dart`: Animated onboarding splash.
- `screens/common/role_selection_screen.dart`: Customer vs Worker portal selection.
- `screens/common/forgot_password_screen.dart`: Mobile OTP recovery and password reset flow.
- `screens/common/chat_screen.dart`: Shared bidirectional messaging screen between customer and worker.
- `screens/common/notifications_screen.dart`: Shared cooperative notifications list.
- `screens/common/settings_screen.dart`: Shared settings screen accessible from both Customer and Worker profiles, featuring Dark Mode toggle, embedded multilingual ChoiceChips (English, Kannada, Hindi, Tamil, Telugu), notification controls, biometric lock, and cooperative data privacy pledge.
- `screens/common/about_help_screen.dart`: Shared Help & Support screen with Cooperative Society Charter, guild FAQs, toll-free helpline, and WhatsApp helpdesk.
- `screens/common/no_internet_screen.dart`: Offline network status screen with cached mode details and retry connectivity action.

## Current Source Structure

```text
SIH_2026/
├── context.md
├── history.md
├── README.md
├── backend/
│   ├── alembic/
│   │   ├── env.py
│   │   ├── script.py.mako
│   │   └── versions/
│   │       ├── 7c590bb021a2_initial_foundation.py
│   │       └── e29d3f46feb9_sprint_1_mvp_schema.py
│   ├── alembic.ini
│   ├── requirements.txt
│   ├── .env.example
│   ├── .env
│   ├── .gitignore
│   └── app/
│       ├── __init__.py
│       ├── main.py
│       ├── core/
│       │   ├── config.py
│       │   ├── logging.py
│       │   ├── security.py
│       │   └── exceptions.py
│       ├── db/
│       │   ├── base.py
│       │   ├── session.py
│       │   └── models/
│       │       ├── __init__.py
│       │       ├── enums.py
│       │       ├── cooperative.py
│       │       ├── user.py
│       │       ├── service.py
│       │       ├── gig.py
│       │       ├── experience.py
│       │       ├── review.py
│       │       ├── completion.py
│       │       ├── payment.py
│       │       ├── multi_worker.py
│       │       ├── visitation.py
│       │       ├── cancellation.py
│       │       └── communication.py
│       ├── api/
│       │   └── v1/
│       │       ├── router.py
│       │       └── endpoints/
│       │           ├── health.py
│       │           ├── me.py
│       │           ├── customer.py
│       │           └── worker.py
│       ├── schemas/
│       │   ├── common.py
│       │   ├── user.py
│       │   └── worker.py
│       ├── repositories/
│       ├── services/
│       │   ├── user_service.py
│       │   ├── worker_service.py
│       │   └── score_service.py
│       └── tests/
│           ├── conftest.py
│           ├── test_config.py
│           ├── test_health.py
│           ├── test_models.py
│           ├── test_verification.py
│           ├── test_auth_and_profiles.py
│           └── test_sprint2_verification.py
├── docs/
│   ├── 04_DATABASE_DESIGN.md
│   ├── 05_API_DESIGN.md
│   ├── 06_BACKEND_SPRINTS.md
│   ├── ALGORITHM_RECOMMENDATION_DEVELOPMENT_ROADMAP.md
│   ├── FRONTEND_DESIGN_SYSTEM.md
│   ├── FRONTEND_DEVELOPMENT_ROADMAP.md
│   ├── SRS_Final.md
│   ├── WAGES.md
│   └── .gitkeep
└── mobile_app/
    ├── pubspec.yaml
    ├── pubspec.lock
    ├── analysis_options.yaml
    ├── .gitignore
    ├── lib/
    │   ├── main.dart
    │   ├── localization/
    │   │   └── .gitkeep
    │   ├── models/
    │   │   ├── .gitkeep
    │   │   ├── gig_draft.dart
    │   │   ├── customer_gig_workflow.dart
    │   │   └── worker_job_workflow.dart
    │   ├── providers/
    │   │   └── .gitkeep
    │   ├── repositories/
    │   │   └── .gitkeep
    │   ├── services/
    │   │   └── .gitkeep
    │   ├── theme/
    │   │   ├── .gitkeep
    │   │   └── app_theme.dart
    │   ├── widgets/common/
    │   │   ├── .gitkeep
    │   │   └── shared_widgets.dart
    │   └── screens/
    │       ├── common/
    │       │   ├── .gitkeep
    │       │   ├── splash_screen.dart
    │       │   ├── role_selection_screen.dart
    │       │   ├── forgot_password_screen.dart
    │       │   ├── chat_screen.dart
    │       │   ├── notifications_screen.dart
    │       │   ├── settings_screen.dart
    │       │   ├── about_help_screen.dart
    │       │   └── no_internet_screen.dart
    │       ├── customer/
    │       │   ├── .gitkeep
    │       │   ├── customer_login_screen.dart
    │       │   ├── customer_register_screen.dart
    │       │   ├── customer_main_screen.dart
    │       │   ├── home/
    │       │   │   ├── customer_home_screen.dart
    │       │   │   ├── create_gig_screen.dart
    │       │   │   ├── material_procurement_screen.dart
    │       │   │   ├── labour_price_preview_screen.dart
    │       │   │   └── emergency_tip_screen.dart
    │       │   ├── my_jobs/
    │       │   │   ├── customer_navigation_2_screen.dart
    │       │   │   ├── gig_details_screen.dart
    │       │   │   ├── waiting_for_candidates_screen.dart
    │       │   │   ├── review_worker_screen.dart
    │       │   │   ├── cancel_gig_screen.dart
    │       │   │   ├── reschedule_gig_screen.dart
    │       │   │   ├── customer_workflow_screens.dart
    │       │   │   ├── accepted_candidates_screen.dart
    │       │   │   ├── worker_comparison_screen.dart
    │       │   │   ├── worker_profile_screen.dart
    │       │   │   ├── final_worker_selected_screen.dart
    │       │   │   ├── previous_worker_request_screen.dart
    │       │   │   ├── active_job_screen.dart
    │       │   │   ├── completion_evidence_review_screen.dart
    │       │   │   ├── completion_confirmation_screen.dart
    │       │   │   ├── payment_screen.dart
    │       │   │   └── material_bill_viewer_screen.dart
    │       │   ├── alerts/
    │       │   │   └── customer_navigation_3_screen.dart
    │       │   └── profile/
    │       │       ├── customer_navigation_4_screen.dart
    │       │       └── customer_account_screens.dart
    │       └── worker/
    │           ├── .gitkeep
    │           ├── worker_login_screen.dart
    │           ├── worker_register_screen.dart
    │           ├── worker_main_screen.dart
    │           ├── home/
    │           │   └── worker_home_screen.dart
    │           ├── opportunities/
    │           │   ├── worker_navigation_2_screen.dart
    │           │   ├── opportunity_details_screen.dart
    │           │   └── conflict_warning_dialog.dart
    │           ├── my_jobs/
    │           │   ├── worker_navigation_3_screen.dart
    │           │   ├── worker_active_job_screen.dart
    │           │   ├── multi_worker_invite_screen.dart
    │           │   ├── incoming_join_request_screen.dart
    │           │   ├── rookie_progression_screen.dart
    │           │   ├── material_bill_upload_screen.dart
    │           │   ├── completion_evidence_upload_screen.dart
    │           │   ├── waiting_confirmation_screen.dart
    │           │   ├── worker_payment_confirmation_screen.dart
    │           │   ├── review_customer_screen.dart
    │           │   └── worker_cancel_reschedule_screen.dart
    │           └── profile/
    │               ├── worker_navigation_4_screen.dart
    │               ├── worker_earnings_screen.dart
    │               ├── worker_availability_screen.dart
    │               └── worker_verification_screen.dart
    └── test/
        └── widget_test.dart
```

## Important File Responsibilities

### Frontend (`mobile_app/`)
- `lib/main.dart`: app entry point; starts `SplashScreen` and applies `buildAppTheme()`.
- `lib/theme/app_theme.dart`: color tokens, Material 3 theme, input/card/navigation themes, and global button style.
- `lib/widgets/common/shared_widgets.dart`: shared visual primitives and reusable authentication layouts.
- `lib/models/worker_job_workflow.dart`: worker models (`WorkerOpportunity`, `WorkerJob`, `WorkerJobStatus`, `WorkerJoinRequest`, `JoinRoleType`, `DayAvailability`) and demo datasets.
- `lib/screens/worker/worker_main_screen.dart`: Worker shell with persistent bottom navigation using per-tab navigators.
- `lib/screens/worker/opportunities/`: opportunity browsing, guaranteed wage inspection, and conflict warning dialog.
- `lib/screens/worker/my_jobs/`: active job workspace, multi-worker invite, incoming join request, rookie progression, material bills, completion evidence, payment confirmation, customer rating, and cancellation/reschedule.
- `lib/screens/worker/profile/`: worker profile hub, weekly recurring availability editor, multi-tier verification status, and worker earnings/patronage dividend breakdown.
- `lib/screens/common/`: shared `ForgotPasswordScreen`, `SettingsScreen`, `AboutHelpScreen`, `NoInternetScreen`, `ChatScreen`, and `NotificationsScreen`.
- `test/widget_test.dart`: 7 comprehensive widget test flows covering Customer navigation, registration, Worker destination navigation, Worker profile & availability, Worker opportunity details & workspace acceptance, Login layout & Forgot Password reset flow, and Worker profile navigation into Earnings, Settings, and Help screens.

### Backend (`backend/`)
- `app/main.py`: FastAPI application entrypoint, CORS middleware, centralized exception handlers, startup catalogue auto-seeding, and `/api/v1` router mount.
- `app/core/config.py`: Pydantic settings loading environment variables with fallback defaults, CORS origin parsing, Supabase parameters, rookie metric defaults, and wage/visitation policy constants (`WAGE_PREMIUM_MAX_FACTOR=0.30`, `VISITATION_FEE=100.00`).
- `app/core/catalogue_data.py`: Complete static catalogue dataset for all 5 guild categories (Plumbing, Carpentry, Electrician, Painter, House Help) and ~115 tasks with durations and base prices from `docs/WAGES.md`.
- `app/core/logging.py`: Centralized logging format and level configuration.
- `app/core/exceptions.py`: Custom `AppException` hierarchy and standardized JSON error handlers conforming to `docs/05_API_DESIGN.md`.
- `app/core/security.py`: Supabase Auth HS256 JWT decoding, claim extraction, user resolution, and role-based access control dependencies.
- `app/db/base.py`: Declarative `Base` and abstract `BaseModel` with UUID primary keys and timezone-aware timestamps.
- `app/db/session.py`: SQLAlchemy engine, session maker, `get_db` FastAPI dependency, and live connectivity check.
- `app/schemas/common.py`: Standard response envelopes (`ResponseEnvelope[T]`, `PaginatedResponse[T]`, `ErrorResponse`, `HealthResponse`).
- `app/schemas/user.py` & `app/schemas/worker.py`: Authentication, user initialization, and profile request/response schemas.
- `app/schemas/catalogue.py`: `ServiceCategoryResponse`, `ServiceTaskResponse` (with complexity score and bucket).
- `app/schemas/pricing.py`: `PricePreviewRequest`, `PricePreviewTaskItem`, `EstimatedWageRange`, and `PricePreviewResponse`.
- `app/schemas/gig.py`: `GigCreateRequest`, `GigTaskItemResponse`, and `GigResponse`.
- `app/services/score_service.py`: Centralized final score computation and rookie default metric generation.
- `app/services/user_service.py` & `app/services/worker_service.py`: User lifecycle, role enforcement, and worker profile management.
- `app/services/catalogue_service.py`: Database seeding with bulk prefetching and catalogue retrieval.
- `app/services/pricing_service.py`: Multi-task duration summing, 45-minute minimum billable enforcement, base price calculation, and single-category validation.
- `app/services/wage_service.py`: Exact wage formula `base_price * (1 + final_score * factor)` with configurable `WAGE_PREMIUM_MAX_FACTOR`, clamping, rounding, and wage range estimation.
- `app/services/experience_service.py`: Logarithmic task complexity normalization `(ln(t) - ln(t_min)) / (ln(t_max) - ln(t_min))`, exact buckets (`0-0.33 LOW`, `0.34-0.66 MID`, `0.67-1.0 HIGH`), rolling window experience score ($N=50$) with rookie 0.5x contribution and no decay factor, and Bayesian rating aggregation.
- `app/services/gig_service.py`: Customer gig creation in DRAFT status with pricing snapshots, atomic task association, GIG_CREATED and GIG_POSTED audit events, gig retrieval, customer gig collection filtering/pagination, and automatic trigger of the Opportunity Engine on post.
- `app/services/opportunity_service.py`: Worker Opportunity Engine, schedule conflict detection, weekly availability checking, exact guaranteed wage snapshots, and atomic accept/reject transaction workflows.
- `app/services/visitation_service.py`: In-person visitation inspection, task proposals, catalogue pricing calculations, customer accept (₹100 fee absorbed) / reject (₹100 fee payable) workflows, and immutable snapshot preservation.
- `app/services/multi_worker_service.py`: Multi-worker collaboration and rookie mentorship service, same-cooperative validation, explicit consent, rookie 0.5x complexity contribution, audit event logging, and in-app notifications.
- `app/schemas/multi_worker.py`: `WorkerParticipationCreateRequest` and `WorkerParticipationResponse` (strictly excluding private worker splits).
- `app/api/v1/router.py`: API v1 router aggregator.
- `app/api/v1/endpoints/`: Health, authentication (`/me`), customer (`/customer/profile`, `/customer/gigs`), worker (`/worker/profile`, `/worker/categories`, `/worker/availability`, `/worker/opportunities`, `/worker/gigs`), catalogue (`/service-categories`), gig operations (`/gigs`, `/gigs/{id}`, `/gigs/{id}/post`, `/gigs/price-preview`, `/gigs/{id}/candidates`, `/gigs/{id}/select-worker`, `/gigs/{id}/start`, `/gigs/{id}/completion`, `/gigs/{id}/completion/confirm`, `/gigs/{id}/payment`, `/gigs/{id}/payment/confirm-receipt`, `/gigs/{id}/visitation/request`, `/gigs/{id}/visitation`, `/gigs/{id}/visitation/proposals`, `/gigs/{id}/visitation/proposals/{proposal_id}/accept`, `/gigs/{id}/visitation/proposals/{proposal_id}/reject`), and multi-worker collaboration (`/gigs/{gig_id}/participations`, `/participations/{id}/accept`, `/participations/{id}/reject`).
- `alembic/`: Database migration environment managing all 31 models live on Supabase PostgreSQL.
- `app/tests/`: Comprehensive pytest suite with 131 automated unit and integration tests covering Sprints 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, and 10.

## Validation

The latest completed validation passed:

```text
# Frontend Validation
dart format lib test
flutter analyze (0 issues found)
flutter test (7/7 tests passed)

# Backend Validation (Sprint 0 through Sprint 10 + Supabase PostgreSQL)
cd backend
pytest -v (150/150 tests passed in 48.28s)
alembic current (76b9636a889b head, live on Supabase PostgreSQL)
GET /api/v1/health -> 200 OK {"status": "ok", "database": "connected"}
POST /api/v1/me/initialize -> 201 Created (Customer/Worker initialization)
GET /api/v1/me -> 200 OK
GET /api/v1/customer/profile -> 200 OK
GET /api/v1/worker/profile -> 200 OK
GET /api/v1/service-categories -> 200 OK (5 guild categories)
GET /api/v1/service-categories/{id}/tasks -> 200 OK (tasks with complexity metrics)
POST /api/v1/gigs/price-preview -> 200 OK (45-min minimum, single-category check, wage range)
POST /api/v1/gigs -> 201 Created (Draft gig, pricing snapshots, location, GIG_CREATED event, financial guard)
POST /api/v1/gigs/{id}/post -> 200 OK (Transition to POSTED, GIG_POSTED event, opportunities generated)
GET /api/v1/gigs/{id} -> 200 OK (Detailed gig view)
GET /api/v1/customer/gigs -> 200 OK (Filtered, paginated customer gigs)
GET /api/v1/worker/opportunities -> 200 OK (Personalized exact wages per worker)
GET /api/v1/worker/opportunities/{id} -> 200 OK (Detailed opportunity view)
POST /api/v1/worker/opportunities/{id}/accept -> 200 OK (Conflict check, atomic ACCEPTED transition)
POST /api/v1/worker/opportunities/{id}/reject -> 200 OK (Permanent REJECTED transition)
GET /api/v1/gigs/{id}/candidates -> 200 OK (Accepted worker candidates with transparent metrics & wages)
POST /api/v1/gigs/{id}/select-worker -> 200 OK (WORKER_SELECTED transition, closes other candidates, notifications)
GET /api/v1/worker/gigs -> 200 OK (Worker assigned gigs with lifecycle tabs & exact agreed wage)
POST /api/v1/gigs/{id}/start -> 200 OK (Worker 'Arrived & Start Work', moves to IN_PROGRESS, WORK_STARTED event)
POST /api/v1/gigs/{id}/completion -> 200 OK (Worker submits notes & photo proof, COMPLETION_SUBMITTED)
GET /api/v1/gigs/{id}/completion -> 200 OK (Customer & worker inspection of completion proof & feedback)
POST /api/v1/gigs/{id}/completion/confirm -> 200 OK (Customer confirms -> CUSTOMER_CONFIRMED, or rejects -> IN_PROGRESS rework loop)
GET /api/v1/gigs/{id}/payment -> 200 OK (Authoritative decimal wage/cancellation fee snapshot, status, UPI deep link)
POST /api/v1/gigs/{id}/payment -> 200 OK (Customer marks CASH/UPI -> PAYMENT_CUSTOMER_PAID or stays CANCELLED, immutable method)
POST /api/v1/gigs/{id}/payment/confirm-receipt -> 200 OK (Worker confirms -> COMPLETED or stays CANCELLED, fully idempotent)
POST /api/v1/gigs/{id}/visitation/request -> 200 OK (Customer initiates visitation, fixed ₹100 fee)
GET /api/v1/gigs/{id}/visitation -> 200 OK (Visitation overview, active proposal, action flags)
POST /api/v1/gigs/{id}/visitation/proposals -> 201 Created (Worker submits catalogue tasks, backend prices)
POST /api/v1/gigs/{id}/visitation/proposals/{id}/accept -> 200 OK (Customer accepts, ₹100 fee absorbed, base price updated)
POST /api/v1/gigs/{id}/visitation/proposals/{id}/reject -> 200 OK (Customer rejects, ₹100 fee payable, moves to CUSTOMER_CONFIRMED)
POST /api/v1/gigs/{gig_id}/participations -> 201 Created (Primary invites peer/rookie, checks coop & active profile)
GET /api/v1/gigs/{gig_id}/participations -> 200 OK (Visible to participants/customer, zero private split leakage)
POST /api/v1/participations/{id}/accept -> 200 OK (Invited co-worker explicitly accepts collaboration)
POST /api/v1/participations/{id}/reject -> 200 OK (Invited co-worker explicitly rejects collaboration)
POST /api/v1/gigs/{gig_id}/cancel -> 200 OK (Customer/worker cancels, ₹50 fee after selection, payment created)
POST /api/v1/gigs/{gig_id}/reopen -> 200 OK (Customer reopens worker-cancelled gig, resets to POSTED)
POST /api/v1/gigs/{gig_id}/reschedule -> 200 OK (Initiate reschedule negotiation, validates slot & availability)
GET /api/v1/gigs/{gig_id}/reschedule -> 200 OK (Fetch reschedule negotiation history)
POST /api/v1/gigs/{gig_id}/reschedule/{request_id}/accept -> 200 OK (Counterparty accepts, updates gig schedule)
POST /api/v1/gigs/{gig_id}/reschedule/{request_id}/reject -> 200 OK (Counterparty rejects, preserves schedule)
POST /api/v1/gigs/{gig_id}/reschedule/{request_id}/alternative -> 200 OK (Counterparty counter-proposes slot)
```

## Pending Backend/Product Work

- Sprint 12: Material Procurement & Itemized Receipt Uploads.
- Sprint 13: Structured 3-4 MCQ Reviews & Bayesian Rating Updates.
- Sprint 14: Mutual In-App Chat & Notifications.
- Sprint 15: Flutter-to-FastAPI End-to-End Integration.





