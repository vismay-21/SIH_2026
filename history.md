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

