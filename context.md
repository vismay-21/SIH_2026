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
│   └── .gitkeep
├── docs/
│   ├── ALGORITHM_RECOMMENDATION_DEVELOPMENT_ROADMAP.md
│   ├── FRONTEND_DESIGN_SYSTEM.md
│   ├── FRONTEND_DEVELOPMENT_ROADMAP.md
│   ├── SRS_Final.md
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

## Validation

The latest completed validation passed:

```text
dart format lib test
flutter analyze (0 issues found)
flutter test (7/7 tests passed)
```

The implementation has no additional package dependency beyond the Flutter project defaults.

## Pending Backend/Product Work

- Production authentication and account persistence.
- API/database/repository/provider architecture.
- Real gig creation and state persistence.
- Cooperative pricing configuration and algorithm implementation.
- Real worker eligibility, acceptance, recommendation, and selection state.
- Real image/evidence/material-bill upload and viewing.
- Production chat transport, notifications, and read state.
- Cash/UPI payment integration and worker payment acknowledgement.
- Multi-worker consent and backend synchronization.
