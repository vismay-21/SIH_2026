# Project History

## Maintenance Rules

- Keep entries concise and limited to important project changes.
- Begin every entry with the date, time, and contributor name.
- Describe what changed and why in a few sentences.
- Add new entries chronologically; do not rewrite older entries unless correcting an error.

## 2026-09-05 02:48:04 +05:30 — Vismay

Established the SIH 2026 repository baseline with the Flutter application inside `mobile_app/`, while reserving root-level `backend/` and `docs/` directories. Created the initial frontend structure under `mobile_app/lib/`, keeping `main.dart` in its standard location and assigning separate folders to Customer and Worker navigation destinations.

Added the simple Splash, Role Selection, Customer, and Worker placeholder screens. Implemented navigation for role selection, registration returning to the relevant login screen, login leading to the relevant main screen, and four bottom-navigation destinations with Home selected by default. Updated widget tests for both role flows and verified `flutter analyze`, three passing `flutter test` tests, and `flutter run -d chrome`. No backend functionality, real authentication, APIs, database logic, algorithms, or additional dependencies were added.

## 2026-09-06 — GitHub Copilot

Established the first Sahakaar Seva frontend design foundation from the supplied reference UI and palette. Added centralized theme tokens, Material 3 styling, shared brand/card/status/action components, styled splash and role selection onboarding, and replaced placeholder role destinations with mock customer and worker dashboard surfaces. Renamed navigation destinations to `Home`, `My jobs`, `Alerts`, `Opportunities`, and `Profile` according to role. The mock UI keeps exact wage visibility, availability, verification, lifecycle, emergency, previous-worker, notifications, and profile concepts visible without adding backend logic or worker bidding.

Added `docs/FRONTEND_DESIGN_SYSTEM.md` to record palette, typography, component rules, navigation, constraints, implemented surfaces, and next design phases. Updated widget tests to validate the redesigned flows. Verified `flutter analyze` and `flutter test` with all three tests passing.

## 2026-09-07 11:45:43 +05:30 — Yug

Completed the frontend product-flow implementation for Sahakaar Seva using Flutter and the existing Material 3 stack. Added the shared visual system with cooperative green, amber attention states, warm off-white surfaces, centralized theme tokens, shared brand/card/status/action components, and the supplied square white button treatment with black border and hard offset shadow. Styled splash, role selection, customer login/registration, worker login/registration, and both role dashboard navigation shells.

Built the Customer gig flow: Create Gig form with category, description, location, date/time, duration, emergency toggle, photo placeholder, and instructions; material procurement choice between customer and worker purchase; labour-only price-range preview; gig posting return path; shared `GigDraft` model; and cooperative example range `₹550 – ₹800`. Added mock customer gig lifecycle data and the complete tracker from Seeking Workers through Workers Responding, Accepted Candidates, Worker Selected, Scheduled, Active, Completion Requested, Payment, and Completed.

Added Customer My Gigs with Active, Upcoming, and Completed tabs. Track Job now opens the Customer shell on My Gigs and immediately opens the selected gig details. Added gig details/status tracker, connected progress line, accepted candidates, transparent worker comparison/recommendation, worker profile, final worker selection confirmation, previous-worker request, active job workspace, chat entry, completion evidence review, completion confirmation, Cash/UPI payment selection/status, and material bill/proof viewer. The screens use mock data and navigation; backend persistence, real matching, uploads, chat service, and payment gateway are not yet implemented.

Added Customer Chat with inbox, worker conversation threads, message input/send behavior, and links back to job details. Added functional Profile surfaces for job history, settings, notification/privacy controls, help/support FAQs and support contact, plus sign-out confirmation returning to Splash. Alerts now open related gig details. Improved customer dashboard hierarchy with clearer gig statuses, Track Job as the primary action, Chat as secondary action, stronger emergency indicators, explicit estimated duration, and worker trust signals.

Updated widget tests and repeatedly verified the implementation with `dart format`, `flutter analyze`, and `flutter test`; the current suite passes all three widget tests. No backend, API, database, production authentication, real media picker, real payment integration, or additional package dependency was added.

## 2026-09-07 20:49:44 +05:30 — Vismay

Reorganized the Customer screen files and bottom-navigation folder layout into clean, domain-specific directories (`home`, `my_jobs`, `alerts`, `profile`) corresponding to the four primary navigation destinations.

Moved gig creation screens (`create_gig_screen.dart`, `material_procurement_screen.dart`, `labour_price_preview_screen.dart`) into `lib/screens/customer/home/`. Renamed generic navigation folders (`navigation_2`, `navigation_3`, `navigation_4`) to descriptive domain folders (`my_jobs`, `alerts`, `profile` for customer, and `opportunities`, `my_jobs`, `profile` for worker). Moved gig details, candidate comparison, active job workspace, completion evidence, payment, and workflow screens into `lib/screens/customer/my_jobs/`. Moved chat inbox/thread, job history, settings, and help/support screens into `lib/screens/customer/profile/`.

Updated all relative import paths across Customer and Worker screens, main shell screens, and subfolders. Verified that all features work without breaking existing flows, and confirmed zero compilation/analysis issues (`flutter analyze` passed with 0 issues) and all widget tests passed (`flutter test` passed 3/3 tests). Updated `context.md` with the new folder tree and file responsibilities.

Implemented all remaining Customer screens and lifecycle flows with theme-aligned UI and rich mock data:
- Built `WaitingForCandidatesScreen` (`lib/screens/customer/my_jobs/waiting_for_candidates_screen.dart`) for fresh gigs in "Seeking Workers / Waiting for candidates to accept" stage, with live broadcast pulse animation, radius indicator, and response window tracker.
- Built `ReviewWorkerScreen` (`lib/screens/customer/my_jobs/review_worker_screen.dart`) for post-completion structured 3–4 MCQ feedback (Work Quality, Punctuality, Communication, Overall Recommendation) and optional written comments.
- Built `CancelGigScreen` (`lib/screens/customer/my_jobs/cancel_gig_screen.dart`) for customer gig cancellation with reason selection, cooperative cancellation policy disclaimer, and confirmation modal.
- Built `RescheduleGigScreen` (`lib/screens/customer/my_jobs/reschedule_gig_screen.dart`) for requesting date/time changes with worker confirmation notice.
- Built `EmergencyTipScreen` (`lib/screens/customer/home/emergency_tip_screen.dart`) for SRS 18.1 emergency no-worker acceptance tip fallback, displaying `Algorithmic Wage + Customer Tip = Total Worker Payout` with 100% direct worker payout guarantee and worker re-notification.
- Refined Emergency & Tipping mechanism per SRS Section 18 & 18.1: removed duplicate Emergency button from `CustomerHomeScreen` (emergency status is set via toggle in `CreateGigScreen`), and added the "No workers accepted yet" tipping fallback notice card directly in `GigDetailsScreen` (`lib/screens/customer/my_jobs/gig_details_screen.dart`) to launch tipping when a posted gig awaits response.
- Added demo gig instances for seeking candidates and emergency tip fallback in `customer_gig_workflow.dart`. Wired next actions in `gig_details_screen.dart`, `customer_home_screen.dart`, and `customer_navigation_3_screen.dart`.
- Implemented persistent bottom navigation in `CustomerMainScreen` (`lib/screens/customer/customer_main_screen.dart`) using per-tab nested `Navigator`s inside an `IndexedStack`. Sub-screens (Gig Details, Accepted Candidates, Active Job Workspace, Chat, Payment, Cancel, Reschedule, Emergency Tip, Review) now push within their tab's viewport, leaving the bottom `NavigationBar` permanently visible at all times.
- Added dedicated Emergency Tipping demo card (`demoGigs[5]`: "Main power fuse tripping", Emergency Electrical, 0 workers accepted) to the active list on `CustomerHomeScreen` (`lib/screens/customer/home/customer_home_screen.dart`) for immediate testing and demonstration of the tipping fallback flow.
- Formatted code (`dart format`), verified `flutter analyze` (0 issues found), and passed all widget tests (`flutter test` 3/3 passed).

## 2026-09-07 23:46:32 +05:30 — Vismay

Implemented all remaining Worker-side screens (14 screens across opportunities, my_jobs, profile, and shell) and shared common screens for the Sahakaar Seva Cooperative platform, completing the full frontend screen inventory:
- Created domain models in `lib/models/worker_job_workflow.dart`: `WorkerOpportunity`, `WorkerJob`, `WorkerJobStatus`, `WorkerJoinRequest`, `JoinRoleType`, and `DayAvailability` alongside rich mock datasets (`demoOpportunities`, `demoWorkerJobs`, `demoJoinRequests`, `demoWeekAvailability`).
- Opportunities Domain (`lib/screens/worker/opportunities/`):
  - Created `conflict_warning_dialog.dart` (SRS 10.3) notifying workers when an opportunity overlaps with scheduled commitments or off-duty hours.
  - Created `opportunity_details_screen.dart` displaying guaranteed fixed cooperative wage (zero bidding per SRS), location, distance, customer instructions, and materials preference with accept/decline flows.
  - Updated `worker_navigation_2_screen.dart` with filter chips ("All", "Emergency", "Conflicts") and direct navigation to opportunity details.
- My Jobs Domain (`lib/screens/worker/my_jobs/`):
  - Created `worker_active_job_screen.dart` as the central job execution workspace with status progression (Accepted -> In Progress -> Evidence -> Payment), customer contact actions, and quick action bar.
  - Created `multi_worker_invite_screen.dart` (SRS 16.2) enabling primary workers to invite verified cooperative peers as either "Equal Sharing" (50/50 split) or "Rookie Mentorship" (0.5 credits).
  - Created `incoming_join_request_screen.dart` (SRS 16.1) allowing invited technicians to inspect and accept/decline collaboration requests.
  - Created `rookie_progression_screen.dart` (SRS 15.2) tracking apprentice learning progress towards full certification with mentor feedback notes.
  - Created `material_bill_upload_screen.dart` (SRS 7.2) for itemized material cost claims and photo receipt audit uploads.
  - Created `completion_evidence_upload_screen.dart` (SRS 19) for work completion photo evidence and testing notes.
  - Created `waiting_confirmation_screen.dart` displaying live awaiting customer review and payment approval status.
  - Created `worker_payment_confirmation_screen.dart` (SRS 19.1) confirming payment reconciliation (UPI Direct / Cash in Hand) with zero platform deductions.
  - Created `review_customer_screen.dart` (SRS 20) with structured 3–4 objective MCQs evaluating work area safety, scope accuracy, and communication.
  - Created `worker_cancel_reschedule_screen.dart` (SRS 21) with reason selection and proposed reschedule date/time pickers.
  - Updated `worker_navigation_3_screen.dart` with tabs for Active/Upcoming and Completed jobs, plus collaboration requests and rookie track shortcuts.
- Profile Domain (`lib/screens/worker/profile/`):
  - Created `worker_verification_screen.dart` (SRS 22) displaying Tier 1 (Identity), Tier 2 (Trade Guild Assessment), Tier 3 (Cooperative Shareholder), and Tier 4 (Police Antecedents) clear status.
  - Created `worker_availability_screen.dart` (SRS 10.1) featuring weekly recurring availability with day toggles, time pickers, and quick presets.
  - Updated `worker_navigation_4_screen.dart` with profile stats, cooperative tariff guidelines dialog, links to availability, verification, rookie progression, and sign out confirmation.
- Shell & Common Components:
  - Updated `worker_main_screen.dart` to provide persistent bottom navigation across all sub-screens using per-tab `Navigator`s inside `IndexedStack`.
  - Updated `worker_home_screen.dart` with live availability status toggle, interactive opportunity cards, upcoming job card, and notification badge entry.
  - Created `screens/common/chat_screen.dart` for shared mutual customer-worker messaging and `screens/common/notifications_screen.dart` for system alerts.
- Verification & Testing:
  - Added test flows to `mobile_app/test/widget_test.dart` expanding test suite to 5 tests covering Customer flows, Worker navigation, Worker profile & availability, and Worker opportunity details & active job acceptance.
  - Formatted codebase (`dart format`), verified `flutter analyze` (0 issues found), and ran `flutter test` (all 5/5 tests passed).
  - Updated `context.md` and `history.md` with complete architectural documentation.
  - Comprehensively updated `docs/FRONTEND_DESIGN_SYSTEM.md` with the finalized visual tokens, signature square offset-shadow buttons, persistent bottom navigation architecture, and completed ~52 screen catalog.

## 2026-09-08 00:14:00 +05:30 — Vismay

Delivered the final screen batch completing 100% of the full ~52 screen frontend catalog, resolved color uniformity across all screens, and expanded the widget test suite:
- Common Screens (`lib/screens/common/`):
  - `forgot_password_screen.dart`: Mobile OTP recovery flow with phone input, 6-digit OTP verification, password reset, and return to login. Wired into `AuthLoginLayout` on both Customer and Worker login screens.
  - `settings_screen.dart`: Shared settings screen accessible from both Customer (`CustomerNavigation4Screen`) and Worker (`WorkerNavigation4Screen`) profile sections. Incorporates Dark Mode toggle, embedded multilingual ChoiceChips (English, ಕನ್ನಡ, हिंदी, தமிழ், తెలుగు), notification controls (push, sound chimes, SMS), biometric app lock, proximity location sharing, and the Cooperative Privacy Pledge.
  - `about_help_screen.dart`: Shared Help & Support screen with Brand Header, Cooperative Society Charter (0% commission explanation), expandable FAQ accordion (tariffs, rookie mentorship, emergency tipping, rescheduling), toll-free helpline, and WhatsApp helpdesk. Wired into both Customer and Worker profile sections.
  - `no_internet_screen.dart`: Dedicated offline network fallback screen with cached mode details and animated retry connectivity button.
- Worker Profile Domain (`lib/screens/worker/profile/`):
  - `worker_earnings_screen.dart`: Comprehensive worker payouts dashboard with timeframe filter (Today, This Week, This Month, All Time), net payout display with 0% platform commission audit breakdown, Bangalore Artisans Guild Society patronage dividend share (+₹1,240 quarterly surplus), and itemized payout history. Wired to `WorkerNavigation4Screen`.
- Color Uniformity & Design Polish:
  - Audited the entire codebase for non-standard raw colors. Replaced all raw `Colors.red` and variant usages in `worker_cancel_reschedule_screen.dart`, `material_bill_upload_screen.dart`, `opportunity_details_screen.dart`, and profile sign-out tiles with unified `AppColors.danger` (`Color(0xFFC85C5C)`) and semantic theme tokens. Verified zero non-standard colors across `mobile_app/lib/`.
- Test Suite Expansion & Validation:
  - Expanded `mobile_app/test/widget_test.dart` to 7 full widget test flows, adding coverage for login layout navigation to `ForgotPasswordScreen` + OTP password reset, and worker profile navigation into `WorkerEarningsScreen`, `SettingsScreen` (dark mode & language selection), and `AboutHelpScreen`.
  - Formatted all files (`dart format lib test`), verified `flutter analyze` (0 errors, 0 warnings), and passed all widget tests (`flutter test` 7/7 passed).

## 2026-09-08 2:38:43 +05:30 — Yug

- Frontend status synchronization and code formatting.

## 2026-09-09 18:15:00 +05:30 — Antigravity (Backend AI)

Completed **Sprint 0 — Backend Foundation** for the Sahakaar Seva Cooperative platform per `docs/06_BACKEND_SPRINTS.md`:
- Established the modular FastAPI backend architecture in `backend/app/` (`main.py`, `core/`, `db/`, `api/`, `schemas/`, `repositories/`, `services/`, `tests/`).
- Configured application settings (`app/core/config.py`) using Pydantic Settings with support for environment variables, dynamic CORS origin parsing, Supabase parameters, and algorithm configuration defaults (`WAGE_PREMIUM_MAX_FACTOR=0.30`, `VISITATION_FEE=100.00`).
- Configured SQLAlchemy 2.0 database engine, session factory, `get_db` FastAPI dependency, and live connectivity health probe in `app/db/session.py`.
- Created declarative `Base` and abstract `BaseModel` (`app/db/base.py`) with UUID primary keys and timezone-aware `created_at` and `updated_at` timestamps per `docs/04_DATABASE_DESIGN.md`.
- Implemented Alembic database migration environment (`alembic.ini`, `alembic/env.py`, `alembic/script.py.mako`, `alembic/versions/`), wired to application settings and metadata, generating and applying initial baseline migration `7c590bb021a2_initial_foundation`.
- Implemented centralized exception handling (`app/core/exceptions.py`) conforming to `docs/05_API_DESIGN.md` error contracts with structured `{ "error": { "code": ..., "message": ..., "details": ... } }` payload.
- Implemented standard response envelopes and health check schemas in `app/schemas/common.py`.
- Implemented `GET /api/v1/health` endpoint (`app/api/v1/endpoints/health.py`) validating live database connectivity and system status.
- Configured CORS middleware supporting Flutter mobile development and web clients.
- Configured pytest test suite (`app/tests/conftest.py`, `app/tests/test_health.py`) testing health endpoint, root discovery, database session, error formatting, and CORS headers.
- Verified: `pytest -v` (5/5 passed), `alembic current` (head), and direct test client call `GET /api/v1/health` (200 OK).

## 2026-09-09 18:35:00 +05:30 — Antigravity (Backend AI)

Completed **Sprint 1 — Database Schema + Models** for the Sahakaar Seva Cooperative platform per `docs/06_BACKEND_SPRINTS.md`:
- Implemented all 31 tables from `docs/04_DATABASE_DESIGN.md` across modular model files in `backend/app/db/models/`:
  - `enums.py`: All 14 database enums (`UserRole`, `GigType`, `GigStatus`, `MaterialProcurementMode`, `OpportunityStatus`, `ParticipationType`, `WorkerParticipationClassification`, `WorkerParticipationStatus`, `ReviewerRole`, `PaymentMethod`, `PaymentStatus`, `VisitationProposalStatus`, `RescheduleStatus`, `PreviousWorkerRequestStatus`).
  - `cooperative.py`: `Cooperative` model.
  - `user.py`: `User`, `CustomerProfile`, `WorkerProfile`, `WorkerMetric` with one-to-one cascading relationships and index definitions.
  - `service.py`: `ServiceCategory`, `ServiceTask`, `WorkerCategory` (with `uq_worker_category`), and `WorkerAvailability` (with day-of-week index).
  - `gig.py`: `Gig` (with price snapshots, emergency flag, procurement mode), `GigTask` (with `uq_gig_task`), and `GigWorkerOpportunity` (with `uq_gig_worker_opportunity` and immutable wage/final_score snapshots).
  - `experience.py`: `WorkerExperienceRecord` tracking individual task complexity and rookie contributions.
  - `review.py`: `Review` (two-way with `uq_review_direction`), `ReviewQuestion` (structured MCQs), and `ReviewAnswer`.
  - `completion.py`: `CompletionSubmission`, `CompletionEvidence` (photo uploads), and `CompletionConfirmation` (customer approval).
  - `payment.py`: `Payment` (cash and UPI lifecycle audit) and `MaterialReceipt` (itemized receipts).
  - `multi_worker.py`: `WorkerParticipation` (co-worker invitation consent and Equal Sharing vs Rookie tracking).
  - `visitation.py`: `VisitationProposal` and `VisitationProposalTask` (fixed ₹100 diagnostic fee, task proposals, fee waiver rules).
  - `cancellation.py`: `GigCancellation`, `RescheduleRequest`, and `PreviousWorkerRequest`.
  - `communication.py`: `Conversation`, `Message`, `Notification`, and `GigEvent` (audit log).
- Configured model export in `backend/app/db/models/__init__.py` and registered with `Base.metadata`.
- Updated `alembic/env.py` to automatically register all 31 models.
- Generated and applied complete database migration: `e29d3f46feb9_sprint_1_mvp_schema.py` (`alembic upgrade head`). Verified 32 tables live in the database (31 domain tables + `alembic_version`).
- Created comprehensive model test suite in `app/tests/test_models.py` validating table registration, foreign keys, 1-to-1 profiles/metrics, service tasks, gig opportunity snapshots, completion submissions, payments, and notifications.
- Validation: `pytest -v` (13/13 tests passed), `alembic current` (e29d3f46feb9 head), and `flutter test` (7/7 passed).
## 2026-09-09 19:55:00 +05:30 — Antigravity (Backend AI)

Completed comprehensive verification of Sprint 1 and successfully deployed the schema to Supabase:
- Performed thorough verification across 5 strict categories:
  - Verified 14 enums match `docs/04_DATABASE_DESIGN.md` verbatim.
  - Verified 4 unique constraints, 27 foreign keys, and 26 required query indexes.
  - Verified clean database migration recreation via `alembic upgrade head`.
  - Added `create_constraint=True` to all `SQLEnum` model columns so that `native_enum=False` generates strict PostgreSQL SQL `CHECK (col IN (...))` constraints.
  - Verified all immutable snapshot fields (`base_price_snapshot`, `standard_duration_minutes_snapshot`, `final_score_snapshot`, `premium_percentage`, `exact_wage`).
- Integrated live Supabase project (`upkxwtnxfnkjuuwrjutk`):
  - Configured PostgreSQL URI with URL-encoded password (`%2F` delimiter handling) and Supabase credentials in `backend/.env`.
  - Updated `app/core/config.py` with `SUPABASE_SERVICE_ROLE_KEY`.
  - Updated `alembic/env.py` with `configparser` `%` interpolation escaping.
  - Successfully executed `alembic upgrade head` against Supabase PostgreSQL, creating all 32 tables live in the cloud database.
  - Verified live FastAPI `GET /api/v1/health` returning 200 OK with `database: connected`.
  ## 2026-09-09 20:05:00 +05:30 — Antigravity (Backend AI)

Completed **Sprint 2 — Authentication + Profiles** for the Sahakaar Seva Cooperative platform per `docs/06_BACKEND_SPRINTS.md` and `docs/05_API_DESIGN.md`:
- Implemented cryptographic Supabase Auth JWT validation and security dependencies in `app/core/security.py`:
  - `decode_supabase_token` verifies token signature against `settings.SUPABASE_JWT_SECRET` (HS256) and extracts subject claim (`sub`).
  - `get_current_token_payload` validates and supplies raw claims.
  - `get_current_user` resolves the application user from database.
  - `get_current_active_user` verifies account active status.
  - `require_role(UserRole.CUSTOMER)` and `require_role(UserRole.WORKER)` enforce strict role-based access control.
  - `create_access_token` utility for token generation and test harnesses.
- Built Pydantic request/response schemas in `app/schemas/user.py` and `app/schemas/worker.py`:
  - `UserResponse`, `UserInitializeRequest`
  - `CustomerProfileResponse`, `CustomerProfileUpdateRequest`
  - `WorkerProfileResponse`, `WorkerProfileUpdateRequest`, `WorkerMetricResponse`
  - `AadhaarUploadRequest`, `AadhaarUploadResponse`
  - `WorkerCategoryResponse`, `WorkerCategorySelectionRequest`
  - `WorkerAvailabilitySlot`, `WorkerAvailabilityUpdateRequest`, `WorkerAvailabilityResponse`
- Implemented business logic and data manipulation in `app/services/user_service.py` and `app/services/worker_service.py`:
  - `initialize_user`: initializes `User` and generates corresponding `CustomerProfile` or `WorkerProfile` + initial `WorkerMetric` (rookie defaults: `final_score=0.35`, `bayesian_score=0.70`, `experience_score=0.00`).
  - Enforced one-role policy: attempts to re-initialize an existing user with a different role are rejected with `409 Conflict` (`ROLE_IMMUTABLE`).
  - Automatically attaches user to primary active cooperative (`get_or_create_default_cooperative`).
  - Aadhaar upload reference storage: stores document URL and upload timestamp without automatically marking verification.
  - Worker category selection and availability schedule replacement.
- Implemented API v1 endpoints and registered them in `app/api/v1/router.py`:
  - `GET /api/v1/me` & `POST /api/v1/me/initialize` (`app/api/v1/endpoints/me.py`)
  - `GET /api/v1/customer/profile` & `PATCH /api/v1/customer/profile` (`app/api/v1/endpoints/customer.py`)
  - `GET /api/v1/worker/profile` & `PATCH /api/v1/worker/profile` (`app/api/v1/endpoints/worker.py`)
  - `POST /api/v1/worker/profile/aadhaar`
  - `GET /api/v1/worker/categories` & `PUT /api/v1/worker/categories`
  - `GET /api/v1/worker/availability` & `PUT /api/v1/worker/availability`
- Built dedicated Sprint 2 test suite in `app/tests/test_auth_and_profiles.py` (13 tests) covering:
  - Valid JWT, invalid JWT format, invalid signature, expired token.
  - Customer initialization and profile updates.
  - Customer access rejection on worker endpoints (403).
  - Worker initialization and profile updates with rookie metrics.
  - Worker access rejection on customer endpoints (403).
  - One-role immutability enforcement (409).
  - Aadhaar upload reference storage without auto-verification.
  - Worker category selection and retrieval.
  - Worker availability slot configuration and time order validation.
  - Profile ownership isolation between distinct users.
- Validation:
  - Pytest: 31/31 passed across entire test suite.
  - Live server: tested live endpoints against running uvicorn instance on port 8000 connected to Supabase PostgreSQL (`/api/v1/health` -> 200, `/api/v1/me` -> 401 without auth, `/api/v1/me/initialize` -> 201, `/api/v1/me` -> 200, `/api/v1/customer/profile` -> 200).

## 2026-09-09 20:25:00 +05:30 — Antigravity (Backend AI)

Completed focused security, architecture, and isolation verification for Sprint 2:
- Centralized rookie score defaults and algorithmic calculations:
  - Added `ROOKIE_EXPERIENCE_SCORE` and computed `ROOKIE_FINAL_SCORE` to `app/core/config.py` (`W = 0.5 * B + 0.5 * E`).
  - Created `app/services/score_service.py` exporting `compute_final_score` and `get_rookie_initial_metrics`.
  - Refactored `user_service.py` and `worker_service.py` to source rookie defaults exclusively from `score_service`, establishing that these are initialization values only and ensuring future dynamic updates are centralized.
- Hardened JWT decoding and application-level security:
  - Enforced strict `sub` claim presence, non-emptiness, and UUID format verification in `app/core/security.py`.
  - Added active user verification in `user_service.initialize_user` preventing deactivated users from calling `POST /api/v1/me/initialize`.
  - Confirmed rejection of `alg: none`, invalid signatures, expired tokens, and uninitialized application identities.
- Verified cooperative isolation and integrity:
  - Added idempotent lookup by name in `get_or_create_default_cooperative` preventing duplicate creations.
  - Verified rejection of invalid/inactive `cooperative_id` on user initialization.
  - Confirmed profile endpoints strictly isolate data by `current_user.id`, preventing cross-user or cross-cooperative data leakage.
- Created dedicated verification suite (`app/tests/test_sprint2_verification.py`, 10 tests). Full test suite: 41/41 tests passing.
## 2026-09-09 21:05:00 +05:30 — Antigravity (Backend AI)

Completed Sprint 3 (Catalogue + Wage Engine) per docs/06_BACKEND_SPRINTS.md (Section 26), docs/WAGES.md, docs/05_API_DESIGN.md, and docs/04_DATABASE_DESIGN.md:
- Implemented Catalogue & Pricing core datasets and schemas:
  - Created `app/core/catalogue_data.py` containing complete, standardized data for all 5 guild categories (Plumbing, Carpentry, Electrician, Painter, House Help) and ~115 tasks with standard durations and base prices from `WAGES.md`.
  - Created `app/schemas/catalogue.py` with `ServiceCategoryResponse` and `ServiceTaskResponse` (including dynamic complexity score and complexity bucket).
  - Created `app/schemas/pricing.py` with `PricePreviewRequest`, `PricePreviewTaskItem`, `EstimatedWageRange` (min, rookie, max wages), and `PricePreviewResponse`.
- Implemented 4 dedicated services:
  - `CatalogueService` (`app/services/catalogue_service.py`): Idempotent database seeding (`seed_catalogue_if_empty`) optimized with bulk prefetching, category listing, and task retrieval enriched with logarithmic complexity metrics.
  - `PricingService` (`app/services/pricing_service.py`): Multi-task duration summing, 45-minute minimum billable time rule enforcement (`billable_duration = max(total_standard_duration, category.minimum_billable_minutes)`), base price calculation (`billable_duration * base_rate_per_minute`), single-category consistency rule validation (rejecting cross-category gigs with `400 CATEGORY_TASK_MISMATCH`).
  - `WageService` (`app/services/wage_service.py`): Exact wage calculation formula `worker_wage = round(base_price * (1 + final_score * factor), 2)` with boundary clamping (`final_score` clamped strictly to `[0.0, 1.0]`), configurable `WAGE_PREMIUM_MAX_FACTOR` (default 0.30), rookie baseline wage, and dynamic minimum/maximum wage range calculation.
  - `ExperienceService` (`app/services/experience_service.py`): Logarithmic task complexity normalization `c = (ln(t) - ln(t_min)) / (ln(t_max) - ln(t_min))` bounded between `0.0` and `1.0`, complexity bucketing strictly per `WAGES.md` (`0–0.33 LOW`, `0.34–0.66 MID`, `0.67–1.0 HIGH`), rolling window experience score across $N=50$ completed gigs using strictly `(Σ complexity_i) / N` with rookie contribution at $0.5 \times \text{normal complexity}$ and zero artificial decay factors, and Bayesian rating normalization/aggregation ($C=10$, prior $m=0.70$).
- Created and mounted API v1 endpoints in `app/api/v1/router.py`:
  - `GET /api/v1/service-categories` (`app/api/v1/endpoints/catalogue.py`)
  - `GET /api/v1/service-categories/{category_id}/tasks` (`app/api/v1/endpoints/catalogue.py`)
  - `POST /api/v1/gigs/price-preview` (`app/api/v1/endpoints/gigs.py`)
  - Integrated auto-seeding into FastAPI application startup lifespan in `app/main.py`.
- Automated testing & live endpoint verification:
  - Created comprehensive test suite in `app/tests/test_sprint3_pricing_and_wages.py` (20 tests) covering category fetching, category tasks, 404 handling, 45-min minimum enforcement (15 min -> 45 min, 20+25 min -> 45 min, 75 min -> 75 min), cross-category task rejection, empty task list validation, wage calculation at 0.0, 1.0, 0.5, rookie baseline 0.35, boundary clamping, 2-decimal rounding, logarithmic complexity bounds, rolling experience window, Bayesian rating aggregation, boundary tests for buckets (0.0, 0.33, 0.34, 0.66, 0.67, 1.0), rookie 0.5x contribution without decay, and dynamic `WAGE_PREMIUM_MAX_FACTOR` configurability verification.
  - Pytest: 61/61 passed across entire backend test suite.
  - Verified live endpoints against running Uvicorn server on port 8000 connected to remote Supabase PostgreSQL.

