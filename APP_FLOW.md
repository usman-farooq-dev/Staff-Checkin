# Staff Check-In App - Complete Architecture & Flow Guide

Is document mein **Staff Check-In App** ka mukammal flow, architecture, screens, aur Firestore database structure aasan alfaz mein explain kiya gaya hai.

---

## 📌 1. Overall System Architecture

```
[Staff PIN Screen] ──(Authentication)──► [Home / Main Navigation]
                                                 │
         ┌───────────────────────────────────────┼───────────────────────────────────────┐
         ▼                                       ▼                                       ▼
  [Home Screen]                            [Tasks Screen]                        [History Screen]
  - Real-time Clock                        - Filter by Status                    - Past Submissions
  - Store Name & City (Streamed)           - Pending / Missed Checks             - Detailed Audit Log
  - Next Check Hero Card                   - Tap to Start Check                  - Photos & GPS records
  - Overdue Alert Banner (START NOW)
  - Today's Progress Bar (Segmented)
  - Compliance Alert (Mobile: Fullscreen / Tablet: Modal Dialog)
         │
         ▼
  [Checklist Screen] ◄─── (Start Check)
         │
         ├─► [Camera Capture] (Photo Evidence)
         ├─► [GPS Location Verification]
         │
         ▼
  [Submit Check-In] ──► Updates Firestore:
                         1. Creates document in `CheckIn_Logs`
                         2. Updates `Scheduled_CheckIn` -> `storeStatus.<storeId> = 'completed'`
```

---

## 📱 2. Step-by-Step App Flow

### Step 1: Authentication (`PinScreen`)
1. **Entry Point**: App open hone par sab se pehle PIN screen aati hai.
2. **Keypad**:
   - Mobile par portrait compact keypad.
   - Tablet/iPad par properly centered landscape/portrait optimized layout.
   - Backspace icon ke sath custom numeric keypad (1 to 9, 0, Backspace).
3. **Validation**:
   - Staff 4-digit PIN enter karta hai.
   - App Firestore collection `Staff_Users` mein check karti hai ke PIN match karta hai ya nahi aur staff `isActive == true` hai ya nahi.
   - **Web / Offline Fallback**: Agar web browser par Firestore SDK initialize na ho to REST API fallback lagaya gaya hai taake screen loading par hang na ho.
4. **Success**: Valid PIN par user data memory aur local storage mein save hota hai aur app **Home Screen** par navigate karti hai.

---

### Step 2: Main Navigation (`MainNavWrapper`)
App ke bottom par 4 main tabs hain:
1. **Home (`HomeScreen`)**: Daily dashboard aur urgent alerts.
2. **Tasks (`TasksScreen`)**: Aaj ke tamam scheduled compliance tasks.
3. **History (`HistoryScreen`)**: Puraani complete ki hui check-ins ka record.
4. **Profile (`ProfileScreen`)**: Staff profile info aur Logout option.

---

### Step 3: Home Dashboard (`HomeScreen`)
Home screen par dynamic realtime data show hota hai:
1. **Header**:
   - Left side: Aaj ki date (`Saturday, August 29`), Greeting (`Good Evening, Ahmed`), aur Store Location marker (`Islamabad Store`). Store ka city `Stores` collection se realtime stream hota hai.
   - Right side: Realtime digital clock badge jo har second update hota hai.
2. **Overdue / Missed Alert Banner (Red Card)**:
   - Agar koi check scheduled time se late ho jaye ya miss ho jaye to red banner show hota hai:
     - `1 check overdue / [Check Title] — escalated to your manager.`
     - **START NOW** button jo direct checklist open karta hai.
3. **Next Check Hero Card (Dark Green Card)**:
   - Aaj ka sab se pehla pending ya missed check show karta hai.
   - Time (e.g. `4:37 PM`), Title (`Hygiene Check`), overdue/due duration, aur total tasks.
   - **START CHECK** orange button.
4. **Today's Progress Card**:
   - Din ke total checks aur completed checks ka ratio (e.g. `5/8 finished - 63%`).
   - Dynamic segmented green bars.
5. **Training Resources Card (Always Visible)**:
   - Compliance training aur operational guidelines ka card jo screen par hamesha visible rehta hai.
   - **ACCESS TRAINING** button ke sath jo external training links (filhal testing ke liye Google) par redirect karta hai.

---

### Step 4: Scheduled Compliance Alert
Jab kisi check ka time hota hai to app automated popup trigger karti hai:
* **Mobile View**:
  - Fullscreen dark alert with bell icon, time, due info, and action buttons.
* **Tablet / iPad View (Mockup 03)**:
  - Screen dim (semi-transparent black overlay) ho jati hai.
  - Center mein focused dark modal dialog open hota hai:
    - Top Warning Triangle Icon container.
    - Subtitle: `Compliance Check Overdue`.
    - Main Title: `Hygiene Check`.
    - Two columns: `Scheduled time` aur `Status: OVERDUE`.
    - Notice: `"This check is now overdue and has been reported to your manager. Please complete it now."`
    - Large Orange **`START CHECK`** button.
    - **`REMIND ME AGAIN IN 15 MINUTES`** text button.
* **Reminder Audio Tune Playback**:
  - Alert trigger hotay hi user ki selected **Reminder Tune** bajna shuru ho jati hai.
  - Jab staff **`START CHECK`**, **`REMIND ME AGAIN`**, ya dialog dismiss karta hai to audio foran **STOP** ho jata hai.
* **Snooze Policy**:
  - Remind later sirf **ek bar (1 time)** allow hota hai (+15 minutes). Ek bar snooze karne ke baad snooze option hide ho jata hai.

---

### Step 4.1: Reminder Tune Settings (`ReminderTuneScreen`)
1. **Access**: Profile tab mein **Sound & alerts** ke andar **Reminder tune** par tap karne se khulti hai.
2. **Tunes List**:
   - `Chime (Default)`: Gentle two-tone chime.
   - `Digital Bell`: Crisp digital chime.
   - `Pulse Alert`: Modern triple-pulse alert.
   - `Gentle Chime`: Soft three-tone melody.
   - `Buzzer Alert`: Audible urgent compliance tone.
3. **Interactive Features**:
   - Kisi bhi tune par tap karne se wo live preview play karti hai aur default select ho jati hai.
   - Selection local device storage (`SharedPreferences`) mein save hoti hai taake app restart ke baad bhi preference barkarar rahe.


---

### Step 5: Tasks Screen (`TasksScreen`)
1. Aaj ke tamam checks Firestore collection `Scheduled_CheckIn` se fetch hotay hain.
2. Status badges:
   - **Upcoming**: Check abhi aane wala hai.
   - **Overdue**: Time guzar gaya hai aur abhi tak pending hai.
   - **Missed**: Check miss ho gaya tha lekin staff abhi bhi is par tap kar ke start kar sakta hai.
   - **Completed**: Check submit ho chuka hai (green badge).
3. Staff kisi bhi active (pending/overdue/missed) task card par tap kar ke checklist screen par ja sakta hai.

---

### Step 6: Checklist & Evidence Submission (`HygieneChecklistScreen`)
1. **Tasks List**: Scheduled check ke andar jitne individual sub-tasks define hotay hain (e.g. Clean counters, sanitize equipment, check fridge temperature).
2. **Checkboxes & Camera**:
   - Staff task ko complete mark karta hai.
   - Evidence photo lene ke liye Camera icon tap karta hai.
3. **Camera Screen (`CameraCaptureScreen`)**:
   - Device camera open hota hai, photo capture hoti hai aur task ke sath attach hoti hai.
4. **Location Check**:
   - Submission ke waqt GPS location fetch ki jaati hai taake verify ho sake ke staff store ke andar hi mojood hai.
5. **Submit Check-In**:
   - Jab staff "SUBMIT CHECK-IN" press karta hai:
     - **`CheckIn_Logs`**: Naya submission record create hota hai (timestamp, staff details, store details, task results, photo paths, GPS coordinates).
     - **`Scheduled_CheckIn`**: Current check ke doc mein `storeStatus.<storeId>` ko `"completed"` update kar diya jata hai.
     - User ko success dialog dikha kar Home screen par redirect kar diya jata hai.

---

### Step 7: History Screen (`HistoryScreen` & `HistoryDetailScreen`)
1. Staff ya manager previous tamam submissions ki history dekh sakta hai.
2. Filter by date range (Today, Yesterday, Last 7 days, Custom).
3. Kisi bhi record par tap karne se `HistoryDetailScreen` open hoti hai jisme:
   - Submitted staff name aur store.
   - Submission exact time.
   - Completed checklist items.
   - Captured photos.
   - Store GPS verification status.

---

## 🗄️ 3. Database Structure (Firestore Collections)

### 1. `Staff_Users`
* Staff credentials aur roles:
```json
{
  "id": "staff_001",
  "pin": "1234",
  "fullName": "Ahmed Khan",
  "role": "Staff",
  "storeId": "store_islamabad",
  "storeName": "Islamabad Store",
  "isActive": true
}
```

### 2. `Scheduled_CheckIn`
* Daily scheduled compliance checks:
```json
{
  "id": "check_hygiene_morning",
  "title": "Hygiene Check",
  "scheduledAt": "2026-09-04T16:37:00.000Z",
  "status": "pending",
  "storeStatus": {
    "store_islamabad": "pending",  // ya "missed", "completed"
    "store_lahore": "completed"
  },
  "remindAt": {
    "store_islamabad": 1788523500000
  },
  "snoozeCount": {
    "store_islamabad": 1
  },
  "tasks": [
    {
      "id": "task_1",
      "title": "Sanitize food counters",
      "requiresPhoto": true
    },
    {
      "id": "task_2",
      "title": "Check refrigerator temperature",
      "requiresPhoto": false
    }
  ]
}
```

### 3. `CheckIn_Logs`
* Completed submissions ki history:
```json
{
  "id": "log_xyz789",
  "checkId": "check_hygiene_morning",
  "checkTitle": "Hygiene Check",
  "staffId": "staff_001",
  "staffName": "Ahmed Khan",
  "storeId": "store_islamabad",
  "storeName": "Islamabad Store",
  "completedAt": "2026-09-04T16:50:00.000Z",
  "tasksCompleted": 5,
  "totalTasks": 5,
  "status": "completed",
  "gpsLocation": {
    "latitude": 33.6844,
    "longitude": 73.0479
  }
}
```

### 4. `Stores`
* Store metadata:
```json
{
  "id": "store_islamabad",
  "name": "Islamabad Store",
  "city": "Islamabad",
  "latitude": 33.6844,
  "longitude": 73.0479,
  "radiusMeters": 150
}
```

---

## 💡 4. Responsive Device Support
* **Mobile (Phones)**:
  - Single column scrolling.
  - Compact numeric keypad on PIN screen.
  - Fullscreen compliance alert.
* **Tablet (iPads / Tablets)**:
  - Centered PIN card layout.
  - Tablet Home screen with top-right clock badge and 24px padding.
  - Centered floating Dark Modal Dialog for compliance alerts (Mockup 03).
  - Responsive multi-column task cards.
