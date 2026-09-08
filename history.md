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

    - history update remaning 

