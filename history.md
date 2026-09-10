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

## 2026-09-09 18:15:00 +05:30 — Vismay & Antigravity (Backend AI)

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

## 2026-09-09 18:35:00 +05:30 — Vismay & Antigravity (Backend AI)

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
## 2026-09-09 19:55:00 +05:30 — Vismay & Antigravity (Backend AI)

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
  ## 2026-09-09 20:05:00 +05:30 — Vismay & Antigravity (Backend AI)

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

## 2026-09-09 20:25:00 +05:30 — Vismay & Antigravity (Backend AI)

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
## 2026-09-09 21:05:00 +05:30 — Vismay & Antigravity (Backend AI)

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

## 2026-09-09 21:42:00 +05:30 — Vismay & Antigravity (Backend AI)

Completed Sprint 4 Focused Verification against `docs/04_DATABASE_DESIGN.md`, `docs/05_API_DESIGN.md`, and `docs/06_BACKEND_SPRINTS.md`:
1. Schedule validation:
   - Audited schedule validation in `app/services/gig_service.py`.
   - Removed undocumented emergency past-date bypass (`and not payload.is_emergency`).
   - Verified that all gigs (both normal and emergency) strictly reject past scheduled dates with `400 INVALID_SCHEDULE_DATE`, while allowing scheduled dates >= today and strictly enforcing `scheduled_end_time > scheduled_start_time`.
2. Non-authoritative `expected_duration_minutes`:
   - Verified that `expected_duration_minutes` is purely a non-authoritative customer estimate and has zero influence on pricing or billable duration.
   - Authoritative duration and base price strictly derive from selected catalogue tasks (`total_standard_duration = sum(standard_duration_minutes)`), category minimum billable rule (`max(total, 45)`), and base rate per minute snapshot (`base_rate_per_minute * billable_duration`).
3. Transaction Atomicity & Audit Events:
   - Wrapped `create_gig` and `post_gig` within explicit `try ... except ... db.rollback(); raise` blocks.
   - Verified that if `GigEvent` logging fails (or if any part of the transaction fails), `db.rollback()` is executed atomically, ensuring that neither an orphaned gig nor an unlinked audit event can ever be committed to the database.
4. Client-supplied `base_price` Immunity:
   - Configured `ConfigDict(extra="ignore")` explicitly on `GigCreateRequest` in `app/schemas/gig.py`.
   - Verified that client-supplied `base_price` or snapshot tampering parameters in request payloads are completely ignored and cannot override backend pricing or database snapshots.
5. Testing & Validation:
   - Added 5 new targeted audit tests to `app/tests/test_sprint4_gig_creation.py` (totaling 15 tests in this module).
   - Full test suite: 76/76 tests passing across all sprints (Sprint 0, 1, 2, 3, 4).
   - Sprint 4 is verified, compliant with all design documents, and fully complete.

## 2026-09-09 21:49:00 +05:30 — Vismay & Antigravity (Backend AI)

Completed Sprint 5 (Worker Opportunity Engine) per `docs/06_BACKEND_SPRINTS.md` (Section 28), `docs/05_API_DESIGN.md` (Section 15), and `docs/04_DATABASE_DESIGN.md` (Sections 18–21):
- Implemented Schemas in `app/schemas/opportunity.py`:
  - `OpportunityGigResponse`: Nested gig details including category, scheduled date/time, expected duration, emergency flag, material mode, and tasks.
  - `OpportunityResponse`: Complete opportunity model containing immutable offer snapshots: `base_price_snapshot`, `final_score_snapshot`, `premium_percentage`, `exact_wage`, `offered_at`, `responded_at`, and nested `gig`.
- Implemented Business Logic in `app/services/opportunity_service.py`:
  - `generate_opportunities_for_gig`: Generates personalized opportunities for all eligible cooperative workers matching category, active status, availability, and non-conflicting schedule upon gig posting.
  - `check_schedule_conflict`: Enforces the MVP rule that any partial or full overlap with an existing confirmed gig (`WORKER_SELECTED`, `SCHEDULED`, `IN_PROGRESS`) blocks acceptance.
  - `check_worker_availability`: Validates worker weekly recurring availability slots against scheduled date and times.
  - `get_worker_opportunities`: Fetches and synchronizes available opportunities for the authenticated worker with filtering by `category_id`, `scheduled_date`, `is_emergency`, and `status`, plus pagination metadata.
  - `get_opportunity_by_id`: Retrieves detailed opportunity data with strict worker ownership verification (`403 FORBIDDEN` for other workers).
  - `accept_opportunity`: Atomically verifies opportunity is `PENDING`, worker ownership, active status, category eligibility, same cooperative, unexpired acceptance deadline, and absence of schedule conflicts before transitioning status to `ACCEPTED` and logging `OPPORTUNITY_ACCEPTED` audit event with atomic rollback guarantee.
  - `reject_opportunity`: Atomically verifies worker ownership and `PENDING` status before transitioning to `REJECTED`, logging `OPPORTUNITY_REJECTED` audit event, and ensuring the same opportunity can never be accepted later.
- Integrated Opportunity Generation into Gig Lifecycle:
  - Updated `GigService.post_gig` in `app/services/gig_service.py` to trigger `OpportunityService.generate_opportunities_for_gig` atomically within the post-gig transaction.
- Mounted Worker Opportunity Endpoints in `app/api/v1/endpoints/worker.py`:
  - `GET /api/v1/worker/opportunities`
  - `GET /api/v1/worker/opportunities/{opportunity_id}`
  - `POST /api/v1/worker/opportunities/{opportunity_id}/accept`
  - `POST /api/v1/worker/opportunities/{opportunity_id}/reject`
- Automated Testing:
  - Created dedicated test suite `app/tests/test_sprint5_opportunity_engine.py` (8 tests) covering:
    - Multiple workers receiving the same gig with personalized wage calculations (e.g., rookie 0.35 -> ₹248.62 vs expert 0.80 -> ₹279.00 on ₹225.00 base price).
    - Independent accept/reject actions without interference.
    - Rejection of re-accepting an already rejected opportunity (`400 ALREADY_REJECTED`).
    - Rejection of duplicate acceptance (`400 ALREADY_ACCEPTED`).
    - Cross-worker authorization isolation (`403 FORBIDDEN`).
    - Category mismatch exclusion (carpenters do not receive plumbing opportunities).
    - Schedule conflict detection blocking acceptance of overlapping gigs (`400 SCHEDULE_CONFLICT`).
    - Opportunity filtering and detail lookup.
  - Full test suite: 84/84 tests passing across all sprints (Sprint 0, 1, 2, 3, 4, 5).
  - Verified live server health check against running Uvicorn server on port 8000 connected to remote Supabase PostgreSQL.

## 2026-09-09 21:54:00 +05:30 — Vismay & Antigravity (Backend AI)

Completed Sprint 5 Focused Verification against `docs/04_DATABASE_DESIGN.md`, `docs/05_API_DESIGN.md`, and `docs/06_BACKEND_SPRINTS.md`:
1. Worker Verification & Eligibility Rule:
   - Verified that worker active status (`User.is_active` and `WorkerProfile.is_active`), cooperative match, and active category association (`WorkerCategory`) are strictly enforced during both opportunity generation AND opportunity acceptance.
   - Verified that uploading an Aadhaar document reference (`POST /api/v1/worker/profile/aadhaar`) does NOT mark the worker verified or automatically activate an inactive profile.
2. Worker Availability Handling:
   - Implemented `PATCH /api/v1/worker/availability/status` per `05_API_DESIGN.md` Section 10 to manage the simple Available/Unavailable toggle (`worker_profile.is_active`).
   - Verified that when a worker is set to unavailable (`is_available=False`), opportunity generation excludes them, and opportunity acceptance is blocked (`400 WORKER_UNAVAILABLE`).
   - Integrated weekly recurring availability checking into `OpportunityService.accept_opportunity` (`400 WORKER_NOT_AVAILABLE`).
3. Concurrency & Locking:
   - Added `with_for_update()` locking on both `GigWorkerOpportunity` and `Gig` records during acceptance.
   - Added concurrency test with near-simultaneous opportunity acceptances: verified that locking serializes execution so exactly one acceptance succeeds (`200 OK`) and the second is rejected (`400 ALREADY_ACCEPTED`).
   - Added concurrency test with overlapping confirmed gigs: verified that schedule conflict checking prevents conflicting acceptances from both succeeding (`400 SCHEDULE_CONFLICT`).
4. Transaction Atomicity & Audit Events:
   - Verified atomic rollback on simulated `GigEvent` failure during acceptance: confirmed that opportunity status reverts cleanly to `PENDING` with no status or timestamp mutation persisted.
5. Testing & Validation:
   - Added 5 new audit tests in `app/tests/test_sprint5_opportunity_engine.py` (total 13 module tests).
   - Full test suite: 89/89 tests passing across all backend modules.
   - Sprint 5 is verified, fully compliant with documentation, and PASS.

## 2026-09-09 21:58:00 +05:30 — Vismay & Antigravity (Backend AI)

Completed Sprint 6 (Customer Candidate List + Worker Selection) per `docs/06_BACKEND_SPRINTS.md` (Section 29), `docs/05_API_DESIGN.md` (Sections 16 & 17), and `docs/04_DATABASE_DESIGN.md` (Sections 13 & 19):
- Implemented Schemas in `app/schemas/candidate.py`:
  - `GigCandidateResponse`: Candidate payload for customer transparency, including `worker_id`, `name`, `exact_wage`, `completed_jobs_count`, `rating_average`, `rating_count`, `final_score`, `profile_photo_url`, and `recommendation: null` (no fake recommendation ranking in MVP).
  - `SelectWorkerRequest`: Payload containing `worker_id`.
  - `SelectWorkerResponse`: Confirmation response with `gig_id`, `selected_worker_id`, `status: "WORKER_SELECTED"`, and success message.
- Implemented Business Logic in `app/services/gig_service.py`:
  - `get_candidates`: Retrieves all workers with an `ACCEPTED` opportunity for the customer's gig, populated with worker metrics and exact offered wages. Ensures customer ownership (`403 FORBIDDEN` for other users).
  - `select_worker`: Executes atomic transaction for customer worker selection:
    1. Verifies caller owns the gig.
    2. Verifies gig is in selectable state (`POSTED` or `ACCEPTANCE_OPEN`).
    3. Verifies gig has not already selected a worker (`selected_worker_id is None`).
    4. Verifies target worker has accepted the gig opportunity (`status == OpportunityStatus.ACCEPTED`).
    5. Sets `gig.selected_worker_id = worker_id` and transitions `gig.status = GigStatus.WORKER_SELECTED`.
    6. Closes all other candidate opportunities for this gig as `OpportunityStatus.NOT_SELECTED`.
    7. Creates `WORKER_SELECTED` audit event in `GigEvent` table.
    8. Dispatches in-app `Notification` records to both the selected worker (`type="WORKER_SELECTED"`) and non-selected candidates (`type="NOT_SELECTED"`).
    9. Guarantees atomic rollback via `try ... except ... db.rollback(); raise`.
- Mounted Endpoints in `app/api/v1/endpoints/gigs.py`:
  - `GET /api/v1/gigs/{gig_id}/candidates` (Customer role enforced).
  - `POST /api/v1/gigs/{gig_id}/select-worker` (Customer role enforced).
- Automated Testing & Validation:
  - Created test suite `app/tests/test_sprint6_worker_selection.py` (6 tests) covering:
    - Customer viewing candidates with metrics and individual exact wages.
    - Customer selecting one candidate, verifying gig status `WORKER_SELECTED`, selected opportunity remaining `ACCEPTED`, other opportunities transitioning to `NOT_SELECTED`, audit event logged, and notifications generated.
    - Rejection when attempting to select a worker who did not accept (`400 WORKER_NOT_ACCEPTED`).
    - Rejection of duplicate selection or selecting from invalid state (`400 INVALID_GIG_STATE`).
    - Cross-customer and worker role authorization checks (`403 FORBIDDEN`).
    - Atomic rollback verification on simulated audit event failure.
  - Full test suite: 95/95 tests passing across all backend modules (Sprint 0 through Sprint 6).

## 2026-09-09 22:04:00 +05:30 — Vismay & Antigravity (Backend AI)

Completed Sprint 6 Focused Verification against `docs/04_DATABASE_DESIGN.md`, `docs/05_API_DESIGN.md`, and `docs/06_BACKEND_SPRINTS.md`:
1. Candidate List Integrity & Isolation:
   - Verified that `GET /api/v1/gigs/{gig_id}/candidates` filters strictly on `OpportunityStatus.ACCEPTED`. No unoffered, pending, rejected, or expired workers are exposed.
   - Verified that customer ownership is enforced (`gig.customer_id == customer_user.id`), rejecting access by any other customer with `403 FORBIDDEN`.
2. Worker Selection Transaction & Sequence:
   - Verified that `POST /api/v1/gigs/{gig_id}/select-worker` only permits selecting a candidate who has already accepted (`OpportunityStatus.ACCEPTED`). Attempting to select a worker with any other status fails with `400 WORKER_NOT_ACCEPTED`.
   - Verified the atomic sequence:
     - Target worker is assigned: `gig.selected_worker_id = worker_id`
     - Gig status is updated to `WORKER_SELECTED`
     - All other candidates with `ACCEPTED` (or pending) status for this gig transition to `OpportunityStatus.NOT_SELECTED`
     - Audit record created in `GigEvent` (`event_type = WORKER_SELECTED`)
     - In-app `Notification` generated for selected worker (`WORKER_SELECTED`) and notifications generated for unselected candidate workers (`NOT_SELECTED`)
     - Entire unit of work rolls back cleanly on any failure.
3. No Backend Recommendation / No Distance Ranking:
   - Verified that candidates are returned without distance ranking or algorithmic ordering (`recommendation: null`).
   - Verified that selection requires explicit customer submission of `worker_id` without automatic selection or heuristic ranking.
4. Concurrency & Protection against Duplicate Selection:
   - `Gig` row is locked with `with_for_update()` in the transaction.
   - Added concurrency test `test_concurrency_simultaneous_worker_selection` using `ThreadPoolExecutor`: verified that near-simultaneous worker selections for the same gig are serialized and exactly one succeeds (`200 OK`) while the other fails (`400 WORKER_ALREADY_SELECTED` / `INVALID_GIG_STATE`), leaving exactly 1 audit event and 1 selected worker.
5. Selectable States Validation:
   - Verified that both `POSTED` and `ACCEPTANCE_OPEN` are approved MVP states in `docs/04_DATABASE_DESIGN.md` (Section 13) and `docs/05_API_DESIGN.md` (Section 32), and are supported as valid selectable states.
6. Testing & Validation:
   - Full test suite: 96/96 tests passing across all backend modules (Sprint 0 through Sprint 6).
   - Sprint 6 is verified, compliant with documentation, and PASS.

## 2026-09-09 22:18:00 +05:30 — Vismay & Antigravity (Backend AI)

Completed Sprint 7 (Core Job Execution) per `docs/06_BACKEND_SPRINTS.md` (Section 30), `docs/05_API_DESIGN.md` (Sections 13, 22, 32, 33), and `docs/04_DATABASE_DESIGN.md` (Sections 28, 29):
- Authoritative Documentation Updates:
  - Documented `POST /api/v1/gigs/{gig_id}/start` in `05_API_DESIGN.md` (Section 22, 33) and `06_BACKEND_SPRINTS.md` (Section 30) for the worker "Arrived & Start Work" action.
  - Formally documented the active states for completion submission (`WORKER_SELECTED`, `SCHEDULED`, `IN_PROGRESS`) as an intentional MVP decision supporting flexible execution.
  - Documented the rejection rework loop (`COMPLETION_SUBMITTED` ➔ Customer Rejection ➔ `IN_PROGRESS`) preserving feedback in `completion_confirmations` without creating unapproved lifecycle states.
- Implemented Schemas in `app/schemas/`:
  - `app/schemas/worker_gig.py`: `WorkerGigListItem` (summary view with category, exact agreed worker wage, customer info, address, status, schedule).
  - `app/schemas/completion.py`: `CompletionEvidenceCreate`, `CompletionEvidenceResponse`, `CompletionSubmissionRequest`, `CompletionSubmissionResponse`, `CompletionConfirmationRequest`, `CompletionConfirmationResponse`, `StartWorkResponse`, `GigCompletionDetailResponse`.
- Implemented Core Services in `app/services/completion_service.py`:
  - `get_worker_gigs`: Paginated worker gig queries (`selected_worker_id == worker.id`) with tab filtering (`upcoming`, `active`, `completed`, `cancelled`), direct status filtering, and exact wage snapshot lookup.
  - `start_work`: Assigned worker starts work (`WORKER_SELECTED`/`SCHEDULED` ➔ `IN_PROGRESS`), logging `WORK_STARTED` audit event.
  - `submit_completion`: Assigned worker submits completion description and photo evidence items (`(WORKER_SELECTED, SCHEDULED, IN_PROGRESS)` ➔ `COMPLETION_SUBMITTED`). Enforces at least 1 photo evidence file, creates `CompletionSubmission` and `CompletionEvidence` records, logs `COMPLETION_SUBMITTED` audit event, and dispatches customer notification.
  - `get_completion`: Retrieves submission evidence and confirmation details for authorized customer or assigned worker (`403 FORBIDDEN` for third parties).
  - `confirm_completion`: Customer confirms completion:
    - On approval (`confirmed: True`): transitions gig to `CUSTOMER_CONFIRMED`, logs `COMPLETION_CONFIRMED` audit event, and notifies worker.
    - On rejection (`confirmed: False`): returns gig to `IN_PROGRESS` (active rework loop), retains customer's `response_note`, logs `COMPLETION_REJECTED` audit event, and notifies worker of rework instructions.
    - Full atomic transactional rollback on failure.
- Mounted Endpoints:
  - `GET /api/v1/worker/gigs` in `app/api/v1/endpoints/worker.py` (Worker role enforced).
  - `POST /api/v1/gigs/{gig_id}/start` in `app/api/v1/endpoints/gigs.py` (Worker role enforced).
  - `POST /api/v1/gigs/{gig_id}/completion` in `app/api/v1/endpoints/gigs.py` (Worker role enforced).
  - `GET /api/v1/gigs/{gig_id}/completion` in `app/api/v1/endpoints/gigs.py` (Authenticated customer or assigned worker).
  - `POST /api/v1/gigs/{gig_id}/completion/confirm` in `app/api/v1/endpoints/gigs.py` (Customer role enforced).
- Automated Testing & Validation:
  - Created `app/tests/test_sprint7_job_execution.py` (8 comprehensive tests) covering:
    - Worker gigs listing and tab filtering (`upcoming`, `completed`).
    - Worker starting work (`WORK_STARTED` audit event).
    - Completion submission from active states (`WORKER_SELECTED`, `IN_PROGRESS`), photo evidence storage, customer notification.
    - Mutual inspection of completion details by customer and assigned worker (`403` for third parties).
    - Customer confirmation of completion (`CUSTOMER_CONFIRMED`).
    - Explicit end-to-end rework loop: worker submits -> customer rejects -> gig reverts to `IN_PROGRESS` -> worker resubmits -> customer approves.
    - Strict authorization, role boundaries, and state validations (rejecting premature confirmation, missing evidence, cross-role actions).
    - Atomic rollback verification on simulated failure.
  - Full test suite: 104/104 tests passing across all backend modules (Sprints 0 through 7) in 25.60s.

## 2026-09-09 22:25:00 +05:30 — Vismay & Antigravity (Backend AI)

Completed Sprint 8 (Payment) per `docs/06_BACKEND_SPRINTS.md` (Section 31), `docs/05_API_DESIGN.md` (Sections 24, 32, 33), and `docs/04_DATABASE_DESIGN.md` (Sections 30, 31):
- Refinements Enforced:
  - Monetary precision: Authoritative payment amounts utilize Python `Decimal` across all schemas, service logic, and database operations. Audit event metadata serializes amounts precisely as strings without binary floating-point conversions.
  - Payment-method immutability: Once recorded as `CUSTOMER_PAID`, retries attempting to change `payment_method` (e.g. CASH to UPI or vice-versa) fail with `409 Conflict` (`PAYMENT_METHOD_IMMUTABLE`). Same-method retries are completely idempotent.
  - Authoritative snapshot amount: Exclusively loads `GigWorkerOpportunity.exact_wage` for `(gig_id, selected_worker_id)` snapshot. Wage calculation engine is never invoked, and client-supplied amounts are never accepted.
- Implemented Schemas in `app/schemas/payment.py`:
  - `PaymentCreateRequest`: Client request payload specifying `payment_method` (`CASH` or `UPI`).
  - `PaymentReceiptConfirmRequest`: Worker request payload confirming receipt (`confirmed: bool = True`).
  - `PaymentResponse`: Payment detail response with precise `amount: Decimal`, `status: PaymentStatus`, `payment_method`, `upi_deeplink`, timestamps, and server-derived eligibility flags (`can_pay`, `can_confirm`).
- Implemented Core Services in `app/services/payment_service.py`:
  - `get_payment_status`: Inspects payment state, computes `can_pay` / `can_confirm` flags, formats standard UPI deep link (`upi://pay?pa=...&pn=...&am=...&cu=INR&tn=...`) without treating it as automatic payment verification.
  - `record_payment`: Customer records payment action. Enforces legal states (`CUSTOMER_CONFIRMED`, `PAYMENT_PENDING`), acquires row locks, records `Payment(status=CUSTOMER_PAID)`, advances gig to `PAYMENT_CUSTOMER_PAID`, logs `PAYMENT_CUSTOMER_PAID` audit event, and dispatches worker notification.
  - `confirm_receipt`: Assigned worker acknowledges receipt of payment. Enforces legal state (`PAYMENT_CUSTOMER_PAID`), advances `Payment(status=WORKER_CONFIRMED)` and atomically transitions gig to `COMPLETED`. Writes `PAYMENT_WORKER_CONFIRMED` and `GIG_COMPLETED` audit events, and dispatches customer notification.
  - Idempotency guarantees: Calling confirm-receipt multiple times safely returns the existing record (`200 OK`) without duplicate audit logs, duplicate notifications, or timestamp changes.
- Mounted Endpoints in `app/api/v1/endpoints/gigs.py`:
  - `GET /api/v1/gigs/{gig_id}/payment` (Authenticated customer or assigned worker).
  - `POST /api/v1/gigs/{gig_id}/payment` (Customer role enforced).
  - `POST /api/v1/gigs/{gig_id}/payment/confirm-receipt` (Worker role enforced).
- Automated Testing & Validation:
  - Created `app/tests/test_sprint8_payment.py` (8 comprehensive tests) covering:
    - End-to-end CASH payment lifecycle (`CUSTOMER_CONFIRMED` -> `CUSTOMER_PAID` -> `WORKER_CONFIRMED` -> `COMPLETED`).
    - End-to-end UPI payment lifecycle with deep-link generation and completion.
    - Payment-method immutability (rejecting CASH -> UPI modification with `409 Conflict`) and idempotent same-method retries.
    - Worker receipt confirmation idempotency (safe repeated calls with zero duplicate events).
    - Payment amount integrity and metric immunity (modifying worker rating/metrics post-selection does not alter historical payable wage snapshot).
    - Legal state boundaries (preventing premature payments before confirmation, preventing premature receipt confirmation before customer payment).
    - Strict authorization and role boundaries (preventing workers from initiating payment, preventing customers from confirming receipt, blocking unauthorized users).
    - Atomic rollback verification on simulated database failure.
  - Full test suite: 112/112 tests passing across all backend modules (Sprints 0 through 8) in 24.86s.

## 2026-09-09 22:40:00 +05:30 — Vismay & Antigravity (Backend AI)

Completed Sprint 9 (Visitation Diagnostics) per `docs/06_BACKEND_SPRINTS.md` (Sections 13, 32), `docs/05_API_DESIGN.md` (Section 19), and `docs/04_DATABASE_DESIGN.md` (Sections 38, 39, 40, 41, 42, 43):
- Financial Contract & Authoritative Rules Enforced:
  - Historical Snapshot Immutability: `GigWorkerOpportunity` snapshots (`exact_wage`, `base_price_snapshot`, `final_score_snapshot`, `premium_percentage`) remain completely immutable and are never overwritten during proposal creation, acceptance, or rejection.
  - Contextual Authoritative Amount Resolution (`PaymentService.get_authoritative_amount`):
    - CASE A (Proposal Accepted): Fixed ₹100 visitation charge is waived/absorbed into the accepted work payment (`visitation_proposals.base_price`, e.g. ₹300, not ₹400). `Payment.amount` settles at ₹300.
    - CASE B (Proposal Rejected / Visit Only): Fixed ₹100 visitation charge (`settings.VISITATION_FEE`) remains strictly payable. No work payment is created. Gig advances to `CUSTOMER_CONFIRMED` and `Payment.amount` settles at ₹100.
    - Standard NORMAL Gigs: Settles at `GigWorkerOpportunity.exact_wage`.
  - Monetary Precision: Amounts utilize Python `Decimal` across schemas, services, and queries; audit event metadata formats exact decimal strings with two decimal places (`f"{amount:.2f}"`).
- Implemented Schemas in `app/schemas/visitation.py`:
  - `VisitationProposalTaskItem`: Itemized task snapshot inside a proposal (`task_id`, `task_name`, `standard_duration_minutes_snapshot`, `base_price_snapshot`).
  - `VisitationProposalCreateRequest`: Worker submission payload (`task_ids: List[UUID]` with `min_length=1`).
  - `VisitationProposalResponse`: Complete proposal details (`id`, `gig_id`, `worker_id`, `base_price`, `status`, timestamps, and itemized task list).
  - `VisitationResponse`: Visitation state overview with `visitation_fee` (₹100.00), active proposal, proposal history, and caller capability flags (`can_propose`, `can_respond`).
- Implemented Core Services in `app/services/visitation_service.py`:
  - `request_visitation`: Customer requests visitation inspection, converting gig to `VISITATION` with fixed ₹100 fee, logging `VISITATION_REQUESTED` audit event and notifying worker.
  - `get_visitation_details`: Returns status and action permissions (`can_propose` for assigned worker in active gig without pending proposals; `can_respond` for customer when proposal is pending).
  - `submit_proposal`: Assigned worker submits catalogue tasks following inspection. Acquires `with_for_update()` lock on `Gig` row to serialize concurrent requests and prevents duplicate `PENDING` proposals. Validates category boundaries and computes server-authoritative catalogue pricing (`max(sum(durations), min_billable) * rate`). Stores proposal and snapshot tasks, logs `VISITATION_PROPOSED` audit event, and notifies customer.
  - `accept_proposal`: Customer accepts proposal with row-level locking. Updates proposal status to `ACCEPTED`, sets `gig.base_price` to proposed work price (absorbing ₹100 fee), replaces `gig_tasks` with proposal tasks, transitions gig to `IN_PROGRESS`, logs `VISITATION_ACCEPTED` audit event, and notifies worker.
  - `reject_proposal`: Customer rejects proposal with row-level locking. Updates proposal status to `REJECTED`, preserves `gig.base_price` at ₹100.00, transitions gig to `CUSTOMER_CONFIRMED` for inspection payment settlement, logs `VISITATION_REJECTED` audit event, and notifies worker.
- Refactored `app/services/payment_service.py`:
  - Integrated `get_authoritative_amount(gig, db)` for unified payment status queries (`GET /gigs/{id}/payment`) and payment execution (`POST /gigs/{id}/payment`).
- Mounted Endpoints in `app/api/v1/endpoints/gigs.py`:
  - `POST /api/v1/gigs/{gig_id}/visitation/request` (Customer role).
  - `GET /api/v1/gigs/{gig_id}/visitation` (Authenticated customer or assigned worker).
  - `POST /api/v1/gigs/{gig_id}/visitation/proposals` (Worker role).
  - `POST /api/v1/gigs/{gig_id}/visitation/proposals/{proposal_id}/accept` (Customer role).
  - `POST /api/v1/gigs/{gig_id}/visitation/proposals/{proposal_id}/reject` (Customer role).
- Automated Testing & Validation:
  - Created `app/tests/test_sprint9_visitation.py` (9 comprehensive tests) covering:
    - Overview and request endpoint (`is_visitation: True`, ₹100 fee).
    - Case A: Accepted proposal payment flow (₹100 fee absorbed into ₹300 proposal, opportunity snapshots unmutated, completion confirmed, CASH payment settled at ₹300, gig completed).
    - Case B: Rejected proposal visitation payment flow (₹100 fee payable, opportunity snapshots unmutated, gig advances to `CUSTOMER_CONFIRMED`, UPI payment settled at ₹100, gig completed).
    - Opportunity snapshot immutability (asserting `exact_wage`, `base_price_snapshot`, `premium_percentage`, `final_score_snapshot` are 100% byte-for-byte immutable across proposal lifecycle).
    - Concurrency protection against duplicate pending proposals (`409 Conflict`).
    - Proposal response retries and state protection (`409 Conflict` on already answered proposals).
    - Category boundary validation (rejecting tasks from different categories with `400 Bad Request`).
    - Strict role and ownership authorization (cross-role and third-party rejection with `403 Forbidden`).
    - Transactional rollback on simulated database failure.
- Automated Testing & Validation:
  - Created `app/tests/test_sprint9_visitation.py` (9 comprehensive tests) covering:
    - Overview and request endpoint (`is_visitation: True`, ₹100 fee).
    - Case A: Accepted proposal payment flow (₹100 fee absorbed into ₹300 proposal, opportunity snapshots unmutated, completion confirmed, CASH payment settled at ₹300, gig completed).
    - Case B: Rejected proposal visitation payment flow (₹100 fee payable, opportunity snapshots unmutated, gig advances to `CUSTOMER_CONFIRMED`, UPI payment settled at ₹100, gig completed).
    - Opportunity snapshot immutability (asserting `exact_wage`, `base_price_snapshot`, `premium_percentage`, `final_score_snapshot` are 100% byte-for-byte immutable across proposal lifecycle).
    - Concurrency protection against duplicate pending proposals (`409 Conflict`).
    - Proposal response retries and state protection (`409 Conflict` on already answered proposals).
    - Category boundary validation (rejecting tasks from different categories with `400 Bad Request`).
    - Strict role and ownership authorization (cross-role and third-party rejection with `403 Forbidden`).
    - Transactional rollback on simulated database failure.
  - Full test suite: 121/121 tests passing across all backend modules (Sprints 0 through 9) in 61.75s.

## 2026-09-09 22:55:00 +05:30 — Vismay & Antigravity (Backend AI)

Completed Sprint 10 (Multi-Worker Collaboration & Rookie Mentorship) per `docs/06_BACKEND_SPRINTS.md` (Section 33: Sprint 10), `docs/05_API_DESIGN.md` (Section 20: Multi-Worker APIs), `docs/04_DATABASE_DESIGN.md` (Sections 34–37: Multi-Worker Participation & Payment), and `docs/WAGES.md` (Sections 2, 3: Task complexity & rookie 0.5x contribution):
- Business Rules & Architectural Invariants Enforced:
  - Cooperative Boundary Integrity: Primary worker and additional worker must strictly belong to the same cooperative society (`worker_a.cooperative_id == worker_b.cooperative_id`). Cross-cooperative collaboration is rejected with `400 Bad Request`.
  - Explicit Consent Workflow: Collaboration invitations are created in `PENDING` status. The invited worker must explicitly accept (`POST /api/v1/participations/{id}/accept`) or reject (`POST /api/v1/participations/{id}/reject`).
  - Strict Authorization & State Boundaries: Only the assigned primary worker (`gig.selected_worker_id == current_user.id`) on active gigs (`WORKER_SELECTED`, `SCHEDULED`, `IN_PROGRESS`) can invite collaborators. Primary workers cannot invite themselves (`400 Bad Request`). Duplicate invitations while `PENDING` or `ACCEPTED` return `409 Conflict`.
  - Rookie Mentorship Experience Weighting:
    - When classification is `ROOKIE`: `experience_contribution = complexity * 0.5`.
    - When classification is `EQUAL_SHARING`: `experience_contribution = complexity * 1.0`.
  - Zero Customer Financial Impact (Section 37 of `04_DATABASE_DESIGN.md`): Customer pays the single agreed labour price. The platform does not add a second charge, does not calculate private worker splits, does not enforce financial sharing, and does not record rookie private compensation.
- Implemented Schemas in `app/schemas/multi_worker.py`:
  - `WorkerParticipationCreateRequest`: Payload with `additional_worker_id: UUID` and `classification: WorkerParticipationClassification` (`ROOKIE` or `EQUAL_SHARING`).
  - `WorkerParticipationResponse`: Complete participation details (`id`, `gig_id`, `inviting_worker_id`, `inviting_worker_name`, `additional_worker_id`, `additional_worker_name`, `status`, `classification`, `experience_contribution`, timestamps). Excludes private worker-to-worker compensation.
- Implemented Core Services in `app/services/multi_worker_service.py`:
  - `invite_worker`: Validates primary worker assignment, active gig states, cooperative membership equality, active verified worker profile, and absence of duplicate pending/accepted invites. Calculates task complexity and experience contribution using `ExperienceService`. Persists `WorkerParticipation(status=PENDING)`, records `WORKER_PARTICIPATION_INVITED` audit event, and sends actionable in-app `Notification` to the invited co-worker.
  - `get_gig_participations`: Returns participation list visible to customer, primary worker, or invited co-workers. Third parties receive `403 Forbidden`.
  - `accept_invitation`: Invited worker accepts invitation (`PENDING` -> `ACCEPTED`), records `responded_at`, logs `WORKER_PARTICIPATION_ACCEPTED` audit event, and notifies the inviting primary worker.
  - `reject_invitation`: Invited worker declines invitation (`PENDING` -> `REJECTED`), records `responded_at`, logs `WORKER_PARTICIPATION_REJECTED` audit event, and notifies the inviting primary worker.
- Mounted Endpoints in `app/api/v1/endpoints/participations.py` & Registered in `app/api/v1/router.py`:
  - `POST /api/v1/gigs/{gig_id}/participations` (Worker role).
  - `GET  /api/v1/gigs/{gig_id}/participations` (Authenticated participant or customer).
  - `POST /api/v1/participations/{participation_id}/accept` (Worker role).
  - `POST /api/v1/participations/{participation_id}/reject` (Worker role).
- Automated Testing & Validation:
  - Created `app/tests/test_sprint10_multi_worker.py` (10 comprehensive tests) covering:
    - Peer collaboration invitation (`EQUAL_SHARING`) and peer acceptance.
    - Rookie mentorship invitation (`ROOKIE`) and exact `0.5 * complexity` contribution calculation.
    - Peer invitation rejection (`REJECTED`) and notification/audit flow.
    - Cross-cooperative invitation isolation (`400 Bad Request`).
    - Self-invitation prevention (`400 Bad Request`).
    - Duplicate invitation conflict protection (`409 Conflict`).
    - Strict RBAC and unauthorized third-party isolation (`403 Forbidden`).
    - Customer price and payment invariance (confirming zero customer billing alterations).
    - Invalid gig lifecycle state validation (rejection on draft/completed/cancelled gigs).
    - Transactional rollback on simulated database commit failure.
  - Full test suite: 131/131 tests passing across all backend modules (Sprints 0 through 10) in 38.15s with 100% pass rate.

## 2026-09-09 23:45:00 +05:30 — Vismay & Antigravity (Backend AI)

Completed Sprint 11 (Cancellation & Rescheduling Policies) per `docs/06_BACKEND_SPRINTS.md` (Section 34: Sprint 11), `docs/05_API_DESIGN.md` (Section 25: Cancellation APIs & Section 26: Rescheduling APIs), `docs/04_DATABASE_DESIGN.md` (Sections 44–47: Cancellation & Rescheduling), and `docs/SRS_Final.md`:
- Business Rules & Architectural Invariants Enforced:
  - Server-Authoritative Fee Calculation:
    - Customer cancellation after worker selection (`WORKER_SELECTED` or `SCHEDULED`): ₹50.00 cancellation fee (`CANCELLATION_FEE_AFTER_SELECTION`).
    - Customer cancellation before worker selection (`DRAFT`, `POSTED`, `ACCEPTANCE_OPEN`): ₹0.00 cancellation fee (`CANCELLATION_FEE_BEFORE_SELECTION`).
    - Worker cancellation: ₹0.00 fee in MVP.
  - Financial Architecture & Settlement Invariants:
    - Customer cancellation after selection creates an active `Payment` obligation: `amount = Decimal("50.00")`, `payment_type = PaymentType.CANCELLATION`, `status = PaymentStatus.PENDING`, `cancellation_id = GigCancellation.id`.
    - Customer settles via existing payment route `POST /api/v1/gigs/{gig_id}/payment` (`CUSTOMER_PAID`).
    - Worker acknowledges receipt via `POST /api/v1/gigs/{gig_id}/payment/confirm-receipt` (`WORKER_CONFIRMED`).
    - Invariant: A cancelled gig strictly REMAINS `GigStatus.CANCELLED` upon payment settlement; it is NEVER transitioned to `COMPLETED` or `PAYMENT_CUSTOMER_PAID`.
    - Payment method immutability and precise `Decimal` representation preserved.
  - Customer Financial Integrity Guard (`CustomerFinancialGuard`):
    - Any customer attempting to create a new gig (`POST /api/v1/gigs`) is blocked with `409 Conflict` (`OUTSTANDING_CANCELLATION_PAYMENT`) if they have ANY unsettled cancellation payment obligation (`status != WORKER_CONFIRMED`).
  - Gig Reopening Guards:
    - Customer-cancelled gigs CANNOT be reopened (`400 Bad Request`, `CUSTOMER_CANCELLATION_CANNOT_REOPEN`).
    - Only worker-cancelled gigs can be reopened by the customer.
    - Reopening is blocked if an unsettled cancellation fee exists on the gig (`409 Conflict`, `CANCELLATION_PAYMENT_REQUIRED`).
    - Reopening atomically resets `selected_worker_id = None`, sets `status = GigStatus.POSTED`, and extends `acceptance_deadline` by 15 minutes.
  - Rescheduling Negotiation Workflow:
    - Permitted strictly in `WORKER_SELECTED` and `SCHEDULED` states (attempting in other states raises `409 StateConflictException`).
    - Atomic row-locking (`with_for_update()`) revalidates future date, `start_time < end_time`, weekly recurring availability (`OpportunityService.check_worker_availability_for_slot`), and overlapping confirmed gigs (`OpportunityService.check_schedule_conflict_for_slot`).
    - Full counterparty negotiation lifecycle supported: `REQUESTED`, `ACCEPTED` (updates gig schedule and sets `SCHEDULED`), `REJECTED`, and `ALTERNATIVE_PROPOSED` (chains counter-proposal).
- Database Migration:
  - Generated and applied Alembic migration `76b9636a889b` (`add payment_type and cancellation_id to payments`) live on Supabase PostgreSQL.
  - Batch alter table enabled for SQLite in-memory test compatibility.
- Implemented Schemas in `app/schemas/cancellation.py`:
  - `GigCancelRequest`, `GigCancelResponse`, `GigReopenResponse`, `RescheduleRequestCreate`, `RescheduleAlternativeRequest`, `RescheduleRequestResponse`.
  - Updated `PaymentResponse` in `app/schemas/payment.py` to include `payment_type`.
- Implemented Services & Endpoints:
  - `CustomerFinancialGuard` in `app/services/financial_guard.py`.
  - `CancellationService` in `app/services/cancellation_service.py`.
  - Updated `PaymentService` in `app/services/payment_service.py` to support `PaymentType.CANCELLATION`.
  - Updated `GigService` in `app/services/gig_service.py` to enforce `CustomerFinancialGuard`.
  - Mounted API endpoints in `app/api/v1/endpoints/cancellation.py` and registered in `app/api/v1/router.py`:
    - `POST /api/v1/gigs/{gig_id}/cancel`
    - `POST /api/v1/gigs/{gig_id}/reopen`
    - `POST /api/v1/gigs/{gig_id}/reschedule`
    - `GET  /api/v1/gigs/{gig_id}/reschedule`
    - `POST /api/v1/gigs/{gig_id}/reschedule/{request_id}/accept`
    - `POST /api/v1/gigs/{gig_id}/reschedule/{request_id}/reject`
    - `POST /api/v1/gigs/{gig_id}/reschedule/{request_id}/alternative`
- Automated Testing & Validation:
  - Created `app/tests/test_sprint11_cancellation_rescheduling.py` (19 comprehensive tests) covering fee calculations across all states, cancellation payment settlement, lifecycle invariants, customer financial guard blocking/unblocking, reopen validations, and full rescheduling negotiations.
  - Full test suite: 150/150 tests passing across all backend modules (Sprints 0 through 11) in 48.28s with 100% pass rate.

## 2026-09-10 00:20:00 +05:30 — Vismay & Antigravity (Backend AI)

Completed Sprint 12 (Material Procurement & Itemized Receipt Uploads) per `docs/06_BACKEND_SPRINTS.md` (Section 35: Sprint 12), `docs/05_API_DESIGN.md` (Section 23: Material APIs & Section 36: File Storage Strategy), `docs/04_DATABASE_DESIGN.md` (Section 32: Material Procurement & Section 33: Material Evidence), and `docs/SRS_Final.md` (Section 7.1: Labour Only & Section 7.2: Material Procurement):
- Business Rules & Architectural Invariants Enforced:
  - Source-of-Truth Separation: Labour price snapshots (`GigWorkerOpportunity.exact_wage`) represent strictly labour only and remain completely immutable. Material procurement is tracked as itemized reimbursement evidence when `material_procurement_mode == WORKER_PURCHASES`.
  - Customer Purchases Mode Protection: When gig procurement mode is `CUSTOMER_PURCHASES`, worker material receipt uploads are rejected with `400 Bad Request` (`code="MATERIAL_PROCUREMENT_NOT_WORKER"`).
  - Dual Upload Format Contract Reconciliation: Reconciled `05_API_DESIGN.md` Section 23 to support both:
    1. `multipart/form-data` (direct mobile upload of JPEG, PNG, or PDF files up to 10MB, auto-generating private storage references, or passing pre-uploaded form references).
    2. `application/json` (pre-uploaded private storage reference payload).
  - Role & Participant Authorization Guard:
    - Only workers with authenticated role `WORKER` can upload material receipts (`403 Forbidden` for customers).
    - Permitted strictly for the assigned primary worker (`gig.selected_worker_id == current_user.id`) or accepted collaborators (`WorkerParticipation.status == ACCEPTED`).
    - Collaborators with `PENDING` or `REJECTED` participation status are rejected with `403 Forbidden` (`code="COLLABORATOR_NOT_ACCEPTED"`).
    - Worker identity is derived exclusively from the JWT session (`current_user.id`); client-supplied IDs are ignored.
  - Privacy & Access Gating:
    - Receipt evidence is private and authorization-gated.
    - `GET /api/v1/gigs/{gig_id}/material-receipts` is accessible only to the customer, primary worker, and accepted collaborators. Third parties and anonymous callers receive `403 Forbidden` / `401 Unauthorized`.
  - Authoritative Itemized Accounting:
    - Backend sums all active receipts using exact `Decimal` precision (`sum(receipts.amount)`) and returns `total_material_cost` and itemized breakdown with worker attribution.
    - Receipt amounts must be strictly greater than zero (`> 0.00`).
  - Receipt Deletion & Lifecycle Freeze:
    - Only the specific worker who uploaded a receipt can delete it (`receipt.worker_id == current_user.id`). Co-workers cannot delete each other's receipts (`403 Forbidden`).
    - Deletion is permitted only during active pre-completion states (`WORKER_SELECTED`, `SCHEDULED`, `IN_PROGRESS`).
    - Once completion evidence has been submitted (`COMPLETION_SUBMITTED`), confirmed (`CUSTOMER_CONFIRMED`), completed (`COMPLETED`), or cancelled (`CANCELLED`), receipts are permanently locked from deletion (`409 Conflict`, `code="MATERIAL_RECEIPTS_LOCKED"`).
  - Audit Trail & Preservation:
    - Uploading a receipt emits `MATERIAL_RECEIPT_UPLOADED` audit event in `gig_events` and sends an in-app `Notification` to the customer.
    - Deleting a receipt emits `MATERIAL_RECEIPT_DELETED` audit event and sends an in-app `Notification` to the customer.
    - Cancelling a gig or reopening a worker-cancelled gig permanently preserves historical material receipts in PostgreSQL for audit and accounting reconciliation.
- Database Schema & Dependencies:
  - Validated existing `material_receipts` table in Supabase PostgreSQL (`id`, `gig_id`, `worker_id`, `amount`, `receipt_url`, `description`, `created_at`, `updated_at`). No database migration needed.
  - Added `python-multipart>=0.0.9` to `backend/requirements.txt` to support multipart form parsing.
- Implemented Schemas in `app/schemas/material.py`:
  - `MaterialReceiptCreateRequest`: Payload for JSON storage-reference workflow.
  - `MaterialReceiptResponse`: Output model with receipt metadata and worker display name.
  - `MaterialReceiptListResponse`: Output model with itemized receipts and calculated `total_material_cost`.
- Implemented Service in `app/services/material_service.py`:
  - `upload_material_receipt`: Implements multi-role validation, state validation, procurement mode checks, receipt record insertion, audit logging, and customer notification.
  - `get_material_receipts`: Implements privacy checks, receipt querying, exact `Decimal` accumulation, and response serialization.
  - `delete_material_receipt`: Implements ownership verification, lifecycle locking checks, record deletion, audit logging, and customer notification.
- Implemented API Endpoints in `app/api/v1/endpoints/materials.py` & Registered in `app/api/v1/router.py`:
  - `POST   /api/v1/gigs/{gig_id}/material-receipts` (Worker role; dual `multipart/form-data` and `application/json` support; 201 Created).
  - `GET    /api/v1/gigs/{gig_id}/material-receipts` (Customer, Primary Worker, Accepted Collaborators; 200 OK).
  - `DELETE /api/v1/gigs/{gig_id}/material-receipts/{receipt_id}` (Uploader Worker only; pre-completion only; 200 OK).
- Automated Testing & Validation:
  - Created `app/tests/test_sprint12_materials.py` (19 comprehensive tests) covering:
    - Procurement mode enforcement (`CUSTOMER_PURCHASES` blocks uploads vs `WORKER_PURCHASES` allows).
    - Dual upload formats: JSON workflow and multipart/form-data binary upload and pre-uploaded URL.
    - MIME type validation and file size / emptiness guards.
    - Customer, third-party, and unaccepted collaborator upload rejection.
    - Accepted collaborator upload permission and attribution.
    - Privacy gating on receipt views (customer, primary worker, collaborator allowed; third party 403; anon 401).
    - Itemized accounting and additive total calculations with exact `Decimal` arithmetic.
    - Receipt deletion by owner in progress and total cost recalculation.
    - Prevention of deleting another worker's receipt.
    - Lifecycle freezing of receipts after completion submission.
    - Audit preservation across gig cancellation and blocked post-cancellation uploads.
    - Audit events (`GigEvent`) and in-app notifications (`Notification`) for uploads and deletions.
  - Full regression test suite: 169/169 tests passing across all backend modules (Sprints 0 through 12) in 43.11s with 100% pass rate.

## 2026-09-10 01:00:00 +05:30 — Vismay & Antigravity (Backend AI)

Completed Sprint 13 (Structured Reviews + Metrics & Bayesian Rating Updates) per `docs/06_BACKEND_SPRINTS.md` (Section 36: Sprint 13), `docs/05_API_DESIGN.md` (Sections 27: Reviews APIs & 28: Public Worker Metrics), `docs/04_DATABASE_DESIGN.md` (Sections 8, 25, 26, 27), `docs/WAGES.md` (Sections 4, 5), and `docs/SRS_Final.md` (Section 20: Rating & Review System):
- Business Rules & Architectural Invariants Enforced:
  - Gating by Completion:
    - Reviews are permitted strictly when `gig.status == GigStatus.COMPLETED`. Attempting reviews in any other state raises `409 Conflict` (`code="GIG_NOT_COMPLETED"`).
  - Strict Directional Participant RBAC:
    - Customer can review the selected primary worker or any accepted collaborator (`WorkerParticipation.status == ACCEPTED`).
    - Primary worker or accepted collaborator can review the customer.
    - Non-participants attempting to submit or read reviews receive `403 Forbidden` (`code="NOT_GIG_PARTICIPANT"`).
    - Single Review Invariant: Exactly one review per directional participant pair per gig (`reviewee_id` + `reviewer_id` + `gig_id`). Duplicate submissions return `409 Conflict` (`code="REVIEW_ALREADY_EXISTS"`).
  - Question Set Architecture & Seeding:
    - Directional question sets: `WORKER` (4 standard questions evaluating worker matching `WAGES.md` Section 4: Work Quality & Completion, Reliability & Punctuality, Professionalism & Behavior, Communication & Transparency) and `CUSTOMER` (3 standard questions evaluating customer: Work Area Preparation & Safety, Gig Description Accuracy, Customer Communication & Respect).
    - Automatic seeding via `seed_review_questions_if_empty()` on FastAPI application startup lifespan, with on-demand fallback if table is empty.
    - Question & Answer Validation: Submitted questions must exist, be active, and match the target role (`WORKER` when reviewing worker, `CUSTOMER` when reviewing customer). Ratings must be integers between 1 and 5. Duplicate question IDs within a single review are rejected with `400 Bad Request` (`code="DUPLICATE_QUESTION_ANSWER"`).
  - Calculated Overall Rating:
    - `overall_rating` is optional in request payload. Backend calculates arithmetic mean from submitted question answers rounded to 2 decimal places (`round(sum/count, 2)`).
    - If client provides `overall_rating`, backend verifies that `round(client_rating, 2) == calculated_overall`; mismatch raises `400 Bad Request` (`code="RATING_MISMATCH"`). The backend never trusts client-provided rating and always stores the calculated value.
  - Worker Metric & Bayesian Rating Update:
    - When a customer reviews a worker, `WorkerMetric` is atomically loaded or initialized within the review transaction.
    - Historical customer reviews for the worker are queried (`reviewer_role == CUSTOMER`) to update `rating_count` and `rating_average`.
    - Bayesian rating aggregation calculates `bayesian_score = (C * m + sum(normalized_ratings)) / (C + n)` using documented parameters ($m = 0.70, C = 10.0, \text{normalized\_rating} = (\text{rating} - 1.0) / 4.0$).
    - Final composite score is updated: `final_score = 0.5 * experience_score + 0.5 * bayesian_score`.
  - Transactional Integrity:
    - `Review`, `ReviewAnswer` records, `WorkerMetric` updates, and `GigEvent` audit trail are committed in a single atomic database transaction.
  - Audit Trail & Notification:
    - Emits `REVIEW_SUBMITTED` audit event in `gig_events`.
    - Dispatches in-app `Notification` to the reviewee.
  - Privacy & Public Metrics:
    - `GET /api/v1/gigs/{gig_id}/reviews` is authorization-gated strictly to actual gig participants (customer, primary worker, accepted collaborators).
    - `GET /api/v1/workers/{worker_id}/metrics` exposes only documented public fields (`worker_id`, `completed_jobs_count`, `rating_average`, `rating_count`, `final_score`), strictly concealing private financial, experience score, and internal metric fields.
- Implemented Schemas in `app/schemas/review.py`:
  - `ReviewQuestionResponse`: Output model for active review questions.
  - `ReviewAnswerItem`: Input model for structured question answers (`question_id`, `answer_value: 1..5`).
  - `ReviewCreateRequest`: Input model strictly conforming to `05_API_DESIGN.md` Section 27 (`reviewee_id`, optional `overall_rating`, and `answers: List[ReviewAnswerItem]`; no undocumented text comments).
  - `ReviewAnswerResponse`: Output model for individual review answers.
  - `ReviewResponse`: Output model for review record with answers list.
  - `WorkerPublicMetricsResponse`: Public output model for worker rating and performance metrics.
- Implemented Service in `app/services/review_service.py`:
  - `seed_review_questions_if_empty`: Automated database seeding of standard question sets.
  - `get_review_questions`: Filtered retrieval of active questions by target role.
  - `submit_review`: End-to-end review validation, rating calculation, record creation, metric update, audit logging, and notification.
  - `get_gig_reviews`: Privacy-gated review retrieval for gig participants.
  - `get_worker_metrics`: Public worker metric retrieval.
- Implemented API Endpoints in `app/api/v1/endpoints/reviews.py` & Registered in `app/api/v1/router.py`:
  - `GET  /api/v1/review-questions` (Public / Authenticated; query by `target_role`).
  - `POST /api/v1/gigs/{gig_id}/reviews` (Gig Participant; completed gigs only; 201 Created).
  - `GET  /api/v1/gigs/{gig_id}/reviews` (Gig Participant only; 200 OK).
  - `GET  /api/v1/workers/{worker_id}/metrics` (Public / Authenticated; 200 OK).
- Lifespan Integration in `app/main.py`:
  - Registered `seed_review_questions_if_empty()` in startup event.
- Automated Testing & Validation:
  - Created `app/tests/test_sprint13_reviews.py` (13 comprehensive tests) covering:
    - Review question seeding and filtering by target role.
    - Completed customer-to-worker review submission and answer recording.
    - Worker metric update, Bayesian score calculation, and final score recalculation.
    - Completed worker-to-customer review submission.
    - Rejection of reviews on non-completed gigs (409 GIG_NOT_COMPLETED).
    - Duplicate review prevention for the same participant pair (409 REVIEW_ALREADY_EXISTS).
    - Participant isolation (403 FORBIDDEN for non-participants).
    - Invalid / mismatched questions and out-of-range ratings rejection.
    - Disallowed duplicate question IDs within a single review.
    - Overall rating calculation and client mismatch validation (400 RATING_MISMATCH).
    - Gig review retrieval privacy gating.
    - Public worker metrics field isolation (no private data leakage).
    - Customer reviewing an accepted collaborator.
    - Atomic rollback verification on failed review transactions.
  - Full regression test suite: 182/182 tests passing across all backend modules (Sprints 0 through 13) in 12.59s with 100% pass rate.

## 2026-09-10 01:15:00 +05:30 — Vismay & Antigravity (Backend AI)

Completed **Sprint 14 — Chat + Notifications** per `docs/06_BACKEND_SPRINTS.md` (Section 37), `docs/05_API_DESIGN.md` (Sections 29–30), `docs/04_DATABASE_DESIGN.md` (Sections 48–49), `docs/SRS_Final.md` (Section 26), and `docs/FRONTEND_DEVELOPMENT_ROADMAP.md` (Section 15.10):
- Chat Architecture & Gating:
  - Reused existing `Conversation` and `Message` models in `app/db/models/communication.py`.
  - Enforced single job-scoped conversation per gig (`Conversation.gig_id` unique); no public or community channels.
  - Chat gating: Strictly available only once a worker is selected (`gig.selected_worker_id is not None`); returns `409 CHAT_NOT_AVAILABLE` prior to selection.
  - Authorization: Strict role-based isolation permitting only customer, selected primary worker, and accepted collaborators (`WorkerParticipationStatus.ACCEPTED` on `additional_worker_id`); returns `403 NOT_GIG_PARTICIPANT` for outsiders.
  - Lazy initialization: Conversation record is generated lazily on first participant access if not already created.
  - Message validation: Trimmed whitespace, length 1–2000 characters, authenticated sender binding (`sender_id = current_user.id`).
  - Read receipts: When a recipient retrieves messages via `GET /api/v1/gigs/{gig_id}/conversation/messages`, counterparty unread messages retrieved in that window are atomically marked `is_read = True`.
  - Emits in-app `Notification` (`type="CHAT_MESSAGE"`) to relevant counterparties (including accepted collaborators) and audit event `GigEvent` (`event_type="CHAT_MESSAGE_SENT"`).
- Notifications System:
  - Reused existing `Notification` model and service architecture; no parallel notification mechanisms introduced.
  - Filtering: Supports filtering by `is_read` (boolean) and `type` (string).
  - Ordering & Pagination: Orders newest first (`created_at DESC`) with `limit` and `offset`, returning total and `unread_count`.
  - Read actions: `POST /api/v1/notifications/{id}/read` sets `is_read = True` and records `read_at = now_utc`.
  - Read-all: `POST /api/v1/notifications/read-all` updates all unread notifications belonging exclusively to the authenticated user and returns `marked_read_count`.
  - Ownership isolation: Users can only inspect and mark their own notifications (returns `403 FORBIDDEN` on unauthorized attempts).
- Lifecycle Notifications Integration:
  - `NEW_OPPORTUNITY`: Emitted to matched workers upon gig posting or sync in `app/services/opportunity_service.py`.
  - `WORKER_ACCEPTED`: Emitted to customer when a worker accepts the opportunity in `app/services/opportunity_service.py`.
  - `REVIEW_AVAILABLE`: Emitted idempotently to both customer and selected worker upon gig reaching `COMPLETED` status in `app/services/payment_service.py`.
- Endpoints Added in `app/api/v1/router.py`:
  - `GET  /api/v1/gigs/{gig_id}/conversation` (`app/api/v1/endpoints/chat.py`)
  - `POST /api/v1/gigs/{gig_id}/conversation/messages` (`app/api/v1/endpoints/chat.py`)
  - `GET  /api/v1/gigs/{gig_id}/conversation/messages` (`app/api/v1/endpoints/chat.py`)
  - `GET  /api/v1/notifications` (`app/api/v1/endpoints/notifications.py`)
  - `POST /api/v1/notifications/{notification_id}/read` (`app/api/v1/endpoints/notifications.py`)
  - `POST /api/v1/notifications/read-all` (`app/api/v1/endpoints/notifications.py`)
- Automated Testing & Regression:
  - Created `app/tests/test_sprint14_chat_notifications.py` (11 comprehensive tests) covering:
    - Lazy conversation initialization.
    - Chat availability gating prior to worker selection (`409 CHAT_NOT_AVAILABLE`).
    - Participant authorization and isolation (`403 NOT_GIG_PARTICIPANT`).
    - Customer <-> worker bidirectional messaging, notification generation, and audit logging.
    - Accepted collaborator chat participation and notification broadcasting.
    - Empty, whitespace, and oversized (>2000 chars) message validation (`422 Unprocessable Content`).
    - Message pagination, chronological ordering (ASC), and dynamic unread counter calculation.
    - Read receipt auto-marking for retrieved counterparty messages.
    - Notification listing with `is_read` and `type` filters and `unread_count`.
    - Single notification mark as read with `read_at` timestamp.
    - Read-all bulk notification updates with count.
    - Notification ownership security isolation (`403 FORBIDDEN`).
    - Lifecycle notification emissions (`NEW_OPPORTUNITY`, `WORKER_ACCEPTED`, `REVIEW_AVAILABLE`).
    - Duplicate/idempotency protection for `REVIEW_AVAILABLE` on repeated payment confirmations.
## 2026-09-10 01:52:00 +05:30 — Vismay & Antigravity (Full-Stack AI)

Completed **Sprint 15 — Integration Hardening** per `docs/06_BACKEND_SPRINTS.md` (Section 38), `docs/FRONTEND_DEVELOPMENT_ROADMAP.md`, `docs/05_API_DESIGN.md`, and `docs/SRS_Final.md`:

### 1. Backend Development Authentication Architecture
- Implemented development authentication strictly compliant with existing Supabase HS256 JWT validation:
  - `POST /api/v1/auth/login` (`app/api/v1/endpoints/auth.py`):
    - Uses identical HS256 secret (`settings.SUPABASE_JWT_SECRET`), algorithm, claims, and expiry (`settings.JWT_EXPIRY_MINUTES`).
    - Normalizes role (`CUSTOMER` / `WORKER`) case-insensitively via Pydantic validator.
    - Resolves existing user or initializes demo user with correct role and cooperative membership.
    - Encodes identical `sub`, `email`, `role`, `user_metadata`, `app_metadata` claims expected by `app/core/auth.py`.
    - Returns `DevLoginResponse` with `access_token`, `token_type`, and `user` profile (`UserResponse`).
  - `GET /api/v1/auth/demo-users` (`app/api/v1/endpoints/auth.py`):
    - Public development discovery endpoint listing pre-seeded/active development test accounts without exposing credentials.
  - Registered router in `app/api/v1/router.py`.
  - Added test suite `app/tests/test_sprint15_dev_auth.py` (4 tests) covering customer login, worker login, demo users listing, and invalid role rejection.
  - All existing Sprint 0–14 business, wage, payment, and pricing rules strictly preserved.

### 2. Flutter Network & State Layer (`mobile_app/lib/`)
- `services/token_storage.dart`:
  - Centralized session token and current user storage.
  - Platform-aware base URL detection (`http://10.0.2.2:8000/api/v1` for Android emulator, `http://localhost:8000/api/v1` for iOS, Desktop, and Web).
  - Clean `setSession(...)` and `clear()` lifecycle methods.
- `models/api/api_response.dart`:
  - `ApiResponse<T>`: Standard envelope parser for backend `{ "data": T, "message": "..." }`.
  - `PaginatedResponse<T>` and `PaginationMeta`: Strongly typed paginated collections matching backend `PaginatedResponse[T]` schema.
  - `ApiError`: Strongly typed error parser for FastAPI `{ "error": { "code": "...", "message": "...", "details": {...} } }` and HTTP 422 validation detail lists.
- `models/api/api_models.dart`:
  - 30+ strongly typed DTOs aligned 1-to-1 with Pydantic schemas:
    - Auth: `DevLoginRequest`, `DevLoginResponse`, `DemoUserItem`, `UserDto`.
    - Catalogue & Pricing: `ServiceCategoryDto`, `ServiceTaskDto`, `PricePreviewDto`, `PricePreviewTaskItemDto`, `EstimatedWageRangeDto`.
    - Gigs: `GigCreateRequestDto`, `GigDto`, `GigTaskItemDto`.
    - Matching: `GigCandidateDto`, `SelectWorkerRequestDto`, `SelectWorkerResponseDto`.
    - Opportunities: `OpportunityDto`, `OpportunityGigDto`, `WorkerGigListItemDto`.
    - Completion: `StartWorkResponseDto`, `CompletionEvidenceCreateDto`, `CompletionEvidenceResponseDto`, `CompletionSubmissionRequestDto`, `CompletionSubmissionResponseDto`, `CompletionConfirmationRequestDto`, `CompletionConfirmationResponseDto`, `GigCompletionDetailDto`.
    - Payments: `PaymentCreateRequestDto`, `PaymentReceiptConfirmRequestDto`, `PaymentDto`.
    - Reviews: `ReviewQuestionDto`, `ReviewAnswerItemDto`, `ReviewCreateRequestDto`, `ReviewAnswerResponseDto`, `ReviewDto`, `WorkerPublicMetricsDto`.
    - Chat: `MessageCreateRequestDto`, `MessageDto`, `ConversationDto`.
    - Notifications: `NotificationDto`, `NotificationListResponseDto`, `NotificationReadAllResponseDto`.
- `services/api_client.dart`:
  - Centralized Dio client wrapper with dynamic base URL and timeout configurations.
  - Request interceptor injecting `Authorization: Bearer <token>` automatically.
  - Test hook `mockHandler` for hermetic unit and widget testing without network access.
  - 401 Unauthorized interceptor automatically clearing stale sessions.
  - Global error translation into structured `ApiError` exceptions.

### 3. Flutter Repositories (`mobile_app/lib/repositories/`)
- `auth_repository.dart`: `login(email, password, role)`, `getDemoUsers()`.
- `catalogue_repository.dart`: `getCategories()`, `getCategoryTasks(categoryId)`, `getPricePreview(...)`.
- `gig_repository.dart`: `createGig(...)`, `postGig(gigId)`, `getCustomerGigs(status, page, pageSize)`, `getCandidates(gigId)`, `selectWorker(gigId, workerId)`, `getCompletion(gigId)`, `confirmCompletion(gigId, confirmed, responseNote)`.
- `worker_repository.dart`: `getOpportunities(page, pageSize)`, `acceptOpportunity(oppId)`, `declineOpportunity(oppId)`, `startWork(gigId)`, `submitCompletion(gigId, description, evidenceItems)`, `getWorkerGigs(...)`.
- `payment_repository.dart`: `getGigPayment(gigId)`, `recordPayment(gigId, paymentMethod)`, `confirmPaymentReceipt(gigId)`.
- `review_repository.dart`: `getReviewQuestions(targetRole)`, `submitReview(gigId, req)`, `getGigReviews(gigId)`, `getWorkerMetrics(workerId)`.
- `chat_repository.dart`: `getConversation(gigId)`, `getMessages(gigId, limit, offset)`, `sendMessage(gigId, text)`.
- `notification_repository.dart`: `getNotifications(...)`, `markAsRead(id)`, `markAllAsRead()`.

### 4. Flutter Screens Connected to Live Backend
- **Customer Authentication**:
  - `CustomerLoginScreen`: Pre-loads live demo accounts from `/auth/demo-users`, authenticates via `AuthRepository.login`, verifies role, and sets session.
- **Customer Ordering Flow**:
  - `CreateGigScreen`: Loads live service categories and tasks from `CatalogueRepository.getCategories()`.
  - `LabourPricePreviewScreen`: Fetches authoritative pricing from `CatalogueRepository.getPricePreview(...)`, creates gig via `GigRepository.createGig(...)`, and posts to matching pool via `GigRepository.postGig(...)`.
  - `CustomerNavigation2Screen`: Fetches live customer gigs via `GigRepository.getCustomerGigs(...)`.
  - `AcceptedCandidatesScreen`: Queries `/gigs/{gig_id}/candidates` to load live accepted worker applicants.
  - `WorkerProfileScreen`: Tapping "Select this worker" invokes `GigRepository.selectWorker(gigId, workerId)`.
  - `CompletionEvidenceReviewScreen`: Loads worker evidence photos from `GigRepository.getCompletion(gigId)`.
  - `CompletionConfirmationScreen`: Submits customer confirmation via `GigRepository.confirmCompletion(gigId, confirmed: true)`.
  - `PaymentScreen`: Fetches authoritative snapshot wage via `PaymentRepository.getGigPayment(gigId)`, executes payment via `PaymentRepository.recordPayment(gigId, method)`, and navigates to review.
  - `ReviewWorkerScreen`: Fetches live question set from `ReviewRepository.getReviewQuestions('WORKER')` and submits ratings via `ReviewRepository.submitReview(...)`.
- **Worker Workflow**:
  - `WorkerLoginScreen`: Authenticates worker, sets token, verifies `WORKER` role.
  - `WorkerHomeScreen`: Fetches live opportunities from `WorkerRepository.getOpportunities()`.
  - `OpportunityDetailsScreen`: Accepts or declines opportunities via `WorkerRepository.acceptOpportunity` / `declineOpportunity`.
  - `WorkerActiveJobScreen`: Starts work via `WorkerRepository.startWork(gigId)` and opens job chat.
  - `CompletionEvidenceUploadScreen`: Submits work description and evidence photos via `WorkerRepository.submitCompletion(...)`.
  - `WorkerPaymentConfirmationScreen`: Confirms payment receipt via `PaymentRepository.confirmPaymentReceipt(gigId)`, transitioning gig to `COMPLETED`.
  - `ReviewCustomerScreen`: Fetches `CUSTOMER` review questions and submits review ratings.
- **Common Screens**:
  - `ChatScreen`: Job-scoped chat connected to `ChatRepository.getMessages` and `sendMessage`.
  - `NotificationsScreen`: Fetches live notifications via `NotificationRepository.getNotifications` with pull-to-refresh and mark-as-read actions.

### 5. Backend Source-of-Truth Pruning & Paused Features
- **Emergency Tip Incentive**: Temporarily paused in `gig_details_screen.dart` (`onPressed: null`, labelled `Add tip incentive (Paused in MVP)`). Preserved UI code without inventing fake backend endpoints.
- **Previous-Worker Direct-Booking**: Temporarily paused in `customer_workflow_screens.dart` (`onTap: null`, labelled `Request a previous worker (Paused in MVP)`). Preserved UI code without inventing fake backend endpoints.

### 6. Automated Validation Results
- **Backend Tests**:
  - Command: `python -m pytest app/tests -q`
  - Result: **197 passed, 10 warnings in 13.91s** (193 Sprint 0–14 regression tests + 4 Sprint 15 dev auth tests).
- **Flutter Analyzer**:
  - Command: `flutter analyze`
  - Result: **0 issues found!**
- **Flutter Tests**:
  - Command: `flutter test`
  - Result: **28 passed, 0 failed!** (21 unit/DTO/envelope/auth integration tests + 7 widget navigation tests).
- **FastAPI Probes**:
  - `/api/v1/health`: 200 OK (database connected).
  - `/api/v1/openapi.json`: 55 registered paths.
  - `/api/v1/auth/demo-users`: 200 OK.
  - `/api/v1/auth/login`: 200 OK (returns valid Supabase-compatible HS256 JWT access token).

## 2026-09-10 02:10:00 +05:30 — Vismay & Antigravity (Full-Stack AI)

Completed **Sprint 15 Final Security + Contract Verification Fixes**:

### 1. Fix 1 — Development Auth Environment Guard Hardening
- Hardened `_ensure_dev_environment()` in `backend/app/api/v1/endpoints/auth.py`.
- Replaced blacklist equality check (`== "production"`) with explicit allowlist:
  `if settings.ENVIRONMENT.lower() not in {"development", "dev", "test", "local"}: raise ForbiddenException(...)`.
- Confirmed that environments `production`, `prod`, `staging`, `live`, or unconfigured/empty strings strictly return HTTP 403 `DEV_ENDPOINT_DISABLED`.
- Added matrix verification test `test_dev_auth_environment_guard_matrix` to `backend/app/tests/test_sprint15_dev_auth.py`.

### 2. Fix 2 — Flutter Catalogue Route Contract Alignment
- Updated `mobile_app/lib/repositories/catalogue_repository.dart`:
  - Changed `'/categories'` → `'/service-categories'`.
  - Changed `'/categories/$categoryId/tasks'` → `'/service-categories/$categoryId/tasks'`.
- Confirmed routes match backend `catalogue.py` OpenAPI endpoints exactly.
- Added automated mock test in `integration_hardening_test.dart` verifying paths.

### 3. Fix 3 — Payment Decimal Parsing Resilience
- Updated `PaymentDto.fromJson` in `mobile_app/lib/models/api/api_models.dart`:
  - Replaced unsafe `(json['amount'] as num?)?.toDouble() ?? 0.0` with `double.tryParse(json['amount']?.toString() ?? '') ?? 0.0`.
  - Safely handles backend `Decimal` values serialized as JSON string (e.g., `"225.50"`), numeric values (`225.50`), and null/missing values (`0.0`).
- Added targeted parsing tests in `integration_hardening_test.dart`.

### 4. Final Validation Metrics
- **Backend Tests**: `198 passed, 10 warnings in 39.81s` (`python -m pytest app/tests -q`).
- **Flutter Analyzer**: `No issues found! (ran in 1.7s)` (`flutter analyze`).
- **Flutter Test Suite**: `All 30 tests passed!` (`flutter test`).
- **Verdict**: APPROVED — Sprint 15 is safe to permanently lock.

## 2026-09-10 11:23:40 +05:30 — Vismay & Antigravity

Successfully deployed the backend to Railway cloud infrastructure and established untethered mobile operation:
- Created and committed `backend/Procfile` targeting `uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}`.
- Identified that Supabase direct connection (`db.upkxwtnxfnkjuuwrjutk.supabase.co:5432`) is IPv6-only, which cloud containers cannot route to without IPv4 dual-stack; resolved by reconfiguring `DATABASE_URL` to use Supabase's AWS Mumbai IPv4 session pooler (`aws-0-ap-south-1.pooler.supabase.com:5432`) with user `postgres.upkxwtnxfnkjuuwrjutk`.
- Added startup table verification and catalogue/review seeding in `backend/app/main.py` lifespan and pre-seeded development demo accounts in `backend/app/api/v1/endpoints/auth.py`.
- Configured `TokenStorage.instance.defaultBaseUrl` in `mobile_app/lib/services/token_storage.dart` with default fallback to `https://sih2026-production-ee63.up.railway.app/api/v1`.
- Verified live cloud health check (`200 OK`), demo accounts retrieval (`GET /api/v1/auth/demo-users` returning all 6 accounts), and development JWT authentication (`POST /api/v1/auth/login` returning 200 OK with valid bearer token).

