# 📋 Client Clarification Questionnaire: Check-In & Compliance Logic

Dear Client,

To ensure the Staff Check-In app functions exactly according to your operational store policies and manager workflows, please review and answer the following business logic questions. Multiple-choice options are provided for quick selection.

---

## 1. Snooze Limit & Reminder Policy
**Context:** When a scheduled compliance check is due, an audible alert dialog pops up on the staff tablet/mobile. Staff can tap **"Remind me again in 15 minutes"**.

* **Question:** How many times is staff allowed to snooze a single check-in?
  * [ ] **Option A (Current): Strict (1 time only)** — Staff can snooze once for 15 minutes. After that, the snooze button disappears and the check must be started.
  * [ ] **Option B: Limited (e.g., 2 or 3 times)** — Staff can snooze up to a fixed limit (e.g., 2 times = 30 mins maximum delay).
  * [ ] **Option C: Unlimited with Escalation** — Staff can keep snoozing, but after each snooze, an escalation flag or manager notification is logged.

---

## 2. "Missed" vs "Overdue" Transition Threshold
**Context:** Currently, if the scheduled time passes, the check becomes **Overdue**. We need to define when it officially transitions from **Overdue** to **Missed**, so upcoming checks can take priority on the dashboard hero card.

* **Question:** At what point should a check-in be automatically marked as **"Missed"**?
  * [ ] **Option A: Fixed Time Window** — Exactly **30 minutes** (or **45 / 60 minutes**) after the scheduled time.
  * [ ] **Option B: When the Next Scheduled Check Arrives** — The check remains "Overdue" until the next check-in time arrives (e.g., if 2:00 PM check is pending, it becomes "Missed" when the 4:00 PM check becomes active).
  * [ ] **Option C: End of Shift / End of Day** — It stays overdue throughout the shift, and only marks "Missed" if store closes or day ends without completion.

---

## 3. Submitting a "Missed" Check-In
**Context:** The app allows staff to start and complete a check-in even if it has been marked as "Missed".

* **Question:** Should staff be allowed to complete a missed check-in late?
  * [ ] **Option A: Yes, allow late completion** — Staff can complete it anytime during the day. The log records it as `"Completed (Late / Missed)"` for manager audit.
  * [ ] **Option B: Yes, but require a Reason/Note** — Staff can start it, but must enter a mandatory brief note explaining why it was missed.
  * [ ] **Option C: No, lock it** — Once marked "Missed", it is permanently closed and staff cannot submit it.

---

## 4. Overlapping Scheduled Checks (Queue Priority)
**Context:** What happens on the Home dashboard if Check #1 is still pending or overdue, and the time for Check #2 arrives?

* **Question:** Which check should be displayed on the main Hero Card?
  * [ ] **Option A: Oldest Overdue Check First** — Keep showing the overdue check until resolved, with a badge indicating "1 more check waiting".
  * [ ] **Option B: Latest Active Check** — Switch the main Hero Card to the new check, while showing the red Overdue Alert Banner for the older check.
  * [ ] **Option C: Multi-Card Carousel** — Allow staff to swipe between both active/overdue checks on the Home screen.

---

## 5. Store Location / GPS Geofencing Strictness
**Context:** When submitting a check-in, the app captures device GPS coordinates and compares them against the store's configured radius (e.g., 150 meters).

* **Question:** What should happen if staff is slightly outside the GPS radius (e.g., poor satellite signal inside a basement or kitchen)?
  * [ ] **Option A: Hard Block** — Prevent submission until staff is inside the exact store perimeter.
  * [ ] **Option B: Soft Warning with Manager Flag** — Allow submission, but mark the log with `"Flagged: Submitted outside radius (X meters away)"`.
  * [ ] **Option C: Reason Prompt** — Prompt staff to confirm why GPS is outside (e.g., "Weak GPS signal indoors").

---

## 6. Manager Escalation Mechanism
**Context:** The overdue banner states: *"Hygiene Check — escalated to your manager."*

* **Question:** How should managers actually be notified when a check is overdue or missed?
  * [ ] **Option A: Dashboard Audit Only** — Highlighted in red in the web admin/manager portal reports (no direct push/SMS).
  * [ ] **Option B: Push Notification / Email** — Send an automated email or push notification to the store manager.
  * [ ] **Option C: WhatsApp / SMS Alert** — Trigger an SMS or WhatsApp alert to the designated store supervisor.

---

## 7. Training Resources URL
**Context:** We have replaced the notifications banner with the **Training Resources Card** on the Home screen (currently pointing to `google.com` as a placeholder).

* **Question:** What is the destination URL or portal you would like staff to be redirected to when tapping **"ACCESS TRAINING"**?
  * URL: __________________________________________________
  * (e.g., Internal LMS portal, Google Drive training folder, YouTube training playlist, Notion doc, etc.)

---

## 8. Staff Authentication & Session Persistence (Auto-Login vs Regular PIN)
**Context:** When a staff member enters their 4-digit PIN, they enter the app dashboard. We need to decide how long the session stays active.

* **Question:** How should staff login sessions behave during the store operational day?
  * [ ] **Option A: Persistent Store Session (Recommended for Shared Kiosk)** — Once a staff member logs in, the app stays on the Home dashboard continuously (even if closed and reopened). It only asks for a PIN when someone explicitly taps **"SWITCH STAFF"** or logs out.
  * [ ] **Option B: Auto-Lock on Inactivity / App Minimize** — The app automatically locks and requires a 4-digit PIN if untouched for a certain period (e.g., 5 or 10 minutes) or whenever the app is minimized/reopened.
  * [ ] **Option C: Store-Level Open Dashboard + PIN on Submit** — The Home dashboard and tasks list are open to view by all store staff without login, but when tapping "START CHECK" or submitting the checklist, the staff member must enter their 4-digit PIN to attribute the checklist to their name.

---

## 9. Kiosk Mode Architecture & Store / Staff Control
**Context:** On the Profile screen, there is a field indicating **"Kiosk mode: Active"**. In retail and hospitality environments, Kiosk mode can be handled at the **Device Level** (shared tablet) or **User Role Level** (admin-controlled per staff).

* **Question:** Which Kiosk mode model best fits your store workflow?
  * [ ] **Model 1: Shared Store Kiosk Device (Device-Level — Recommended)**
    * The store tablet/iPad is designated as a fixed "Store Kiosk" bound to `storeId` (e.g., Islamabad Store).
    * The operating system (iOS Guided Access / Android Kiosk) locks the device to the Staff Check-In app so staff cannot exit or open other apps.
    * Admin sets kiosk policy for the store location via the Admin Portal, not per individual staff member. Any staff on shift simply punches their PIN to complete tasks.
  * [ ] **Model 2: Per-Staff Role Permission (User-Level from Admin)**
    * Configured in the Web Admin Portal per staff member profile (e.g., `isActive: true, kioskLock: true`).
    * When regular staff logs in, settings/exit are restricted. When a Store Manager PIN logs in, an admin unlock code or full exit access is enabled.
  * [ ] **Model 3: Hybrid Store Display with Manager Override**
    * The app runs in kiosk full-screen mode by default, but provides a hidden or manager PIN-protected exit button to access device Wi-Fi, settings, or app updates.

---

### Summary Checklist for Quick Response:
| Question | Selected Option | Additional Notes |
|---|---|---|
| **1. Snooze Limit** | [ ] A &nbsp; [ ] B &nbsp; [ ] C | |
| **2. Missed Threshold** | [ ] A &nbsp; [ ] B &nbsp; [ ] C | If Option A, specify minutes: ___ |
| **3. Late Missed Submission** | [ ] A &nbsp; [ ] B &nbsp; [ ] C | |
| **4. Overlapping Checks** | [ ] A &nbsp; [ ] B &nbsp; [ ] C | |
| **5. GPS Geofence Policy** | [ ] A &nbsp; [ ] B &nbsp; [ ] C | |
| **6. Manager Escalation** | [ ] A &nbsp; [ ] B &nbsp; [ ] C | |
| **7. Training URL** | _______________________ | |
| **8. Session / Auto-Login** | [ ] A &nbsp; [ ] B &nbsp; [ ] C | |
| **9. Kiosk Mode Model** | [ ] Model 1 &nbsp; [ ] Model 2 &nbsp; [ ] Model 3 | |

