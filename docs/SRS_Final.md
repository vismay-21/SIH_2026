SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
Services Platform

SOFTWARE REQUIREMENTS SPECIFICATION Cooperative Gig Services Platform
for Household & Community Services

Smart India Hackathon 2026 --- Problem Statement SIH26089 Version: 1.1
(Restructured & Deduplicated) Document Status: Requirements Baseline
Primary Prototype Roles: Customer, Worker Prototype Cooperative Scope:
One Labour Cooperative operating in one City / Service Area

Editorial note on this version: This version reorganizes the original
v1.0 draft to remove sentence-level and section-level repetition (the
same rule restated in multiple places). No requirement, constraint,
role, workflow step, non-functional requirement, or pending/undecided
item from the original draft has been removed or altered in meaning.
Where a rule previously appeared in more than one section, it is now
stated once in its primary section and referenced elsewhere. All items
the team explicitly marked as not yet decided remain marked as pending
in this version --- nothing has been silently resolved or assumed.

                                                         Page 1

SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
Services Platform

Table of Contents 1. Document Purpose 2. Product Vision 3. Product Scope
(MVP, Out of Scope, Future Scope Register) 4. User Roles 5. Core Product
Principles 6. Customer Gig Creation 7. Labour Pricing 8. Worker
Opportunity and Acceptance 9. Geographic Matching 10. Worker
Availability 11. Acceptance Deadline 12. Customer Worker Selection and
Transparency 13. Worker Wage Algorithm 14. Recommendation Algorithm 15.
Rookie Worker System 16. Multi-Worker Jobs 17. Previous Worker Booking
18. Emergency Services 19. Completion and Payment Workflow 20. Reviews
and Reputation 21. Cancellation and Rescheduling 22. Verification 23.
Worker Welfare 24. Safety 25. Live Location 26. Communication (MVP and
Future Communities) 27. Cooperative Ownership and Platform Economics 28.
Institutional and Maintenance Services (Future) 29. Localization 30.
Notifications 31. Core Gig Lifecycle 32. Non-Functional Requirements 33.
Critical Product Constraints (Quick-Reference Index) 34. Pending
Requirements (Complete Register) 35. Product Definition Summary

                                                       Page 2

SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
Services Platform

1.  Document Purpose This Software Requirements Specification (SRS)
    defines the agreed product requirements for the Cooperative Gig
    Services Platform. This document is intended to become the single
    source of truth for the project. Future architecture, database
    design, API design, UI design, implementation phases, testing, and
    deployment decisions should be derived from this document. This SRS
    deliberately focuses on what the system must do and why. It does not
    prematurely freeze: • programming language • framework • system
    architecture • database technology • repository structure •
    deployment infrastructure • exact algorithm formulas •
    implementation roadmap This follows the requirements-first
    methodology used in the team's previous Student Buddy development
    process: requirements → product definition → architecture →
    database/design decisions → bounded implementation → verification
    and documentation.

2.  Product Vision The platform is a cooperative-owned digital
    marketplace for household and community labour services. It
    connects: • Customers who need household/community work; and •
    Workers belonging to a labour cooperative who can perform that work.
    The platform is not intended to be another conventional
    commission-driven service marketplace. Its primary differentiating
    principle is: Fair Matching instead of merely Smart Matching. The
    system should consider worker eligibility, skill, experience,
    quality, reliability, availability, workload/fairness, job timing,
    geography and other relevant factors rather than simply selecting
    the nearest or highest-rated worker. The platform should
    simultaneously provide: • Fairer opportunities for workers •
    Transparent pricing • Customer choice • Worker progression •
    Cooperative ownership • Verification and trust • Auditable job
    completion and payment • Emergency-service support • Worker welfare
    extensibility

3.  Product Scope 3.1 MVP Scope

                                                     Page 3

    SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
    Services Platform

The MVP consists of: • One labour cooperative • One city/service area •
Customer and Worker roles • Household/community gig posting • Worker
acceptance/rejection • Cooperative-defined labour price boundaries •
Algorithmically calculated worker-specific wages • Fair worker
recommendation • Customer choice among accepted workers • Worker
availability • Time-sensitive geographic matching • Emergency jobs •
Worker verification requirements • Multi-worker jobs • Rookie
participation • Completion evidence • Customer completion confirmation •
Payment confirmation • Structured two-way reviews •
Cancellation/rescheduling • In-app customer-worker chat • English
language support • Centralized localization architecture

3.2 Out of Scope for MVP The following are explicitly not MVP features
(these may be addressed in later phases): • Worker bidding • Worker
quotation/competitive pricing • Automatic worker assignment • Live
worker location tracking • Multiple simultaneous cooperatives • Multiple
service areas per prototype cooperative • Admin dashboard •
Institutional customer workflows • Quarterly maintenance contracts •
Recurring maintenance gigs • Worker community • Combined customer-worker
open community • Detailed welfare-benefit processing • Production
integrations with Aadhaar/police/DigiLocker/e-Shram • Material
dispute-resolution system • Production-grade insurance integration •
Production-grade pension integration

3.3 Future Scope Register

                                                     Page 4

SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
Services Platform

The table below consolidates every MVP-vs-future classification made in
this document into a single reference view.

Feature MVP Future Customer ✓ Worker ✓ One cooperative ✓ Multiple
cooperatives ✓ One city/service area ✓ Multiple service areas ✓ Worker
bidding Never Never Fair matching ✓ Emergency services ✓ Rookie system ✓
Multi-worker jobs ✓ Admin ✓ Institutional customers ✓ Quarterly
maintenance ✓ Recurring contracts ✓ e-Shram/welfare integration ✓
Advanced verification integrations ✓ Worker Community ✓ Worker +
Customer Open Community ✓ Hindi ✓ Live worker tracking No Not currently
planned

4.  User Roles 4.1 Customer The customer: • Creates a gig • Specifies
    work requirements • Sees the labour-price range before posting •
    Receives worker responses • Sees accepted workers • Sees their exact
    wages • Sees relevant worker information • Receives a system
    recommendation • Chooses the final worker • Confirms completion •
    Pays • Reviews the worker • Can cancel or request rescheduling •
    Communicates through in-app chat

                                                    Page 5

    SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
    Services Platform

4.2 Worker The worker: • Maintains a worker profile • Specifies skills •
Maintains availability • Receives eligible gigs • Accepts/rejects gigs •
Sees exact wage before acceptance • Performs work • Uploads completion
evidence • Can add other verified workers • Can participate as an
experienced worker or rookie • Confirms payment receipt • Reviews
customers • Communicates through in-app chat

4.3 Cooperative The cooperative is the fundamental organizational
entity. The prototype contains one cooperative operating in one
city/service area. The cooperative conceptually: • Owns/operates the
platform • Defines labour-price boundaries • Manages its worker
ecosystem • Provides the organizational context for worker verification
• Provides the foundation for future cooperative governance and welfare
functionality Pending: Detailed cooperative governance/economic
mechanics are not frozen in this SRS.

4.4 Administrator --- Future An administrator is a future role. A future
version may have three login roles: Customer, Worker, Admin. The future
administrator may access: • Worker records • Customer records • Active
jobs • Completed jobs • Complaints • Verification records • Cooperative
operational information Note: No admin dashboard is required in the
current prototype.

5.  Core Product Principles 5.1 No Worker Bidding Workers shall never
    bid against one another for a gig. There shall be no: • Lowest-bid
    competition • Worker quotation competition • Customer negotiation
    between workers • Auction-style pricing

                                                       Page 6

    SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
    Services Platform

The cooperative establishes the pricing boundaries.

5.2 Cooperative Price Boundary The cooperative defines: Minimum Labour
Price ← Algorithm → Maximum Labour Price. The customer sees the
applicable range before posting the gig. After workers accept the
opportunity, the system calculates an exact wage for each accepted
worker. Note: Example only --- Labour range Rs. 550-Rs. 800: Worker A
Rs. 550, Worker B Rs. 680, Worker C Rs. 800. The exact value depends on
the wage algorithm (see Section 13, pending).

5.3 Fair Matching The system shall not use nearest worker = best worker
as its fundamental logic. The system shall first determine eligibility,
then calculate recommendation/fairness signals. Potential factors
include: • Skill match • Verification status • Experience • Completed
comparable jobs • Structured review quality • Reliability • Cancellation
history • Availability • Workload • Geographic practicality • Job timing
• Previous customer-worker relationship • Wage • Completion efficiency •
Rookie progression Pending: The final formula and weights remain pending
(see Section 34).

6.  Customer Gig Creation The customer shall be able to create a
    work/gig request. A gig should contain, where applicable: •
    Service/work category • Work description • Location • Required date
    • Required time • Expected duration • Emergency/immediate status •
    Images • Additional instructions • Material procurement preference •
    Optional acceptance deadline Before posting, the customer shall see
    the applicable labour-price range.

7.  Labour Pricing

                                                       Page 7

    SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
    Services Platform

7.1 Labour Only The platform's primary calculated price represents
labour/service cost. Materials are separate.

7.2 Material Procurement The customer decides between: • Option A ---
Customer purchases materials: The customer obtains the required
materials. • Option B --- Worker purchases materials: The worker
purchases the required materials. The worker uploads a bill/photo/proof,
the customer can see the proof, and the customer is expected to honour
legitimate material bills. The application may recommend that customers
purchase materials themselves where practical. The worker does not
decide the procurement mode. Pending: Material disputes are outside the
MVP.

8.  Worker Opportunity and Acceptance After a customer posts a gig: •
    The system identifies eligible workers • Eligible workers receive
    the opportunity • Each worker can Accept or Reject • Workers see the
    exact wage before accepting • Accepted workers become candidates •
    Customer sees accepted candidates • System recommends a worker •
    Customer makes the final selection Note: The above list is
    sequential (steps 1-8). There is no automatic assignment.

9.  Geographic Matching Geographic eligibility depends on the amount of
    time available before the job.

9.1 Immediate / Emergency For an immediate job approximately 15-30
minutes away: initial matching radius ≈ 5 km; priority is given to
practically nearby eligible workers.

9.2 Future Jobs For jobs scheduled several hours later, the next day, or
approximately 4-5+ hours later, the eligible notification radius may
expand to approximately 15-20 km. Pending: The exact radius policy
remains configurable (see Section 34).

9.3 Important Constraint Distance does not automatically decide which
worker receives the job. It primarily determines geographic
eligibility/notification. The worker chooses whether to accept. The
customer chooses which accepted worker to select.

10. Worker Availability 10.1 Weekly Availability

                                                      Page 8

    SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
    Services Platform

Workers can define recurring availability. Note: Example: Monday 9 AM-6
PM; Tuesday 9 AM-2 PM; Wednesday unavailable.

10.2 Availability Control Workers shall also have a simple Available /
Unavailable control.

10.3 Conflict Detection The system shall identify obvious schedule
conflicts: • Complete overlap: The worker should not be allowed to
accept the gig. • Partial overlap: The system warns the worker. The
worker may still accept subject to the defined rules.

11. Acceptance Deadline By default, a gig has no mandatory acceptance
    deadline. The customer may optionally specify a deadline. Therefore:
    default → no deadline; customer-selected deadline → workers must
    respond before the selected deadline.

12. Customer Worker Selection and Transparency 12.1 Selection
    Information After worker acceptance, the customer shall see: •
    Worker name • Exact wage • Experience • Structured review summary •
    Relevant recommendation factors • Other relevant profile information
    The system recommends one worker. However, the customer can choose
    any accepted worker. The recommendation is advisory rather than
    mandatory.

12.2 Transparent Worker Tradeoffs The UI may present meaningful
differences such as:

Worker Experience Wage Rookie Lower Rs. 550 Experienced Medium Rs. 680
Highly experienced High Rs. 800

However, the interface shall not deliberately use psychological
anchoring or presentation tricks that systematically disadvantage
rookies, highly experienced workers, lower-priced workers, or
higher-priced workers. The purpose is transparency, not manipulation.

13. Worker Wage Algorithm Pending: The exact algorithm is intentionally
    not finalized in this SRS. The algorithm may consider: • Experience
    • Completed jobs • Comparable completed jobs

                                                               Page 9

    SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
    Services Platform

    • Quality • Structured reviews • Completion efficiency • Reliability
    • Cancellation history • Emergency status • Availability • Job
    characteristics • Other fairness-related signals The wage must
    remain within the cooperative's defined minimum/maximum boundary,
    except for explicitly defined emergency/tip treatment (see Section
    18).

13.1 Important Algorithm Constraint The system shall not assume faster
worker = better worker. A worker who completes a job faster should not
automatically receive a higher performance score. Performance should
consider quality, comparable job complexity, customer satisfaction,
completion reliability, and appropriate completion time. The algorithm
must avoid incentivizing unsafe rushing or poor-quality work.

14. Recommendation Algorithm The recommendation algorithm is a core
    product component. It shall not merely display factors in the UI ---
    the factors agreed by the team shall actually influence the
    recommendation logic. Potential inputs include: • Skill match •
    Verification • Experience • Quality • Comparable job history •
    Availability • Reliability • Cancellation behaviour •
    Workload/fairness • Geographic practicality • Price •
    Repeat-customer relationship • Completion efficiency • Rookie
    progression Pending: The final mathematical model is pending. The
    algorithm should also be configurable/versionable so that the team
    can improve it later without changing the overall product workflow.

15. Rookie Worker System 15.1 Direct Participation A rookie worker can
    accept jobs directly. The system does not permanently restrict
    rookies from working. A rookie may have lower experience, lower job
    history, lower reputation initially, and lower algorithmic wage ---
    this does not mean the rookie is automatically excluded.

15.2 Learning Through Experienced Workers

                                                       Page 10

SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
Services Platform

An experienced worker can add a rookie to a job. The flow is: • Worker A
accepts a job. • Worker A decides a rookie can participate. • Worker A
selects a verified cooperative worker. • Worker B receives a join
request. • Worker B decides whether to Accept or Reject. • If Worker B
accepts, Worker A classifies the participation as Rookie. • The system
records participation. • Participation contributes to Worker B's
experience progression according to a configurable weighting. Note:
Example only: 1 participation = 0.5 equivalent job experience. Pending:
The exact weighting is not yet frozen.

15.3 Rookie Compensation The application shall not record how much
Worker A pays Worker B. The platform therefore does not manage or expose
rookie compensation amount, private worker-to-worker payment split, or
private negotiation. The platform records participation/classification
for experience purposes only.

16. Multi-Worker Jobs 16.1 Adding Workers An accepting worker can add
    other verified cooperative workers. Only existing verified
    cooperative workers can be added --- an unverified person cannot
    directly participate. The additional worker receives a join request
    and must explicitly accept.

16.2 Classification The inviting worker classifies the additional worker
as: • Rookie: The additional worker is participating in a
learning/progression relationship. • Equal Sharing: The additional
worker participates as an equal-sharing worker. The application records
the classification. It does not record the private financial split.

16.3 Payment The customer does not pay extra simply because multiple
workers participate --- the customer pays the agreed labour amount. For
normal multi-worker jobs, the workers themselves determine how the
labour amount is divided. The application does not algorithmically
enforce the internal worker-to-worker split.

16.4 Required Worker Count The application may recommend how many
workers appear necessary. Note: Example: Recommended workforce: 2
workers. However, if the accepting worker chooses to perform the work
with fewer workers, the application does not automatically block the
job. The system may use successful solo completion as a future
performance signal, provided that the algorithm does not reward unsafe
rushing.

17. Previous Worker Booking A customer can request a worker they have
    previously used. If the previous worker is online: the worker
    receives the request; worker accepts/rejects/reschedules; customer
    receives the result.

                                                       Page 11

    SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
    Services Platform

If the worker is offline: the customer receives options such as "Wait
for \[Worker\]" or "Open to Other Workers." When the worker becomes
available, they receive a notification and can accept, reject, or
request/reschedule. The customer is notified accordingly. If the
customer chooses another worker, the gig enters the open matching flow.

18. Emergency Services The customer can mark a gig as Emergency. An
    emergency gig receives special treatment: • Emergency service
    category • Emergency surcharge • Additional worker incentive •
    Faster matching • Smaller initial geographic radius (see Section
    9.1)

18.1 Emergency No-Acceptance Flow If no eligible worker accepts: •
System tells the customer that the service is currently unavailable. •
Customer is offered the option to add a tip. • Customer may add a tip. •
Eligible workers are notified again. • The compensation is displayed
separately. Note: Example: Algorithmic wage Rs. 147 + Tip Rs. 20 =
Worker receives Rs. 167. The current requirement is that the tip goes
100% to the worker. Pending: This tip policy may be revised later. Exact
emergency surcharge, worker incentive, and emergency definition also
remain pending (see Section 34).

19. Completion and Payment Workflow The completion workflow is
    intentionally controlled: • Step 1: Worker completes the job. • Step
    2: Worker uploads completion images/evidence. • Step 3: Customer
    receives a completion request. • Step 4: Customer confirms
    completion. • Step 5: The job moves to payment. • Step 6: Customer
    pays (supported modes: cash, UPI). • Step 7: Worker confirms receipt
    of payment. • Step 8: The gig becomes fully completed. • Step 9:
    Both parties become eligible for the structured review. The worker
    cannot independently mark the job as completed without customer
    confirmation.

19.1 Payment Confirmation Payment confirmation is part of the job audit
chain. For cash: customer confirms the amount and worker confirms
receipt. For UPI: the system should eventually support an appropriate
payment confirmation mechanism. Pending: The exact production payment
integration remains pending.

20. Reviews and Reputation

                                                       Page 12

    SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
    Services Platform

The system shall not rely solely on conventional star ratings. After
completion, the customer reviews the worker and the worker reviews the
customer. Each review contains approximately 3-4 multiple-choice
questions using radio-button style selection. Pending: The exact
questions and scoring system remain pending.

20.1 Review Rules Reviews: • Are available only after completed gigs •
Cannot be submitted before completion • Are two-way • Contribute to
reputation/performance • May influence future recommendation The system
should prevent pre-job/fake reputation accumulation.

20.2 Experience vs Quality The system shall explicitly distinguish: •
Experience --- e.g. completed jobs, participation in jobs, relevant
experience, rookie progression. • Quality --- e.g. structured review
results, successful completion, reliability, comparable-job performance.
A worker with 100 jobs is not automatically a better worker than someone
with 30 high-quality jobs.

21. Cancellation and Rescheduling 21.1 Cancellation Both parties can
    cancel. Customer cancellation may hurt customer reputation and
    generate a cancellation fee. Pending: The exact fee is configurable.
    The example discussed during requirements elicitation included
    time-dependent charges, but those example amounts are not frozen
    requirements. Exact cancellation charges and timing thresholds
    remain pending (see Section 34). Worker cancellation may hurt worker
    reputation and causes the customer to be asked whether they want
    another worker. If the customer chooses "Yes, find another worker,"
    the gig is re-listed/opened to eligible workers. If the customer
    chooses "No," the job stops.

21.2 Rescheduling Rescheduling is preferred over unnecessary
cancellation where possible. The customer can request a reschedule; the
worker must confirm. A reschedule request therefore has at least three
outcomes: requested, accepted, or rejected/alternative outcome. Pending:
Exact scheduling constraints remain to be finalized.

21.3 Configurable Cancellation Policy Cancellation charges shall be
configurable, allowing the cooperative to define policies such as
cancellation close to job time, cancellation far from job time, and
emergency-specific cancellation. The SRS does not freeze exact rupee
values.

22. Verification Worker verification is a core trust requirement. The
    system should conceptually distinguish: • Uploaded information •
    Identity verified

                                                     Page 13

    SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
    Services Platform

    • Skill verified • Cooperative verified • Police/antecedent status
    where applicable • Other category-specific verification Note: The
    prototype may use simulated/manual verification rather than live
    integrations.

22.1 Sensitive Service Verification Certain sensitive service categories
may require additional verification. The system shall support
category-specific verification requirements. Pending: The exact
categories and verification procedures remain pending.

22.2 Future Verification Integrations Potential future integrations
include: • Aadhaar-compatible identity verification • Police/antecedent
verification • DigiLocker-backed documents • Recognized skill
certificates • Other government/cooperative verification mechanisms
Pending: These must be validated separately before production
implementation. Exact verification levels, Aadhaar integration, police
verification, skill certificate verification, and DigiLocker integration
remain pending (see Section 34). The product must not claim that a
worker is verified simply because a document was uploaded.

23. Worker Welfare Worker welfare is part of the product vision.
    However, the exact welfare package is not yet frozen. The SRS
    therefore establishes welfare as an extensible requirement rather
    than inventing specific benefits. Future possibilities include: •
    e-Shram-linked worker services • Insurance • Pension •
    Healthcare/social-security schemes • Cooperative welfare programs
    The system must not claim enrollment in a welfare program without
    verifiable status. Pending: Detailed welfare requirements (exact
    schemes, eligibility, e-Shram workflow, insurance, pension,
    healthcare, cooperative welfare) will be defined separately (see
    Section 34).

24. Safety The SRS includes a planned safety layer. Potential safety
    functionality includes: • SOS • Emergency contact • Job check-in •
    Job check-out • Customer identity display • Worker identity display
    • Incident reporting

                                                         Page 14

    SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
    Services Platform

    • Cooperative escalation • Possible active-job location sharing
    Pending: These require further detailed safety specification (exact
    SOS flow, emergency contact flow, check-in/check-out, incident
    reporting, active-job location sharing, cooperative escalation
    remain pending --- see Section 34).

25. Live Location The platform shall not implement live worker tracking
    in the current scope. The worker's job location can be shown where
    necessary. Live worker location is explicitly different from
    geographic eligibility/matching radius (Section 9) --- the latter is
    required; continuous live tracking is not.

26. Communication 26.1 MVP Customer and worker shall have in-app chat
    for job-related communication.

26.2 Pending Pending: Calling/voice communication remains a team
decision. The SRS does not assume calling is an MVP requirement. The
policy regarding sharing phone numbers, off-platform communication, and
contact leakage also remains pending.

26.3 Future Worker Community A future Worker Community shall be
considered, separate from ordinary job chat. Potential functionality:
worker-to-worker chat, discussions, knowledge sharing, work showcasing,
community interaction.

26.4 Future Open Community A separate future Open Community shall
support interaction between workers and customers. Potential
functionality: workers showcasing their work, workers and customers
communicating, community discussion, discovery, engagement. The Worker
Community and Open Community should not be treated as dependencies for
the MVP job marketplace. Pending: For future Worker Community and Open
Community: moderation, reporting, content policy, abuse prevention,
privacy, discovery, and work-showcase rules remain pending (see Section
34).

27. Cooperative Ownership and Platform Economics The platform is
    fundamentally cooperative-owned rather than a conventional
    investor-owned marketplace extracting transaction commission from
    workers. The prototype represents one cooperative. Future versions
    should conceptually support multiple cooperatives. The platform
    shall not take a transaction commission from worker fares. A
    possible cooperative operational model is: cooperative operating
    cost ÷ participating workers to determine a small monthly
    platform/operational contribution. Pending: The exact formula is
    pending. Potential future revenue sources may include cooperative
    operational contributions, sponsorships, and advertisements ---
    these are future possibilities and not MVP requirements. Exact
    monthly operational fee, governance, voting, surplus distribution,
    ownership structure, and federation economics remain pending (see
    Section 34).

28. Institutional and Maintenance Services (Future)

                                                      Page 15

    SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
    Services Platform

Institutional customers and recurring maintenance are future scope.
Future functionality may include: • Institutions • Apartment/community
organizations • Recurring contracts • Quarterly maintenance • Scheduled
maintenance • Multiple workers assigned to recurring work These are not
part of the current gig category.

29. Localization The MVP language is English. Hindi and other languages
    are future scope. However, the product shall be designed for
    centralized localization. User-facing text should reference
    translation/resource keys rather than being hard-coded throughout
    the UI. Note: Conceptually: English Resource → Language Manager → UI
    Translation Keys. A future Hindi resource can then be added without
    rewriting the UI. The implementation technology is not prescribed by
    this SRS.

30. Notifications The platform shall provide notifications for important
    state changes.

30.1 Customer Notifications • Worker accepted • Worker selected • Worker
rejected • Previous worker available • Previous worker accepted/rejected
• Reschedule response • Cancellation • Completion request • Payment
status • Review availability • Emergency availability/tip response

30.2 Worker Notifications • New eligible gig • Job information update •
Acceptance outcome • Previous-worker request • Multi-worker join request
• Reschedule request • Cancellation • Completion • Payment • Emergency
tip re-notification • Review availability

                                                     Page 16

SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
Services Platform

Notifications should contain actionable information where appropriate.

31. Core Gig Lifecycle The conceptual lifecycle is: Draft → Posted /
    Seeking Workers → Workers Accept / Reject → Accepted Candidates →
    Customer Selects Worker → Scheduled / Active → Completion Evidence
    Submitted → Customer Confirms Completion → Payment → Worker Confirms
    Payment → Completed → Two-Way Review

Possible alternate states include: cancelled; reschedule requested;
reschedule confirmed; unavailable/no worker accepted.

32. Non-Functional Requirements NFR-01 --- Usability. The main Customer
    and Worker workflows should be understandable to users without
    technical expertise. NFR-02 --- Transparency. The system should
    clearly communicate: labour-price range, exact worker wage, material
    separation, worker selection factors, emergency tip. NFR-03 ---
    Fairness. The recommendation system shall not depend on a single
    simplistic factor such as distance, star rating, number of jobs, or
    completion speed. NFR-04 --- Reliability. Important gig, payment and
    review state changes must remain consistent. NFR-05 --- Security.
    Authentication, authorization, personal information and verification
    data must be protected. Detailed security architecture remains a
    later design stage. NFR-06 --- Privacy. Sensitive worker information
    shall not be unnecessarily exposed to customers or other workers.
    NFR-07 --- Extensibility. The system should be extensible toward
    multiple cooperatives, admin, welfare, verification, additional
    languages, institutional customers, and communities. NFR-08 ---
    Configurability. Policies such as cancellation charges, price
    ranges, emergency incentives, geographic radius, and algorithm
    parameters should be configurable wherever practical. NFR-09 ---
    Auditability. The system should preserve important events such as
    posting, acceptance, selection, cancellation, completion evidence,
    customer confirmation, payment, payment acknowledgement, and review.
    NFR-10 --- Maintainability. Business rules should be structured so
    that future changes do not require rewriting unrelated product
    functionality. NFR-11 --- Localization Readiness. User-facing
    strings must be centrally manageable.

33. Critical Product Constraints (Quick-Reference Index) The following
    constraints are considered particularly important. Each is fully
    specified in its primary section; this index exists only for quick
    lookup and does not introduce new rules.

Constraint Statement See

1.  No bidding Workers must never compete through bids. Section 5.1

2.  Customer retains The algorithm recommends; the customer decides.
    Sections 8, 12.1 choice

3.  Fairness is algorithmic Fairness must exist in the actual
    recommendation logic, not merely Sections 5.3, 14 in the UI.

                                                             Page 17

    SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
    Services Platform

Constraint Statement See

4.  Rookie inclusion Rookies must be able to obtain work and progress.
    Section 15

5.  Quality ≠ quantity Completed-job count cannot be treated as quality
    by itself. Section 20.2

6.  Speed ≠ quality Fast completion must not automatically imply
    superior performance. Section 13.1

7.  Verified workers only Unverified individuals cannot be directly
    added to jobs. Section 16.1

8.  Explicit join consent An added worker receives a request and chooses
    whether to join. Sections 15.2, 16.1

9.  Private worker The platform does not record rookie compensation or
    internal Sections 15.3, compensation worker-to-worker payment
    splits. 16.3

10. Completion requires Worker completion evidence alone does not
    finalize a job. Section 19 customer confirmation

11. Payment follows Payment occurs after customer confirmation. Section
    19 completion

12. No worker transaction The platform does not deduct a transaction
    commission from Section 27 commission worker fares.

13. Future features stay Admin, institutional maintenance, welfare
    integrations and Sections 3.2, 3.3 future communities are not
    allowed to silently become MVP dependencies.

14. Pending Requirements (Complete Register) The following decisions are
    deliberately not finalized. This register consolidates every pending
    item flagged anywhere in this document --- nothing here has been
    decided, assumed, or removed.

Algorithm • Exact wage formula • Factor weights • Recommendation formula
• Fairness constraints • Workload calculation • Comparable-job
methodology • Efficiency calculation • Rookie weighting • Performance
reward mechanism

Reviews • Exact 3-4 questions • Scoring model • Aggregation • Review
moderation

Verification • Exact verification levels • Aadhaar integration • Police
verification • Skill certificate verification

                                                              Page 18

SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
Services Platform

     • DigiLocker integration
     • Sensitive-category rules

Welfare • Exact welfare schemes • Eligibility • e-Shram workflow •
Insurance • Pension • Healthcare • Cooperative welfare

Safety • Exact SOS flow • Emergency contact flow • Check-in/check-out •
Incident reporting • Active-job location sharing • Cooperative
escalation

Communication • Calling • Contact-number sharing • Off-platform leakage
policy

Cancellation • Exact cancellation charges • Exact timing thresholds

Emergency • Exact emergency surcharge • Exact worker incentive • Exact
emergency definition

Multi-worker • Exact recommended workforce calculation • Exact
experience weighting • Performance effects of solo completion

Cooperative Economics • Exact monthly operational fee • Governance •
Voting • Surplus distribution • Ownership structure • Federation
economics

Production

                                                   Page 19

SIH26089 - SRS v1.1 (Restructured, Deduplicated) Cooperative Gig
Services Platform

     • Authentication
     • Payment gateway
     • Data retention
     • Security
     • Privacy
     • Legal/compliance requirements

Community (Future Worker Community and Open Community) • Moderation •
Reporting • Content policy • Abuse prevention • Privacy • Discovery •
Work-showcase rules

35. Product Definition Summary The MVP is a cooperative-owned household
    and community labour marketplace operated by one labour cooperative
    in one city/service area. A customer posts a gig without asking
    workers to bid; the cooperative establishes the labour-price
    boundary; eligible verified workers receive the opportunity
    according to time-sensitive geographic eligibility; workers
    independently choose whether to accept; the platform calculates an
    exact worker-specific wage; the customer compares accepted workers
    on transparent information and retains final selection authority
    through a fair-matching recommendation; workers may work
    individually or invite other verified cooperative workers, who must
    explicitly consent to join; work proceeds through an auditable
    evidence → confirmation → payment → acknowledgement chain; both
    parties then provide structured two-way review; and emergency work
    follows a separate, faster workflow with an optional customer tip
    when no worker accepts. Verification, worker welfare, safety,
    cooperative ownership, localization, and future community
    functionality are part of the broader product vision; their
    unresolved details are explicitly marked as pending (Section 34)
    rather than invented. The future product can expand toward: multiple
    cooperatives, institutional customers, recurring maintenance,
    government/welfare integrations, advanced verification,
    administration, Worker Community, Worker + Customer Open Community,
    and additional languages.

This SRS therefore establishes the current product boundary: a
cooperative-owned, fair-matching, non-bidding local labour marketplace
where customers retain choice, workers retain agency, and the platform
creates a transparent and auditable path from work request to worker
payment and reputation.

                                                    Page 20


