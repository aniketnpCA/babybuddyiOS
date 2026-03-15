# Baby Buddy Mobile App Feature Parity Report

**Date:** March 2026
**iOS App:** BabyBuddySonnet (this repository)
**Android App:** [babybuddy/babybuddy-for-android](https://github.com/babybuddy/babybuddy-for-android)
**Reference Webapp:** [babybuddy/babybuddy](https://github.com/babybuddy/babybuddy)

---

## 1. Tracked Activity Types

| Activity / Data Type | Webapp | iOS App | Android App |
|---|:---:|:---:|:---:|
| Feeding | ✅ | ✅ | ✅ |
| Sleep | ✅ | ✅ | ✅ |
| Diaper Changes | ✅ | ✅ | ✅ |
| Pumping | ✅ | ✅ | ✅ |
| Tummy Time | ✅ | ❌ | ✅ |
| Temperature | ✅ | ❌ | ✅ |
| Notes | ✅ | ❌ | ✅ |
| Weight (Growth) | ✅ | ✅ | ✅ |
| Height (Growth) | ✅ | ✅ | ✅ |
| Head Circumference (Growth) | ✅ | ✅ | ✅ |
| BMI | ✅ | ✅ (read only) | ✅ (read only) |

---

## 2. CRUD Operations by Activity

### Feeding

| Operation | Webapp | iOS App | Android App |
|---|:---:|:---:|:---:|
| Create | ✅ | ✅ | ✅ |
| Read / List | ✅ | ✅ Today + Week + Custom range | ✅ Unified timeline |
| Edit / Update | ✅ | ✅ In-app form | ❌ Web browser redirect |
| Delete | ✅ | ✅ | ✅ Quick delete |
| Tags | ✅ | ❌ | ❌ |

**iOS fields supported:** type (breast milk / formula / fortified breast milk / solid food), method (bottle / left/right/both breasts / parent fed / self fed), amount, start, end, notes
**Android fields supported:** same type + method + amount + notes

### Sleep

| Operation | Webapp | iOS App | Android App |
|---|:---:|:---:|:---:|
| Create | ✅ | ✅ | ✅ |
| Read / List | ✅ | ✅ Today + Week + Custom range | ✅ Unified timeline |
| Edit / Update | ✅ | ✅ In-app form | ❌ Web browser redirect |
| Delete | ✅ | ✅ | ✅ Quick delete |
| Nap flag | ✅ | ✅ | ❌ |
| Tags | ✅ | ❌ | ❌ |

### Diaper Changes

| Operation | Webapp | iOS App | Android App |
|---|:---:|:---:|:---:|
| Create | ✅ | ✅ | ✅ |
| Read / List | ✅ | ✅ Today + Week + Custom range | ✅ Unified timeline |
| Edit / Update | ✅ | ✅ In-app form | ❌ Web browser redirect |
| Delete | ✅ | ✅ | ✅ Quick delete |
| Color picker | ✅ | ✅ (6 colors) | ✅ (4 colors: black/brown/green/yellow) |
| Amount field | ✅ | ❌ | ❌ |
| Tags | ✅ | ❌ | ❌ |

### Pumping

| Operation | Webapp | iOS App | Android App |
|---|:---:|:---:|:---:|
| Create | ✅ | ✅ | ✅ |
| Read / List | ✅ | ✅ Today + Week + Custom range | ✅ Unified timeline |
| Edit / Update | ✅ | ✅ In-app form | ❌ Web browser redirect |
| Delete | ✅ | ✅ | ✅ Quick delete |
| Milk category (to-be-consumed / consumed / frozen) | ❌ (app-specific extension) | ✅ | ❌ |
| Tags | ✅ | ❌ | ❌ |

### Tummy Time

| Operation | Webapp | iOS App | Android App |
|---|:---:|:---:|:---:|
| Create | ✅ | ❌ | ✅ |
| Read / List | ✅ | ❌ | ✅ Unified timeline |
| Edit / Update | ✅ | ❌ | ❌ Web browser redirect |
| Delete | ✅ | ❌ | ✅ Quick delete |
| Milestone field | ✅ | ❌ | ✅ |

### Temperature

| Operation | Webapp | iOS App | Android App |
|---|:---:|:---:|:---:|
| Create | ✅ | ❌ | ✅ |
| Read / List | ✅ | ❌ | ✅ Unified timeline |
| Edit / Update | ✅ | ❌ | ❌ Web browser redirect |
| Delete | ✅ | ❌ | ✅ Quick delete |

### Notes

| Operation | Webapp | iOS App | Android App |
|---|:---:|:---:|:---:|
| Create | ✅ | ❌ | ✅ |
| Read / List | ✅ | ❌ | ✅ Unified timeline |
| Edit / Update | ✅ | ❌ | ❌ Web browser redirect |
| Delete | ✅ | ❌ | ✅ Quick delete |
| Image attachment | ✅ | ❌ | ❌ |

### Growth Measurements (Weight / Height / Head Circumference)

| Operation | Webapp | iOS App | Android App |
|---|:---:|:---:|:---:|
| Create | ✅ | ✅ | ✅ |
| Read / Display | ✅ | ✅ Charts + WHO percentiles | ✅ Unified timeline |
| Edit / Update | ✅ | ❌ (create-only) | ❌ Web browser redirect |
| Delete | ✅ | ❌ | ✅ Quick delete |
| BMI (auto-calculated) | ✅ | ✅ Chart only | ✅ Timeline only |

---

## 3. Dashboard & Summary Views

| Feature | Webapp | iOS App | Android App |
|---|:---:|:---:|:---:|
| "Today at a glance" dashboard | ✅ | ✅ | ❌ |
| Child profile card (name, age) | ✅ | ✅ | ✅ (pager) |
| Latest growth measurements on dashboard | ✅ | ✅ | ❌ |
| Active server-side timers display | ✅ | ✅ | ✅ |
| Next expected feeding/pumping/diaper | ✅ (reports) | ✅ | ❌ |
| Daily feeding consumed vs. pumped surplus | ❌ (app-specific) | ✅ | ❌ |
| Customizable dashboard widgets | ❌ | ✅ | ❌ |
| Quick-log buttons (FAB) | ✅ | ✅ | ✅ |

---

## 4. Timers

| Feature | Webapp | iOS App | Android App |
|---|:---:|:---:|:---:|
| Start a timer | ✅ | ❌ | ✅ |
| Stop a timer | ✅ | ❌ | ✅ |
| View active timers | ✅ | ✅ (read-only display) | ✅ |
| Assign timer to activity type | ✅ | ❌ | ✅ |
| Elapsed time display | ✅ | ✅ | ✅ |
| Conflict resolution (multi-caregiver) | N/A | ❌ | ✅ |
| Recreate default timers | ✅ | ❌ | ✅ |

---

## 5. Analytics & Charts

| Chart / Report | Webapp | iOS App | Android App |
|---|:---:|:---:|:---:|
| Feeding amounts over time | ✅ | ✅ Daily trend + weekly bar | ❌ |
| Feeding by type (stacked chart) | ✅ | ✅ | ❌ |
| Feeding intervals | ✅ | ✅ | ❌ |
| Feeding duration | ✅ | ✅ | ❌ |
| Feeding pattern (time-of-day heatmap) | ✅ | ✅ | ❌ |
| Feeding scatter pattern | ❌ | ✅ | ❌ |
| Cumulative feeding progress (today) | ❌ | ✅ | ❌ |
| Sleep pattern (time-of-day) | ✅ | ✅ | ❌ |
| Sleep totals (daily) | ✅ | ✅ | ❌ |
| Diaper change types (by day) | ✅ | ✅ Frequency chart | ❌ |
| Diaper intervals | ✅ | ✅ | ❌ |
| Diaper lifetimes | ✅ | ✅ | ❌ |
| Pumping amounts | ✅ | ✅ | ❌ |
| Weight / Height / Head Circumference charts | ✅ | ✅ + WHO percentiles | ❌ (timeline only) |
| BMI chart | ✅ | ✅ | ❌ |
| Temperature over time | ✅ | ❌ | ❌ |
| Tummy time duration | ✅ | ❌ | ❌ |
| Monthly comparison card | ❌ | ✅ | ❌ |
| AI-powered analytics chat | ❌ | ✅ (OpenAI-compatible) | ❌ |
| Interactive server-rendered graphs | ✅ (Plotly) | ❌ | ❌ |

---

## 6. Notifications & Platform Integrations

| Feature | Webapp | iOS App | Android App |
|---|:---:|:---:|:---:|
| Local reminder notifications (per category) | ❌ | ✅ Configurable threshold (0.5–12h) | ❌ |
| Live Activity / Dynamic Island | ❌ | ✅ (next feeding/pumping/diaper + daily oz) | ❌ |
| iCloud sync for app settings | ❌ | ✅ (NSUbiquitousKeyValueStore) | ❌ |
| Home screen widget | ❌ | ❌ | ❌ |
| App update notifications | ❌ | ❌ | ✅ |
| Barcode scanning | ❌ | ❌ | ✅ (partial — zxing library present) |

---

## 7. Settings & Configuration

| Setting | Webapp | iOS App | Android App |
|---|:---:|:---:|:---:|
| Daily feeding target (oz) | ❌ | ✅ | ❌ |
| Sleep target (hours) | ❌ | ✅ | ❌ |
| Expected feeding/pumping/diaper intervals | ❌ | ✅ | ❌ |
| Wake time (for feeding progress calculation) | ❌ | ✅ | ❌ |
| Reminder thresholds per category | ❌ | ✅ | ❌ |
| Child sex (for WHO growth chart percentiles) | ❌ | ✅ | ❌ |
| Timezone override | ✅ (per user) | ✅ | ❌ |
| AI provider configuration (API key, model, base URL) | ❌ | ✅ | ❌ |
| Tab order customization | ❌ | ✅ | ❌ |
| Dashboard widget customization | ❌ | ✅ | ❌ |
| Appearance (Dog Mode theme) | ❌ | ✅ | ❌ |
| Dark / Light / System theme | ✅ | ✅ (system) | ✅ |
| Update API token | N/A | ✅ | ❌ (re-login required) |
| Language selection | ✅ (25+ languages) | ❌ (system locale only) | ❌ (system locale only) |

---

## 8. Authentication & Multi-User

| Feature | Webapp | iOS App | Android App |
|---|:---:|:---:|:---:|
| Token auth (API key) | ✅ | ✅ | ✅ (derived from login) |
| Username + password login | ✅ | ❌ | ✅ |
| Multi-user support | ✅ | ❌ (single token) | ❌ (single user) |
| Read-only vs standard vs staff roles | ✅ | ❌ | ❌ |
| QR code login | ✅ | ❌ | ❌ |
| Multi-child support | ✅ | ✅ (reads from server, select at setup) | ✅ (swipe pager) |
| Create / edit child profiles | ✅ | ❌ | ❌ |
| Child photo | ✅ | ❌ (not displayed) | ❌ |

---

## 9. Data Management

| Feature | Webapp | iOS App | Android App |
|---|:---:|:---:|:---:|
| Import data (CSV / XLSX) | ✅ (staff only) | ❌ | ❌ |
| Export data (CSV / XLSX) | ✅ (staff only) | ❌ | ❌ |
| Tags on all record types | ✅ | ❌ | ❌ |
| Offline mode / local cache | ❌ | ❌ | ❌ |
| Demo server support | ✅ | ❌ | ✅ |

---

## 10. Summary: Feature Gap Analysis

### iOS vs. Android

The iOS app is substantially **more feature-rich** than the Android app in most dimensions. The Android app's main advantages are breadth of tracked types (tummy time, temperature, notes) and full timer management. The iOS app's advantages are deeper in nearly every area it does cover.

**iOS leads Android in:**
- Full in-app edit of all entries (Android redirects to web browser)
- Rich analytics (12+ chart types vs. none on Android)
- Dashboard with live summary cards, next-due predictions, and customizable widgets
- Local push notifications and reminders with configurable thresholds
- Live Activity (Dynamic Island) integration
- Pumping milk category tracking (to-be-consumed / consumed / frozen)
- Nap flag on sleep entries
- WHO growth percentile charts with sex-specific curves
- Configurable feeding/sleep targets, intervals, and wake time
- AI-powered analytics chat (OpenAI-compatible)
- iCloud settings sync across devices

**Android leads iOS in:**
- Tummy Time: full logging with timer, milestone tracking — missing entirely from iOS
- Temperature: logging — missing entirely from iOS
- Notes: logging — missing entirely from iOS
- Timer management: start, stop, rename, restart, delete timers — iOS only displays active timers
- Color picker parity: Android uses the standard 4-color set from the API; iOS supports 6 colors (adds red and white)
- Diaper amount field: neither app supports it, but Android's omission is consistent with its minimal scope
- Demo server: built-in support for testing without a real server

---

## 11. Feature Gaps vs. the Baby Buddy Webapp

This section evaluates what both mobile apps are missing relative to the full Baby Buddy webapp.

### Tracking Types — Both Apps Missing

| Webapp Feature | iOS | Android | Notes |
|---|:---:|:---:|---|
| Tummy Time logging | ❌ | ✅ | iOS has no UI or model |
| Temperature logging | ❌ | ✅ | iOS has no UI or model |
| Notes logging (with image attachment) | ❌ | ✅ (text only, no image) | iOS has no UI or model |
| Image attachments on Notes | ❌ | ❌ | Neither app supports this |
| Tags on any record type | ❌ | ❌ | Webapp's tagging system unsupported in both apps |
| Diaper amount field | ❌ | ❌ | Neither app exposes the urine-output amount field |
| Birth time (separate from birth date) | ❌ | ❌ | Child model doesn't include birth_time |

### CRUD Gaps — Both Apps

| Operation | iOS | Android | Notes |
|---|:---:|:---:|---|
| Create / edit children | ❌ | ❌ | Must use webapp to add new children |
| Edit any logged entry | ✅ | ❌ | Android redirects to browser |
| Delete growth measurements | ❌ | ✅ | iOS can only create, not delete |
| Edit growth measurements | ❌ | ❌ | Neither app supports editing growth entries |
| Import / export data | ❌ | ❌ | Staff-only webapp feature |
| User management | ❌ | ❌ | Admin feature only on webapp |

### Timer Gaps

| Feature | iOS | Android | Notes |
|---|:---:|:---:|---|
| Start a timer | ❌ | ✅ | iOS displays timers but cannot create/control them |
| Stop a timer and log activity | ❌ | ✅ | Core workflow on Android |
| Edit timer start time | ❌ | ❌ | Webapp allows retroactive timer editing |
| Assign multiple timers concurrently | ❌ | ✅ | |

### Analytics / Reporting Gaps

Both apps are behind the webapp's server-rendered Plotly charts in some areas:

| Report | iOS | Android | Notes |
|---|:---:|:---:|---|
| Tummy time duration chart | ❌ | ❌ | Webapp has this |
| Temperature chart | ❌ | ❌ | Webapp has this |
| Diaper change amounts (urine output) chart | ❌ | ❌ | Webapp has this |
| Per-child report filtering | ✅ | ✅ | Both apps are child-scoped |
| Interactive chart zoom / pan | ❌ (native charts) | ❌ | Webapp uses Plotly |

### Platform & Ecosystem Gaps

| Feature | iOS | Android | Notes |
|---|:---:|:---:|---|
| Multi-user / role-based access | ❌ | ❌ | Webapp supports read-only and staff roles |
| 25+ language localization | ❌ (system locale) | ❌ (system locale) | Webapp has full i18n |
| Home Assistant integration | ❌ | ❌ | Webapp-only |
| Alexa skill | ❌ | ❌ | Webapp-only |
| QR code login | ❌ | ❌ | Webapp-only |
| Hardware integrations (scales, keypads) | ❌ | ❌ | Webapp / ESPHome only |
| Grafana dashboard | ❌ | ❌ | Webapp / API only |

---

## 12. Overall Assessment

| Dimension | iOS App | Android App |
|---|---|---|
| **Tracking breadth** | 8 of 11 activity types | 11 of 11 activity types |
| **Edit capability** | Full in-app CRUD | Create + delete only (edit via browser) |
| **Analytics depth** | 14+ chart types, WHO charts, AI chat | None |
| **Dashboard** | Rich customizable dashboard | None |
| **Notifications** | Configurable local reminders | None |
| **Timer control** | Read-only display | Full start/stop management |
| **Platform features** | Live Activity, iCloud sync | App update notifications |
| **Settings depth** | 15+ configurable options | Theme toggle only |
| **Development status** | Active | Paused (per Android repo README) |

**Verdict:** The iOS app is the more fully-featured mobile companion for day-to-day use, with superior analytics, notifications, editing, and dashboard capabilities. The Android app has wider coverage of Baby Buddy's data types (tummy time, temperature, notes) and is the only mobile app with proper timer management. Neither app fully replaces the webapp for administrative tasks (user management, child creation, import/export, tagging).
