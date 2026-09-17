# SIH 2026 Project Context

## Current State

Sahakaar Seva is a comprehensive, production-grade cooperative household-services marketplace engineered for the Smart India Hackathon (SIH 2026). The platform features an ultra-responsive Flutter mobile application (serving Customer and Worker personas) backed by a high-performance FastAPI/SQLAlchemy REST backend operating on PostgreSQL (Supabase session pooler in production / local PostgreSQL with sub-5ms latency over ADB reverse proxy in development).

The system enforces strict cooperative principles: guaranteed algorithmic tariffs, zero worker bidding, zero platform commission on worker payouts, multi-tier guild verification, apprentice/rookie mentorship progression, structured objective two-way reviews with Bayesian scoring, authoritative cancellation state enforcement, itemized material receipt audits, and job-scoped real-time chat with mutual status tracking.

Latest documented implementation: 2026-09-15, contributors Vismay & Antigravity.

## Design System

- **Theme**: Material 3 with centralized tokens in `mobile_app/lib/theme/app_theme.dart`.
- **Palette**: Primary cooperative green `#245B52`, dark green `#173B36`, amber attention `#E8B84A`, warm off-white canvas `#F7F8F5`, surface white `#FFFFFF`, dark text `#17211F`, muted text `#737C78`, border `#D8DDDA`, success `#3D8B68`, and danger `#C85C5C`.
- **Shimmer Loading**: Continuous horizontal linear gradient highlight sweeping left-to-right via `ShimmerEffect` in `skeleton_loaders.dart` (soft base `#E8ECE9` → bright highlight `#FFFFFF` → soft base `#E8ECE9`), replacing blank flashes and opacity pulsing during data fetches.
- **Shared Primitives**: `BrandMark`, `SurfaceCard`, `SectionTitle`, `StatTile`, `StatusPill`, `PrimaryAction`, `AuthLoginLayout`, `AuthRegisterLayout` in `shared_widgets.dart`.
- **Signature Action Buttons**: Cooperative square white button treatment with black border, square corners, and hard black offset shadow (`boxShadow: [BoxShadow(color: Colors.black, offset: Offset(3, 3))]`).
- **Navigation Shells & Tab Switching**: Both `CustomerMainScreen` and `WorkerMainScreen` implement persistent bottom navigation using per-tab nested `Navigator` widgets inside an `IndexedStack`. Sub-screens push within the active tab's viewport, keeping the bottom `NavigationBar` permanently visible. Native tab switching is exposed via static methods `CustomerMainScreen.switchTab(context, index)` and `WorkerMainScreen.switchTab(context, index)`, preventing duplicate navigation bars or nested scaffolds.
- **Fullscreen Overlays**: Screens that require full-screen focus (such as `ChatScreen`) are pushed via `Navigator.of(context, rootNavigator: true).push(...)` so they cleanly cover the entire viewport without bottom navigation bar interference.

## State Management Architecture (Riverpod)

The Flutter mobile application uses Flutter Riverpod (`flutter_riverpod: ^2.6.1`) for unified, reactive, single-source-of-truth state management across both personas:

1. **Customer State (`customerGigsProvider`)**:
   - Manages `CustomerGigsState` with computed getters: `activeGigs`, `completedGigs`, `activeNow` (seeking/in-progress), `upcoming` (scheduled), `allGigs`, and `activeCount`.
   - `CustomerHomeScreen`: Watches `customerGigsProvider` to reactively render the active gigs list, empty states, and dynamic header badge count.
   - `CustomerNavigation2Screen` (My Gigs): Directly binds the `Active`, `Upcoming`, and `Completed` tabs to `gigsState.activeNow`, `gigsState.upcoming`, and `gigsState.completedGigs`, eliminating duplicate network calls and custom polling timers.
   - `CustomerNavigation3Screen` (Alerts): Derives action notifications and candidate alerts directly from `gigsState.allGigs` with zero extra API overhead.
   - **Cross-Screen Mutations**: Gig creation (`LabourPricePreviewScreen`), cancellation (`CancelGigScreen`), and rescheduling (`RescheduleGigScreen`) automatically trigger provider invalidation/reloads, updating all customer tabs instantaneously without manual refresh.

2. **Worker State (`workerOpportunitiesProvider` & `workerJobsProvider`)**:
   - `WorkerHomeScreen`: Watches `workerJobsProvider` for active job workspace entry and `workerOpportunitiesProvider` for new dispatch opportunities.
   - `WorkerNavigation2Screen` (Opportunities): Shares the cached `workerOpportunitiesProvider`, enabling instant, zero-flicker tab switching and reactive filtering ("All", "Emergency", "Conflicts").
   - `WorkerNavigation3Screen` (My Jobs): Watches `workerJobsProvider` to separate active and completed jobs.

3. **Real-Time Job Sync (`activeGigSyncProvider`)**:
   - Auto-disposed stream family provider (`activeGigSyncProvider(gigId)`) that streams status transitions in real time during job execution and safely tears down timers when the user leaves the screen.

## Implemented User Flows

### App Entry & Authentication Flow

```text
SplashScreen [Animated cooperative splash & mission statement]
  └── RoleSelectionScreen [Select between Customer and Worker portals]
        ├── CustomerLoginScreen [Customer portal login; clears root stack via pushAndRemoveUntil]
        │     └── CustomerMainScreen (Persistent Bottom Nav: Home | My Gigs | Alerts | Profile)
        └── WorkerLoginScreen [Worker guild login; clears root stack via pushAndRemoveUntil]
              └── WorkerMainScreen (Persistent Bottom Nav: Home | Opportunities | My Jobs | Profile)
```

Both login screens purge pre-auth routes from the root stack upon authentication (`pushAndRemoveUntil(..., (route) => false)`), guaranteeing that popping routes inside the app will never unintentionally reveal the login or role selection screen.

### Customer Gig Creation & Management

```text
Customer Home Dashboard
  └── "+ Create a gig" Action
        ├── Step 1: CreateGigScreen [Service category, ₹100 site visit toggle, collapsible task search, instructions]
        ├── Step 2: MaterialProcurementScreen [Customer purchases vs Worker purchases materials]
        └── Step 3: LabourPricePreviewScreen [Algorithmic wage breakdown, deposit preview, gig confirmation]
              └── Pop to Tab 0 Root -> CustomerHomeScreen (Gigs list reloads automatically)
```

- **Site Visit First Option (Fixed ₹100 Charge)**: Positioned directly below category selection in `CreateGigScreen`, enabling customers to request an on-site scope inspection by a verified worker before committing, creating a `VISITATION` gig with a ₹100 line item.
- **Collapsible Task Search**: Searchable task catalog with instant query filtering, clean checkboxes showing only task names without raw rates, and compact summary chip display when collapsed.
- **Dynamic Price Display**: Shows transparent price range before worker selection (`₹min – ₹max`), locking to the exact guaranteed wage once a worker is assigned.
- **Emergency Tipping Fallback (SRS 18.1)**: When a posted gig awaits accepting workers, `GigDetailsScreen` displays a fallback banner allowing the customer to add a voluntary tip incentive (100% direct worker payout) and re-notify nearby workers.
- **Customer Gig Details (`GigDetailsScreen`)**: Single-viewport hub featuring a horizontal 4-step progress tracker (`Accepted` | `In Progress` | `Evidence` | `Payment`), quick action buttons, live candidate count banner, assigned worker contact card, and location notes.
- **Dynamic Quick Actions & Redundancy Removal**: 
  - Before a worker is assigned (`!hasWorker`), only two quick action buttons are shown: `[Reschedule]` and `[Cancel Gig]`. The `[Material Bill]` button is hidden until a worker has been selected/assigned.
  - The redundant bottom full-width `Cancel Gig Request` bar has been removed to eliminate duplication with the `Cancel Gig` quick action.
- **Explicit Date & Time Display**: Both customer and worker interfaces now showcase live, formatted date and start time (`scheduleDisplay`, e.g., "17 Sep 2026, 11:00 AM" or "Today, 11:00 AM") fetched directly from the database rather than generic "As arranged".
- **Pre-Worker Direct Rescheduling**: 
  - Prior to worker assignment, `RescheduleGigScreen` presents a direct schedule update mode (`[Update Gig Schedule]`) that atomically updates `scheduled_date` and `scheduled_start_time` in PostgreSQL via `PATCH /api/v1/gigs/{gig_id}/schedule`.
  - Only after a worker is assigned does it switch to the multi-party negotiation mode (`[Send reschedule request]`) with worker confirmation notices.
- **Live Worker Opportunity Date & Time Synchronization**:
  - `OpportunityDetailsScreen` is a reactive stateful screen that fetches fresh gig information from the database upon entry, with pull-to-refresh and AppBar refresh support.
  - Workers always see the up-to-date customer-rescheduled date and time directly in the "Timing & Duration" card.
- **SOS Emergency Dialing & Direct Calling**: In-progress gigs provide an SOS emergency dialog directly triggering native telephone dialer (`tel:112` / `tel:100` / guild dispatch). Both customer and worker profiles feature direct dialer launch buttons (`tel:...`) beside the message button.
- **Mandatory Inline Review on Payment**: `PaymentScreen` embeds 5-star rating, compliment tags, and feedback note directly on the screen with a single `"Submit Review & Return Home"` button.
- **Full-Stack Gig Cancellation**: `CancelGigScreen` invokes `POST /api/v1/gigs/{gig_id}/cancel`, atomically transitioning the gig to `CANCELLED` and expiring opportunities on the backend while instantly dropping the gig from both customer and worker active views.

### Worker Opportunities & Acceptance Workflow

```text
Worker Home / Opportunities Tab
  └── OpportunityDetailsScreen [Guaranteed fixed wage, live DB date/time, distance, conflict warning check]
        ├── ConflictWarningDialog [Alert modal when opportunity overlaps existing commitments]
        └── Accept Gig
              └── Status: Awaiting Customer Selection
                    └── WorkerActiveJobScreen (Awaiting Banner + "Check Status")
                          └── [Customer Selects Worker] -> Status: Accepted / Scheduled
                                └── "Arrived & Start Work" Unlocks
```

- **Guaranteed Wage & Real Schedule Visibility**: Exact cooperative wage and live database date/time displayed before acceptance; worker bidding is strictly prohibited to prevent predatory undercutting.
- **Filterable Opportunities Feed**: `WorkerNavigation2Screen` filters by "All", "Emergency", and "Conflicts", automatically hiding already-responded or cancelled gigs.
- **Schedule Conflict Detection (SRS 10.3)**: Overlapping commitments trigger `ConflictWarningDialog` informing the worker of conflicts prior to acceptance.
- **True Cooperative Acceptance Lifecycle**: Accepting an opportunity places the worker in `WorkerJobStatus.awaitingSelection`. Physical work execution is locked until the customer confirms the assignment.

### Worker Active Job Execution & Audit Chain

```text
Worker Active Job Workspace [worker_active_job_screen.dart]
  ├── Customer Contact Card [Phone call & full-screen ChatScreen]
  ├── MultiWorkerInviteScreen [Invite colleague: Equal Sharing (50/50) vs Rookie Mentorship (0.5 credit)]
  ├── MaterialBillUploadScreen [Itemized receipts & photo audit uploads]
  ├── WorkerCancelRescheduleScreen [Cancellation or reschedule negotiation]
  └── Job Progression Lifecycle:
        [Accepted / Scheduled] -> "Arrived & Start Work"
        -> [In Progress] -> "Complete Work & Submit Evidence" (SRS 19)
        -> CompletionEvidenceUploadScreen [Work completion photo proof + notes]
        -> WaitingConfirmationScreen [Awaiting customer review & payment approval]
        -> WorkerPaymentConfirmationScreen [UPI Direct / Cash in Hand confirmation]
        -> ReviewCustomerScreen [Structured 3–4 MCQ review for customer]
        -> WorkerMainScreen.switchTab(context, 2) [Clean return to "My Jobs" with completed status]
```

- **Multi-Worker Collaboration (SRS 16)**: Lead technicians can invite verified colleagues as either "Equal Sharing" (50/50 split) or "Rookie Mentorship" (0.5 apprentice credits).
- **Rookie Progression Tracker (SRS 15.2)**: Apprentices monitor shadowed gig credits and mentor evaluations towards full guild certification on `RookieProgressionScreen`.
- **Completion Evidence (SRS 19)**: Mandatory photo evidence of finished work and cleaned work areas before payment settlement.
- **Review Submission Stack Resolution**: Submitting a customer evaluation smoothly transitions back to the "My Jobs" tab (`WorkerMainScreen.switchTab(context, 2)`) with zero backstack leaks.

### Shared Common Screens

- `screens/common/splash_screen.dart`: Animated onboarding splash.
- `screens/common/role_selection_screen.dart`: Customer vs Worker portal selection.
- `screens/common/forgot_password_screen.dart`: Mobile OTP recovery and password reset flow.
- `screens/common/chat_screen.dart`: Shared bidirectional messaging screen with backend API delivery, demo simulation, and auto-scroll.
- `screens/common/notifications_screen.dart`: Shared cooperative notifications list.
- `screens/common/settings_screen.dart`: Settings screen featuring Dark Mode toggle, multilingual choice chips, notification controls, and data privacy pledge.
- `screens/common/about_help_screen.dart`: Cooperative Society Charter, guild FAQs, toll-free helpline, and WhatsApp helpdesk.
- `screens/common/no_internet_screen.dart`: Offline network status screen with cached mode details and retry connectivity action.

## Current Source Structure

```text
SIH_2026/ [Project Root: Cooperative household-services platform]
├── context.md [Authoritative project context, architectural overview, and file tree]
├── history.md [Chronological changelog of all major milestones, bug fixes, and audits]
├── README.md [Project introduction, setup instructions, and quickstart guide]
├── .gitignore [Root Git ignore rules: ignores sensitive .env files, local databases, build artifacts, and editor files]
├── docs/ [Comprehensive architecture specifications and sprint roadmaps]
│   ├── 04_DATABASE_DESIGN.md [Authoritative database design: 31 tables, foreign keys, constraints]
│   ├── 05_API_DESIGN.md [REST API specification: endpoints, request/response envelopes, error codes]
│   ├── 06_BACKEND_SPRINTS.md [Backend sprint roadmap: Sprints 0 through 15 checkpoints]
│   ├── ALGORITHM_RECOMMENDATION_DEVELOPMENT_ROADMAP.md [Matching heuristics, dispatch, Bayesian scoring]
│   ├── FRONTEND_DESIGN_SYSTEM.md [Design tokens, Material 3 styling, button shadows, color palette]
│   ├── FRONTEND_DEVELOPMENT_ROADMAP.md [Frontend screen inventory, sprint plans, and user flow blueprints]
│   ├── SRS_Final.md [Software Requirements Specification: cooperative model, zero bidding, fair wages]
│   ├── WAGES.md [Cooperative wage formulas, experience tier modifiers, zero commission rules]
│   └── backend_plus_frontend_integration_testing.md [E2E test suite, seed credentials, cancellation matrix, ADB reverse proxy guide]
│
├── backend/ [FastAPI / SQLAlchemy backend service]
│   ├── alembic/ [Database migration environment]
│   │   ├── env.py [Alembic migration runtime environment]
│   │   ├── script.py.mako [Template for generating new Alembic migration scripts]
│   │   └── versions/ [Versioned database migration scripts]
│   │       ├── 7c590bb021a2_initial_foundation.py [Initial baseline migration]
│   │       ├── e29d3f46feb9_sprint_1_mvp_schema.py [Sprint 1 core schema migration]
│   │       └── 76b9636a889b_add_payment_type_and_cancellation_id_to_.py [Cancellation & payment schema additions]
│   ├── alembic.ini [Alembic database migration configuration]
│   ├── requirements.txt [Python dependencies: FastAPI, SQLAlchemy, Pydantic, Uvicorn, etc.]
│   ├── Procfile [Railway production deployment startup command]
│   ├── .env [Local environment configuration]
│   ├── .env.example [Template for environment variables]
│   ├── .gitignore [Git ignore rules for Python, cache, and virtual environments]
│   └── app/ [FastAPI application package]
│       ├── __init__.py [Backend app package initialization]
│       ├── main.py [FastAPI application factory, lifespan seeding, CORS, exception handlers]
│       ├── core/ [Core system infrastructure]
│       │   ├── config.py [Pydantic settings: database URL, JWT secret, CORS origins, constants]
│       │   ├── catalogue_data.py [Static catalogue data: 5 guild categories, ~115 standardized tasks]
│       │   ├── exceptions.py [Domain exceptions: NotFound, Conflict, Forbidden, BadRequest, and error handlers]
│       │   ├── logging.py [Centralized application logging configuration]
│       │   └── security.py [Password hashing, JWT creation/decoding, get_current_user dependencies]
│       ├── db/ [Database layer]
│       │   ├── base.py [Declarative Base and BaseModel with UUID, timestamp audit columns]
│       │   ├── session.py [SQLAlchemy engine, connection pool, SessionLocal factory, get_db dependency]
│       │   └── models/ [SQLAlchemy entity models (31 tables)]
│       │       ├── __init__.py [Exports all 31 database models and enums for Alembic and runtime]
│       │       ├── cancellation.py [GigCancellation, RescheduleRequest, PreviousWorkerRequest models]
│       │       ├── communication.py [Conversation, Message, Notification, GigEvent audit models]
│       │       ├── completion.py [CompletionSubmission, CompletionEvidence, CompletionConfirmation models]
│       │       ├── cooperative.py [Cooperative society registry model: legal name, registration number]
│       │       ├── enums.py [Database enums: UserRole, GigStatus, GigType, PaymentMethod, etc.]
│       │       ├── experience.py [WorkerExperienceRecord model tracking apprentice credits and guild history]
│       │       ├── gig.py [Gig, GigTask, GigWorkerOpportunity marketplace transaction models]
│       │       ├── multi_worker.py [WorkerParticipation model for multi-worker collaboration & rookie mentorship]
│       │       ├── payment.py [Payment and MaterialReceipt models for escrow, payouts, and receipts]
│       │       ├── review.py [Review, ReviewQuestion, ReviewAnswer models for two-way objective evaluation]
│       │       ├── service.py [ServiceCategory, ServiceTask, WorkerCategory, WorkerAvailability models]
│       │       ├── user.py [User, CustomerProfile, WorkerProfile, WorkerMetric models]
│       │       └── visitation.py [VisitationProposal, VisitationProposalTask models for on-site scope inspection]
│       ├── api/ [API Routing Layer]
│       │   ├── __init__.py [API package initialization]
│       │   └── v1/ [API Version 1 package]
│       │       ├── __init__.py [API v1 package initialization]
│       │       ├── router.py [Master v1 router registering all 13 domain endpoint modules]
│       │       └── endpoints/ [REST API domain endpoint controllers]
│       │           ├── __init__.py [Endpoints package initialization]
│       │           ├── auth.py [Development auth: pre-seeded demo accounts retrieval, JWT login, refresh]
│       │           ├── cancellation.py [Gig cancellation and rescheduling enforcing authoritative fee policies]
│       │           ├── catalogue.py [Service catalogue: categories, standardized tasks, duration baselines]
│       │           ├── chat.py [Job-scoped chat thread initialization and messaging endpoints]
│       │           ├── customer.py [Customer profile management and past gig history endpoints]
│       │           ├── gigs.py [Gig lifecycle: price preview, creation, candidate listing, worker selection]
│       │           ├── health.py [System health and database connectivity check endpoint]
│       │           ├── materials.py [Material procurement mode and itemized receipt audit upload endpoints]
│       │           ├── me.py [Current authenticated user profile inspection and session retrieval]
│       │           ├── notifications.py [User notification feed, unread counters, and mark-as-read endpoints]
│       │           ├── participations.py [Multi-worker collaboration and rookie mentorship invitation endpoints]
│       │           ├── reviews.py [Two-way structured MCQ review submission, questions, and public metrics]
│       │           └── worker.py [Worker profile, multi-tier verification, availability schedule, earnings]
│       ├── schemas/ [Pydantic request & response validation schemas]
│       │   ├── __init__.py [Schemas package initialization]
│       │   ├── auth.py [TokenResponse, LoginRequest, DemoUserResponse schemas]
│       │   ├── cancellation.py [Cancellation request, fee calculation preview, and reschedule schemas]
│       │   ├── candidate.py [Worker candidate response schemas: wage, score, ratings, matching factors]
│       │   ├── catalogue.py [ServiceCategoryResponse, ServiceTaskResponse schemas]
│       │   ├── chat.py [Conversation thread, message create request, message list response schemas]
│       │   ├── common.py [ResponseEnvelope, PaginatedEnvelope, and shared pagination query schemas]
│       │   ├── completion.py [Completion evidence upload, submission detail, customer confirmation schemas]
│       │   ├── gig.py [Gig create request, task item, and detailed gig response schemas]
│       │   ├── material.py [Material procurement mode and receipt upload response schemas]
│       │   ├── multi_worker.py [Worker participation request and invite status schemas]
│       │   ├── notification.py [Notification item and unread count response schemas]
│       │   ├── opportunity.py [Worker opportunity feed item and dispatch status schemas]
│       │   ├── payment.py [Payment recording, UPI reconciliation, and receipt confirmation schemas]
│       │   ├── pricing.py [Dynamic price preview request and tariff breakdown schemas]
│       │   ├── review.py [Review create request, answer item, question list, public metrics schemas]
│       │   ├── user.py [User profile, registration, and role management schemas]
│       │   ├── visitation.py [Visitation proposal, task quotation, customer approval schemas]
│       │   ├── worker.py [Worker verification, experience tier, and availability schedule schemas]
│       │   └── worker_gig.py [Worker job detail and active gig execution schemas]
│       ├── repositories/ [Repository abstraction package reserved for specialized data query builders]
│       │   └── __init__.py [Repositories package initialization]
│       ├── services/ [Core business logic & domain services]
│       │   ├── __init__.py [Services package initialization]
│       │   ├── cancellation_service.py [Authoritative cancellation policy enforcement, fee calculation, worker re-open]
│       │   ├── catalogue_service.py [Service catalogue query and initial database seeding service]
│       │   ├── chat_service.py [Job-scoped chat initialization, message delivery, audit event logging]
│       │   ├── completion_service.py [Work completion evidence verification, photo submission, customer sign-off]
│       │   ├── experience_service.py [Apprentice credit progression and shadow gig verification service]
│       │   ├── financial_guard.py [Escrow integrity and zero-commission fee guard validations]
│       │   ├── gig_service.py [Gig creation, status lifecycle transitions, candidate assignment service]
│       │   ├── material_service.py [Itemized material claims, receipt verification, bill audit service]
│       │   ├── multi_worker_service.py [Multi-worker invite dispatch, equal sharing split, rookie mentorship tracking]
│       │   ├── notification_service.py [Notification event dispatch, counterparty alerting, read-state service]
│       │   ├── opportunity_service.py [Opportunity dispatch engine, geographic matching, schedule conflict checks]
│       │   ├── payment_service.py [Escrow settlement, UPI Direct/Cash reconciliation, payout confirmation]
│       │   ├── pricing_service.py [Transparent labour wage computation, duration estimates, visitation tariffs]
│       │   ├── review_service.py [Two-way structured review processing, Bayesian rating calculation, metrics updates]
│       │   ├── score_service.py [Worker final reliability score computation and rookie initial metrics]
│       │   ├── user_service.py [User account lifecycle, authentication, profile management service]
│       │   ├── visitation_service.py [Fixed ₹100 visitation workflow, on-site scope estimation, proposal approval]
│       │   ├── wage_service.py [Cooperative guild tariff lookup, emergency floor rules, experience multiplier]
│       │   └── worker_service.py [Worker verification tier checking, weekly schedule availability management]
│       └── tests/ [Comprehensive automated pytest suite (198 tests)]
│           ├── __init__.py [Tests package initialization]
│           ├── conftest.py [Pytest test fixtures, in-memory SQLite engine, authenticated client setups]
│           ├── test_auth_and_profiles.py [Authentication and profile endpoints test suite]
│           ├── test_config.py [Configuration and environment variables validation tests]
│           ├── test_health.py [Health check endpoint and DB connectivity tests]
│           ├── test_models.py [SQLAlchemy models and database constraints validation tests]
│           ├── test_sprint2_verification.py [Sprint 2 multi-tier verification test suite]
│           ├── test_sprint3_pricing_and_wages.py [Sprint 3 pricing formulas and guild tariff tests]
│           ├── test_sprint4_gig_creation.py [Sprint 4 customer gig creation and validation tests]
│           ├── test_sprint5_opportunity_engine.py [Sprint 5 worker opportunity dispatch and conflict tests]
│           ├── test_sprint6_worker_selection.py [Sprint 6 candidate ranking and worker selection tests]
│           ├── test_sprint7_job_execution.py [Sprint 7 active job progression and evidence submission tests]
│           ├── test_sprint8_payment.py [Sprint 8 payment reconciliation and receipt confirmation tests]
│           ├── test_sprint9_visitation.py [Sprint 9 fixed ₹100 visitation and proposal tests]
│           ├── test_sprint10_multi_worker.py [Sprint 10 multi-worker collaboration and rookie mentorship tests]
│           ├── test_sprint11_cancellation_rescheduling.py [Sprint 11 cancellation fee policy and reschedule tests]
│           ├── test_sprint12_materials.py [Sprint 12 itemized material receipt upload and audit tests]
│           ├── test_sprint13_reviews.py [Sprint 13 two-way review submission and Bayesian rating tests]
│           ├── test_sprint14_chat_notifications.py [Sprint 14 job chat messaging and notifications tests]
│           ├── test_sprint15_dev_auth.py [Sprint 15 development demo accounts and authentication tests]
│           └── test_verification.py [General verification and security integrity tests]
│
└── mobile_app/ [Flutter Mobile Application]
    ├── pubspec.yaml [Flutter package dependencies and asset configuration]
    ├── pubspec.lock [Locked dependency versions]
    ├── analysis_options.yaml [Dart analyzer rules and linter configuration]
    ├── .gitignore [Flutter-specific Git ignore rules]
    ├── lib/ [Flutter application source code]
    │   ├── main.dart [App entry point: theme configuration and initial SplashScreen route]
    │   ├── theme/ [Styling & Visual Design]
    │   │   ├── .gitkeep [Theme directory marker]
    │   │   └── app_theme.dart [Centralized Material 3 theme tokens, color palette, typography, button styles]
    │   ├── services/ [Core application services]
    │   │   ├── .gitkeep [Services directory marker]
    │   │   ├── api_client.dart [Centralized Dio HTTP client: base URL, dynamic bearer auth, error unwrapping, mock test handler]
    │   │   └── token_storage.dart [Secure session persistence: JWT tokens, active user model, baseUrl switcher]
    │   ├── repositories/ [Frontend API repository abstractions]
    │   │   ├── .gitkeep [Repositories directory marker]
    │   │   ├── auth_repository.dart [Authentication API calls: login, register, token refresh, demo accounts]
    │   │   ├── catalogue_repository.dart [Service catalogue API calls: categories, sub-services, standardized tasks]
    │   │   ├── chat_repository.dart [Job-scoped chat API calls: get or create conversation, messages, send text]
    │   │   ├── gig_repository.dart [Customer gig lifecycle API calls: create, price preview, candidates, select worker]
    │   │   ├── notification_repository.dart [User notifications API calls: fetch alerts, mark read, unread counter]
    │   │   ├── payment_repository.dart [Payment reconciliation API calls: record payment, confirm receipt, breakdown]
    │   │   ├── review_repository.dart [Structured review API calls: fetch questions, submit ratings, public metrics]
    │   │   └── worker_repository.dart [Worker workflow API calls: fetch opportunities, accept/decline, start work, complete]
    │   ├── models/ [Data models & transfer objects]
    │   │   ├── gig_draft.dart [Customer gig creation state model: category, tasks, visitation toggle, location, notes]
    │   │   ├── customer_gig_workflow.dart [Customer gig lifecycle model: GigStage enum, GigCandidate, CustomerGig mapper from DTO]
    │   │   ├── worker_job_workflow.dart [Worker job domain model: WorkerOpportunity, WorkerJob, WorkerJobStatus, DayAvailability]
    │   │   └── api/ [API Data Transfer Objects (DTOs)]
    │   │       ├── api_models.dart [Strongly typed backend DTOs: User, Gig, Candidate, Task, Payment, Review, Chat, Notification]
    │   │       └── api_response.dart [Generic API envelope models: ApiResponse, PaginatedResponse, ApiError]
    │   ├── providers/ [Riverpod state management & cross-screen synchronizers]
    │   │   ├── .gitkeep [Providers directory marker]
    │   │   ├── active_job_sync_provider.dart [Synchronizes active gig lifecycle between Customer and Worker state stores]
    │   │   ├── customer_gigs_provider.dart [Customer active, upcoming, and past gigs state management with cancellation filtering]
    │   │   └── worker_jobs_provider.dart [Worker opportunities, active jobs, and scheduled gigs state management with cancellation filtering]
    │   ├── utils/ [Shared utility helpers]
    │   │   └── phone_dialer_helper.dart [Standardized cross-platform telephone dialer launcher (tel:...) via url_launcher]
    │   ├── widgets/ [Reusable UI widgets]
    │   │   └── common/ [Common cross-cutting widgets]
    │   │       ├── .gitkeep [Common widgets directory marker]
    │   │       ├── location_picker_dialog.dart [Interactive location map picker and address selector]
    │   │       ├── shared_widgets.dart [Core UI primitives: BrandMark, SurfaceCard, StatusPill, PrimaryAction, shared auth layouts]
    │   │       ├── skeleton_loaders.dart [Shining horizontal shimmer animation, GigCardSkeleton, OpportunityCardSkeleton]
    │   │       └── sos_dialog.dart [Emergency assistance dialog triggering native telephone dialer (tel:112 / tel:100 / guild dispatch)]
    │   └── screens/ [UI Screen controllers & views]
    │       ├── common/ [Shared cross-role screens]
    │       │   ├── .gitkeep [Common screens directory marker]
    │       │   ├── about_help_screen.dart [Cooperative Society Charter, FAQs, toll-free helpline, WhatsApp helpdesk]
    │       │   ├── chat_screen.dart [Shared fullscreen chat interface: live backend messaging, demo fallback, auto-scrolling]
    │       │   ├── forgot_password_screen.dart [Mobile OTP recovery and password reset verification]
    │       │   ├── no_internet_screen.dart [Offline network error screen with cached mode and retry action]
    │       │   ├── notifications_screen.dart [Shared cooperative notifications feed and status alerts]
    │       │   ├── role_selection_screen.dart [Entry gate: select between Customer and Worker portals]
    │       │   ├── settings_screen.dart [Settings screen: dark mode toggle, multilingual picker, privacy controls]
    │       │   └── splash_screen.dart [Animated onboarding splash with cooperative mission statement]
    │       ├── customer/ [Customer-facing screens & navigation]
    │       │   ├── .gitkeep [Customer directory marker]
    │       │   ├── customer_login_screen.dart [Customer portal login with demo credentials and root stack clearing]
    │       │   ├── customer_main_screen.dart [Customer bottom navigation shell: 4 tab navigators, switchTab static helper]
    │       │   ├── customer_register_screen.dart [Customer account registration with cooperative onboarding]
    │       │   ├── alerts/ [Customer Alerts Tab]
    │       │   │   └── customer_navigation_3_screen.dart [Customer Alerts tab: system notifications and job updates]
    │       │   ├── home/ [Customer Home Tab]
    │       │   │   ├── create_gig_screen.dart [Step 1: Category dropdown, ₹100 site visit toggle, collapsible task search, instructions]
    │       │   │   ├── customer_home_screen.dart [Customer dashboard: dynamic greeting, active gig counter, quick create]
    │       │   │   ├── emergency_tip_screen.dart [Emergency voluntary tipping fallback when posted gig awaits accepting workers]
    │       │   │   ├── labour_price_preview_screen.dart [Step 3: Algorithmic wage breakdown, deposit calculation, gig confirmation]
    │       │   │   └── material_procurement_screen.dart [Step 2: Material choice: customer purchase vs worker purchase]
    │       │   ├── my_jobs/ [Customer My Gigs Tab]
    │       │   │   ├── accepted_candidates_screen.dart [Convenience re-export for accepted candidate review list]
    │       │   │   ├── active_job_screen.dart [Convenience re-export for live customer job monitoring screen]
    │       │   │   ├── cancel_gig_screen.dart [Customer gig cancellation with policy fees disclaimer]
    │       │   │   ├── completion_confirmation_screen.dart [Convenience re-export for customer work sign-off]
    │       │   │   ├── completion_evidence_review_screen.dart [Convenience re-export for reviewing worker completion photos]
    │       │   │   ├── customer_navigation_2_screen.dart [Customer My Gigs tab: Active, Upcoming, Completed gig lists with live candidate badge]
    │       │   │   ├── customer_workflow_screens.dart [Customer workflow suite: candidates review, active tracking, payment, evidence viewer]
    │       │   │   ├── final_worker_selected_screen.dart [Convenience re-export for worker assignment confirmation]
    │       │   │   ├── gig_details_screen.dart [Customer gig hub: 4-step horizontal tracker, candidates banner, quick actions, location]
    │       │   │   ├── material_bill_viewer_screen.dart [Convenience re-export for inspecting worker material receipts]
    │       │   │   ├── payment_screen.dart [Convenience re-export for UPI/Cash payment settlement]
    │       │   │   ├── previous_worker_request_screen.dart [Convenience re-export for requesting previous trusted worker]
    │       │   │   ├── reschedule_gig_screen.dart [Customer gig rescheduling with worker approval notice]
    │       │   │   ├── review_worker_screen.dart [Post-completion structured 3–4 MCQ review for assigned worker]
    │       │   │   ├── waiting_for_candidates_screen.dart [Live broadcasting radar screen awaiting worker responses]
    │       │   │   ├── worker_comparison_screen.dart [Convenience re-export for side-by-side candidate comparison]
    │       │   │   └── worker_profile_screen.dart [Convenience re-export for candidate profile and trust signals]
    │       │   └── profile/ [Customer Profile Tab]
    │       │       ├── customer_account_screens.dart [Customer account screens: job history, support chat, FAQs]
    │       │       └── customer_navigation_4_screen.dart [Customer Profile tab: account details, history, settings, help]
    │       └── worker/ [Worker-facing screens & navigation]
    │           ├── .gitkeep [Worker directory marker]
    │           ├── worker_login_screen.dart [Worker portal login with role verification and root stack clearing]
    │           ├── worker_main_screen.dart [Worker bottom navigation shell: 4 tab navigators, switchTab static helper]
    │           ├── worker_register_screen.dart [Worker guild registration and skill onboarding]
    │           ├── home/ [Worker Home Tab]
    │           │   └── worker_home_screen.dart [Worker dashboard: availability toggle, active job card, new opportunities]
    │           ├── opportunities/ [Worker Opportunities Tab]
    │           │   ├── conflict_warning_dialog.dart [Conflict alert modal when opportunity overlaps existing commitments]
    │           │   ├── opportunity_details_screen.dart [Guaranteed wage, distance, conflict warning check, accept/decline actions]
    │           │   └── worker_navigation_2_screen.dart [Worker Opportunities tab: filterable feed (Emergency, Conflicts, All)]
    │           ├── my_jobs/ [Worker My Jobs Tab]
    │           │   ├── completion_evidence_upload_screen.dart [Work completion photo proof upload and handover notes]
    │           │   ├── incoming_join_request_screen.dart [Inspect incoming collaboration invites from lead technicians]
    │           │   ├── material_bill_upload_screen.dart [Itemized material cost claims and photo receipt audit uploads]
    │           │   ├── multi_worker_invite_screen.dart [Invite verified colleague as Equal Sharing (50/50) or Rookie Mentorship (0.5 credit)]
    │           │   ├── review_customer_screen.dart [Worker structured 3–4 MCQ review for customer, resetting to My Jobs]
    │           │   ├── rookie_progression_screen.dart [Apprentice progression tracker towards full trade guild certification]
    │           │   ├── visitation_proposal_dialog.dart [Fixed ₹100 on-site visitation scope assessment and quotation modal]
    │           │   ├── waiting_confirmation_screen.dart [Live awaiting customer review and payment approval screen]
    │           │   ├── worker_active_job_screen.dart [Central job execution workspace: status stepper, contact actions, co-worker invite]
    │           │   ├── worker_cancel_reschedule_screen.dart [Worker gig cancellation or reschedule request with policy checks]
    │           │   ├── worker_navigation_3_screen.dart [Worker My Jobs tab: Active/Upcoming and Completed lists, invitations, rookie track]
    │           │   └── worker_payment_confirmation_screen.dart [Reconciliation confirmation (UPI Direct / Cash) with zero deductions]
    │           └── profile/ [Worker Profile Tab]
    │               ├── worker_availability_screen.dart [Weekly recurring availability schedule editor (Mon–Sun toggles & time pickers)]
    │               ├── worker_earnings_screen.dart [Worker transparent earnings breakdown, gig payouts, zero-commission ledger]
    │               ├── worker_navigation_4_screen.dart [Worker Profile tab: credentials, guild tariff guidelines, earnings, settings]
    │               └── worker_verification_screen.dart [Multi-tier verification viewer: KYC, Guild Trade, Shareholder, Police Antecedents]
    └── test/ [Flutter Automated Tests (35 tests passing)]
        ├── cancellation_workflow_test.dart [5 comprehensive unit & workflow tests for gig cancellation and status consistency]
        ├── integration_hardening_test.dart [23 comprehensive integration hardening tests covering API models, serialization, and repositories]
        └── widget_test.dart [7 comprehensive widget tests covering Customer/Worker flows, navigation shells, and authentication layouts]
```

---

## Important File Responsibilities

### Frontend (`mobile_app/`)
- `lib/main.dart`: App entry point; launches `SplashScreen` and configures Material 3 app theme.
- `lib/theme/app_theme.dart`: Color tokens, Material 3 styling, component themes, and global square offset-shadow button styling.
- `lib/services/api_client.dart`: Centralized Dio HTTP client wrapper with automatic base URL syncing, bearer token injection, structured error transformation (`ApiError`), and mock handler hook for unit tests.
- `lib/services/token_storage.dart`: Session manager persisting JWT access tokens and user profile state in memory and storage, notifying listeners on auth changes.
- `lib/widgets/common/shared_widgets.dart`: Standard UI building blocks (`BrandMark`, `SurfaceCard`, `StatusPill`, `PrimaryAction`, `AuthLoginLayout`, `AuthRegisterLayout`).
- `lib/widgets/common/skeleton_loaders.dart`: Continuous left-to-right shining shimmer animations and card skeletons (`GigCardSkeleton`, `OpportunityCardSkeleton`) providing smooth, flicker-free data loading.
- `lib/widgets/common/sos_dialog.dart`: Emergency assistance dialog triggering native telephone dialer (`tel:112` / `tel:100` / guild dispatch) during active job execution.
- `lib/widgets/common/location_picker_dialog.dart`: Interactive map picker and address selector for customer gig creation and location updates.
- `lib/utils/phone_dialer_helper.dart`: Unified cross-platform telephone dialer utility invoking `tel:...` via `url_launcher`.
- `lib/providers/customer_gigs_provider.dart` & `worker_jobs_provider.dart`: Riverpod state stores keeping active/scheduled gigs in sync across tabs, strictly filtering out cancelled or expired items.
- `lib/models/worker_job_workflow.dart`: Worker domain models (`WorkerOpportunity`, `WorkerJob`, `WorkerJobStatus`, `WorkerJoinRequest`, `DayAvailability`, `demoWeekAvailability`).
- `lib/models/customer_gig_workflow.dart`: Customer domain models (`GigStage` enum, `GigCandidate`, `CustomerGig` mapper from DTO).
- `lib/models/api/api_models.dart`: Full suite of backend DTO models matching FastAPI responses.
- `lib/screens/worker/worker_main_screen.dart`: Worker shell with persistent bottom navigation using per-tab navigators and static `switchTab` helper.
- `lib/screens/customer/customer_main_screen.dart`: Customer shell with persistent bottom navigation and static `switchTab` helper.
- `lib/screens/common/chat_screen.dart`: Fullscreen chat interface supporting both live backend messaging (`_chatRepo.sendMessage`) and interactive demo simulation with automatic scroll to bottom.
- `test/cancellation_workflow_test.dart`: 5 unit and workflow tests validating `GigCancelResponseDto` parsing, `GigRepository` cancel contract, and CustomerGig/WorkerJob cancellation status filtering.
- `test/integration_hardening_test.dart`: 23 integration hardening tests validating API models, JSON serialization, DTO mapping, and edge-case handling.
- `test/widget_test.dart`: 7 widget test flows validating Customer/Worker navigation, registration, profiles, opportunity details, and settings.

### Backend (`backend/`)
- `app/main.py`: FastAPI application entrypoint, CORS middleware, centralized exception handlers, startup database verification and catalogue/review auto-seeding, and `/api/v1` router mount.
- `app/core/config.py`: Pydantic settings loading environment variables, Supabase credentials, and wage/visitation policy constants (`VISITATION_FEE=100.00`, `CANCELLATION_FEE_AFTER_SELECTION=50.00`).
- `app/core/catalogue_data.py`: Static catalogue dataset for all 5 guild categories (Plumbing, Carpentry, Electrician, Painter, House Help) and ~115 standardized tasks.
- `app/core/security.py`: Password hashing, JWT creation/decoding, user resolution, and role-based access control dependencies.
- `app/db/session.py`: Database engine, connection pooling, SessionLocal factory, and `get_db` dependency.
- `app/db/models/__init__.py`: Exports all 31 database models and enums for Alembic and application runtime.
- `app/services/cancellation_service.py`: Enforces authoritative cancellation policy (₹0 pre-selection, ₹50 post-selection, lock once `IN_PROGRESS`).
- `app/services/visitation_service.py`: Fixed ₹100 on-site visitation inspection workflow, task proposals, and fee absorption/payment rules.
- `app/services/chat_service.py`: Job-scoped conversation thread initialization, message delivery, unread counter management, and audit events.
- `app/services/review_service.py`: Two-way structured MCQ review processing, Bayesian rating calculation, and worker metrics updates.
- `app/services/opportunity_service.py`: Worker opportunity dispatch, geographic matching, schedule conflict checks, and atomic acceptance transactions.
- `app/services/pricing_service.py` & `app/services/wage_service.py`: Cooperative wage formulas, experience tier modifiers, duration summing, and 45-min billable minimum enforcement.
- `app/tests/`: Comprehensive pytest suite with 198 automated unit and integration tests across Sprints 0 through 15.

---

## Validation Summary

The entire stack has been verified and passes all tests:

```text
# Frontend Validation
flutter analyze -> 0 issues found!
flutter test -> All 35 tests passed! (5 cancellation tests + 23 integration tests + 7 widget tests)

# Backend Validation
pytest app/tests/ -> 198 passed in 14.8s
GET /api/v1/health -> 200 OK {"status": "ok", "database": "connected"}
```
