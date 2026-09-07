# Sahakaar Seva Frontend Design System

## Status

Comprehensive mobile design system implemented in the Flutter app (`mobile_app/`) as of **2026-09-07**. This document records the finalized visual specifications, component design patterns, navigation architecture, and implemented surface catalog for the Sahakaar Seva Cooperative household-services platform.

---

## 1. Visual Direction & Principles

The Sahakaar Seva interface reflects cooperative values: **transparent, dignified, practical, and worker-supportive**. It deliberately eschews decorative clutter, aggressive gamification, and predatory bidding mechanisms in favor of:
- **Calm, legible contrast**: Warm off-white canvas with pure white working surfaces and deep forest green primary tones.
- **Strict wage transparency**: Exact algorithmic and guild-tariff wages are displayed upfront prior to worker acceptance and customer confirmation.
- **Dignified equality**: Symmetrical review mechanisms, multi-tier trust verification, and collaborative apprenticeship progression.
- **Attention state discipline**: Amber accent tones are reserved strictly for emergency tasks, schedule conflicts, and apprenticeship milestones.

---

## 2. Color Palette & Theme Tokens

The centralized source of truth for all color tokens is `mobile_app/lib/theme/app_theme.dart`.

| Token | Constant | Hex | Role & Application |
| --- | --- | --- | --- |
| **Primary** | `AppColors.primary` | `#245B52` | Cooperative brand green, primary actions, selected navigation icons, badges |
| **Primary Dark** | `AppColors.primaryDark` | `#173B36` | Headings, high-emphasis text, prominent banner icons |
| **Accent** | `AppColors.accent` | `#E8B84A` | Emergency badges, schedule conflict warnings, apprentice milestones |
| **Background** | `AppColors.background` | `#F7F8F5` | Warm off-white scaffold canvas |
| **Surface** | `AppColors.surface` | `#FFFFFF` | Cards, sheets, dialogs, form input backgrounds |
| **Text** | `AppColors.text` | `#17211F` | Primary typography, titles, body copy |
| **Muted** | `AppColors.muted` | `#737C78` | Secondary labels, timestamps, distances, captions |
| **Border** | `AppColors.border` | `#D8DDDA` | Clean, subtle card borders, dividers, unselected states |
| **Success** | `AppColors.success` | `#3D8B68` | Available toggles, verified badges, completed states, positive credits |
| **Danger** | `AppColors.danger` | `#C85C5C` | Gig cancellations, decline actions, error states |

---

## 3. Typography & Hierarchy

The app uses `Avenir Next` as primary font family, falling back gracefully to platform sans-serif defaults:

- **Headline Large / Medium**: `22px – 26px`, `FontWeight.w800`, line height `1.2`. Used for screen titles, customer greeting, and wage amounts.
- **Title / Section Heading**: `15px – 18px`, `FontWeight.w800`, line height `1.3`. Used for card headers, section titles (`SectionTitle`), and modal titles.
- **Body Regular**: `13px – 14px`, `FontWeight.normal` / `FontWeight.w600`, line height `1.4`. Used for descriptions, instructions, and list tile titles.
- **Caption / Meta**: `10px – 12px`, `FontWeight.normal` / `FontWeight.w700`, color `AppColors.muted`. Used for timestamps, distances, categories, and badge subtitles.

No screen should introduce secondary font families.

---

## 4. Component Architecture & UI Primitives

Reusable components live in `mobile_app/lib/widgets/common/shared_widgets.dart` and domain subfolders:

### 4.1 Card Primitives
- **`SurfaceCard`**: Standard content container with 14px–16px border radius, white surface background, subtle `AppColors.border` border, and 14px–16px internal padding.
- **`StatTile`**: Dashboard metric tile with icon, bold numerical value, and descriptive label. Direct child of `Row`.

### 4.2 Badges & Labels
- **`StatusPill`**: Rounded pill (20px radius) with soft background tint (`color.withValues(alpha: 0.12)`). Supports default brand green, attention amber (`warning: true`), and emergency red.

### 4.3 Signature Cooperative Buttons
- **Square Offset-Shadow Buttons**: Core action buttons feature a white surface, solid black border (`1.5px`), square/12px corners, and a signature hard-offset black drop shadow (`BoxShadow(color: Colors.black, offset: Offset(3, 3))`).
- **Filled Primary Action Buttons**: High-intent floating actions and bottom sheets use `AppColors.primary` filled buttons with 12px rounded corners and white text.

### 4.4 Interactive Selection Cards
- Replaces deprecated radio controls with custom rounded interactive cards. When selected, cards display a soft tint (`AppColors.primary.withValues(alpha: 0.08)`), a highlighted border, and an active `Icons.radio_button_checked_rounded` icon.

---

## 5. Navigation Architecture (Persistent Bottom Nav)

Both `CustomerMainScreen` and `WorkerMainScreen` implement **persistent bottom navigation** via per-tab nested `Navigator` widgets inside an `IndexedStack`:

```text
Scaffold
  ├── body: IndexedStack(index: selectedIndex)
  │     ├── Tab 0: Navigator(key: navKeys[0], onGenerateRoute: (_) => HomeScreen)
  │     ├── Tab 1: Navigator(key: navKeys[1], onGenerateRoute: (_) => Opportunities/MyJobsScreen)
  │     ├── Tab 2: Navigator(key: navKeys[2], onGenerateRoute: (_) => Alerts/MyJobsScreen)
  │     └── Tab 3: Navigator(key: navKeys[3], onGenerateRoute: (_) => ProfileScreen)
  └── bottomNavigationBar: NavigationBar(...)
```

### Key Navigation Behaviors:
1. **Per-Tab Viewports**: Pushing sub-screens (e.g. `GigDetailsScreen`, `WorkerActiveJobScreen`, `ReviewCustomerScreen`) pushes within the active tab's `Navigator`. The bottom navigation bar remains permanently visible.
2. **Tab Reselection**: Tapping an already selected tab pops that tab back to its root screen (`popUntil((route) => route.isFirst)`).
3. **Hardware Back Button Handling**: Handled via `PopScope`:
   - If the active tab has sub-screens, it pops the top sub-screen.
   - If at the root of a secondary tab (tabs 1–3), it smoothly returns to Tab 0 (Home).
   - If at the root of Tab 0, it delegates to the root navigator.
4. **Sign Out**: Explicitly invokes `Navigator.of(context, rootNavigator: true)` to pop the shell completely and return to `SplashScreen`.

---

## 6. Implemented Surface Catalog (~52 Screens)

### A. Common Screens (`lib/screens/common/`)
- `SplashScreen`: App initialization & logo presentation.
- `RoleSelectionScreen`: Dual entry selection between Customer and Worker.
- `ChatScreen`: Shared bidirectional messaging screen with timestamps, status, and composer.
- `NotificationsScreen`: Shared cooperative notifications list with unread markers.

### B. Customer Screens (`lib/screens/customer/`)
- **Authentication**: `CustomerLoginScreen`, `CustomerRegisterScreen`.
- **Shell & Home (`home/`)**:
  - `CustomerMainScreen`: Persistent 4-tab shell (Home, My Jobs, Alerts, Profile).
  - `CustomerHomeScreen`: Dashboard with active gigs, track job primary actions, emergency tipping demo.
  - `CreateGigScreen`: Category, description, date/time, duration, emergency toggle, photo placeholder, instructions.
  - `MaterialProcurementScreen`: Procurement choice (Customer vs Worker).
  - `LabourPricePreviewScreen`: Cooperative tariff labour range preview (`₹550 – ₹800`).
  - `EmergencyTipScreen`: Voluntary tip fallback when no workers accept (SRS 18.1).
- **My Jobs (`my_jobs/`)**:
  - `CustomerNavigation2Screen`: Tabbed list (Active, Upcoming, Completed).
  - `GigDetailsScreen`: Full lifecycle tracker and status milestones.
  - `WaitingForCandidatesScreen`: Seeking workers radar pulse animation & response timer.
  - `AcceptedCandidatesScreen` & `WorkerComparisonScreen`: Transparent worker profiles & recommendation factors.
  - `FinalWorkerSelectedScreen` & `PreviousWorkerRequestScreen`: Direct worker selection.
  - `ActiveJobScreen`: Active execution workspace with live status.
  - `CompletionEvidenceReviewScreen` & `CompletionConfirmationScreen`: Before/after photo audit & approval.
  - `PaymentScreen`: Cash / UPI Direct reconciliation.
  - `MaterialBillViewerScreen`: Itemized receipt audit viewer.
  - `CancelGigScreen`: Cancellation reason selection & policy notice.
  - `RescheduleGigScreen`: Reschedule proposal form.
  - `ReviewWorkerScreen`: Structured 3–4 objective MCQs.
- **Alerts & Profile (`alerts/`, `profile/`)**:
  - `CustomerNavigation3Screen`: Notifications & event alerts.
  - `CustomerNavigation4Screen`: Profile hub.
  - `CustomerAccountScreens`: In-app chat inbox, job history, settings, help/support FAQs, and sign out.

### C. Worker Screens (`lib/screens/worker/`)
- **Authentication**: `WorkerLoginScreen`, `WorkerRegisterScreen`.
- **Shell & Home (`home/`)**:
  - `WorkerMainScreen`: Persistent 4-tab shell (Home, Opportunities, My Jobs, Profile).
  - `WorkerHomeScreen`: Availability toggle, opportunity cards, upcoming job card, notifications.
- **Opportunities (`opportunities/`)**:
  - `WorkerNavigation2Screen`: Filterable opportunities ("All", "Emergency", "Conflicts").
  - `OpportunityDetailsScreen`: Guaranteed fixed wage, location, instructions, material preference, accept/reject.
  - `ConflictWarningDialog`: SRS 10.3 Schedule conflict alert modal.
- **My Jobs (`my_jobs/`)**:
  - `WorkerNavigation3Screen`: Tabbed list (Active & Upcoming, Completed), join requests shortcut, rookie track shortcut.
  - `WorkerActiveJobScreen`: Central workspace with progress stages, quick actions, customer contact.
  - `MultiWorkerInviteScreen`: SRS 16.2 Co-worker invitation (Equal Sharing 50/50 vs Rookie Mentorship).
  - `IncomingJoinRequestScreen`: SRS 16.1 Incoming invitation review & acceptance.
  - `RookieProgressionScreen`: SRS 15.2 Apprentice credits tracker (0.5 cr per job) and mentor feedback notes.
  - `MaterialBillUploadScreen`: SRS 7.2 Itemized parts entry & shop receipt photo upload.
  - `CompletionEvidenceUploadScreen`: SRS 19 Work completion photos & verification notes.
  - `WaitingConfirmationScreen`: Live awaiting customer confirmation status.
  - `WorkerPaymentConfirmationScreen`: SRS 19.1 Payment reconciliation & payment channel confirmation.
  - `ReviewCustomerScreen`: SRS 20 Structured 3–4 MCQs rating the customer.
  - `WorkerCancelRescheduleScreen`: SRS 21 Reason selection & reschedule proposal.
- **Profile (`profile/`)**:
  - `WorkerNavigation4Screen`: Profile summary, tariff guidelines dialog, sign out dialog.
  - `WorkerAvailabilityScreen`: SRS 10.1 Weekly recurring availability scheduler (Mon–Sun).
  - `WorkerVerificationScreen`: SRS 22 Multi-tier verification status (Tiers 1–4).

---

## 7. Design System Phase Status

### Completed Phases
- [x] **Phase 1**: Core design system tokens, Material 3 theming, shared primitives, and button styles.
- [x] **Phase 2**: Full Customer gig creation 3-step wizard, emergency tipping fallback, and lifecycle tracker.
- [x] **Phase 3**: Candidate comparison, worker profile, final selection, and active job workspace.
- [x] **Phase 4**: Complete post-completion audit chain (evidence upload, confirmation, cash/UPI payment, material bill upload/viewer).
- [x] **Phase 5**: Complete Worker lifecycle (opportunity inspection, conflict warnings, multi-worker invites, rookie progression, availability scheduler, multi-tier verification, structured reviews, cancel/reschedule).
- [x] **Phase 6**: Persistent bottom navigation architecture in both `CustomerMainScreen` and `WorkerMainScreen`.

### Remaining Frontend Polish & Backend Integration Phases
1. **Common Fallback Screens**:
   - `ForgotPasswordScreen` (Placeholder in MVP).
   - `GenericErrorScreen` / `NoInternetScreen` for offline connectivity drops.
   - `LanguageSelectionScreen` (English implemented; localization hooks ready).
2. **Dedicated Worker Earnings Analytics Screen**:
   - Detailed visual breakdown of daily, weekly, and monthly earnings, guild dividends, and patronage bonus payouts.
3. **Backend & Service Integration**:
   - Connect Dio HTTP client, Riverpod state management, and real REST/WebSocket endpoints per the development roadmap.
