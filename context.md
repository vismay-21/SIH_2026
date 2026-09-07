# SIH 2026 Project Context

## Current State

Sahakaar Seva is a Flutter frontend for a cooperative household-services marketplace. The app supports Customer and Worker role entry, styled authentication/registration flows, role dashboards, customer gig creation, customer gig lifecycle management, chat, alerts, profile/account surfaces, and mock completion/payment flows.

The implementation is frontend-only and uses Flutter's existing dependencies. Mock data is used for gigs, workers, prices, messages, evidence, material bills, and notifications. There is no production backend, API, database, real authentication, real worker matching, image picker, chat service, payment gateway, or persistence layer yet.

Latest documented implementation: 2026-09-07, contributor Yug.

## Design System

- Theme: Material 3 with centralized tokens in `mobile_app/lib/theme/app_theme.dart`.
- Palette: primary cooperative green `#245B52`, dark green `#173B36`, amber `#E8B84A`, warm off-white `#F7F8F5`, white surfaces, dark text, muted text, border, success, and danger colors.
- Shared primitives: `BrandMark`, `SurfaceCard`, `SectionTitle`, `StatTile`, `StatusPill`, `PrimaryAction`, shared login layout, and shared registration layout in `mobile_app/lib/widgets/common/shared_widgets.dart`.
- Action buttons: filled/elevated/outlined Material action buttons use the supplied white rectangular design with black border, square corners, and hard black offset shadow. Text links and icon-only controls remain lightweight.
- The interface favors clear hierarchy, explicit status text, connected lifecycle progress, role-specific copy, and customer/worker-specific navigation.

## Implemented User Flows

### App entry and roles

```text
Splash
  -> Role Selection
     -> Customer Login -> Customer Main
        -> Home | My Gigs | Alerts | Profile
     -> Worker Login -> Worker Main
        -> Home | Opportunities | My Jobs | Profile
```

Login and registration actions are demo navigation, not real authentication.

### Customer gig creation

```text
Customer Home
  -> Create a gig
     -> Gig details form
     -> Material procurement choice
     -> Labour price preview
     -> Post gig
     -> Customer Home
```

The form supports category, work description, location, required date/time, duration, emergency status toggle, photo-count placeholder, additional instructions, and materials. The material choice is Customer purchases materials or Worker purchases materials. Labour is shown separately from materials. The current mock cooperative example range is `₹550 – ₹800`. Emergency status is toggled during gig creation. If no worker accepts a posted gig, opening `GigDetailsScreen` displays a fallback banner allowing the customer to add a voluntary tip incentive (100% direct worker payout) and re-notify nearby workers.

The Customer shell (`customer_main_screen.dart`) implements persistent bottom navigation using per-tab nested `Navigator`s inside an `IndexedStack`. Sub-screens (Gig Details, Accepted Candidates, Active Job Workspace, Chat, Payment, Cancel, Reschedule, Emergency Tip, Review) push within the active tab's viewport, leaving the bottom `NavigationBar` permanently visible at all times.

### Customer gig management

My Gigs has Active, Upcoming, and Completed tabs. Selecting a gig opens Gig Details. Track Job from the home dashboard opens the Customer shell on My Gigs and immediately opens the selected gig.

The gig tracker displays:

```text
Seeking Workers
Workers Responding
Accepted Candidates
Worker Selected
Scheduled
Active
Completion Requested
Payment
Completed
```

Customer workflow routes include accepted candidates, worker comparison/recommendation, worker profile, final worker selection, previous-worker request, active job, completion evidence review, completion confirmation, Cash/UPI payment, and material bill/proof viewer. Evidence alone does not complete a gig; customer confirmation comes before payment.

### Customer chat and account

- Chat inbox lists worker conversations.
- Chat thread supports mock message display, text entry, send behavior, and a job-details link.
- Home Chat and Active Job Chat open the relevant worker thread.
- Alerts open related gig details.
- Profile opens Job History, Settings, Help and Support, and Sign Out.
- Settings includes job alerts, worker messages, location-sharing controls, and account management feedback.
- Help includes expandable FAQs and contact-support feedback.
- Sign out confirms and returns to Splash.

### Customer dashboard improvements

The dashboard uses clearer statuses such as `3 workers interested`, stronger emergency badges, shorter descriptions, explicit `Estimated` duration labels, Track Job as the primary card action, Chat as a secondary action, and previous-worker trust signals with ratings and completed-job counts.

### Worker surfaces

Worker login, registration, main shell, Home, Opportunities, My Jobs, Alerts, and Profile screens are implemented as styled mock surfaces. They show opportunities, exact wages, availability, emergency status, worker jobs, notifications, and profile concepts. Worker backend actions and persistence are not implemented.

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
    │   │   └── customer_gig_workflow.dart
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
    │       │   └── role_selection_screen.dart
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
    │           ├── home/worker_home_screen.dart
    │           ├── opportunities/worker_navigation_2_screen.dart
    │           ├── my_jobs/worker_navigation_3_screen.dart
    │           └── profile/worker_navigation_4_screen.dart
    ├── test/widget_test.dart
    ├── android/              # Android Gradle/project files and generated plugin wiring
    ├── ios/                  # iOS Runner/Xcode files and generated Flutter wiring
    ├── linux/                # Linux runner and generated Flutter wiring
    ├── macos/                # macOS Runner/Xcode files and generated Flutter wiring
    ├── windows/              # Windows runner and generated Flutter wiring
    └── web/                  # Web entrypoint, manifest, favicon, and icons
```

## Important File Responsibilities

- `lib/main.dart`: app entry point; starts `SplashScreen` and applies `buildAppTheme()`.
- `lib/theme/app_theme.dart`: color tokens, Material 3 theme, input/card/navigation themes, and global button style.
- `lib/widgets/common/shared_widgets.dart`: shared visual primitives and reusable authentication layouts.
- `lib/models/gig_draft.dart`: draft data passed through gig creation steps.
- `lib/models/customer_gig_workflow.dart`: gig lifecycle enum, candidate model, customer gig model, and demo gig/candidate data.
- `lib/screens/customer/customer_main_screen.dart`: Customer bottom navigation and initial-tab/initial-gig routing.
- `lib/screens/customer/home/`: customer home dashboard (`customer_home_screen.dart`) and gig creation forms (`create_gig_screen.dart`, `material_procurement_screen.dart`, `labour_price_preview_screen.dart`).
- `lib/screens/customer/my_jobs/`: tabbed My Gigs list (`customer_navigation_2_screen.dart`), gig details (`gig_details_screen.dart`), and connected candidate/workflow screens (`customer_workflow_screens.dart`).
- `lib/screens/customer/alerts/`: customer notification & event alerts (`customer_navigation_3_screen.dart`).
- `lib/screens/customer/profile/`: main customer profile UI (`customer_navigation_4_screen.dart`) and account surfaces (`customer_account_screens.dart`: chat, history, settings, help/support).
- Individual customer workflow route files re-export their implementation from `customer_workflow_screens.dart` for clear feature-level imports.
- Worker files provide the existing styled Worker role surfaces and navigation shell.
- `test/widget_test.dart`: three widget flows covering Customer navigation, Customer registration return, and Worker registration/destination navigation.

## Validation

The latest completed validation passed:

```text
dart format ...
flutter analyze
flutter test
```

Current widget suite result: 3 tests passed. The implementation has no additional package dependency beyond the Flutter project defaults.

## Pending Backend/Product Work

- Production authentication and account persistence.
- API/database/repository/provider architecture.
- Real gig creation and state persistence.
- Cooperative pricing configuration and algorithm implementation.
- Real worker eligibility, acceptance, recommendation, and selection state.
- Real image/evidence/material-bill upload and viewing.
- Production chat transport, notifications, and read state.
- Cash/UPI payment integration and worker payment acknowledgement.
- Completion reviews, cancellation, rescheduling, multi-worker consent, emergency fallback, localization, and accessibility/contrast testing.
