# Complete Firestore, History, Permissions & Scheduled Alerts Guide

Yeh document explain karta hai:
1. **Staff Authentication Requirement for Scheduled Alerts (No Alerts When Logged Out)**
2. **Scheduled Check-In Alert Auto-Trigger & 1-Time 15-Minute Snooze Rule**
3. **Firestore Fields for 15-Minute Snooze & Snooze Count** (`remindAt.<storeId>`, `snoozeCount.<storeId>`)
4. **Notifications Disabled Banner & Direct Permission Ask (Auto-Hide Banner)**
5. **Real-time Live Clock & Location Permission on Home Screen**
6. **Current Store City Display (Marker Icon)**
7. **Profile / Settings Real Device Permissions (Auto-Hide Review Button & Allowed/Blocked Status)**
8. **History Tab Filtering & Grouping Logic** (Today Completed, Past Completed & Missed)
9. **`CheckIn_Logs` & `Stores` Location Integration in History Details**
10. **Full Media Evidence Preview (Videos & Photos)**
11. **High-Efficiency Media Compression on Upload**

---

## 1. Staff Authentication Requirement for Alerts

- **Strict Session Verification:**
  - Scheduled alert popup **sirf aur sirf us waqt trigger hoga jab koi active staff member logged in ho** (`StaffAuthService.instance.isLoggedIn == true` aur `currentStaff.isActive == true` aur valid `storeId` ho).
  - Agar user PIN screen par hai ya "SWITCH STAFF" se logout ho chuka hai, to **koi bhi compliance reminder popup open nahi hoga**.

---

## 2. Scheduled Alert & 1-Time Snooze Rule (Only Once)

### First Time Alert Shows:
- Jab scheduled time aata hai aur staff logged in hota hai to alert screen pop-up hoti hai.
- Options: **"START CHECK"** aur **"REMIND ME AGAIN IN 15 MINUTES"**.
- Agar 15 min snooze karein to Firestore me `remindAt.<storeId>` set ho jata hai aur `snoozeCount.<storeId>` increment ho kar `1` ho jata hai.

### Second Time Alert Shows (After 15 Minutes):
- 15 minutes ke baad jab alert dobara show hota hai:
  - **"REMIND ME AGAIN IN 15 MINUTES" button completely HIDE ho jata hai!**
  - Screen par sirf aur sirf **"START CHECK"** ka button rehta hai aur dialog dismiss nahi hota (`barrierDismissible: false`).

---

## 3. Database Schema Structure (`Scheduled_CheckIn`)

```json
{
  "title": "Evening Hygiene & Safety Check",
  "scheduledAt": 1788393734000,
  "status": "pending",
  "storeStatus": {
    "14kXk65BydERfs7eFCk4": "pending"
  },
  "remindAt": {
    "14kXk65BydERfs7eFCk4": 1788394634000
  },
  "snoozeUntil": {
    "14kXk65BydERfs7eFCk4": 1788394634000
  },
  "snoozeCount": {
    "14kXk65BydERfs7eFCk4": 1
  }
}
```

---

## 4. Verification
- `flutter analyze` run kiya gaya: **0 issues / No errors**.
