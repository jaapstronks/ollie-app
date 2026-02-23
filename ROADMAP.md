# Ollie iOS — Feature Roadmap

*Last updated: 2026-02-23*

## Current State
- Core logging functionality complete
- Timeline view, quick-log bar, stats dashboard
- Profile-based configuration
- Local JSONL storage
- ✅ Haptic feedback throughout app (v1.1)
- ✅ TipKit contextual tips (v1.1)
- ✅ App Intents / Siri Shortcuts (v1.3)

## In Progress
- CloudKit sync & family sharing
- Push notifications
- Weather forecasts for walks
- Photo/video attachments

## Next Up
- Basic Widgets (Phase 2.1)

---

## Phase 0: Infrastructure & Quality

Essential infrastructure for production readiness and App Store compliance.

### 0.1 Privacy Manifest ⚠️ REQUIRED
**Effort:** Low | **Impact:** Critical
**Deadline:** Required for App Store since May 2024

Apple requires `PrivacyInfo.xcprivacy` declaring data collection and API usage.

**Must declare:**
- Required reason APIs used (UserDefaults, file timestamps, etc.)
- Data types collected
- Tracking status

**Files:** `Ollie-app/PrivacyInfo.xcprivacy`

---

### 0.2 Crash Reporting
**Effort:** Low | **Impact:** High

Capture crashes and errors in production to fix issues users encounter.

**Options:**
- Firebase Crashlytics (free, Google ecosystem)
- Sentry (privacy-focused, EU hosting available)
- Bugsnag (simple setup)

**Files:**
- `Services/CrashReporter.swift`
- SPM dependency

---

### 0.3 Unit Tests
**Effort:** Medium | **Impact:** High

XCTest target for testing business logic.

**Priority test targets:**
- `GapCalculations` — potty interval logic
- `PredictionCalculations` — next potty predictions
- `SleepCalculations` — nap vs night sleep detection
- `StreakCalculations` — outdoor streak counting
- `EventStore` — JSONL parsing/writing

**Files:** New target `Ollie-appTests/`

---

### 0.4 CI/CD Pipeline
**Effort:** Medium | **Impact:** Medium

GitHub Actions for automated testing and builds.

**Workflows:**
- Run tests on PR
- Build verification
- Optional: TestFlight deployment

**Files:** `.github/workflows/ci.yml`

---

### 0.5 Analytics (Optional)
**Effort:** Low | **Impact:** Medium

Understand how users interact with the app.

**Privacy-first options:**
- TelemetryDeck (privacy-focused, EU)
- Aptabase (open source)
- PostHog (self-hostable)

**Key events to track:**
- Onboarding completion rate
- Most-used event types
- Feature adoption (stats, predictions)

---

### 0.6 Feature Flags
**Effort:** Low | **Impact:** Medium

Toggle features without app updates.

**Options:**
- Firebase Remote Config
- Simple UserDefaults-based local flags
- PostHog feature flags

**Use cases:**
- A/B test onboarding flows
- Gradual feature rollout
- Kill switch for problematic features

---

### 0.7 Deep Linking / Universal Links
**Effort:** Medium | **Impact:** Low

Open specific screens from URLs or notifications.

**Routes:**
- `ollie://log/plassen` — open quick-log for potty
- `ollie://stats` — open stats view
- `ollie://today` — open today view

**Files:**
- `Utils/DeepLinkHandler.swift`
- Associated Domains entitlement

---

### 0.8 Force Update Mechanism
**Effort:** Low | **Impact:** Medium

Require users to update when critical fixes are released.

**Implementation:**
- Check minimum version from remote config or simple JSON
- Show blocking alert if current version < minimum

**Files:** `Services/VersionChecker.swift`

---

### 0.9 iPad Optimization
**Effort:** Medium | **Impact:** Low

Adapt layouts for larger screens.

**Considerations:**
- Sidebar navigation on iPad
- Multi-column layouts
- Keyboard shortcuts
- Pointer/trackpad support

---

## Phase 1: Foundation Enhancements

### 1.1 Haptic Feedback ✅ DONE
**Effort:** Low | **Impact:** Medium

Add subtle haptics throughout the app for better tactile feedback.

- ✅ Success haptic on event logged
- ✅ Selection haptics in quick-log bar
- ✅ Warning haptic for destructive actions (delete)

**Files:** `Utils/HapticFeedback.swift`, `QuickLogBar.swift`, `LogEventSheet.swift`, `SettingsView.swift`, `MediaPreviewView.swift`, `NotificationSettingsView.swift`, `CloudSharingView.swift`

**How to test:**
1. Log any event via quick-log bar → feel medium haptic on tap
2. Save event in LogEventSheet → feel success haptic
3. Swipe to delete event in timeline → feel warning haptic
4. Tap "Reset profiel" in Settings → feel warning haptic
5. Tap "Stop delen" in CloudKit sharing → feel warning haptic
6. Delete photo in MediaPreviewView → feel warning haptic
7. Remove walk in NotificationSettingsView → feel warning haptic

---

### 1.2 TipKit Integration ✅ DONE
**Effort:** Low | **Impact:** Medium
**Requires:** iOS 17+

Contextual feature tips for new users.

- ✅ "Veeg om te verwijderen" (swipe to delete)
- ✅ "Hou ingedrukt voor opties" (long press)
- ✅ "Stel maaltijd herinneringen in" (meal reminders)
- ✅ "Snel loggen" (quick log bar)
- ✅ "Ontdek patronen" (stats patterns)
- ✅ "Voorspelling" (potty prediction)

**Files:** `Utils/AppTips.swift`, `Ollie_appApp.swift`, `TimelineView.swift`, `SettingsView.swift`

**How to test:**
1. Fresh install or reset tips: Tips appear contextually
2. EventList shows SwipeToDeleteTip at top of event list
3. Empty timeline shows QuickLogBarTip
4. Settings > Herinneringen shows MealRemindersTip (after 3+ meals logged)
5. Tips can be dismissed by tapping X
6. To reset tips for testing, add `Tips.resetDatastore()` in `configureTips()`

---

## Phase 2: Widgets

### 2.1 Basic Widgets (WidgetKit)
**Effort:** Medium | **Impact:** High
**Requires:** iOS 14+

Home screen widgets for at-a-glance info.

**Small widget options:**
- Potty timer — "2u 15m sinds laatste plas"
- Streak counter — "🔥 5 dagen buiten"
- Next meal countdown

**Medium widget:**
- Combined: timer + streak + last 3 events

**Files:** New target `OllieWidgets/`
- `PottyTimerWidget.swift`
- `StreakWidget.swift`
- `WidgetDataProvider.swift` (shared data access)

**Considerations:**
- App Groups for shared UserDefaults/data access between app and widget
- Timeline refresh strategy (every 15 min for timer accuracy)

---

### 2.2 Interactive Widgets
**Effort:** Medium | **Impact:** High
**Requires:** iOS 17+

Add buttons to widgets for quick logging without opening app.

- "Plas buiten" button
- "Plas binnen" button
- "Poep buiten" button

**Dependencies:** ✅ App Intents (3.1) — already implemented

---

### 2.3 Lock Screen Widgets
**Effort:** Low | **Impact:** Medium
**Requires:** iOS 16+

Circular/rectangular lock screen widgets.

- Potty timer (circular, inline)
- Streak count (circular)

**Files:** Extend `OllieWidgets/` with lock screen families

---

## Phase 3: Siri & Shortcuts

### 3.1 App Intents ✅ DONE
**Effort:** Medium | **Impact:** High
**Requires:** iOS 16+

Enable Siri and Shortcuts integration.

**Implemented intents:**
- ✅ `LogPeeOutsideIntent` — "Ollie peed outside"
- ✅ `LogPoopOutsideIntent` — "Ollie pooped outside"
- ✅ `LogPottyIntent` — "Log potty with Ollie" (with type/location params)
- ✅ `LogMealIntent` — "Ollie ate"
- ✅ `LogWalkIntent` — "Ollie went for a walk"
- ✅ `LogSleepIntent` — "Ollie is sleeping"
- ✅ `LogWakeUpIntent` — "Ollie woke up"
- ✅ `GetPottyStatusIntent` — "When did puppy last pee"
- ✅ `GetPoopStatusIntent` — "When did puppy last poop"

**Files:**
- `Intents/OllieShortcuts.swift` (App Shortcuts provider)
- `Intents/IntentDataStore.swift` (shared data access)
- `Intents/Entities/` (EventTypeEntity, LocationEntity)
- `Intents/Intents/` (all intent implementations)

**Enables:**
- ✅ Voice logging during walks
- Interactive widget buttons (ready for Phase 2.2)
- Spotlight suggestions
- Action buttons in notifications
- Apple Watch support (intents work on watch)

---

### 3.2 Spotlight Suggestions
**Effort:** Low | **Impact:** Medium

Donate intents to make suggestions contextual.

- "Log potty" appears around predicted times
- "Log walk" appears in mornings

**Files:** Integrate donations in `TimelineViewModel.swift`

---

## Phase 4: Apple Watch

### 4.1 Watch App — Basic
**Effort:** High | **Impact:** High
**Requires:** watchOS 9+

Companion watch app for quick logging.

**Features:**
- Quick-log grid (same as phone quick-log bar)
- Current potty timer
- Today's event count
- Streak display

**Files:** New target `OllieWatch/`
- `ContentView.swift`
- `QuickLogView.swift`
- `WatchConnectivityManager.swift`

**Considerations:**
- WatchConnectivity for syncing with phone
- Can share CloudKit container for independent operation

---

### 4.2 Watch Complications
**Effort:** Medium | **Impact:** High

Glanceable info on watch face.

**Complication types:**
- Circular: potty timer
- Rectangular: timer + streak
- Corner: streak number

**Files:** `OllieWatch/Complications/`

---

### 4.3 Watch Haptic Reminders
**Effort:** Low | **Impact:** Medium

Gentle tap when predicted potty time approaches.

**Files:** Extend `NotificationService.swift` for watch

---

## Phase 5: Live Activities

### 5.1 Walk Live Activity
**Effort:** Medium | **Impact:** High
**Requires:** iOS 16.1+

Dynamic Island / Lock Screen live activity during walks.

**Triggers:** When `uitlaten` event logged
**Shows:**
- Walk duration (counting up)
- Distance (if location enabled)
- "End walk" button

**Ends:** When walk ended or after 2 hours

**Files:**
- `LiveActivities/WalkActivity.swift`
- `LiveActivities/WalkActivityAttributes.swift`
- Update `TimelineViewModel` to start/stop activities

---

### 5.2 Potty Reminder Live Activity
**Effort:** Medium | **Impact:** Medium

Optional "focus mode" live activity.

**Shows:** Time since last potty, updates live
**Use case:** New puppy owners wanting constant awareness

---

## Phase 6: Maps & Location

### 6.1 Walk Route Tracking
**Effort:** High | **Impact:** Medium

Record GPS route during walks.

**Features:**
- Start/stop tracking with walk events
- Store route as polyline in event data
- View route on map in event detail

**Files:**
- `Services/LocationService.swift`
- `Models/WalkRoute.swift`
- `Views/WalkRouteMapView.swift`

**Considerations:**
- Background location permission
- Battery impact warnings
- Privacy: location data stays local unless CloudKit shared

---

### 6.2 Favorite Spots
**Effort:** Medium | **Impact:** Low

Mark and name frequently visited locations.

- "Hondenveldje park"
- "Buurman's tuin"

---

## Phase 7: Advanced

### 7.1 Control Center Widget
**Effort:** Low | **Impact:** Medium
**Requires:** iOS 18+

Quick log button in Control Center.

**Files:** `ControlCenterWidget/` target

---

### 7.2 Core Spotlight Search
**Effort:** Medium | **Impact:** Low

Search events from iOS Spotlight.

- "Ollie training februari"
- "Milestone eerste keer buiten"

**Files:** `Services/SpotlightIndexer.swift`

---

## Implementation Priority

| Priority | Feature | Status | Why |
|----------|---------|--------|-----|
| 0 | Privacy Manifest | ⚠️ | **Required** for App Store submission |
| 1 | Crash Reporting | | Know when things break in production |
| 2 | Haptic feedback | ✅ Done | Quick win, immediate UX improvement |
| 3 | Unit Tests | | Confidence in calculation logic |
| 4 | Basic Widgets | | Most requested, high daily utility |
| 5 | App Intents | ✅ Done | Enables voice, widgets, shortcuts |
| 6 | Interactive Widgets | | Killer feature: log without unlocking |
| 7 | CI/CD Pipeline | | Automated testing on every PR |
| 8 | Watch App | | Perfect for walks, hands-free logging |
| 9 | Live Activities | | Nice-to-have, great for walk tracking |
| 10 | TipKit | ✅ Done | Helps new users discover features |
| 11 | Analytics | | Understand user behavior (optional) |
| 12 | Maps | | Niche, high effort |
| 13 | Spotlight | | Low priority, users won't search often |

---

## Technical Prerequisites

### App Groups
Required for widget data sharing.

```swift
// Capability: App Groups
// Group: group.com.yourname.ollie

// Shared UserDefaults
let sharedDefaults = UserDefaults(suiteName: "group.com.yourname.ollie")
```

### Shared Data Layer
Widgets and watch need read access to events.

Options:
1. **Shared UserDefaults** — Simple, good for small data (last event, streak)
2. **Shared App Container** — Full JSONL access for widgets
3. **CloudKit** — Watch can query independently

---

## Version Targets

| Version | Features | iOS Min | Status |
|---------|----------|---------|--------|
| 1.1 | Haptics, TipKit | iOS 17 | ✅ Done |
| 1.2 | Widgets (basic + lock screen) | iOS 16 | |
| 1.3 | App Intents | iOS 16 | ✅ Done |
| 1.4 | Interactive widgets | iOS 17 | |
| 2.0 | Apple Watch app | iOS 17 + watchOS 10 | |
| 2.1 | Live Activities | iOS 16.1 | |
| 2.2 | Maps, routes | iOS 17 | |
