# Backend & Frontend Integration Testing Protocol

## SIH26089 — Sahakaar Seva Cooperative Household Services Platform

**Document:** Integration Testing, Local Environment Setup, and State Machine Verification  
**Target:** Local Prototype Demonstration & Final SIH 2026 Evaluation  
**Architecture:** FastAPI (Python 3.11+ / SQLAlchemy / PostgreSQL) + Flutter 3.x (Dart / Android)  

---

## 1. Document Purpose & Scope

This document provides the definitive, actionable protocol for verifying end-to-end integration between the **Sahakaar Seva Backend** and the **Flutter Mobile App**.

It defines:
1. **Local USB-Reverse Environment Setup**: Eliminates external cloud network latency (reducing 15–20s cloud cold-start delays to `< 5ms` local execution).
2. **Authoritative Gig Lifecycle & Cancellation Matrix**: Exact rules for when a gig may or may not be cancelled, the financial penalties applied, and the corresponding UI constraints derived from `SRS_Final.md`, `04_DATABASE_DESIGN.md`, `05_API_DESIGN.md`, and `cancellation_service.py`.
3. **Pre-Configured Evaluation Accounts**: Seeded credentials showcasing customer gig dispatch and three tiered worker profiles with algorithmic wage variations.
4. **Comprehensive Step-by-Step Test Suite**: Verification scenarios covering the entire lifecycle from job creation to UPI settlement and dual mutual reviews.

*(Note: In accordance with project requirements, this document contains no sprint divisions and leaves video recording scripts to the evaluation team).*

---

## 2. Ultra-Fast Local Environment Setup

### 2.1 Why Local Backend is Required for Evaluation
In cloud hosting (e.g., Railway free tier), database sleeping and cross-region routing introduce 15–20 second response times. For an evaluation or recording, this creates unacceptable lag. By running FastAPI locally and routing device traffic over USB via Android Debug Bridge (`adb reverse`), all requests execute in **under 5 milliseconds**.

### 2.2 Prerequisites
- PostgreSQL running locally on port `5432` with database `sih_gig_db` (or Supabase local).
- Python 3.11+ with backend virtual environment active.
- Android device connected via USB cable with **USB Debugging** enabled in Developer Options.
- `adb` accessible in system `PATH`.

### 2.3 Step-by-Step Launch Commands

#### Step 1: Start the Local FastAPI Backend
Open a terminal in the project root:
```powershell
cd d:\Tech_Projects\10_SIH_2026\SIH_2026\backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
*Verification:* Navigate to `http://127.0.0.1:8000/docs` in your browser. The OpenAPI Swagger interface should load instantly.

#### Step 2: Establish USB Reverse Port Forwarding
Open a second terminal:
```powershell
adb devices
# Verify your device (e.g. A142) is listed as "device"

adb reverse tcp:8000 tcp:8000
```
*What this does:* Any HTTP request sent by the physical Android phone to `http://127.0.0.1:8000` is forwarded over the USB cable directly to port 8000 on your development PC.

#### Step 3: Verify Phone-to-PC Connectivity
On your computer, run:
```powershell
curl http://127.0.0.1:8000/api/v1/health
```
*Expected response:*
```json
{"status":"ok","app":"Sahakaar Seva Backend","version":"0.1.0"}
```

#### Step 4: Mobile App Endpoint Configuration
The Flutter application's default endpoint in `mobile_app/lib/services/token_storage.dart` is pre-configured to:
```dart
static const String defaultBaseUrl = 'http://127.0.0.1:8000/api/v1';
```
No manual configuration is required in the app settings.

---

## 3. Pre-Seeded Evaluation Credentials

To demonstrate algorithmic pricing, ranking factors, and tiered experience during judging, four pre-configured accounts are seeded in the database:

| Role | Email | Password | Profile Details & Tariff Tier |
| :--- | :--- | :--- | :--- |
| **Customer** | `customer@example.com` | `password123` | Default customer account. Used for creating gigs, selecting workers, approving work, and initiating UPI payments. |
| **Worker 1 (Master / High XP)** | `worker1@example.com` | `password123` | **Name: Rajesh**<br>• Experience: 9+ Years (Master Artisan)<br>• Rating: 4.9 ★ (41 completed jobs)<br>• Wage Tier: **+30% Algorithmic Premium** (Highest rate) |
| **Worker 2 (Journeyman / Mid XP)** | `worker2@example.com` | `password123` | **Name: Rajesh**<br>• Experience: 4 Years (Journeyman)<br>• Rating: 4.7 ★ (23 completed jobs)<br>• Wage Tier: **+15% Algorithmic Premium** (Moderate rate) |
| **Worker 3 (Entry / Rookie)** | `worker3@example.com` | `password123` | **Name: Rajesh**<br>• Experience: 1 Year (Apprentice / Rookie)<br>• Rating: 4.5 ★ (6 completed jobs)<br>• Wage Tier: **Base Tariff** (Lowest rate, apprentice track) |

> **Judging Note on Pricing Differentiation:**  
> When the Customer posts a plumbing task (e.g. *Leaking tap repair*, base duration 20 min), all three workers receive the opportunity. Per the formula in `docs/WAGES.md`:
> $$\text{worker\_wage} = \text{base\_task\_wage} \times (1 + \text{final\_score} \times 0.3)$$
> Worker 1 will quote the highest fair wage, Worker 2 mid-tier, and Worker 3 the lowest baseline rate. This transparently proves algorithmic fairness without predatory race-to-the-bottom bidding.

---

## 4. Authoritative Gig Lifecycle & Cancellation Matrix

The cancellation policy is enforced authoritatively on the backend (`backend/app/services/cancellation_service.py`) and reflected on the frontend. Once physical work commences, cancellation is **strictly forbidden**.

### 4.1 State-by-State Rules

| Internal State | Visible Stage | Can Customer Cancel? | Fee Amount | Can Worker Cancel? | Allowed Next States | UI Action & Constraint |
| :--- | :--- | :---: | :---: | :---: | :--- | :--- |
| `DRAFT` | Draft | **YES** | ₹0.00 | N/A | `POSTED`, `CANCELLED` | "Cancel Draft" button. |
| `POSTED` / `ACCEPTANCE_OPEN` | Seeking / Responding | **YES** | **₹0.00** | N/A (Can reject invite) | `WORKER_SELECTED`, `CANCELLED` | "Cancel Gig Request" is visible at bottom with ₹0 fee notice. |
| `WORKER_SELECTED` / `SCHEDULED` | Scheduled | **YES** | **₹50.00** | **YES** (Prior to arrival) | `IN_PROGRESS`, `CANCELLED`, `REOPENED` | **Customer:** Show ₹50 fee warning before cancel.<br>**Worker:** Cancelling prompts customer: *"Find another worker?"* (`/reopen`) or *Stop*. |
| `IN_PROGRESS` | Active / Work Started | **STRICTLY NO** | N/A | **STRICTLY NO** | `COMPLETION_REQUESTED`, `DISPUTED` | **"Cancel Gig" option is completely removed from UI.** Bottom action shows *"Open Active Job Workspace"*. Backend returns `GIG_CANNOT_BE_CANCELLED`. |
| `COMPLETION_REQUESTED` | Completion Audit | **STRICTLY NO** | N/A | **STRICTLY NO** | `CUSTOMER_CONFIRMED`, `DISPUTED` | Worker submitted completion proof photos. Customer must verify or raise dispute. |
| `CUSTOMER_CONFIRMED` / `PAYMENT_PENDING` | Payment Required | **STRICTLY NO** | N/A | **STRICTLY NO** | `PAYMENT_CUSTOMER_PAID` | Customer approved the work. Primary button: *"Proceed to Payment"*. |
| `PAYMENT_CUSTOMER_PAID` | Payment Verifying | **STRICTLY NO** | N/A | **STRICTLY NO** | `COMPLETED` | Customer completed UPI payment. Shows green card: *"Payment Complete · Awaiting worker receipt confirmation"*. |
| `COMPLETED` | Closed / Completed | **STRICTLY NO** | N/A | **STRICTLY NO** | None | Gig archived. Structured 4-category mutual reviews unlocked. |

---

## 5. End-to-End Integration Verification Checklist

Execute the following test cases in order to validate complete frontend-to-backend integration.

### Test Case 1: Local Server & Reverse Proxy Validation
- [ ] Connect Android device via USB.
- [ ] Execute `adb reverse tcp:8000 tcp:8000`.
- [ ] Run `curl http://127.0.0.1:8000/api/v1/health` from PC. Verify HTTP 200 `status: ok`.
- [ ] Open Sahakaar Seva app on device. Verify splash screen connects without network timeout dialog.

### Test Case 2: Customer Authentication & Fast Skeleton Loading
- [ ] Log in as Customer (`customer@example.com` / `password123`).
- [ ] Observe initial feed load: verify left-to-right shining shimmer cards (`GigCardSkeleton`) appear smoothly without screen flashing or blocking circular spinners.
- [ ] Perform pull-to-refresh: verify existing feed data remains visible during background reload.

### Test Case 3: Create Household Gig (Plumbing Catalog)
- [ ] Tap **Create Gig** (`+`) on Customer Home.
- [ ] Select category: **Plumbing**.
- [ ] Choose task: **Leaking tap repair** (Duration: 20 min, Base Tariff: ₹100 per `WAGES.md`).
- [ ] Toggle procurement mode: *Customer provides materials*.
- [ ] Set schedule time: *Today · Immediate*.
- [ ] Tap **Publish Gig**.
- [ ] **Verification:**
  - Backend receives `POST /api/v1/gigs/`.
  - Database status becomes `POSTED` / `ACCEPTANCE_OPEN`.
  - Gig appears on Customer Home with status badge `"Seeking Workers"`.
  - Open Gig Details: Bottom bar shows **"Cancel Gig Request"** with ₹0.00 fee notice.

### Test Case 4: Multi-Worker Opportunity Dispatch & Tiered Pricing Inspection
- [ ] Open Worker 1 (`worker1@example.com`):
  - Check **Opportunities** tab. Notice opportunity card appears with highest recommended wage (e.g. ₹130, reflect +30% master bonus).
  - Tap **Accept Opportunity**. Status changes to `"Waiting for customer confirmation"`.
- [ ] Open Worker 2 (`worker2@example.com`):
  - Check Opportunities. Notice mid-tier rate (e.g. ₹115).
  - Tap **Accept Opportunity**.
- [ ] Open Worker 3 (`worker3@example.com`):
  - Check Opportunities. Notice entry base rate (₹100).
  - Tap **Accept Opportunity**.
- [ ] **Verification:**
  - Backend creates `GigWorkerOpportunity` records for all three workers.
  - All three workers appear as candidates under the Customer's gig.

### Test Case 5: Customer Candidate Comparison & Worker Selection
- [ ] Switch back to Customer app.
- [ ] Tap the active gig card. Status now displays `"3 Candidates Available"`.
- [ ] Review the candidate comparison screen:
  - Worker 1 highlighted for *Highest Experience & Quality*.
  - Worker 3 highlighted for *Lowest Labour Wage*.
- [ ] Select **Worker 1 (Rajesh)** and tap **Confirm Artisan**.
- [ ] **Verification:**
  - Backend executes `POST /api/v1/gigs/{gig_id}/select-worker`.
  - Gig status transitions to `WORKER_SELECTED` / `SCHEDULED`.
  - Other worker opportunities transition to `EXPIRED`.
  - Cancellation fee shifts from ₹0.00 to **₹50.00** policy fee.

### Test Case 6: Worker Arrival & Job Commencement (Cancellation Lock)
- [ ] Switch to Worker 1 app.
- [ ] Navigate to **My Jobs** → **Active & Upcoming**.
- [ ] Tap the scheduled job to open the **Worker Active Job Workspace**.
- [ ] Tap **Start Working**.
- [ ] **Verification:**
  - Backend executes `POST /api/v1/gigs/{gig_id}/start`.
  - Gig status updates to `IN_PROGRESS`.
  - Switch to Customer app: Open Gig Details.
  - **CRITICAL CHECK:** Verify the "Cancel Gig Request" button is **completely gone**.
  - Customer UI displays active workspace status with assigned worker card.

### Test Case 7: Completion Proof Upload (Worker)
- [ ] In Worker Active Job Workspace, tap **Complete Work**.
- [ ] Upload completion photo (take camera snapshot or select test photo).
- [ ] Enter summary notes: *"Replaced tap washer and resealed valve joint. Tested under water pressure."*
- [ ] Tap **Submit Completion Evidence**.
- [ ] **Verification:**
  - Backend executes `POST /api/v1/gigs/{gig_id}/completion-evidence`.
  - Gig status transitions to `COMPLETION_REQUESTED`.
  - Worker screen transitions to *"Waiting for customer approval"*.

### Test Case 8: Customer Verification & UPI Deep Link Settlement
- [ ] Open Customer app.
- [ ] Tap the completion notification / active gig.
- [ ] Review before/after work evidence and tap **Approve Completion**.
- [ ] Gig transitions to `CUSTOMER_CONFIRMED` / `PAYMENT_PENDING`.
- [ ] Tap **Proceed to Payment**.
- [ ] Select payment method: **UPI Direct**.
- [ ] Tap **Pay with UPI**:
  - The native Android intent triggers `upi://pay?pa=yugshah5253@oksbi&pn=Sahakaar%20Seva&am=...&cu=INR`.
  - Device prompts to select an installed UPI app (Google Pay / PhonePe / Paytm / BHIM) with prefilled VPA `yugshah5253@oksbi` and exact job amount.
- [ ] Upon returning from the payment sheet, tap **I Have Paid**.
- [ ] **Verification:**
  - Backend executes `POST /api/v1/gigs/{gig_id}/payments/customer-paid`.
  - Gig status transitions to `PAYMENT_CUSTOMER_PAID`.
  - Customer screen displays green card: *"Payment Complete · Awaiting worker receipt confirmation"*. No cancel button appears.

### Test Case 9: Worker Payment Confirmation & Dual Review Loop
- [ ] Open Worker 1 app → **My Jobs**.
- [ ] Worker screen prompts: *"Customer has marked payment as completed via UPI. Have you received the funds?"*
- [ ] Tap **Confirm Payment Received**.
- [ ] **Verification:**
  - Backend executes `POST /api/v1/gigs/{gig_id}/payments/worker-confirm`.
  - Gig status transitions to `COMPLETED`.
- [ ] Complete 4-category review (Quality, Punctuality, Behavior, Communication) on both Worker and Customer apps.
- [ ] Gig moves to **Completed** tab on both profiles.

---

## 6. Diagnostics & Common Troubleshooting

| Issue / Symptom | Root Cause | Resolution |
| :--- | :--- | :--- |
| App shows *"Cannot connect to server"* or infinite spinner | `adb reverse` dropped after cable disconnect | Re-run `adb reverse tcp:8000 tcp:8000` in PowerShell. |
| Port 8000 already in use error on PC | Previous uvicorn process still running | Run `Get-Process python \| Stop-Process -Force` then restart uvicorn. |
| Customer tries to cancel during `IN_PROGRESS` via direct API | Backend state guard | Backend will correctly reject with HTTP 409 `GIG_CANNOT_BE_CANCELLED`. |
| UPI App does not launch | No UPI application installed or running on Android Emulator | Physical Android device with PhonePe/GPay/Paytm installed is required for full native UPI intent handling. |
