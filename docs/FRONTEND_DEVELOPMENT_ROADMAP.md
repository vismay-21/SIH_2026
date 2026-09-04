# SIH26089 --- Frontend Development Roadmap

## Cooperative Gig Services Platform

**Team:** Frontend Team\
**Technology:** Flutter / Dart\
**Primary roles:** Customer and Worker

------------------------------------------------------------------------

## 1. Purpose

This is the working roadmap for the Frontend Team.

The goal is to build a complete, clean and usable Flutter application
for the MVP, covering both Customer and Worker workflows.

Build the frontend **screen-by-screen and feature-by-feature**, not as
one large implementation.

The frontend should work with **mock data first**. Backend and database
integration can be connected later without rewriting the screens.

The SRS remains the source of truth for product requirements.
fileciteturn2file2

------------------------------------------------------------------------

## 2. Frontend ownership

The Frontend Team owns:

-   Flutter application structure
-   Customer UI
-   Worker UI
-   Authentication screens
-   Role selection
-   Navigation
-   Forms
-   Job/gig screens
-   Worker information screens
-   Availability UI
-   Recommendation display
-   Completion and payment UI
-   Reviews
-   Chat UI
-   Notifications UI
-   Profile UI
-   Verification-related UI
-   Reusable components
-   Common styling
-   Loading, empty and error states
-   Localization-ready UI
-   Backend API integration later

The team does **not** decide backend business logic or the final
wage/recommendation formula.

------------------------------------------------------------------------

## 3. Important product rules

### Customer

The customer:

1.  Creates a gig.
2.  Sees the labour-price range before posting.
3.  Receives worker responses.
4.  Sees accepted workers.
5.  Sees exact wages and relevant worker information.
6.  Sees the system recommendation.
7.  Chooses the final worker.
8.  Can chat with the selected worker.
9.  Confirms completion.
10. Pays.
11. Reviews the worker.
12. Can cancel or request rescheduling.

### Worker

The worker:

1.  Maintains a profile and skills.
2.  Maintains availability.
3.  Receives eligible gigs.
4.  Sees the exact wage before accepting.
5.  Accepts or rejects.
6.  Performs the work.
7.  Uploads completion evidence.
8.  Can participate in multi-worker jobs.
9.  Can participate as an experienced worker or rookie.
10. Confirms payment receipt.
11. Reviews the customer.
12. Communicates through in-app chat.

These flows come from the SRS. fileciteturn2file0

### Rules the UI must never accidentally change

-   **No worker bidding.**
-   The system recommends; **the customer makes the final choice**.
-   Do not imply that the nearest worker is automatically the best
    worker.
-   Show the exact wage before worker acceptance.
-   Completion evidence does not itself complete the job.
-   Customer confirmation is required before payment.
-   Reviews are available only after completed gigs.
-   Additional workers must explicitly accept an invitation.
-   Only verified workers can be added as additional workers.
-   Live worker tracking is not part of the MVP.
-   Admin/community features are not part of the MVP.

------------------------------------------------------------------------

## 4. Recommended Flutter organization

The exact folder structure is a **recommendation**, not a strict rule.

A useful starting point is:

``` text
lib/
├── screens/
│   ├── common/
│   ├── customer/
│   └── worker/
├── widgets/
│   └── common/
├── theme/
├── localization/
├── models/
├── services/
├── repositories/
└── providers/
```

The important separation is:

-   Common screens/components
-   Customer screens
-   Worker screens

The team can decide the exact deeper structure and navigation.

Do not spend excessive time trying to create the perfect folder
structure. A simple structure that everyone follows is better.

------------------------------------------------------------------------

## 5. Keep the code modular

Do not put an entire feature into one huge Dart file.

For example:

``` text
CustomerJobDetailsScreen
    ├── WorkerCard
    ├── PriceCard
    ├── RecommendationCard
    ├── CompletionDialog
    └── CancelJobDialog
```

These can be separate reusable files where appropriate.

If a screen becomes difficult to read, move a meaningful section into:

-   a reusable widget;
-   a separate screen;
-   a separate dialog;
-   a separate form component.

Do not create a separate file for every tiny piece just to increase the
number of files.

The goal is easier development, testing and debugging.

------------------------------------------------------------------------

## 6. Build common/shared UI first

Create repeated UI elements once and reuse them.

Examples:

-   App buttons
-   Input fields
-   Cards
-   Status chips
-   Loading indicators
-   Error messages
-   Empty-state widgets
-   Confirmation dialogs
-   Date/time selectors
-   Image components
-   Job cards
-   Worker cards
-   Price displays
-   Review summaries
-   Notification tiles

If the same button style is used in 20 places, do not manually recreate
it 20 times.

------------------------------------------------------------------------

## 7. Centralize the visual design

The Frontend Team will decide the application's visual identity because
there are currently no fixed colors, fonts or design assets.

Decide centrally:

-   Primary/secondary colours
-   Background and text colours
-   Error/success/warning colours
-   Fonts and text styles
-   Border radius
-   Card style
-   Button style
-   Spacing
-   Icon style

Keep these in a central theme/design system rather than copying styles
throughout the application.

Flutter's Material 3 and centralized `ThemeData`/`ColorScheme` are
suitable foundations for this.

------------------------------------------------------------------------

## 8. Riverpod

**Recommendation: use Riverpod.**

Riverpod is a Flutter state-management tool.

### What is state?

State is information that can change while the application is running,
such as:

-   logged-in status;
-   selected role;
-   user profile;
-   current job;
-   loading status;
-   errors;
-   selected worker;
-   notifications;
-   availability.

Without proper state management, changing information can become
scattered across screens.

### What Riverpod provides

Riverpod helps the application:

-   store changing data in a structured way;
-   share data between screens;
-   update the UI when data changes;
-   keep shared state outside large UI files;
-   replace mock data with real data more easily.

A useful structure is:

``` text
Screen
   ↓
Riverpod provider
   ↓
Repository / service
   ↓
Mock data now
   ↓
Backend API later
```

Do not make every small value a complicated provider. Use Riverpod where
shared or changing state actually needs to be managed.

------------------------------------------------------------------------

## 9. Dio

**Recommendation: use Dio for backend communication.**

Dio is a Dart/Flutter HTTP client. In simple terms, it helps the Flutter
application communicate with the backend server.

``` text
Flutter app
     ↓
Dio
     ↓
Backend API
     ↓
Database
```

Avoid putting raw network requests into every screen.

Prefer:

``` text
Screen
   ↓
Provider
   ↓
Repository / service
   ↓
Dio
   ↓
API
```

During early development, the repository/service can return mock data.

The exact API endpoints will be agreed with the Backend Team.

------------------------------------------------------------------------

## 10. Authentication and role selection

Recommended flow:

``` text
Splash / App Start
        ↓
Login / Register
        ↓
Choose Role
   ┌────┴────┐
Customer   Worker
```

The two roles should have different application experiences.

### First frontend version

Use:

-   Email field
-   Password field
-   Login button
-   Register option

Initially, email and password are **placeholders**.

Until backend authentication and the database are connected:

-   fields do not need real authentication;
-   clicking Login should move to the appropriate next screen;
-   Register can proceed through the frontend flow.

When real authentication is available, connect the buttons to it.

Do not build fake authentication that looks like real security.

------------------------------------------------------------------------

## 11. Localization

The MVP language is **English**.

Hindi and other languages are future scope, but the SRS requires
centralized localization readiness. fileciteturn2file6

Do not hard-code user-facing text throughout the UI.

Instead of having English strings directly inside every screen, use
centralized translation/resource keys.

Conceptually:

``` text
English resource
       ↓
Language manager
       ↓
UI translation key
       ↓
Screen
```

Later:

``` text
Hindi resource
       ↓
same language manager
       ↓
same UI
```

The exact Flutter implementation can be decided by the team. The
important requirement is that adding another language later should not
require rewriting every screen.

------------------------------------------------------------------------

## 12. Loading, empty and error states

Every important data-driven screen should handle:

1.  Loading
2.  Success
3.  Empty
4.  Error

For example, an opportunity screen should not only contain the job list.
It should also have clear states for:

``` text
Loading jobs...
No suitable jobs available.
Unable to load jobs. Try again.
Jobs displayed here.
```

------------------------------------------------------------------------

## 13. Internet requirement

For this MVP, do **not** build offline database synchronization or
offline-first functionality.

The real application requires an internet connection because customers
and workers need to communicate and receive current job information.

Mock-data mode is still recommended during development.

------------------------------------------------------------------------

# 14. Customer screens

The following is the detailed Customer checklist.

The exact screen names and navigation arrangement are the team's
decision.

## 14.1 Authentication/onboarding

Build:

-   Splash
-   Login
-   Register
-   Role selection
-   Initial customer profile/setup if required

## 14.2 Customer home

Provide access to:

-   Create new gig
-   Active/current gigs
-   Upcoming gigs
-   Previous/completed gigs
-   Notifications
-   Profile

## 14.3 Create Gig

The form should support:

-   Service/work category
-   Work description
-   Location
-   Required date
-   Required time
-   Expected duration
-   Emergency/immediate status
-   Images
-   Additional instructions
-   Material procurement preference
-   Optional acceptance deadline

Before posting, show the applicable **labour-price range**.

Clearly distinguish labour/service cost from materials.
fileciteturn2file8

## 14.4 Material procurement

Let the customer choose:

``` text
Customer purchases materials
OR
Worker purchases materials
```

If the worker purchases materials, the worker can later upload a
bill/proof and the customer can view it.

Material disputes are outside MVP.

## 14.5 Posted gig

Show the current gig state, for example:

``` text
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

The visual design is the team's decision, but the UI should reflect the
actual job lifecycle. fileciteturn2file6

## 14.6 Accepted worker candidates

After workers accept, show:

-   Name
-   Exact wage
-   Experience
-   Structured review summary
-   Relevant recommendation factors
-   Relevant profile information

Clearly identify the system recommendation as a recommendation, not an
automatic assignment.

The customer must be able to choose any accepted worker.
fileciteturn2file11

## 14.7 Worker comparison/recommendation

Present worker differences clearly:

``` text
Worker
Experience
Wage
Quality/review summary
Relevant factors
Recommendation
```

Do not use presentation tricks that deliberately disadvantage rookies,
experienced workers, lower-priced workers or higher-priced workers.

The purpose is transparency.

## 14.8 Final worker selection

After selection:

-   show the selected worker;
-   update the gig state;
-   show the next available actions;
-   enable job-related chat.

**Chat becomes available after the customer finalizes the worker.**

## 14.9 Previous worker booking

Support:

``` text
Request previous worker
        ↓
Accept
OR Reject
OR Reschedule/alternative outcome
OR Open matching if unavailable
```

The previous worker is not automatically selected.

## 14.10 Active job

Show:

-   Job information
-   Selected worker
-   Date/time
-   Location
-   Instructions
-   Chat
-   Current status
-   Relevant actions

Do not add live worker tracking.

## 14.11 Completion confirmation

Worker uploads completion evidence.

Customer receives a completion request and can:

-   view evidence;
-   confirm completion;
-   proceed to payment.

The job must not appear fully completed just because evidence was
uploaded. fileciteturn2file16

## 14.12 Payment

Support the MVP payment states for:

-   Cash
-   UPI

The exact production payment integration is a backend decision.

## 14.13 Reviews

After completion:

-   Customer reviews Worker
-   Worker reviews Customer

Reviews contain approximately 3--4 structured multiple-choice questions.

The exact questions and scoring are pending, so do not hard-code a final
scoring system.

Reviews must not be available before completion. fileciteturn2file16

## 14.14 Cancellation/rescheduling

Customer should be able to:

-   Cancel
-   Request rescheduling
-   View the current response/status

Do not hard-code final cancellation fees because the exact policy is
pending/configurable.

## 14.15 Customer notifications

Support important events such as:

-   Worker accepted
-   Worker selected
-   Worker rejected
-   Previous worker response
-   Reschedule response
-   Cancellation
-   Completion request
-   Payment status
-   Review availability
-   Emergency/tip response

fileciteturn2file6

## 14.16 Customer profile

Include appropriate:

-   Personal information
-   Profile details
-   Previous jobs
-   Relevant reputation/review information
-   Settings
-   Language setting when implemented
-   Logout

Do not expose sensitive worker information unnecessarily.

------------------------------------------------------------------------

# 15. Worker screens

## 15.1 Authentication/onboarding

Build:

-   Splash
-   Login
-   Register
-   Role selection
-   Worker setup/profile

## 15.2 Worker home

Provide access to:

-   New opportunities
-   Current job
-   Upcoming jobs
-   Completed jobs
-   Notifications
-   Availability
-   Profile

## 15.3 Worker profile

Support:

-   Basic profile information
-   Skills
-   Experience
-   Verification status
-   Availability

Experience and quality are not the same thing. fileciteturn2file16

## 15.4 Worker verification

Represent verification states such as:

-   Information uploaded
-   Identity verified
-   Skill verified
-   Cooperative verified
-   Other applicable verification

Prototype verification may be simulated/manual.

Do not show a worker as verified merely because a document was uploaded.
fileciteturn2file5

## 15.5 Worker availability

Support:

### Weekly availability

Example:

``` text
Monday      9 AM – 6 PM
Tuesday     9 AM – 2 PM
Wednesday   Unavailable
```

### General availability

``` text
Available / Unavailable
```

### Conflict messages

-   Complete overlap → worker should not be allowed to accept.
-   Partial overlap → show a warning according to backend rules.

## 15.6 Worker opportunity list

Show eligible gigs.

A gig card may show:

-   Work category
-   Short description
-   Location/distance information where appropriate
-   Date/time
-   Duration
-   Emergency status
-   Exact wage
-   Relevant basic information

The worker must be able to:

``` text
Accept
Reject
```

The exact wage must be visible before acceptance. fileciteturn2file11

## 15.7 Worker gig details

Show:

-   Full work description
-   Location
-   Date/time
-   Expected duration
-   Emergency status
-   Images
-   Instructions
-   Material procurement mode
-   Acceptance deadline if present
-   Exact wage
-   Relevant information
-   Accept/Reject actions

## 15.8 Worker acceptance

Do **not** create bidding or quotation screens.

Correct flow:

``` text
Gig opportunity
      ↓
Worker sees exact wage
      ↓
Accept / Reject
```

## 15.9 Accepted/upcoming job

Show:

-   Job details
-   Appropriate customer information
-   Schedule
-   Location
-   Current state
-   Chat
-   Completion-related actions

## 15.10 Chat

Provide job-related in-app chat with the customer.

For this project, chat becomes available after the customer finalizes
the worker.

Public community chat is not part of MVP.

## 15.11 Multi-worker participation

Support:

-   Inviting verified workers
-   Receiving invitations
-   Accepting/rejecting join requests
-   Showing Rookie or Equal Sharing status

An invited worker must explicitly accept.

Do not expose private worker-to-worker compensation details.
fileciteturn2file13

## 15.12 Rookie participation

Support the UI for a worker participating as a rookie.

Show participation/experience progression where the backend provides it,
without presenting rookie status as automatically meaning poor quality.

The exact progression calculation is not a frontend responsibility.

## 15.13 Completion evidence

Allow the worker to:

-   Upload completion images/evidence
-   Submit the completion request

Then show that the job is waiting for customer confirmation.

## 15.14 Material bill/proof

If the worker purchased materials:

-   Upload bill/photo/proof
-   Show upload status
-   Make proof available for customer viewing

Material dispute resolution is not an MVP feature.

## 15.15 Payment confirmation

After customer payment, provide:

``` text
Confirm payment received
```

Do not mark the job fully completed before the required lifecycle states
are satisfied.

## 15.16 Worker reviews

After completion:

-   Worker reviews Customer
-   Use the final structured review questions

Do not build a final scoring model before the requirements are
finalized.

## 15.17 Cancellation/rescheduling

Support:

-   Worker cancellation where allowed
-   Rescheduling requests/responses
-   Current cancellation/rescheduling state
-   Find-another-worker flow where applicable

## 15.18 Worker notifications

Support:

-   New eligible gig
-   Job information update
-   Acceptance outcome
-   Previous-worker request
-   Multi-worker join request
-   Reschedule request
-   Cancellation
-   Completion
-   Payment
-   Emergency re-notification
-   Review availability

fileciteturn2file6

------------------------------------------------------------------------

# 16. Navigation

Do not freeze bottom navigation before reviewing all workflows.

Customer and Worker should have different navigation because their main
actions differ.

A possible starting point is:

``` text
Customer:
Home | My Jobs | Notifications | Profile

Worker:
Home | Opportunities | My Jobs | Notifications | Profile
```

This is a recommendation only.

Choose the final navigation based on:

-   frequency of actions;
-   number of screens;
-   simplicity;
-   clarity for non-technical users.

Do not add navigation buttons merely because a screen exists.

------------------------------------------------------------------------

# 17. Mock-data-first development

The frontend should not wait for the backend.

Create simple models and mock repositories/data for concepts such as:

``` text
Job
Worker
Customer
Notification
Review
Message
Availability
Payment
```

Then build screens against those models.

Later:

``` text
Mock Repository
       ↓
replace with
       ↓
API Repository using Dio
```

The UI should ideally not care where the data came from.

This lets Frontend and Backend teams work in parallel.

------------------------------------------------------------------------

# 18. Recommended implementation order

## F0 --- Foundation

Build:

-   Project structure
-   Theme
-   Colours
-   Typography
-   Common widgets
-   Basic navigation
-   Localization setup
-   Basic Riverpod setup
-   Mock-data structure
-   Loading/empty/error components

**Done:** future screens can reuse a clean foundation.

## F1 --- Authentication

Build:

-   Splash
-   Login
-   Register
-   Role selection
-   Customer entry flow
-   Worker entry flow

Use placeholder email/password behaviour.

**Done:** a developer can enter either role without a backend.

## F2 --- Customer foundation

Build:

-   Customer home
-   Customer navigation
-   Create gig
-   Gig form
-   Labour-price range display
-   Customer gig list
-   Gig details
-   Mock posted/seeking states

**Done:** a customer can simulate creating and viewing a gig.

## F3 --- Worker foundation

Build:

-   Worker home
-   Worker navigation
-   Worker profile
-   Skills
-   Verification display
-   Availability
-   Opportunity list
-   Opportunity details
-   Accept/reject

**Done:** a worker can simulate receiving and responding to a gig.

## F4 --- Selection and core lifecycle

Build:

-   Accepted candidates
-   Worker cards
-   Worker comparison
-   Recommendation display
-   Final worker selection
-   Selected-worker state
-   Active job
-   Job status display
-   Chat entry

**Done:** the main customer-to-worker selection flow works with mock
data.

## F5 --- Completion, payment and reviews

Build:

-   Completion evidence upload
-   Customer completion confirmation
-   Payment status
-   Worker payment confirmation
-   Completed job
-   Customer review
-   Worker review

**Done:** the normal job lifecycle can be demonstrated end-to-end.

## F6 --- Remaining MVP flows

Build:

-   Previous-worker request
-   Rescheduling
-   Cancellation
-   Emergency UI
-   Multi-worker invitations
-   Rookie/Equal Sharing states
-   Material bill/proof
-   Notifications
-   Remaining profile/settings screens

**Done:** all agreed MVP frontend workflows are represented.

## F7 --- Backend integration

After API contracts are available:

-   Connect authentication
-   Replace mock data with API data
-   Connect gig creation
-   Connect opportunities
-   Connect acceptance/rejection
-   Connect worker selection
-   Connect job states
-   Connect completion evidence
-   Connect payment status
-   Connect reviews
-   Connect chat
-   Connect notifications
-   Handle real API errors/loading states

Avoid rewriting screens unnecessarily. Replace the data source behind
the UI where possible.

------------------------------------------------------------------------

# 19. Testing

Testing is part of every phase.

For each major screen, check:

### UI

-   Correct appearance on normal phone sizes
-   Readable buttons and text
-   Long text handling
-   Understandable forms
-   Clear primary actions

### States

-   Loading
-   Success
-   Empty
-   Error

### Navigation

-   Correct next screen
-   Safe back navigation
-   Correct role sees correct screens

### Product rules

-   No bidding
-   Customer retains final choice
-   Exact wage shown before acceptance
-   Completion requires customer confirmation
-   Payment follows completion
-   Reviews only after completion
-   Additional workers require explicit consent

### Mock data

The feature should work without the backend.

------------------------------------------------------------------------

# 20. Usability and accessibility

The application is intended for people who may not be technically
experienced.

Therefore:

-   Use clear language.
-   Avoid unnecessary technical terms.
-   Make primary actions obvious.
-   Keep forms manageable.
-   Avoid crowded screens.
-   Use readable text sizes.
-   Give clear feedback after actions.
-   Do not depend only on colour to communicate status.
-   Make errors understandable.

Accessibility improvements should be included where practical without
making the first implementation unnecessarily complex.

------------------------------------------------------------------------

# 21. Do not build these for MVP

Do not accidentally expand the project with:

-   Worker bidding
-   Worker quotation system
-   Automatic worker assignment
-   Live worker tracking
-   Admin dashboard
-   Multiple cooperatives
-   Multiple service areas
-   Institutional customer workflows
-   Recurring maintenance contracts
-   Worker community
-   Open customer-worker community
-   Production Aadhaar integration
-   Production police verification integration
-   DigiLocker integration
-   e-Shram integration
-   Production insurance integration
-   Production pension integration
-   Material dispute-resolution system

These are outside the current MVP scope. fileciteturn2file0

------------------------------------------------------------------------

# 22. Working with the Backend Team

Before connecting real APIs, agree on:

``` text
Endpoint
Data to send
Data returned
Possible errors
Allowed role
Required job state
```

Do not guess the backend response structure.

If the backend is not ready, continue using mock data based on the
agreed expected structure.

------------------------------------------------------------------------

# 23. Working with the Algorithm Team

The frontend **displays** wage and recommendation results. It should not
independently recreate the wage or recommendation algorithm.

For example, the frontend may receive:

``` text
Worker
Exact wage
Recommendation status
Recommendation factors
```

and display them.

The actual calculation belongs to the backend/algorithm implementation.

The SRS intentionally leaves the exact wage formula and recommendation
weights pending. fileciteturn2file12

------------------------------------------------------------------------

# 24. Working with an AI coding assistant

Use AI coding tools in small, bounded tasks.

A useful request should specify:

``` text
Current feature:
What needs to be built:
Existing files to use:
What must not be changed:
Expected result:
```

Example:

``` text
Build the Customer Create Gig screen.

Use the existing theme and common input widgets.
Use mock data for now.
Do not change navigation or other customer screens.
Keep the screen modular.
Add loading/error handling where relevant.
Return the files changed and explain important decisions.
```

Avoid:

``` text
Build the entire frontend of the application.
```

Before accepting AI-generated changes:

-   inspect changed files;
-   run the application;
-   test the feature;
-   check unrelated files were not unnecessarily changed;
-   keep the code consistent with the existing structure.

------------------------------------------------------------------------

# 25. Definition of Done

A frontend feature is complete when:

### Basic

-   UI is implemented.
-   Navigation works.
-   Mock data works.
-   Common components are reused where appropriate.
-   Theme is respected.
-   User-facing text is localization-ready.

### Behaviour

-   Loading works where required.
-   Empty state works where required.
-   Error state works where required.
-   Main success flow works.
-   Invalid/unexpected actions are handled appropriately.

### Product correctness

-   The feature follows the SRS.
-   Future features have not become MVP dependencies.
-   Customer/Worker permissions are represented correctly.
-   Job lifecycle state is represented correctly.

### Code quality

-   No unnecessary giant Dart file.
-   No unnecessary duplicated UI.
-   No unnecessary hard-coded colours/styles.
-   No raw API calls scattered through screens.
-   No fake production authentication/security.
-   No unnecessary complexity.

### Verification

-   Run the application.
-   Test the feature manually.
-   Check affected screens on a normal phone layout.
-   Record important decisions in `decision.md` when needed.

------------------------------------------------------------------------

# 26. Final target

The final frontend should allow:

``` text
Open App
   ↓
Login/Register
   ↓
Choose Customer or Worker
   ↓
Enter role-specific application
   ↓
Use the relevant complete workflow
   ↓
Complete a gig
   ↓
Complete payment confirmation
   ↓
Submit the appropriate review
```

### Customer

``` text
Create Gig
   ↓
See Labour Price Range
   ↓
Wait for Worker Responses
   ↓
See Accepted Workers
   ↓
Compare Workers + Recommendation
   ↓
Choose Worker
   ↓
Chat
   ↓
Job
   ↓
Confirm Completion
   ↓
Payment
   ↓
Review Worker
```

### Worker

``` text
Profile + Availability
   ↓
Receive Eligible Gig
   ↓
See Exact Wage
   ↓
Accept / Reject
   ↓
Selected by Customer
   ↓
Chat
   ↓
Perform Job
   ↓
Upload Completion Evidence
   ↓
Customer Confirms
   ↓
Payment
   ↓
Confirm Payment Receipt
   ↓
Review Customer
```

The target is a frontend that is **simple, modular, transparent and easy
to change** as the Backend and Algorithm teams complete their parts.

The SRS remains the authority whenever a frontend decision conflicts
with a product requirement. fileciteturn2file2
