# 04 — DATABASE DESIGN

## SIH26089 — Cooperative Gig Services Platform

**Document Type:** MVP Database Design  
**Status:** Implementation Baseline  
**Database:** PostgreSQL / Supabase PostgreSQL  
**Authentication:** Supabase Auth  
**ORM/Migrations:** SQLAlchemy + Alembic  
**Primary Roles:** Customer, Worker  
**Prototype Scope:** One Cooperative / One City-Service Area

---

# 1. Purpose

This document defines the database structure for the SIH26089 Cooperative Gig Services Platform MVP.

It converts the approved product requirements and subsequent implementation decisions into:

- database entities;
- tables;
- columns;
- relationships;
- statuses;
- constraints;
- indexes;
- historical snapshots;
- pricing records;
- worker experience records;
- gig lifecycle records;
- payment records;
- review records;
- chat records;
- notification records.

This document is the database source of truth for MVP implementation.

The SRS remains the formal requirements reference. The database design translates those requirements into an implementable relational structure. This follows the project's documented methodology of moving from requirements → architecture → database design → bounded implementation.

---

# 2. MVP Database Principles

## 2.1 Relational database

Use PostgreSQL with normalized relational tables.

Do not store important relational data such as gig tasks, worker skills, reviews, payments, or opportunities inside arbitrary JSON fields.

JSON may be used for genuinely flexible metadata where appropriate, but it must not replace proper relationships.

---

## 2.2 UUID primary keys

Use UUIDs as primary keys for application entities.

Recommended:

```text
id UUID PRIMARY KEY
```

Use generated UUIDs at the database/application layer.

---

## 2.3 Timestamps

Important entities should contain:

```text
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

Historical/action records should additionally preserve their relevant event timestamps.

---

## 2.4 Soft deletion

Do not physically delete important transactional records such as:

- gigs;
- opportunities;
- payments;
- reviews;
- cancellations;
- reschedule requests;
- chat messages;
- worker participation records.

Historical records are part of auditability.

If profile-level removal is required later, it should be handled separately.

---

# 3. High-Level Entity Relationship

The core structure is:

```text
                    ┌──────────────┐
                    │ cooperatives │
                    └───────┬──────┘
                            │
                            │
                       ┌────▼─────┐
                       │  users   │
                       └────┬─────┘
                            / \
                           /   \
                          /     \
             ┌────────────▼┐   ┌▼───────────────┐
             │  customers  │   │    workers     │
             └──────┬──────┘   └───────┬────────┘
                    │                  │
                    │                  ├── worker_categories
                    │                  ├── availability
                    │                  ├── verification
                    │                  └── worker_metrics
                    │
                    ▼
                  gigs
                    │
          ┌─────────┼──────────┐
          │         │          │
          ▼         ▼          ▼
      gig_tasks  opportunities  visitation
                    │          proposals
                    │
                    ▼
             selected worker
                    │
          ┌─────────┼─────────────┐
          ▼         ▼             ▼
     completion   payment       worker
       evidence                  participation
          │                       │
          ▼                       ▼
      confirmation              rookie /
                                equal sharing

                    gigs
                     │
          ┌──────────┼──────────┐
          ▼          ▼          ▼
       reviews     chat       notifications
```

---

# 4. Authentication and Users

## 4.1 `users`

Application-level user record.

Authentication itself is handled by Supabase Auth.

### Columns

| Column | Type | Null | Description |
|---|---|---:|---|
| `id` | UUID | No | Same UUID as Supabase Auth user ID |
| `role` | ENUM | No | `CUSTOMER` / `WORKER` |
| `cooperative_id` | UUID FK | No | Associated cooperative |
| `full_name` | VARCHAR | No | User's name |
| `phone` | VARCHAR | Yes | Phone number |
| `email` | VARCHAR | Yes | Email |
| `profile_photo_url` | TEXT | Yes | Profile image |
| `is_active` | BOOLEAN | No | Account active status |
| `created_at` | TIMESTAMPTZ | No | Creation time |
| `updated_at` | TIMESTAMPTZ | No | Last update |

### Constraints

```text
role ∈ {CUSTOMER, WORKER}
```

A user has **exactly one role**.

A user cannot simultaneously be a customer and worker in MVP.

---

# 5. Cooperatives

## 5.1 `cooperatives`

Although MVP contains only one cooperative, the cooperative must be represented as a real entity.

This prevents hard-coding the cooperative into the application and keeps the system extensible toward multiple cooperatives later.

### Columns

| Column | Type | Null |
|---|---|---:|
| `id` | UUID | No |
| `name` | VARCHAR | No |
| `city` | VARCHAR | No |
| `service_area` | TEXT | Yes |
| `is_active` | BOOLEAN | No |
| `created_at` | TIMESTAMPTZ | No |
| `updated_at` | TIMESTAMPTZ | No |

---

# 6. Customer Profile

## 6.1 `customer_profiles`

One-to-one extension of a customer user.

### Columns

| Column | Type | Null |
|---|---|---:|
| `user_id` | UUID PK/FK | No |
| `address` | TEXT | Yes |
| `created_at` | TIMESTAMPTZ | No |
| `updated_at` | TIMESTAMPTZ | No |

The user table contains common identity information; this table contains customer-specific information.

---

# 7. Worker Profile

## 7.1 `worker_profiles`

One-to-one extension of a worker user.

### Columns

| Column | Type | Null | Description |
|---|---|---:|---|
| `user_id` | UUID PK/FK | No | Worker user |
| `address` | TEXT | Yes | Worker address |
| `city` | VARCHAR | Yes | Worker city |
| `aadhaar_document_url` | TEXT | Yes | Uploaded Aadhaar document |
| `aadhaar_uploaded_at` | TIMESTAMPTZ | Yes | Upload time |
| `is_active` | BOOLEAN | No | Worker active status |
| `created_at` | TIMESTAMPTZ | No | Creation time |
| `updated_at` | TIMESTAMPTZ | No | Update time |

### Aadhaar rule

MVP only provides an Aadhaar upload facility.

Uploading the document **does not mean that the worker is Aadhaar verified**.

There is:

- no Aadhaar API;
- no production identity verification;
- no automatic verified status from uploading.

This follows the SRS requirement that uploaded information and verified identity must remain conceptually distinct.

---

# 8. Worker Metrics

## 8.1 `worker_metrics`

One-to-one with `worker_profiles`.

This table stores the worker's current calculated/aggregate performance information.

### Columns

| Column | Type | Null | Description |
|---|---|---:|---|
| `worker_id` | UUID PK/FK | No | Worker |
| `completed_jobs_count` | INTEGER | No | Completed primary-worker jobs |
| `rating_average` | NUMERIC(4,3) | No | Human-readable aggregate rating |
| `rating_count` | INTEGER | No | Number of customer reviews |
| `bayesian_score` | NUMERIC(6,5) | No | Normalized rating signal |
| `experience_score` | NUMERIC(6,5) | No | Experience signal |
| `final_score` | NUMERIC(6,5) | No | Combined worker score |
| `updated_at` | TIMESTAMPTZ | No |

### Important worker indicators

The worker has three primary visible/important performance indicators:

```text
1. Ratings
2. Number of completed jobs
3. Final score
```

However, these do not have equal algorithmic meaning.

A worker with many easy jobs must not automatically outrank a worker with fewer difficult jobs.

The SRS explicitly requires experience and quality to be distinguished.

---

# 9. Worker Categories

## 9.1 `service_categories`

Examples:

```text
PLUMBING
CARPENTRY
ELECTRICIAN
PAINTER
HOUSE_HELP
```

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `name` | VARCHAR |
| `description` | TEXT |
| `base_rate_per_minute` | NUMERIC(10,2) |
| `minimum_billable_minutes` | INTEGER |
| `is_active` | BOOLEAN |
| `created_at` | TIMESTAMPTZ |
| `updated_at` | TIMESTAMPTZ |

The category stores the pricing configuration.

---

## 9.2 `worker_categories`

Many-to-many relationship between workers and categories.

### Columns

| Column | Type |
|---|---|
| `worker_id` | UUID FK |
| `category_id` | UUID FK |
| `created_at` | TIMESTAMPTZ |

### Constraint

```text
UNIQUE(worker_id, category_id)
```

A worker can belong to multiple categories.

Example:

```text
Worker A
├── Plumbing
└── Electrician
```

---

# 10. Service Tasks

## 10.1 `service_tasks`

The task catalogue comes from the pricing/task catalogue defined in `WAGES.md`. The catalogue contains task standard duration and base wage/rate information.

### Columns

| Column | Type | Description |
|---|---|---|
| `id` | UUID | Task ID |
| `category_id` | UUID FK | Parent category |
| `name` | VARCHAR | Task name |
| `description` | TEXT | Task description |
| `standard_duration_minutes` | INTEGER | Normal/standard task duration |
| `base_price` | NUMERIC(10,2) | Base task price |
| `is_active` | BOOLEAN | Active catalogue entry |
| `created_at` | TIMESTAMPTZ | Creation |
| `updated_at` | TIMESTAMPTZ | Update |

The task's standard duration is **not actual worker completion time**.

---

# 11. Worker Availability

## 11.1 `worker_availability`

MVP retains recurring weekly availability.

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `worker_id` | UUID FK |
| `day_of_week` | SMALLINT |
| `start_time` | TIME |
| `end_time` | TIME |
| `is_available` | BOOLEAN |
| `created_at` | TIMESTAMPTZ |
| `updated_at` | TIMESTAMPTZ |

### Rules

`day_of_week`:

```text
0–6
```

or another consistently defined convention.

A worker can have multiple availability periods on one day if required.

Example:

```text
Monday
09:00–13:00
15:00–19:00
```

### Availability logic

A worker may accept a future gig if their availability covers the gig's scheduled time.

Current physical location is irrelevant to eligibility.

---

# 12. Gig

## 12.1 `gigs`

Central transaction entity.

### Columns

| Column | Type | Description |
|---|---|---|
| `id` | UUID | Gig ID |
| `customer_id` | UUID FK | Customer |
| `cooperative_id` | UUID FK | Cooperative |
| `category_id` | UUID FK | Single service category |
| `gig_type` | ENUM | `NORMAL` / `VISITATION` |
| `status` | ENUM | Current lifecycle state |
| `description` | TEXT | Customer description |
| `instructions` | TEXT | Additional instructions |
| `address` | TEXT | Customer address |
| `latitude` | NUMERIC | Map pin latitude |
| `longitude` | NUMERIC | Map pin longitude |
| `scheduled_date` | DATE | Required date |
| `scheduled_start_time` | TIME | Required start |
| `scheduled_end_time` | TIME | Derived/entered end |
| `expected_duration_minutes` | INTEGER | Expected duration |
| `is_emergency` | BOOLEAN | Emergency flag |
| `acceptance_deadline` | TIMESTAMPTZ | Optional deadline |
| `material_procurement_mode` | ENUM | Customer/Worker |
| `base_price` | NUMERIC(10,2) | Final calculated base labour price |
| `minimum_billable_minutes_snapshot` | INTEGER | Pricing snapshot |
| `base_rate_per_minute_snapshot` | NUMERIC(10,2) | Pricing snapshot |
| `selected_worker_id` | UUID FK | Final selected worker |
| `created_at` | TIMESTAMPTZ | Creation |
| `updated_at` | TIMESTAMPTZ | Update |

---

# 13. Gig Status

Recommended MVP states:

```text
DRAFT
POSTED
ACCEPTANCE_OPEN
WORKER_SELECTED
SCHEDULED
IN_PROGRESS
COMPLETION_SUBMITTED
CUSTOMER_CONFIRMED
PAYMENT_PENDING
PAYMENT_CUSTOMER_PAID
PAYMENT_WORKER_CONFIRMED
COMPLETED
CANCELLED
```

Visitation can use the same gig entity with additional visitation state/proposal information.

---

# 14. Gig Tasks

## 14.1 `gig_tasks`

Many-to-many relationship between gigs and service tasks.

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `gig_id` | UUID FK |
| `task_id` | UUID FK |
| `standard_duration_minutes_snapshot` | INTEGER |
| `base_price_snapshot` | NUMERIC(10,2) |
| `created_at` | TIMESTAMPTZ |

### Constraints

```text
UNIQUE(gig_id, task_id)
```

---

# 15. Single Category Rule

Every gig has exactly **one category**.

Multiple tasks are allowed only when all tasks belong to that category.

Valid:

```text
Plumbing
├── Tap repair
├── Drain unclogging
└── Pipe leakage fix
```

Invalid:

```text
Plumbing
+
Electrician
```

The backend must validate this rather than trusting the Flutter client.

---

# 16. Pricing Calculation

The basic base-price calculation is:

```text
total_standard_minutes
=
SUM(gig_tasks.standard_duration_minutes_snapshot)
```

If a minimum billable standard duration exists:

```text
billable_minutes =
MAX(
    total_standard_minutes,
    minimum_billable_minutes
)
```

Then:

```text
base_price =
billable_minutes × category_rate_per_minute
```

The minimum billable duration represents a **pricing floor**, not a requirement that the worker physically spend that amount of time.

---

# 17. Pricing Snapshots

The gig stores:

```text
base_price
base_rate_per_minute_snapshot
minimum_billable_minutes_snapshot
```

Each gig task stores:

```text
standard_duration_minutes_snapshot
base_price_snapshot
```

This prevents historical gigs from changing if the cooperative changes its task catalogue or pricing later.

Example:

```text
Today:
Plumbing = ₹5/min

Gig A:
45 minutes
Base price = ₹225

Later:
Plumbing = ₹6/min

Gig A remains:
₹225
```

This is essential for transaction integrity.

---

# 18. Worker Opportunity

## 18.1 `gig_worker_opportunities`

Represents an individual worker receiving an opportunity for a gig.

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `gig_id` | UUID FK |
| `worker_id` | UUID FK |
| `status` | ENUM |
| `base_price_snapshot` | NUMERIC(10,2) |
| `final_score_snapshot` | NUMERIC(6,5) |
| `premium_percentage` | NUMERIC(6,3) |
| `exact_wage` | NUMERIC(10,2) |
| `offered_at` | TIMESTAMPTZ |
| `responded_at` | TIMESTAMPTZ |
| `created_at` | TIMESTAMPTZ |
| `updated_at` | TIMESTAMPTZ |

### Constraint

```text
UNIQUE(gig_id, worker_id)
```

---

# 19. Opportunity Status

```text
PENDING
ACCEPTED
REJECTED
EXPIRED
NOT_SELECTED
```

A rejected worker cannot accept the same opportunity again.

When the customer selects one accepted worker:

```text
selected worker → ACCEPTED / SELECTED
other accepted workers → NOT_SELECTED
```

---

# 20. Worker Wage Calculation

The current wage design uses:

```text
final_score =
0.5 × experience_score
+
0.5 × bayesian_score
```

and the intended premium model is:

```text
worker_wage =
base_price × (1 + final_score × 0.30)
```

`WAGES.md` currently identifies the incentive mapping as an ambiguity requiring finalization, so this database design treats the formula as the **approved current implementation direction**, while the implementation should keep the formula configurable rather than scattering `0.30` throughout application code.

---

# 21. Wage Snapshot Rule

When an opportunity is created:

```text
worker current final_score
        ↓
snapshot
        ↓
calculate exact wage
        ↓
store exact wage
```

The opportunity must preserve:

```text
base_price_snapshot
final_score_snapshot
premium_percentage
exact_wage
```

If the worker's score later changes, the old offer **must not change**.

Example:

```text
At Gig A creation:

final_score = 0.60
wage = ₹590

Later:

final_score = 0.75

Gig A still has:
final_score_snapshot = 0.60
agreed wage = ₹590
```

This is required for historical consistency.

---

# 22. Worker Experience History

## 22.1 `worker_experience_records`

Do not rely only on the current `experience_score`.

Preserve the individual experience contributions.

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `worker_id` | UUID FK |
| `gig_id` | UUID FK |
| `participation_type` | ENUM |
| `complexity_value` | NUMERIC(6,5) |
| `experience_contribution` | NUMERIC(6,5) |
| `created_at` | TIMESTAMPTZ |

Participation types:

```text
PRIMARY_COMPLETION
ROOKIE_PARTICIPATION
```

For normal completed work:

```text
experience_contribution = complexity_value
```

For rookie participation:

```text
experience_contribution =
complexity_value × 0.5
```

---

# 23. Complexity

`WAGES.md` defines complexity normalization using:

```text
complexity =
(
    ln(t) - ln(t_min)
)
/
(
    ln(t_max) - ln(t_min)
)
```

where `t` is standard task duration.

The category-specific bounds are defined in `WAGES.md`.

The backend algorithm should calculate this deterministically.

Do not allow Flutter to submit an arbitrary complexity value.

---

# 24. Experience Score

Current WAGES design:

```text
experience_score =
Σ complexity_i / N
```

using the rolling last:

```text
N = 50 completed jobs
```

The database therefore stores the underlying experience records, while `worker_metrics.experience_score` stores the current aggregate.

---

# 25. Worker Ratings

## 25.1 `reviews`

One review represents one direction of review.

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `gig_id` | UUID FK |
| `reviewer_id` | UUID FK |
| `reviewee_id` | UUID FK |
| `reviewer_role` | ENUM |
| `overall_rating` | NUMERIC(3,2) |
| `created_at` | TIMESTAMPTZ |
| `updated_at` | TIMESTAMPTZ |

### Constraint

```text
UNIQUE(gig_id, reviewer_id, reviewee_id)
```

Therefore:

```text
Customer → Worker
```

and:

```text
Worker → Customer
```

are two separate review records.

---

# 26. Review Questions

## 26.1 `review_questions`

Configurable structured review questions.

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `target_role` | ENUM |
| `question_text` | TEXT |
| `display_order` | INTEGER |
| `is_active` | BOOLEAN |
| `created_at` | TIMESTAMPTZ |

---

## 26.2 `review_answers`

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `review_id` | UUID FK |
| `question_id` | UUID FK |
| `answer_value` | INTEGER |
| `created_at` | TIMESTAMPTZ |

This supports the structured 3–4-question review model without hard-coding questions into the database.

---

# 27. Worker Rating Aggregation

Customer reviews of workers feed the worker's rating metrics.

Store current aggregates:

```text
rating_average
rating_count
bayesian_score
```

while retaining all historical reviews.

The current Bayesian model is:

```text
bayesian_score =
(C × m + Σ rating_score_i)
/
(C + n)
```

with the current WAGES values:

```text
m = 0.7
C = 10
```

and:

```text
rating_score =
(avg_rating - 1) / 4
```

---

# 28. Completion Evidence

## 28.1 `completion_submissions`

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `gig_id` | UUID FK |
| `worker_id` | UUID FK |
| `description` | TEXT |
| `submitted_at` | TIMESTAMPTZ |

---

## 28.2 `completion_evidence`

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `submission_id` | UUID FK |
| `file_url` | TEXT |
| `file_type` | VARCHAR |
| `created_at` | TIMESTAMPTZ |

MVP supports image/photo evidence.

---

# 29. Customer Completion Confirmation

## 29.1 `completion_confirmations`

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `gig_id` | UUID FK |
| `customer_id` | UUID FK |
| `confirmed` | BOOLEAN |
| `response_note` | TEXT |
| `created_at` | TIMESTAMPTZ |

The worker cannot independently make the gig fully completed.

The flow remains:

```text
Worker evidence
↓
Customer confirmation
↓
Payment
↓
Worker payment acknowledgement
↓
Completed
```

---

# 30. Payments

## 30.1 `payments`

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `gig_id` | UUID FK |
| `customer_id` | UUID FK |
| `worker_id` | UUID FK |
| `amount` | NUMERIC(10,2) |
| `payment_method` | ENUM |
| `status` | ENUM |
| `paid_at` | TIMESTAMPTZ |
| `worker_confirmed_at` | TIMESTAMPTZ |
| `created_at` | TIMESTAMPTZ |
| `updated_at` | TIMESTAMPTZ |

Payment methods:

```text
CASH
UPI
```

---

# 31. Payment Status

```text
PENDING
CUSTOMER_PAID
WORKER_CONFIRMED
```

For UPI, the MVP uses a UPI deep link but does not automatically verify that money was received.

Therefore:

```text
Customer pays through UPI
        ↓
System records customer payment action
        ↓
Worker is asked:
"Did you receive the payment?"
        ↓
Worker confirms
        ↓
Gig becomes fully completed
```

The worker confirmation is the final payment acknowledgement for MVP.

---

# 32. Material Procurement

## 32.1 Gig material mode

The gig stores:

```text
CUSTOMER_PURCHASES
WORKER_PURCHASES
```

The SRS explicitly separates labour/service cost from materials.

---

# 33. Material Evidence

## 33.1 `material_receipts`

Required when the worker purchases materials.

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `gig_id` | UUID FK |
| `worker_id` | UUID FK |
| `amount` | NUMERIC(10,2) |
| `receipt_url` | TEXT |
| `description` | TEXT |
| `created_at` | TIMESTAMPTZ |

Material dispute resolution remains outside MVP.

---

# 34. Multi-Worker Participation

## 34.1 `worker_participations`

Used when an accepting worker adds another cooperative worker.

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `gig_id` | UUID FK |
| `inviting_worker_id` | UUID FK |
| `additional_worker_id` | UUID FK |
| `status` | ENUM |
| `classification` | ENUM |
| `experience_contribution` | NUMERIC(6,5) |
| `created_at` | TIMESTAMPTZ |
| `responded_at` | TIMESTAMPTZ |

---

# 35. Worker Participation Status

```text
PENDING
ACCEPTED
REJECTED
```

The additional worker must explicitly accept.

---

# 36. Worker Participation Classification

```text
ROOKIE
EQUAL_SHARING
```

If:

```text
ROOKIE
```

the experience contribution is:

```text
complexity × 0.5
```

The private compensation between workers is not recorded.

---

# 37. Multi-Worker Payment

The customer pays the agreed gig labour amount.

The platform does **not**:

- add a second charge because of additional workers;
- calculate private worker-to-worker splits;
- enforce equal sharing financially;
- record the rookie's private payment.

The SRS explicitly states that the internal split is outside platform control.

---

# 38. Visitation

## 38.1 Visitation is a gig type

A visitation is represented through the normal `gigs` entity:

```text
gig_type =
NORMAL
VISITATION
```

A customer can select visitation during normal gig creation.

---

# 39. Visitation Charge

The visitation charge is:

```text
₹100
```

This is a fixed MVP product rule.

The visitation amount should be represented separately from the eventual labour amount.

---

# 40. Visitation Proposal

## 40.1 `visitation_proposals`

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `gig_id` | UUID FK |
| `worker_id` | UUID FK |
| `base_price` | NUMERIC(10,2) |
| `proposed_at` | TIMESTAMPTZ |
| `status` | ENUM |
| `customer_responded_at` | TIMESTAMPTZ |

---

# 41. Visitation Proposed Tasks

## 41.1 `visitation_proposal_tasks`

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `proposal_id` | UUID FK |
| `task_id` | UUID FK |
| `standard_duration_minutes_snapshot` | INTEGER |
| `base_price_snapshot` | NUMERIC(10,2) |

The worker uses the **same task menu** available to the customer.

Multiple tasks are allowed, but all must belong to the gig's single category.

---

# 42. Visitation Proposal Status

```text
PENDING
ACCEPTED
REJECTED
```

The customer has only:

```text
ACCEPT
REJECT
```

for MVP.

There is no negotiation flow.

This preserves the SRS's no-bidding/no-quotation/no-negotiation principle.

---

# 43. Visitation Payment Rule

If the customer accepts the worker's proposal:

```text
₹100 visitation charge
→ NOT additionally charged
```

Example:

```text
Visitation = ₹100
Work = ₹300

Customer accepts

Final labour payment = ₹300
NOT ₹400
```

If the customer rejects:

```text
Customer pays ₹100
No work payment
```

The visitation proposal and customer response must remain auditable.

---

# 44. Cancellation

## 44.1 `gig_cancellations`

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `gig_id` | UUID FK |
| `cancelled_by` | UUID FK |
| `reason` | TEXT |
| `fee_amount` | NUMERIC(10,2) |
| `created_at` | TIMESTAMPTZ |

Both customer and worker can cancel.

The exact cancellation fee policy remains configurable/pending and must not be hard-coded into the database.

---

# 45. Worker Cancellation

When a worker cancels:

```text
Worker cancels
↓
Customer receives:
"Find another worker?"
```

If yes:

```text
gig reopened
↓
worker opportunity process begins again
```

If no:

```text
gig stops/cancelled
```

The existing gig should be reused rather than creating an unrelated new gig.

---

# 46. Rescheduling

## 46.1 `reschedule_requests`

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `gig_id` | UUID FK |
| `requested_by` | UUID FK |
| `proposed_date` | DATE |
| `proposed_start_time` | TIME |
| `proposed_end_time` | TIME |
| `reason` | TEXT |
| `status` | ENUM |
| `responded_by` | UUID FK |
| `created_at` | TIMESTAMPTZ |
| `responded_at` | TIMESTAMPTZ |

---

# 47. Reschedule Status

```text
REQUESTED
ACCEPTED
REJECTED
ALTERNATIVE_PROPOSED
```

Both customer and worker can initiate rescheduling.

The other party must respond.

A new schedule becomes active only after the request is accepted.

---

# 48. Chat

## 48.1 `conversations`

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `gig_id` | UUID FK |
| `customer_id` | UUID FK |
| `worker_id` | UUID FK |
| `created_at` | TIMESTAMPTZ |
| `updated_at` | TIMESTAMPTZ |

A conversation is associated with a gig.

---

## 48.2 `messages`

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `conversation_id` | UUID FK |
| `sender_id` | UUID FK |
| `message_text` | TEXT |
| `is_read` | BOOLEAN |
| `created_at` | TIMESTAMPTZ |

MVP supports in-app customer-worker text communication.

Calling/phone-number sharing policy remains outside this database design because the SRS has not frozen it.

---

# 49. Notifications

## 49.1 `notifications`

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `recipient_id` | UUID FK |
| `gig_id` | UUID FK |
| `type` | ENUM |
| `title` | VARCHAR |
| `body` | TEXT |
| `action_url` | TEXT |
| `is_read` | BOOLEAN |
| `created_at` | TIMESTAMPTZ |
| `read_at` | TIMESTAMPTZ |

Notifications should be generated for important state changes.

The SRS lists worker and customer notification categories including acceptance, selection, cancellation, rescheduling, completion, payment, reviews, multi-worker requests, and emergency events.

---

# 50. Previous Worker Booking

## 50.1 `previous_worker_requests`

A customer may request a worker they have previously used.

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `gig_id` | UUID FK |
| `customer_id` | UUID FK |
| `worker_id` | UUID FK |
| `status` | ENUM |
| `created_at` | TIMESTAMPTZ |
| `responded_at` | TIMESTAMPTZ |

Status:

```text
REQUESTED
ACCEPTED
REJECTED
RESCHEDULE_REQUESTED
EXPIRED
```

If the worker is unavailable/offline, the customer can open the gig to other workers.

The SRS explicitly includes previous-worker booking as part of the product workflow.

---

# 51. Geographic Eligibility — REMOVED FROM MVP

There must be **no worker geographic eligibility table or radius-matching requirement** in the MVP.

Do not implement:

```text
worker_latitude
worker_longitude
worker_radius
nearest_worker
distance_eligibility
travel_compensation
```

for worker opportunity filtering.

The customer job location still stores:

```text
address
latitude
longitude
```

for map display and job-location purposes.

---

# 52. Emergency Gig

The gig itself contains:

```text
is_emergency
```

Emergency functionality exists conceptually, but the exact:

- surcharge;
- additional worker incentive;
- emergency definition;
- emergency matching behavior

remain configurable/pending.

The MVP database should therefore support the emergency flag without hard-coding an unfinished emergency pricing formula. The SRS explicitly lists these values as pending.

---

# 53. Audit Events

## 53.1 `gig_events`

A general audit/event table is recommended.

### Columns

| Column | Type |
|---|---|
| `id` | UUID |
| `gig_id` | UUID FK |
| `actor_id` | UUID FK |
| `event_type` | VARCHAR/ENUM |
| `metadata` | JSONB |
| `created_at` | TIMESTAMPTZ |

Examples:

```text
GIG_CREATED
GIG_POSTED
WORKER_OPPORTUNITY_CREATED
WORKER_ACCEPTED
WORKER_REJECTED
WORKER_SELECTED
VISITATION_REQUESTED
VISITATION_PROPOSED
VISITATION_ACCEPTED
VISITATION_REJECTED
COMPLETION_SUBMITTED
CUSTOMER_CONFIRMED
PAYMENT_CUSTOMER_PAID
PAYMENT_WORKER_CONFIRMED
CANCELLED
RESCHEDULE_REQUESTED
RESCHEDULE_ACCEPTED
RESCHEDULE_REJECTED
REVIEW_SUBMITTED
```

This supports the SRS auditability requirement.

---

# 54. Database Relationships

Core relationships:

```text
cooperative
    1 ──── N users

users
    1 ──── 1 customer_profile
    1 ──── 1 worker_profile

worker
    N ──── N service_categories

service_category
    1 ──── N service_tasks

customer
    1 ──── N gigs

gig
    1 ──── N gig_tasks

gig
    1 ──── N worker_opportunities

worker
    1 ──── N worker_opportunities

gig
    1 ──── 1 selected_worker

worker
    1 ──── 1 worker_metrics

worker
    1 ──── N worker_experience_records

gig
    1 ──── N reviews

review
    1 ──── N review_answers

gig
    1 ──── N completion_submissions

completion_submission
    1 ──── N completion_evidence

gig
    1 ──── 1 payment

gig
    1 ──── N worker_participations

gig
    1 ──── N visitation_proposals

visitation_proposal
    1 ──── N visitation_proposal_tasks

gig
    1 ──── N cancellations

gig
    1 ──── N reschedule_requests

gig
    1 ──── 1 conversation

conversation
    1 ──── N messages

user
    1 ──── N notifications

gig
    1 ──── N gig_events
```

---

# 55. Important Database Constraints

The backend/database must enforce the following where practical.

## User

```text
One user = exactly one role.
```

## Worker

```text
Worker must belong to a cooperative.
```

## Gig

```text
One gig = exactly one service category.
```

## Gig tasks

```text
Every gig task must belong to the gig's category.
```

## Worker category

```text
Worker can have multiple categories.
```

## Opportunity

```text
One worker cannot have duplicate opportunity records for the same gig.
```

## Worker acceptance

```text
Rejected opportunity cannot be accepted.
```

## Selection

```text
Only an ACCEPTED worker can be selected.
```

## Payment

```text
Only the selected worker can receive the gig payment.
```

## Review

```text
Only participants of the completed gig can review each other.
```

## Review timing

```text
Reviews cannot exist before completion/payment eligibility.
```

## Multi-worker

```text
Additional worker must belong to the same cooperative.
```

## Rookie

```text
Rookie participation requires explicit acceptance by the additional worker.
```

## Visitation

```text
Visitation proposal requires worker participation.
```

## Completion

```text
Worker evidence must exist before customer completion confirmation.
```

## Payment

```text
Customer payment must occur before worker payment confirmation.
```

---

# 56. Important Indexes

At minimum:

```text
users(role)
users(cooperative_id)

worker_categories(worker_id)
worker_categories(category_id)

service_tasks(category_id)

gigs(customer_id)
gigs(cooperative_id)
gigs(category_id)
gigs(status)
gigs(scheduled_date)
gigs(selected_worker_id)

gig_tasks(gig_id)
gig_tasks(task_id)

gig_worker_opportunities(gig_id)
gig_worker_opportunities(worker_id)
gig_worker_opportunities(status)

worker_availability(worker_id, day_of_week)

worker_experience_records(worker_id)
worker_experience_records(gig_id)

reviews(reviewee_id)
reviews(gig_id)

payments(gig_id)
payments(worker_id)
payments(status)

messages(conversation_id, created_at)

notifications(recipient_id, is_read)

gig_events(gig_id, created_at)
```

These should be adjusted based on actual query patterns during implementation.

---

# 57. What Must NOT Be Stored

The MVP database must not introduce unnecessary entities for features that are explicitly outside the MVP.

Do not create MVP tables for:

```text
worker bidding
worker quotations
auction pricing
live worker tracking
worker GPS eligibility
travel compensation
multiple simultaneous cooperatives as a product feature
admin dashboard
institutional recurring contracts
worker community
open customer-worker community
Aadhaar verification API
police verification integration
DigiLocker integration
e-Shram integration
production insurance
production pension
```

The SRS explicitly places these kinds of capabilities outside MVP or leaves them for future development.

---

# 58. IMPORTANT PRODUCT DECISIONS ADDED DURING DATABASE DESIGN

> **This section is intentionally separate from the normal database schema.**
>
> It exists because several critical product rules were clarified after the original SRS/WAGES documents were created.
>
> **Every future AI/developer working on the backend, frontend, database, or API must read this section before modifying related functionality.**

---

## 58.1 Worker performance indicators

Every worker has three important indicators:

```text
1. Ratings
2. Number of completed jobs
3. Final score
```

Number of jobs alone must not determine worker quality/wage.

A worker can complete many easy jobs while another worker completes fewer difficult jobs.

The system therefore uses task complexity in experience calculation and combines experience with rating quality into `final_score`.

---

## 58.2 Rookie experience

A rookie participating in a job receives:

```text
50% of the job complexity value
```

as experience contribution.

Example:

```text
Job complexity = 0.4

Rookie contribution:
0.4 × 0.5 = 0.2
```

This does not represent rookie compensation.

---

## 58.3 Standard task duration

Task duration means:

> **The standard/normal duration that the task generally requires.**

It does **not** mean:

> The amount of time the worker must physically spend on the job.

Therefore:

```text
20-minute standard task
```

does not mean:

```text
worker must take 20 actual minutes
```

A worker finishing faster must not automatically receive a performance reward merely for being faster.

This distinction is consistent with the existing WAGES/SRS algorithm principles.

---

## 58.4 Base price calculation

The customer selects one category and one or more tasks from that category.

The system calculates:

```text
Selected tasks
      ↓
standard durations
      ↓
minimum billable-duration rule
      ↓
billable standard duration
      ↓
category rate per minute
      ↓
base price
```

There are **not two separate pricing models**.

The selected tasks determine the base price.

---

## 58.5 Minimum billable standard duration

The cooperative can define a minimum billable standard-duration window.

Example:

```text
Minimum = 45 standard minutes
Plumbing = ₹5/min
```

Then:

```text
20-minute task
→ billable = 45 minutes
→ base = ₹225
```

For:

```text
20 + 25 = 45 minutes
→ base = ₹225
```

For:

```text
20 + 25 + 30 = 75 minutes
→ base = ₹375
```

The 45-minute rule is a **pricing floor**, not an actual required working time.

---

## 58.6 Worker-specific wage

The customer-facing base price is not automatically the wage of every worker.

Instead:

```text
Base gig price
       ↓
Worker final_score
       ↓
0–30% premium
       ↓
Worker-specific exact wage
```

Example:

```text
Base = ₹225

Score 0.0 → ₹225
Score 0.5 → ₹258.75
Score 1.0 → ₹292.50
```

---

## 58.7 Customer price range

Before posting the gig, the customer sees the possible labour-price range.

Conceptually:

```text
Minimum = Base price
Maximum = Base price × 1.30
```

The customer does not choose the worker wage.

There is no worker bidding or negotiation.

---

## 58.8 Worker exact wage

Each worker receives an opportunity showing their own exact wage.

Example:

```text
Worker A → ₹238.50
Worker B → ₹265.50
Worker C → ₹292.50
```

Each worker independently chooses:

```text
Accept
Reject
```

The exact offered wage is stored in the opportunity.

---

## 58.9 Customer selection and payment

After workers accept:

```text
Customer sees accepted workers
        ↓
Customer sees each worker's exact wage
        ↓
Customer selects one worker
        ↓
Customer pays that worker's exact wage
```

The full agreed labour amount goes to the selected worker.

The platform does not take a transaction commission in this MVP model. The SRS establishes that the platform is not intended to extract transaction commission from worker fares.

---

## 58.10 Wage snapshot

When the worker opportunity is created:

```text
final_score
premium
exact wage
```

are calculated and stored.

If the worker's score changes later, historical offers do not change.

---

## 58.11 Multiple tasks

A customer can select multiple tasks.

All tasks must belong to the same service category.

Example:

```text
Plumbing:
✓ Tap repair
✓ Drain unclogging
✓ Pipe leakage fix
```

but:

```text
Plumbing + Electrician
```

is not allowed in one gig.

---

## 58.12 Visitation

A customer may not know the actual problem.

During gig creation, the customer can request a visitation.

The visitation costs:

```text
₹100
```

The worker visits and selects the required tasks using the **same task menu** available to the customer.

The worker submits:

```text
tasks
+
calculated price
```

The customer receives a confirmation request.

Only:

```text
Accept
Reject
```

are available for MVP.

---

## 58.13 Visitation payment

If the customer accepts the worker's proposed work:

```text
Visitation ₹100
+
Work ₹300

Final payment = ₹300
```

The ₹100 is **not added again**.

If the customer rejects:

```text
Customer pays ₹100
```

and the work does not proceed.

---

## 58.14 Visitation audit

The system must preserve:

```text
worker
proposed tasks
calculated price
timestamp
customer response
response timestamp
```

This protects against a worker silently changing/adding tasks without customer confirmation.

---

## 58.15 Geographic eligibility removed

Geographic worker eligibility is **removed from MVP**.

Do not implement:

```text
5 km emergency radius
15–20 km future radius
nearest worker
worker distance scoring
travel compensation
worker current GPS eligibility
```

A worker's current location must not prevent them from receiving a future scheduled job.

Example:

```text
Worker currently lives 30 km away.

Worker normally travels into the cooperative city.

Job is scheduled two days later.

Worker can still receive and accept the job.
```

Future emergency matching may introduce geographic logic again.

---

## 58.16 Worker location

No worker latitude/longitude is required for MVP matching.

The customer job still stores:

```text
address
latitude
longitude
```

because the customer uses an integrated map to pinpoint the job location.

---

## 58.17 Worker availability

Recurring weekly availability **is part of MVP**.

Workers can configure the hours they normally work throughout the week.

A future gig is evaluated against the worker's scheduled availability.

Current physical location is irrelevant.

---

## 58.18 Gig conflict rule

For MVP, if a worker already has a confirmed gig that overlaps with a new gig:

```text
Worker cannot accept the new gig.
```

This applies to partial overlap as well as full overlap.

Example:

```text
Existing:
10:00–11:00

New:
10:30–12:00

→ Reject acceptance
```

Do **not** implement the previous concept of warning the worker and allowing acceptance anyway.

---

## 58.19 Aadhaar

MVP only supports:

```text
Worker registration
→ upload Aadhaar document
→ store document reference
```

There is no verification.

The system must never display:

```text
Aadhaar Verified
```

merely because the document exists.

---

## 58.20 Worker roles

A user has exactly one role:

```text
CUSTOMER
OR
WORKER
```

No dual-role account in MVP.

---

## 58.21 Recommendation algorithm

The recommendation algorithm is **deferred from the immediate MVP implementation**.

The backend should return accepted-worker information.

Flutter can sort/display workers using available information such as:

```text
price
completed jobs
rating
final score
```

No backend recommendation engine should be implemented as part of the current MVP unless the project later explicitly reactivates this scope.

---

## 58.22 Multi-worker private payment

The customer pays the agreed gig amount.

If multiple workers participate:

```text
Customer
   ↓
pays agreed amount
   ↓
selected/primary worker
```

The platform does not calculate or enforce how workers privately divide that amount.

The system also does not record rookie compensation.

---

## 58.23 Payment confirmation

For:

```text
Cash
UPI
```

the platform cannot independently guarantee that the worker actually received the money.

Therefore:

```text
Customer pays
        ↓
Payment = CUSTOMER_PAID
        ↓
Worker confirms receipt
        ↓
Payment = WORKER_CONFIRMED
        ↓
Gig = COMPLETED
```

For UPI, the MVP may use a UPI deep link, but receipt confirmation remains worker-confirmed.

---

# 59. MVP Database Table Summary

The complete proposed MVP database consists of the following major tables:

```text
1.  cooperatives
2.  users
3.  customer_profiles
4.  worker_profiles
5.  worker_metrics

6.  service_categories
7.  service_tasks
8.  worker_categories
9.  worker_availability

10. gigs
11. gig_tasks
12. gig_worker_opportunities

13. worker_experience_records

14. reviews
15. review_questions
16. review_answers

17. completion_submissions
18. completion_evidence
19. completion_confirmations

20. payments
21. material_receipts

22. worker_participations

23. visitation_proposals
24. visitation_proposal_tasks

25. gig_cancellations
26. reschedule_requests

27. previous_worker_requests

28. conversations
29. messages

30. notifications

31. gig_events
```

---

# 60. Final Database Architecture

The most important transactional chain is:

```text
USER
 ↓
WORKER / CUSTOMER
 ↓
GIG
 ↓
GIG TASKS
 ↓
BASE PRICE
 ↓
WORKER OPPORTUNITIES
 ↓
WORKER-SPECIFIC WAGE
 ↓
WORKER ACCEPTANCE
 ↓
CUSTOMER SELECTION
 ↓
SCHEDULED JOB
 ↓
COMPLETION EVIDENCE
 ↓
CUSTOMER CONFIRMATION
 ↓
PAYMENT
 ↓
WORKER PAYMENT CONFIRMATION
 ↓
COMPLETED
 ↓
TWO-WAY REVIEWS
 ↓
WORKER METRICS / EXPERIENCE / FINAL SCORE
```

This creates the feedback loop:

```text
Completed jobs
      +
Task complexity
      +
Customer reviews
      ↓
Worker metrics
      ↓
Final score
      ↓
Future worker-specific wage
```

The underlying historical records remain preserved so that current worker metrics can change without rewriting previous transactions.

---

# 61. Implementation Rule

The backend must treat the database constraints and business rules in this document as authoritative.

The Flutter client must **not** be trusted to enforce:

- pricing;
- worker wage;
- role restrictions;
- task/category consistency;
- availability conflicts;
- opportunity status;
- worker selection;
- payment state;
- completion state;
- review eligibility;
- rookie experience contribution.

Those calculations and validations belong in the backend/database layer.

This follows the project's methodology of keeping deterministic business logic in the backend rather than duplicating critical logic in the presentation layer.
