# SIH26089 --- Algorithm & Recommendation Team Roadmap

## Cooperative Gig Services Platform

**Team:** Algorithm & Recommendation Team\
**Main responsibility:** Build and test the algorithmic logic that
supports fair worker matching and worker-specific wages.

------------------------------------------------------------------------

# 1. Purpose

The Algorithm Team is responsible for turning the SRS requirements
around **wage calculation, worker recommendation, fairness,
eligibility-related calculations and worker progression** into clear,
testable algorithms.

The SRS intentionally does **not** provide a final mathematical formula.
Therefore, the team has freedom to research, compare approaches and
choose a suitable model.

The important requirement is that the final approach must satisfy the
SRS constraints and be explainable, testable and changeable. The SRS
remains the source of truth. fileciteturn4file4

------------------------------------------------------------------------

# 2. What the team owns

The team should work on:

-   Worker-specific wage calculation
-   Fair worker recommendation
-   Factor definitions and calculations
-   Worker eligibility-related calculations
-   Geographic/time-based matching logic
-   Availability/conflict-related algorithmic checks where required
-   Workload/fairness calculation
-   Comparable-job methodology
-   Completion-efficiency calculation
-   Rookie experience progression
-   Emergency matching treatment
-   Recommended workforce count where implemented
-   Algorithm testing and simulation
-   Algorithm configuration/versioning
-   Recommendation explanations
-   Documentation of assumptions and limitations

The team does **not** own:

-   Flutter UI implementation
-   Database implementation
-   Authentication
-   Payment implementation
-   Chat implementation
-   Final API implementation

Those areas should be coordinated with the relevant teams.

------------------------------------------------------------------------

# 3. Most important principle

The goal is **Fair Matching**, not simply Smart Matching.

Do not build:

``` text
Nearest worker → recommended worker
```

or:

``` text
Highest rated worker → recommended worker
```

The SRS expects the system to consider multiple meaningful factors such
as skill, experience, quality, reliability, availability,
workload/fairness, geography, timing and rookie progression.
fileciteturn4file5

The customer must still have the final choice.

``` text
Algorithm
    ↓
Recommendation
    ↓
Customer chooses
```

The algorithm must **recommend**, not automatically assign.

------------------------------------------------------------------------

# 4. Start with understanding the data

Before deciding the formula, define what information the algorithm
actually has available.

## Worker information

Potential inputs:

-   Skills
-   Verification status
-   Experience
-   Completed jobs
-   Comparable completed jobs
-   Quality/review information
-   Reliability
-   Cancellation history
-   Availability
-   Current workload
-   Rookie progression
-   Completion performance

## Job information

Potential inputs:

-   Service category
-   Required skills
-   Job characteristics
-   Location
-   Date/time
-   Expected duration
-   Emergency status
-   Material procurement mode
-   Acceptance deadline
-   Other relevant complexity information

## Relationship information

Potential inputs:

-   Previous customer-worker relationship
-   Previous comparable jobs
-   Previous completion history
-   Previous cancellations

These inputs are based on the SRS; the team should decide the exact
representation of each input. fileciteturn3file3

------------------------------------------------------------------------

# 5. First task --- Create a Factor Dictionary

Before writing a large formula, create a simple document/table defining
every factor.

Example:

  ---------------------------------------------------------------------------------
  Factor         Meaning        Possible range Data source    Used in
  -------------- -------------- -------------- -------------- ---------------------
  Skill Match    How closely    0--1           Worker + Job   Recommendation
                 worker skills                                
                 match the job                                

  Reliability    History of     0--1           Job history    Recommendation/Wage
                 successfully                                 
                 completing                                   
                 accepted work                                

  Workload       Current        Team decision  Job history    Fairness
                 workload                                     
                 compared with                                
                 other workers                                

  Experience     Relevant       Team decision  Job history    Wage/Recommendation
                 experience                                   
  ---------------------------------------------------------------------------------

The exact ranges and calculations are for the team to decide.

The important rule is:

> Every factor used by the algorithm should have a clear meaning.

Avoid creating vague factors such as `worker_score` without explaining
what contributes to it.

------------------------------------------------------------------------

# 6. Second task --- Separate eligibility from recommendation

This distinction is very important.

First:

``` text
All workers
     ↓
Eligibility checks
     ↓
Eligible workers
```

Then:

``` text
Eligible workers
     ↓
Workers receive opportunity
     ↓
Workers Accept / Reject
     ↓
Accepted workers
     ↓
Recommendation algorithm
```

The algorithm should not recommend a worker who should not be eligible
for the job.

------------------------------------------------------------------------

# 7. Geographic matching

Geography is primarily an **eligibility/practicality** factor, not a
simple quality ranking.

The SRS currently gives approximate examples:

### Immediate/emergency

Initial matching radius:

``` text
≈ 5 km
```

### Future jobs

The radius may expand to approximately:

``` text
15–20 km
```

The exact radius remains configurable. fileciteturn3file4

The team should therefore design the geographic logic so that values
such as radius can be changed through configuration rather than buried
inside code.

Example:

``` text
Job timing
     ↓
Determine applicable radius
     ↓
Check worker geographic eligibility
     ↓
Eligible / Not eligible
```

Do not turn this into:

``` text
Closer worker = automatically better worker
```

------------------------------------------------------------------------

# 8. Availability and conflict logic

Worker availability should be considered before a worker becomes a
practical candidate.

The SRS requires:

-   recurring weekly availability;
-   Available/Unavailable control;
-   complete-overlap conflict blocking;
-   partial-overlap warning. fileciteturn3file4

The Algorithm Team can define the calculation clearly, while the Backend
Team can enforce the resulting business rule.

Example:

``` text
Gig: 2 PM – 5 PM

Worker A: 2 PM – 5 PM unavailable
→ Reject eligibility

Worker B: 4 PM – 6 PM existing job
→ Partial conflict
→ Warning / defined rule

Worker C: available
→ Eligible
```

The exact implementation boundary between Algorithm and Backend should
be agreed with the Backend Team.

------------------------------------------------------------------------

# 9. Algorithm 1 --- Worker-specific wage

The first major algorithm is:

``` text
Worker + Gig
      ↓
Exact worker-specific wage
```

The wage must remain inside the cooperative's minimum and maximum
labour-price boundary, except for explicitly defined emergency/tip
treatment. fileciteturn4file11

Potential inputs from the SRS include:

-   Experience
-   Completed jobs
-   Comparable completed jobs
-   Quality
-   Structured reviews
-   Completion efficiency
-   Reliability
-   Cancellation history
-   Emergency status
-   Availability
-   Job characteristics
-   Other fairness-related signals

The final formula is deliberately pending. fileciteturn3file8

------------------------------------------------------------------------

# 10. How to design the wage algorithm

Do not immediately jump to a complicated machine-learning model.

First build a **simple, deterministic baseline**.

For example, conceptually:

``` text
Base labour range
       ↓
Worker-related factors
       ↓
Calculate adjustment
       ↓
Apply fairness/rule checks
       ↓
Clamp to cooperative minimum/maximum
       ↓
Exact worker wage
```

The actual formula is for the team to decide.

A good first model should be:

-   understandable;
-   deterministic;
-   easy to test;
-   easy to explain;
-   configurable;
-   easy to improve later.

A complex model is not automatically a better model.

------------------------------------------------------------------------

# 11. Important wage constraints

## 11.1 Speed is not quality

Do not use:

``` text
Faster worker = higher score
```

The SRS specifically says faster completion must not automatically
produce a higher performance score.

Performance should consider:

-   Quality
-   Comparable job complexity
-   Customer satisfaction
-   Completion reliability
-   Appropriate completion time

The model must avoid encouraging unsafe rushing or poor-quality work.
fileciteturn4file11

------------------------------------------------------------------------

## 11.2 Completed jobs are not the same as quality

Do not assume:

``` text
100 completed jobs > 30 completed jobs
```

without considering the quality and relevance of those jobs.

The SRS explicitly states:

``` text
Quality ≠ quantity
```

fileciteturn3file1

------------------------------------------------------------------------

## 11.3 Rookie workers must not be permanently disadvantaged

A rookie may initially have:

-   less experience;
-   fewer completed jobs;
-   less reputation;
-   lower algorithmic wage.

But the algorithm must not permanently exclude rookies from
opportunities.

The purpose of rookie progression is to allow experience to grow.
fileciteturn4file11

------------------------------------------------------------------------

# 12. Comparable jobs

This is one of the most important unresolved areas.

The team should define what makes two jobs comparable.

Possible questions:

``` text
Same service category?
Same skill requirements?
Similar complexity?
Similar duration?
Similar location?
Similar emergency status?
Similar work characteristics?
```

Do not assume every previous job is equally useful.

Example:

``` text
Worker completed:
10 plumbing jobs
2 painting jobs

New job:
Plumbing

The 10 plumbing jobs should normally provide more relevant evidence
than the 2 painting jobs.
```

This is an example of the type of reasoning the team should formalize.

The final comparable-job methodology is explicitly pending in the SRS.
fileciteturn3file1

------------------------------------------------------------------------

# 13. Completion efficiency

The team must decide how to represent efficiency.

Avoid using only:

``` text
Efficiency = 1 / completion time
```

A worker finishing unusually quickly is not automatically performing
better.

A more appropriate conceptual structure is:

``` text
Appropriate completion time
        +
Quality
        +
Customer satisfaction
        +
Reliability
```

The exact calculation remains a team decision.

Document the reasoning behind the chosen method.

------------------------------------------------------------------------

# 14. Algorithm 2 --- Worker recommendation

The recommendation flow should be:

``` text
Customer posts gig
       ↓
Eligibility
       ↓
Eligible workers receive opportunity
       ↓
Workers accept/reject
       ↓
Accepted workers become candidates
       ↓
Recommendation scoring
       ↓
Fairness checks
       ↓
Recommended worker
       ↓
Customer chooses
```

The SRS lists potential recommendation inputs:

-   Skill match
-   Verification
-   Experience
-   Quality
-   Comparable job history
-   Availability
-   Reliability
-   Cancellation behaviour
-   Workload/fairness
-   Geographic practicality
-   Price
-   Repeat-customer relationship
-   Completion efficiency
-   Rookie progression

The exact mathematical model is still pending. fileciteturn3file8

------------------------------------------------------------------------

# 15. Recommendation model --- suggested starting approach

Start with an explainable scoring model.

Conceptually:

``` text
Candidate Worker
       ↓
Calculate factors
       ↓
Normalize factors
       ↓
Apply weights
       ↓
Apply fairness rules
       ↓
Final recommendation score
```

For example only:

``` text
Skill Match          → 30%
Quality              → 20%
Reliability          → 15%
Relevant Experience  → 15%
Workload/Fairness    → 10%
Availability         → 5%
Geography            → 5%
```

**This is only an example, not a proposed final weighting.**

The team should test different weightings and decide what produces
sensible outcomes.

Do not copy the example directly into production.

------------------------------------------------------------------------

# 16. Recommendation must be explainable

The algorithm should ideally be able to provide information such as:

``` text
Recommended because:
✓ Strong skill match
✓ Good relevant job history
✓ Reliable completion record
✓ Suitable availability
✓ Current workload considered
```

The exact explanation shown to customers will be decided with the
Frontend Team.

The Algorithm Team should at least be able to answer:

> Why did Worker A rank above Worker B?

If the team cannot answer this clearly, the model is probably too opaque
for the MVP.

------------------------------------------------------------------------

# 17. Fairness

Fairness is not a message shown by the UI.

It must exist inside the algorithm.

The team should define what fairness means for this platform.

At minimum, investigate:

### Opportunity fairness

Are the same workers repeatedly receiving recommendations while others
receive very few?

### Rookie fairness

Can a new worker realistically obtain work and gain experience?

### Workload fairness

Does the system repeatedly favour workers who already have a large
workload?

### Experience fairness

Does experience help appropriately without making less-experienced
workers permanently irrelevant?

### Quality fairness

Are high-quality workers rewarded without treating job count as quality?

The exact fairness constraints are pending in the SRS, so the team has
to research and propose them. fileciteturn3file15

------------------------------------------------------------------------

# 18. Workload calculation

Workload is explicitly pending.

The team should propose a clear definition.

For example, investigate:

``` text
Current active jobs
+
Upcoming accepted jobs
+
Estimated time commitment
```

Then consider:

``` text
How much should workload affect recommendation?
```

The team should also decide the time window.

For example:

``` text
Current day?
Next 24 hours?
Next 7 days?
Rolling period?
```

These are examples for investigation, not fixed requirements.

The important point is that the final definition must be measurable.

------------------------------------------------------------------------

# 19. Rookie progression

A rookie can accept jobs directly.

An experienced worker can also invite a verified rookie to participate.

When the rookie accepts:

``` text
Participation
      ↓
Experience progression
```

The SRS gives an example:

``` text
1 participation = 0.5 equivalent job experience
```

but explicitly says the exact weighting is not frozen.
fileciteturn3file8

The team should therefore make the progression value configurable.

Possible questions to research:

-   How much should one participation contribute?
-   Should different job types contribute differently?
-   Should repeated participation in the same type of work matter
    differently?
-   Should quality of the completed participation affect progression?
-   How should rookie progression influence wage?
-   How should it influence recommendation?

------------------------------------------------------------------------

# 20. Multi-worker jobs

The application can recommend how many workers may be necessary.

Example:

``` text
Recommended workforce: 2 workers
```

The exact workforce calculation is pending.

The team can investigate inputs such as:

-   Job complexity
-   Expected duration
-   Required skills
-   Work characteristics

However, the SRS does not require the platform to automatically force
the recommended number of workers.

The accepting worker may still perform the job with fewer workers.
fileciteturn4file11

------------------------------------------------------------------------

# 21. Emergency jobs

Emergency jobs receive differentiated treatment.

The SRS specifies:

-   faster matching;
-   smaller initial geographic radius;
-   emergency surcharge/incentive concepts;
-   optional customer tip when no worker accepts.

The exact emergency definition, surcharge and worker incentive remain
pending/configurable. fileciteturn3file11

The team should therefore design the algorithm so that emergency
parameters can be changed without rewriting the whole model.

Conceptually:

``` text
Emergency?
   ↓
Yes → Emergency matching configuration
   ↓
Smaller initial radius
   ↓
Faster opportunity treatment
   ↓
Emergency wage/incentive treatment where defined
```

Do not invent final emergency values before the team decides them.

------------------------------------------------------------------------

# 22. What the algorithm should NOT do

Do not build:

-   Automatic worker assignment
-   Worker bidding
-   Worker quotation competition
-   Nearest-worker-only recommendation
-   Highest-rating-only recommendation
-   Fastest-worker-only recommendation
-   Job-count-only ranking
-   Permanent rookie exclusion
-   Hidden worker ranking rules with no explanation
-   Private rookie compensation calculation
-   Internal worker-to-worker payment splitting

These conflict with the SRS product rules. fileciteturn3file1

------------------------------------------------------------------------

# 23. AI / Machine Learning

For the MVP, start with **deterministic and explainable algorithms**.

Do not add AI or machine learning merely because the project contains
the word "algorithm".

A conventional formula is easier to:

-   test;
-   explain;
-   debug;
-   reproduce;
-   modify;
-   demonstrate during the hackathon.

The methodology also recommends using deterministic logic where
deterministic logic is sufficient rather than adding AI unnecessarily.
fileciteturn4file12

Machine learning can be considered later if the team has enough
meaningful data and a clear reason for using it.

------------------------------------------------------------------------

# 24. Synthetic data and simulation

Real production data will not be available initially.

Therefore, create synthetic worker/job datasets.

Example:

``` text
Worker A
Skill match: High
Experience: High
Quality: High
Workload: High

Worker B
Skill match: High
Experience: Low
Quality: Unknown
Workload: Low

Worker C
Skill match: Medium
Experience: Medium
Quality: High
Workload: Low
```

Then run the algorithm against many scenarios.

The purpose is not to prove that the algorithm is perfect.

The purpose is to discover obvious problems before integration.

------------------------------------------------------------------------

# 25. Build an evaluation/test set

Create scenarios such as:

### Scenario 1 --- Experienced vs rookie

Check that the rookie is not automatically eliminated.

### Scenario 2 --- High quality vs high job count

Check that quantity does not automatically beat quality.

### Scenario 3 --- Fast worker vs reliable worker

Check that speed does not automatically dominate.

### Scenario 4 --- Nearby vs better overall match

Check that distance does not become the entire recommendation.

### Scenario 5 --- Overloaded worker vs available worker

Check whether workload/fairness behaves as intended.

### Scenario 6 --- Repeat customer

Check how previous customer-worker relationships affect the
recommendation.

### Scenario 7 --- Emergency job

Check that emergency configuration changes the appropriate behaviour.

### Scenario 8 --- Identical scores

Check deterministic tie-breaking.

------------------------------------------------------------------------

# 26. Tie-breaking

The team should explicitly define what happens when two workers have
equal or almost equal scores.

Do not allow arbitrary behaviour such as whichever database record
happens to appear first.

Possible approaches for investigation:

``` text
Fair rotation
↓
Lower workload
↓
Better relevant skill match
↓
Stable worker ID
```

This is only an example.

The final tie-breaking policy should be decided and documented.

------------------------------------------------------------------------

# 27. Normalization

If different factors are combined into one score, their scales need to
be made comparable.

For example:

``` text
Experience: 0–20 years
Rating: 1–5
Cancellation rate: 0–1
Distance: 0–20 km
```

These cannot simply be added together.

The team should decide how each factor is normalized before combining
them.

Document the chosen method.

------------------------------------------------------------------------

# 28. Versioning and configuration

The SRS specifically says the algorithm should be
configurable/versionable.

A useful conceptual structure is:

``` text
Algorithm Version
      ↓
Factor definitions
      ↓
Weights
      ↓
Configuration
      ↓
Calculation
```

For example:

``` text
Recommendation v1
Recommendation v2
Recommendation v3
```

This makes it possible to compare changes and understand which version
produced a result.

Do not bury weights throughout unrelated code.

Keep important algorithm parameters in one clear configuration area.

------------------------------------------------------------------------

# 29. Backend integration contract

The Algorithm Team and Backend Team must agree on:

### Inputs

``` text
What worker data is required?
What job data is required?
What historical data is required?
```

### Outputs

``` text
Worker wage
Recommendation score/result
Relevant explanation factors
Algorithm version
```

### Errors

For example:

``` text
Insufficient historical data
Missing required skill information
Invalid job data
No eligible candidates
```

### Version

Every important algorithm result should be traceable to the algorithm
version/configuration that produced it.

The final API structure belongs to the Backend Team, but the Algorithm
Team should define the algorithmic contract clearly.

------------------------------------------------------------------------

# 30. Recommended implementation phases

## A0 --- Understand and define

Deliver:

-   Read relevant SRS sections
-   Factor dictionary
-   Input/output list
-   Pending decisions list
-   Initial assumptions
-   Data requirements

**Done when:** the team can clearly explain what the algorithms need to
calculate.

------------------------------------------------------------------------

## A1 --- Eligibility and supporting calculations

Build/prototype:

-   Geographic eligibility
-   Time-sensitive radius logic
-   Availability/conflict calculations
-   Basic worker/job matching inputs

**Done when:** the team can determine which workers are practical
candidates for a gig.

------------------------------------------------------------------------

## A2 --- Wage baseline

Build:

-   First deterministic wage formula
-   Cooperative minimum/maximum boundary
-   Factor normalization
-   Configurable weights
-   Basic tests

**Done when:** synthetic workers receive sensible, bounded
worker-specific wages.

------------------------------------------------------------------------

## A3 --- Recommendation baseline

Build:

-   Factor calculations
-   Weighted scoring
-   Fairness checks
-   Tie-breaking
-   Recommendation explanation
-   Version identifier

**Done when:** accepted workers can be ranked/recommended using
synthetic data.

------------------------------------------------------------------------

## A4 --- Fairness and edge-case testing

Test:

-   Rookie inclusion
-   Workload fairness
-   Quality vs quantity
-   Speed vs quality
-   Geography
-   Repeat relationships
-   Missing data
-   Equal scores
-   Emergency cases

**Done when:** obvious unfair or unstable behaviour has been identified
and corrected.

------------------------------------------------------------------------

## A5 --- Rookie and multi-worker logic

Build/prototype:

-   Rookie progression
-   Participation weighting
-   Recommended workforce count if implemented
-   Relevant multi-worker calculations

Keep private worker-to-worker compensation outside the algorithm.

**Done when:** rookie progression works according to a configurable
rule.

------------------------------------------------------------------------

## A6 --- Emergency logic

Build:

-   Emergency configuration
-   Faster/smaller-radius treatment
-   Emergency wage/incentive treatment when finalized
-   No-acceptance/tip-related algorithm inputs where required

**Done when:** emergency behaviour can be demonstrated separately from
normal matching.

------------------------------------------------------------------------

## A7 --- Backend integration

Connect the approved algorithm to the backend contract.

Verify:

``` text
Backend data
     ↓
Algorithm
     ↓
Wage / Recommendation result
     ↓
Backend
     ↓
Frontend
```

Do not change the mathematical model simply because the frontend needs a
different display.

If a change is required, document it.

------------------------------------------------------------------------

## A8 --- Final audit

Check:

-   Formula correctness
-   Boundary enforcement
-   Fairness
-   Rookie inclusion
-   Recommendation behaviour
-   Geographic logic
-   Availability logic
-   Emergency logic
-   Missing-data behaviour
-   Tie-breaking
-   Versioning
-   Performance
-   Reproducibility
-   Test coverage

------------------------------------------------------------------------

# 31. Testing standard

Every algorithm should have tests before being treated as complete.

At minimum, test:

### Normal cases

Expected worker/job combinations produce sensible results.

### Boundary cases

``` text
Minimum wage
Maximum wage
Zero experience
Very high experience
No reviews
No comparable jobs
Maximum workload
Minimum workload
Emergency
Non-emergency
```

### Invalid data

``` text
Missing worker
Missing job
Invalid location
Invalid availability
Invalid factor values
```

### Fairness cases

Test deliberately constructed cases where the algorithm could
accidentally favour one category of worker.

------------------------------------------------------------------------

# 32. Reproducibility

Given the same:

``` text
Worker data
+
Job data
+
Algorithm version
+
Configuration
```

the algorithm should produce the same result.

This is especially important for debugging.

If the result changes, the team should be able to identify why.

------------------------------------------------------------------------

# 33. Working with an AI coding assistant

Use AI tools for bounded work, not for designing the entire algorithm
blindly.

A good task might be:

``` text
Current phase:
A2 — Wage Baseline

Objective:
Implement the wage calculation prototype.

Use:
- Current factor definitions
- Current configuration
- Synthetic test data

Do not change:
- Recommendation algorithm
- API contract
- Database schema

Required:
- Calculation
- Unit tests
- Boundary tests
- Example outputs
- Explanation of changed files
```

Before accepting generated code:

-   inspect the formula;
-   test edge cases;
-   verify the output manually;
-   check that the AI did not introduce unapproved factors;
-   check that weights and limits are configurable;
-   record important decisions.

The development methodology recommends small, bounded implementation
tasks and testing rather than asking an AI assistant to build the entire
system at once. fileciteturn4file12

------------------------------------------------------------------------

# 34. Team freedom

The team has freedom to decide:

-   Mathematical formula
-   Factor weights
-   Normalization methods
-   Fairness methodology
-   Workload definition
-   Comparable-job methodology
-   Efficiency calculation
-   Rookie progression weighting
-   Tie-breaking
-   Recommended workforce calculation
-   Exact implementation structure
-   Whether a later advanced model is justified

However, every decision must satisfy the SRS.

If a decision is not clearly specified in the SRS, the team should:

``` text
Research / discuss
      ↓
Propose
      ↓
Test
      ↓
Choose
      ↓
Document
```

Do not silently turn an assumption into a permanent requirement.

The SRS explicitly lists these algorithm areas as pending.
fileciteturn3file15

------------------------------------------------------------------------

# 35. What the team should deliver

By the time the Algorithm Team's MVP work is ready for integration, it
should have:

``` text
1. Factor Dictionary
2. Input/Data Requirements
3. Eligibility Logic
4. Wage Algorithm v1
5. Recommendation Algorithm v1
6. Fairness Rules
7. Workload Definition
8. Comparable-job Definition
9. Efficiency Definition
10. Rookie Progression Rule
11. Emergency Parameters/Logic
12. Configuration
13. Algorithm Versioning
14. Synthetic Test Dataset
15. Test Cases
16. Example Results
17. Known Limitations
18. Backend Integration Contract
```

Not every item needs to be a large document. Keep them organized and
concise.

------------------------------------------------------------------------

# 36. Final goal

The Algorithm Team should ultimately make this possible:

``` text
Customer creates gig
        ↓
System determines practical eligible workers
        ↓
Workers accept/reject
        ↓
Accepted workers become candidates
        ↓
System calculates each worker's exact wage
        ↓
Recommendation algorithm evaluates candidates
        ↓
Fairness rules are applied
        ↓
One worker is recommended
        ↓
Customer sees meaningful recommendation information
        ↓
Customer chooses any accepted worker
```

The algorithm should be:

**Fair enough to justify the product's core idea, simple enough to
understand, deterministic enough to test, configurable enough to
improve, and transparent enough to explain.**

The exact mathematical model is intentionally left to the Algorithm Team
to research, design, test and finalize within the SRS constraints.
fileciteturn4file4
