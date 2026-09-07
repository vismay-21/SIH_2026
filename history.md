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
