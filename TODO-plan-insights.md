# Plan & Insights Feature Evolution

## Overview

This document outlines the recommended approach for evolving the Plan tab and Insights (formerly Stats) functionality in Otis. The goal is to create a cohesive experience that helps puppy parents understand where they are in their puppy's developmental journey, what's coming up, and how to stay on track.

**Key decision:** No users yet, so we make clean architectural cuts. No migration paths, no backwards compatibility—just build it right.

---

## Current State

### Existing Infrastructure

| Component | Location | Status | Action |
|-----------|----------|--------|--------|
| PlanTabView | `Views/PlanTabView.swift` | Exists | Remove, merge into Insights |
| HealthMilestone | `OtisShared/Models/HealthMilestone.swift` | Basic | Replace with new Milestone model |
| HealthTimelineView | `Views/HealthTimelineView.swift` | Exists | Enhance significantly |
| SocializationStore | `Services/SocializationStore.swift` | Complete | Extend with weekly progress |
| TrainingPlan | `Models/TrainingPlan.swift` | Exists | Keep as-is for now |
| WalkSchedule | `OtisShared/Models/WalkSchedule.swift` | Complete | Keep as-is |
| InsightsView | `Views/InsightsView.swift` | Exists | Restructure to include Plan |

### What We're Building

- Week-by-week socialization window visualization
- Calendar export/sync for appointments (Otis+)
- Developmental milestones (fear periods, teething, adolescence)
- User-created custom milestones/appointments (Otis+)
- "This Week" card on Today view
- Unified Insights tab with Plan section

---

## Premium Gating Strategy

### Free Tier

| Feature | Rationale |
|---------|-----------|
| Socialization window visualization | Core value prop for puppy owners, drives engagement |
| Week-by-week progress tracking | Part of socialization, keep it free |
| Basic milestone list (view only) | Users should see what's coming |
| Default vaccination schedule | Essential health info shouldn't be paywalled |
| Developmental phase awareness | Fear period warnings are safety-critical |
| "This Week" card on Today | Surfaces free features, teases premium |

### Otis+ (Premium)

| Feature | Rationale |
|---------|-----------|
| Calendar integration (EventKit) | Power user feature, clear value-add |
| Custom milestone creation | Personalization = premium |
| Milestone completion with notes/photos | Enhanced tracking = premium |
| Export timeline (ICS file) | Export features are premium |
| Recurring milestones | Advanced scheduling = premium |
| Milestone reminders (in-app) | Notification features = premium |
| Detailed milestone insights | Analytics depth = premium |
| "Export All to Calendar" bulk action | Convenience feature = premium |

### Gating UX

When free users tap a premium feature:
```
┌─────────────────────────────────────────────────┐
│                                                 │
│  📅 Add to Calendar                             │
│                                                 │
│  Export appointments to your calendar and       │
│  never miss a vaccination or vet visit.         │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │       Unlock with Otis+                │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  [Maybe Later]                                  │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Recommended Approach: Detailed Architecture

### Philosophy

1. **Surface where relevant** — Don't make users hunt. Show upcoming milestones on Today.
2. **Deep-dive available** — Full timeline accessible when users want context.
3. **Progressive disclosure** — Simple at first glance, detailed on demand.
4. **Premium feels valuable** — Free tier is useful, premium is delightful.

### Tab Structure (4 tabs)

```
Tab Bar
├── Today        — Daily logging + "This Week" preview
├── Timeline     — Chronological event history
├── Insights     — Stats + Plan (combined)
└── Train        — Training exercises
```

**Rationale:** 4 tabs is the sweet spot. 5 feels cluttered. Plan content isn't visited daily—it belongs grouped with Insights where users go to "understand" their puppy.

### Navigation Architecture

```
Today View
├── Status Cards (Potty, Sleep, etc.)
├── This Week Card ─────────────────┐
│   ├── Next Milestone (tap) ───────┼──► Milestone Detail Sheet
│   ├── Socialization Progress ─────┼──► Socialization Categories
│   └── Card Header (tap) ──────────┼──► Insights (Plan section)
├── Walk Suggestions                │
└── Quick Log Bar                   │
                                    │
Insights View ◄─────────────────────┘
├── Plan Section (top, prominent)
│   ├── Puppy Age & Stage
│   ├── Socialization Window Timeline
│   ├── Upcoming Milestones (3 max)
│   ├── [View Full Timeline] ───────────► Health Timeline View
│   └── [View Socialization] ───────────► Socialization Categories
├── Week Overview
├── Streak Card
├── Potty Insights (collapsible)
├── Sleep Patterns (collapsible)
└── Walk History (collapsible)

Health Timeline View (Full Screen)
├── Header: "Puppy's Health & Development"
├── [+ Add Milestone] (Otis+ gated)
├── Next Up Section
│   └── Milestone Cards with actions
├── Future Section
│   └── Upcoming milestones
└── Completed Section
    └── Past milestones with details
```

### Information Hierarchy

**Level 1: Glanceable (Today View)**
- Next milestone name + date
- Socialization week number + progress bar
- Any warnings (fear period, overdue vaccine)

**Level 2: Summary (Insights → Plan Section)**
- Puppy's current age and developmental stage
- Week-by-week socialization visualization
- Next 3 milestones with actions
- Quick links to full views

**Level 3: Detail (Full Screen Views)**
- Complete health timeline with all milestones
- Full socialization checklist by category
- Milestone detail with notes, photos, history

---

## Component Specifications

### 1. "This Week" Card (Today View)

**Purpose:** Surface upcoming milestones and socialization status without leaving the main screen.

**Location:** Today view, after status cards, before walk suggestions.

**Visibility Rules:**

| Puppy Age | Show Socialization | Show Milestones | Show Card |
|-----------|-------------------|-----------------|-----------|
| < 8 weeks | No (with breeder) | If within 14 days | Conditional |
| 8-16 weeks | Yes (prominent) | If within 14 days | Always |
| 16-52 weeks | "Window closed" badge | If within 14 days | If milestone exists |
| 1+ year | No | If within 30 days | If milestone exists |

**Wireframe:**
```
┌─────────────────────────────────────────────────┐
│ This Week                                    ▶  │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │ 🩺 2nd Vaccination                        │  │
│  │    Friday · in 3 days                     │  │
│  │                                           │  │
│  │    ┌──────────────┐  ┌──────────────┐     │  │
│  │    │   Done ✓     │  │ Calendar 📅  │     │  │
│  │    │              │  │    Otis+    │     │  │
│  │    └──────────────┘  └──────────────┘     │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │ 🐾 Socialization · Week 10 of 16          │  │
│  │                                           │  │
│  │    8   9  10  11  12  13  14  15  16      │  │
│  │    ✓   ✓   ●   ○   ○   ○   ○   ○   ○      │  │
│  │                                           │  │
│  │    This week: 23 exposures · 62%          │  │
│  │    ████████████░░░░░░░░                   │  │
│  │                                           │  │
│  │    Focus: Sounds, Vehicles                │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Interaction States:**

| Element | Tap Action | Long Press |
|---------|------------|------------|
| Card header "▶" | Navigate to Insights (Plan section) | — |
| Milestone row | Expand inline details | — |
| "Done ✓" button | Open completion sheet | — |
| "Calendar 📅" button | Add to calendar (or show Otis+ upsell) | — |
| Socialization section | Navigate to Socialization Categories | — |
| Week dot | Show that week's stats in tooltip | — |

**Empty State:**
```
┌─────────────────────────────────────────────────┐
│ This Week                                    ▶  │
├─────────────────────────────────────────────────┤
│                                                 │
│  ✨ All caught up!                              │
│                                                 │
│  No upcoming milestones this week.              │
│  Keep logging those daily activities!           │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

### 2. Socialization Window Timeline

**Purpose:** Make the critical window feel urgent and trackable week-by-week.

**Design Principles:**
- The window is finite and precious—communicate urgency without anxiety
- Show cumulative progress, not just current week
- Make "now" unmistakably clear
- Celebrate completed weeks

**Visual Design:**

```
┌─────────────────────────────────────────────────┐
│                                                 │
│  CRITICAL PERIOD        CLOSING      ONGOING    │
│  ══════════════════════════════════════════     │
│                                                 │
│   8    9   10   11   12   13   14   15   16+    │
│  [✓]  [✓]  [●]  [○]  [○]  [○]  [○]  [○]  [·]   │
│              ▲                                  │
│             NOW                                 │
│                                                 │
└─────────────────────────────────────────────────┘

Legend:
  [✓] = Completed week (40+ exposures, all categories touched)
  [●] = Current week (highlighted, pulsing subtly)
  [○] = Future week in critical window
  [·] = Post-window (still important, less critical)
```

**Color Coding:**

| Status | Color | Meaning |
|--------|-------|---------|
| Completed | `Color.green` | Week goals met |
| Current | `Color.accentColor` | Active focus |
| Future (critical) | `Color.secondary` | In window |
| Future (closing) | `Color.orange` | Urgency |
| Post-window | `Color.gray` | Lower priority |

**Expanded Week View (tap on week):**
```
┌─────────────────────────────────────────────────┐
│ Week 10 · Feb 18-24                             │
├─────────────────────────────────────────────────┤
│                                                 │
│  47 exposures logged                            │
│  8 of 9 categories touched                      │
│  92% positive reactions                         │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │ People      ████████░░░░  8/12          │    │
│  │ Animals     ██████░░░░░░  5/10          │    │
│  │ Sounds      ████░░░░░░░░  4/12          │    │
│  │ Vehicles    ██░░░░░░░░░░  2/8   ⚠️      │    │
│  │ Surfaces    ██████████░░  9/10          │    │
│  │ Handling    ████████████  10/10 ✓       │    │
│  │ Weather     ██████░░░░░░  6/10          │    │
│  │ Objects     ████████░░░░  7/10          │    │
│  │ Environments ░░░░░░░░░░░  0/8   ⚠️      │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  Suggested Focus:                               │
│  🚗 Vehicles: trucks, motorcycles, buses        │
│  🏙️ Environments: pet store, outdoor café       │
│                                                 │
│  [Log Exposure]                                 │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Weekly Goals Algorithm:**

```swift
struct WeeklyGoals {
    static let minimumExposures = 40
    static let minimumCategoriesWithExposure = 7  // out of 9
    static let minimumPositiveReactionRate = 0.7  // 70%

    static func isWeekComplete(_ progress: WeeklyProgress) -> Bool {
        progress.exposureCount >= minimumExposures &&
        progress.categoriesWithExposures >= minimumCategoriesWithExposure &&
        progress.positiveReactionRate >= minimumPositiveReactionRate
    }
}
```

**Focus Suggestions Algorithm:**

Priority ranking for suggestions:
1. Categories with 0 exposures this week (critical gap)
2. Categories below 50% of target (falling behind)
3. Categories with recent fearful reactions (need positive follow-up)
4. High-priority items not yet exposed (from seed data)
5. Items marked "is_walkable" if user is about to walk

---

### 3. Milestones Model (Clean Cut)

**Remove:** `HealthMilestone.swift` (delete entirely)

**Create:** `Milestone.swift` with complete implementation

```swift
import Foundation

// MARK: - Milestone Category

enum MilestoneCategory: String, Codable, CaseIterable {
    case health         // Vaccinations, vet visits, deworming
    case developmental  // Fear periods, teething, adolescence
    case administrative // Insurance, registration, microchip
    case custom         // User-created (Otis+ only)

    var icon: String {
        switch self {
        case .health: return "cross.case.fill"
        case .developmental: return "brain.head.profile"
        case .administrative: return "doc.text.fill"
        case .custom: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .health: return .red
        case .developmental: return .purple
        case .administrative: return .blue
        case .custom: return .orange
        }
    }
}

// MARK: - Milestone Status

enum MilestoneStatus: String, Codable {
    case upcoming   // Future, not yet actionable
    case nextUp     // Within 14 days, should take action
    case overdue    // Past target date, not completed
    case completed  // Done

    var badgeColor: Color {
        switch self {
        case .upcoming: return .secondary
        case .nextUp: return .accentColor
        case .overdue: return .red
        case .completed: return .green
        }
    }
}

// MARK: - Milestone

struct Milestone: Identifiable, Codable {
    let id: UUID
    var category: MilestoneCategory
    var labelKey: String              // Localization key
    var detailKey: String?            // Localization key for description

    // Timing (one of these should be set)
    var targetAgeWeeks: Int?          // Relative to birth date
    var targetAgeDays: Int?           // More precise for early milestones
    var targetAgeMonths: Int?         // For later milestones
    var fixedDate: Date?              // For custom milestones

    // Recurrence
    var isRecurring: Bool = false
    var recurrenceMonths: Int?        // e.g., 12 for annual

    // Completion (Otis+ for notes/photos)
    var isCompleted: Bool = false
    var completedDate: Date?
    var completionNotes: String?      // Otis+ only
    var completionPhotoID: UUID?      // Otis+ only
    var vetClinicName: String?        // Otis+ only

    // Calendar (Otis+ only)
    var calendarEventID: String?
    var reminderDaysBefore: Int = 7

    // Display
    var icon: String
    var isActionable: Bool            // Can user mark complete?
    var isUserDismissable: Bool       // Can user hide this?
    var sortOrder: Int                // For deterministic ordering

    // Computed
    func targetDate(birthDate: Date) -> Date? {
        if let fixed = fixedDate { return fixed }

        let calendar = Calendar.current
        if let weeks = targetAgeWeeks {
            return calendar.date(byAdding: .weekOfYear, value: weeks, to: birthDate)
        }
        if let days = targetAgeDays {
            return calendar.date(byAdding: .day, value: days, to: birthDate)
        }
        if let months = targetAgeMonths {
            return calendar.date(byAdding: .month, value: months, to: birthDate)
        }
        return nil
    }

    func status(birthDate: Date, now: Date = Date()) -> MilestoneStatus {
        if isCompleted { return .completed }

        guard let target = targetDate(birthDate: birthDate) else {
            return .upcoming
        }

        let daysUntil = Calendar.current.dateComponents([.day], from: now, to: target).day ?? 0

        if daysUntil < 0 { return .overdue }
        if daysUntil <= 14 { return .nextUp }
        return .upcoming
    }
}

// MARK: - Default Milestones

enum DefaultMilestones {

    static func all() -> [Milestone] {
        return health() + developmental()
    }

    static func health() -> [Milestone] {
        [
            // Vaccinations (Dutch LICG schedule)
            Milestone(
                id: UUID(),
                category: .health,
                labelKey: "milestone.vaccination.first",
                detailKey: "milestone.vaccination.first.detail",
                targetAgeWeeks: 8,
                icon: "syringe.fill",
                isActionable: true,
                isUserDismissable: false,
                sortOrder: 100
            ),
            Milestone(
                id: UUID(),
                category: .health,
                labelKey: "milestone.vaccination.second",
                detailKey: "milestone.vaccination.second.detail",
                targetAgeWeeks: 12,
                icon: "syringe.fill",
                isActionable: true,
                isUserDismissable: false,
                sortOrder: 101
            ),
            Milestone(
                id: UUID(),
                category: .health,
                labelKey: "milestone.vaccination.third",
                detailKey: "milestone.vaccination.third.detail",
                targetAgeWeeks: 16,
                icon: "syringe.fill",
                isActionable: true,
                isUserDismissable: false,
                sortOrder: 102
            ),
            Milestone(
                id: UUID(),
                category: .health,
                labelKey: "milestone.vaccination.annual",
                detailKey: "milestone.vaccination.annual.detail",
                targetAgeMonths: 15,  // ~3 months after 3rd
                isRecurring: true,
                recurrenceMonths: 12,
                icon: "syringe.fill",
                isActionable: true,
                isUserDismissable: false,
                sortOrder: 103
            ),

            // Deworming
            Milestone(
                id: UUID(),
                category: .health,
                labelKey: "milestone.deworming.first",
                detailKey: "milestone.deworming.first.detail",
                targetAgeWeeks: 9,
                icon: "pill.fill",
                isActionable: true,
                isUserDismissable: false,
                sortOrder: 200
            ),

            // Vet visits
            Milestone(
                id: UUID(),
                category: .health,
                labelKey: "milestone.vet.first",
                detailKey: "milestone.vet.first.detail",
                targetAgeWeeks: 9,
                icon: "stethoscope",
                isActionable: true,
                isUserDismissable: false,
                sortOrder: 300
            ),

            // Spay/Neuter (size-dependent, shows as range)
            Milestone(
                id: UUID(),
                category: .health,
                labelKey: "milestone.spayneuter.discuss",
                detailKey: "milestone.spayneuter.discuss.detail",
                targetAgeMonths: 6,
                icon: "scissors",
                isActionable: true,
                isUserDismissable: true,  // Some owners skip
                sortOrder: 400
            ),
        ]
    }

    static func developmental() -> [Milestone] {
        [
            // Fear periods
            Milestone(
                id: UUID(),
                category: .developmental,
                labelKey: "milestone.fearperiod.first",
                detailKey: "milestone.fearperiod.first.detail",
                targetAgeWeeks: 8,
                icon: "exclamationmark.triangle.fill",
                isActionable: false,  // Awareness only
                isUserDismissable: false,
                sortOrder: 500
            ),
            Milestone(
                id: UUID(),
                category: .developmental,
                labelKey: "milestone.fearperiod.second",
                detailKey: "milestone.fearperiod.second.detail",
                targetAgeMonths: 6,
                icon: "exclamationmark.triangle.fill",
                isActionable: false,
                isUserDismissable: false,
                sortOrder: 501
            ),

            // Teething
            Milestone(
                id: UUID(),
                category: .developmental,
                labelKey: "milestone.teething.start",
                detailKey: "milestone.teething.start.detail",
                targetAgeWeeks: 12,
                icon: "mouth.fill",
                isActionable: false,
                isUserDismissable: false,
                sortOrder: 600
            ),
            Milestone(
                id: UUID(),
                category: .developmental,
                labelKey: "milestone.teething.complete",
                detailKey: "milestone.teething.complete.detail",
                targetAgeMonths: 7,
                icon: "mouth.fill",
                isActionable: true,  // Can mark when adult teeth in
                isUserDismissable: false,
                sortOrder: 601
            ),

            // Socialization window
            Milestone(
                id: UUID(),
                category: .developmental,
                labelKey: "milestone.socialization.closing",
                detailKey: "milestone.socialization.closing.detail",
                targetAgeWeeks: 14,
                icon: "person.3.fill",
                isActionable: false,
                isUserDismissable: false,
                sortOrder: 700
            ),
            Milestone(
                id: UUID(),
                category: .developmental,
                labelKey: "milestone.socialization.closed",
                detailKey: "milestone.socialization.closed.detail",
                targetAgeWeeks: 16,
                icon: "person.3.fill",
                isActionable: false,
                isUserDismissable: false,
                sortOrder: 701
            ),

            // Adolescence
            Milestone(
                id: UUID(),
                category: .developmental,
                labelKey: "milestone.adolescence.start",
                detailKey: "milestone.adolescence.start.detail",
                targetAgeMonths: 6,
                icon: "figure.stand",
                isActionable: false,
                isUserDismissable: false,
                sortOrder: 800
            ),

            // Maturity
            Milestone(
                id: UUID(),
                category: .developmental,
                labelKey: "milestone.maturity.social",
                detailKey: "milestone.maturity.social.detail",
                targetAgeMonths: 18,  // Varies by breed
                icon: "star.fill",
                isActionable: false,
                isUserDismissable: false,
                sortOrder: 900
            ),
        ]
    }
}
```

---

### 4. Insights View Restructure

**New Structure:**

```
InsightsView
├── Plan Section (always visible at top)
│   ├── Age & Stage Header
│   ├── Socialization Window (if < 6 months)
│   ├── Upcoming Milestones (max 3)
│   └── Action Links
├── Week Overview Card
├── Streak Card
├── Collapsible: Potty Insights
├── Collapsible: Sleep Patterns
└── Collapsible: Walk History
```

**Wireframe:**

```
┌─────────────────────────────────────────────────┐
│ Insights                                        │
├─────────────────────────────────────────────────┤
│                                                 │
│ ┌───────────────────────────────────────────┐   │
│ │  🐕 Otis · Week 10                       │   │
│ │     10 weeks old · 2 weeks home           │   │
│ │     Socialization window: OPEN            │   │
│ └───────────────────────────────────────────┘   │
│                                                 │
│ ┌───────────────────────────────────────────┐   │
│ │  Socialization Progress                   │   │
│ │                                           │   │
│ │   8   9  10  11  12  13  14  15  16       │   │
│ │  [✓] [✓] [●] [○] [○] [○] [○] [○] [·]     │   │
│ │                                           │   │
│ │  Week 10: 47 exposures · 62%              │   │
│ │  ████████████░░░░░░░░                     │   │
│ │                                           │   │
│ │  [View Checklist →]                       │   │
│ └───────────────────────────────────────────┘   │
│                                                 │
│ ┌───────────────────────────────────────────┐   │
│ │  Upcoming                                 │   │
│ │                                           │   │
│ │  🩺 2nd Vaccination · Feb 28        [📅]  │   │
│ │     in 3 days · Book with vet             │   │
│ │                                           │   │
│ │  ⚠️ Fear Period 2 · ~Mar 15               │   │
│ │     in 2 weeks · Be gentle                │   │
│ │                                           │   │
│ │  🦷 Teething Starts · ~Mar 20             │   │
│ │     in 3 weeks · Provide chew toys        │   │
│ │                                           │   │
│ │  [View Full Timeline →]                   │   │
│ └───────────────────────────────────────────┘   │
│                                                 │
│ ─────────────────────────────────────────────   │
│                                                 │
│ ┌───────────────────────────────────────────┐   │
│ │  This Week                                │   │
│ │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐         │   │
│ │  │ 24  │ │ 89% │ │14.2h│ │ 47  │         │   │
│ │  │walks│ │potty│ │sleep│ │socl │         │   │
│ │  └─────┘ └─────┘ └─────┘ └─────┘         │   │
│ └───────────────────────────────────────────┘   │
│                                                 │
│ ▶ Potty Insights                               │
│                                                 │
│ ▶ Sleep Patterns                               │
│                                                 │
│ ▶ Walk History                                 │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Collapsible Section Behavior:**
- Sections remember expanded/collapsed state
- "Potty Insights" expanded by default for puppies < 6 months
- All sections accessible, just collapsed to reduce scroll

---

### 5. Health Timeline View (Full Screen)

**Purpose:** Complete milestone management with premium features.

**Wireframe:**

```
┌─────────────────────────────────────────────────┐
│ ← Health & Development               [+ Add]   │
│                                       Otis+   │
├─────────────────────────────────────────────────┤
│                                                 │
│ NEXT UP                                         │
│                                                 │
│ ┌───────────────────────────────────────────┐   │
│ │ ●───                                      │   │
│ │     🩺 2nd Vaccination (DHP + Lepto)      │   │
│ │        Friday, Feb 28 · in 3 days         │   │
│ │                                           │   │
│ │        Book your appointment now.         │   │
│ │        This protects against distemper,   │   │
│ │        hepatitis, parvo, and lepto.       │   │
│ │                                           │   │
│ │        ┌────────┐  ┌────────────────┐     │   │
│ │        │ Done ✓ │  │ Add to Cal 📅  │     │   │
│ │        └────────┘  │    Otis+      │     │   │
│ │                    └────────────────┘     │   │
│ └───────────────────────────────────────────┘   │
│ │                                               │
│ │                                               │
│ COMING UP                                       │
│ │                                               │
│ ├─○ Mar 7 · Fear Period 2                       │
│ │    ℹ️ Avoid traumatic experiences. Your      │
│ │    puppy may seem more cautious—this is      │
│ │    normal. Keep socialization positive.      │
│ │                                               │
│ ├─○ Mar 14 · Teething Starts                    │
│ │    ℹ️ Baby teeth fall out, adult teeth       │
│ │    come in. Expect increased chewing.        │
│ │    Provide appropriate outlets.              │
│ │                                               │
│ ├─○ Mar 28 · 3rd Vaccination                    │
│ │    Final puppy vaccine. Full immunity        │
│ │    ~2 weeks after this shot.                 │
│ │    ┌────────────────┐                        │
│ │    │ Add to Cal 📅  │                        │
│ │    └────────────────┘                        │
│ │                                               │
│ COMPLETED                                       │
│ │                                               │
│ ├─✓ Feb 14 · 1st Vaccination                    │
│ │    ✓ Completed · Dierenkliniek Amsterdam     │
│ │    [View details]     Otis+ badge           │
│ │                                               │
│ ├─✓ Feb 7 · First Vet Visit                     │
│ │    ✓ Completed · Weight: 4.2 kg              │
│ │                                               │
│ └─✓ Jan 24 · Arrived Home! 🎉                   │
│      Automatically added                        │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

### 6. Calendar Integration (Otis+ Only)

**EventKit Implementation:**

```swift
import EventKit

actor CalendarService {
    private let store = EKEventStore()

    enum CalendarError: LocalizedError {
        case accessDenied
        case eventNotFound
        case saveFailed(Error)

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return Strings.Calendar.accessDenied
            case .eventNotFound:
                return Strings.Calendar.eventNotFound
            case .saveFailed(let error):
                return error.localizedDescription
            }
        }
    }

    func requestAccess() async throws -> Bool {
        try await store.requestFullAccessToEvents()
    }

    func hasAccess() -> Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    func addMilestone(
        _ milestone: Milestone,
        profile: PuppyProfile,
        calendar: EKCalendar? = nil
    ) async throws -> String {
        guard try await requestAccess() else {
            throw CalendarError.accessDenied
        }

        guard let targetDate = milestone.targetDate(birthDate: profile.birthDate) else {
            throw CalendarError.saveFailed(NSError(domain: "Otis", code: 1))
        }

        let event = EKEvent(eventStore: store)
        event.title = "🐕 \(profile.name): \(milestone.localizedLabel)"
        event.startDate = targetDate
        event.endDate = Calendar.current.date(
            byAdding: .hour,
            value: 1,
            to: targetDate
        )!
        event.notes = milestone.localizedDetail
        event.calendar = calendar ?? store.defaultCalendarForNewEvents

        // Add reminder
        let reminderSeconds = TimeInterval(-milestone.reminderDaysBefore * 24 * 60 * 60)
        event.addAlarm(EKAlarm(relativeOffset: reminderSeconds))

        try store.save(event, span: .thisEvent)
        return event.eventIdentifier
    }

    func removeEvent(identifier: String) async throws {
        guard try await requestAccess() else {
            throw CalendarError.accessDenied
        }

        guard let event = store.event(withIdentifier: identifier) else {
            throw CalendarError.eventNotFound
        }

        try store.remove(event, span: .thisEvent)
    }

    func availableCalendars() -> [EKCalendar] {
        store.calendars(for: .event)
            .filter { $0.allowsContentModifications }
            .sorted { $0.title < $1.title }
    }
}
```

**User Flow:**

1. User taps "Add to Calendar" on milestone
2. If no access: show system permission dialog
3. If denied previously: show settings prompt
4. If granted: add event, show confirmation toast
5. Button changes to "In Calendar ✓" with option to remove

**Calendar Picker (optional, v2):**

For users with multiple calendars, show picker on first use:
```
┌─────────────────────────────────────────────────┐
│ Choose Calendar                        [Cancel] │
├─────────────────────────────────────────────────┤
│                                                 │
│  Which calendar should Otis use?               │
│                                                 │
│  ○ Personal                                     │
│  ● Family (shared)                              │
│  ○ Work                                         │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │              Use This Calendar          │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  Remember my choice                      [✓]    │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

### 7. Custom Milestone Creation (Otis+ Only)

**Use Cases:**
- Grooming appointments
- Training class schedule
- Boarding/daycare reservations
- Puppy playdates
- Vet follow-ups

**Sheet Design:**

```
┌─────────────────────────────────────────────────┐
│ New Milestone                          [Cancel] │
├─────────────────────────────────────────────────┤
│                                                 │
│  What's happening?                              │
│  ┌─────────────────────────────────────────┐    │
│  │ First grooming appointment              │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  When?                                          │
│  ┌─────────────────────────────────────────┐    │
│  │ Saturday, March 15, 2026        [📅]    │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  Category                                       │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐               │
│  │ 🏥  │ │ ✂️  │ │ 🎓  │ │ 🐕  │               │
│  │Health│ │Care │ │Train│ │Social│              │
│  └─────┘ └─────┘ └─────┘ └─────┘               │
│            ▲ selected                           │
│                                                 │
│  Notes (optional)                               │
│  ┌─────────────────────────────────────────┐    │
│  │ Puppy trim only, no full haircut yet.   │    │
│  │ Bring treats for positive association.  │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  ─────────────────────────────────────────────  │
│                                                 │
│  Remind me                              [ON]    │
│  3 days before                          [▼]     │
│                                                 │
│  Add to Calendar                        [ON]    │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │                  Save                   │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Implementation Phases

### Phase 1: Data Foundation

**Goal:** New Milestone model, store, and default milestones.

**Tasks:**
1. Delete `HealthMilestone.swift`
2. Create `Milestone.swift` with full model (as specified above)
3. Create `MilestoneStore.swift` with Core Data persistence
4. Add localization keys for all default milestones
5. Create computed properties for status, target date, etc.

**Files:**
- Delete: `OtisShared/Models/HealthMilestone.swift`
- Create: `OtisShared/Models/Milestone.swift`
- Create: `Services/MilestoneStore.swift`
- Update: `Strings+Health.swift` (add milestone keys)

**No UI changes yet—just data layer.**

---

### Phase 2: Socialization Week Timeline

**Goal:** Week-by-week visualization of socialization progress.

**Tasks:**
1. Add `WeeklyProgress` struct to SocializationStore
2. Implement `weeklyProgress(for:)` and `allWeeklyProgress()`
3. Create `SocializationWeekTimeline` view component
4. Add focus suggestions algorithm
5. Integrate into existing SocializationProgressCard

**Files:**
- Update: `Services/SocializationStore.swift`
- Create: `Views/Components/SocializationWeekTimeline.swift`
- Update: `Views/SocializationProgressCard.swift`

---

### Phase 3: Insights Restructure

**Goal:** Merge Plan into Insights, new section hierarchy.

**Tasks:**
1. Create `PlanSection` component for Insights
2. Add age/stage header
3. Integrate socialization timeline (from Phase 2)
4. Add upcoming milestones list (max 3)
5. Add navigation links to full views
6. Make other sections collapsible
7. Delete `PlanTabView.swift`
8. Update tab bar (remove Plan tab if it exists)

**Files:**
- Create: `Views/Insights/PlanSection.swift`
- Update: `Views/InsightsView.swift`
- Delete: `Views/PlanTabView.swift`
- Update: `ContentView.swift` (tab bar)

---

### Phase 4: This Week Card

**Goal:** Surface plan content on Today view.

**Tasks:**
1. Create `ThisWeekCard` component
2. Implement visibility logic based on puppy age
3. Show next milestone with inline actions
4. Show socialization progress (compact)
5. Add navigation to Insights
6. Integrate into TodayView

**Files:**
- Create: `Views/Cards/ThisWeekCard.swift`
- Create: `ViewModels/ThisWeekViewModel.swift`
- Update: `Views/TodayView.swift`

---

### Phase 5: Enhanced Health Timeline

**Goal:** Full milestone management view.

**Tasks:**
1. Rebuild `HealthTimelineView` with new Milestone model
2. Group by status (Next Up, Coming Up, Completed)
3. Add inline milestone details with educational content
4. Add "Done" button with completion sheet
5. Show premium badge on calendar/notes features
6. Implement premium gating for calendar button

**Files:**
- Update: `Views/HealthTimelineView.swift`
- Create: `Views/MilestoneCompletionSheet.swift`
- Create: `Views/MilestoneRow.swift`

---

### Phase 6: Calendar Integration (Otis+)

**Goal:** EventKit integration for premium users.

**Tasks:**
1. Create `CalendarService` actor
2. Add calendar permission handling
3. Implement add/remove event methods
4. Create calendar picker sheet (optional)
5. Update milestone UI with "In Calendar" state
6. Handle edge cases (permission denied, event deleted externally)

**Files:**
- Create: `Services/CalendarService.swift`
- Update: `Views/HealthTimelineView.swift`
- Update: `Info.plist` (calendar usage description)

---

### Phase 7: Custom Milestones (Otis+)

**Goal:** User-created milestones for premium users.

**Tasks:**
1. Create `AddMilestoneSheet` view
2. Implement category picker
3. Add date picker with sensible defaults
4. Wire up reminder and calendar toggles
5. Persist custom milestones in MilestoneStore
6. Show custom milestones in timeline

**Files:**
- Create: `Views/AddMilestoneSheet.swift`
- Update: `Services/MilestoneStore.swift`
- Update: `Views/HealthTimelineView.swift`

---

### Phase 8: Polish

**Goal:** Edge cases, empty states, delight.

**Tasks:**
1. Empty states for all new views
2. Loading states with skeletons
3. Error handling with retry
4. Animations for week completion
5. Haptic feedback on milestone completion
6. Onboarding tooltip for "This Week" card
7. Analytics events for feature usage

---

## File Structure (Final)

```
Otis-app/
├── Models/
│   └── (keep existing)
├── OtisShared/Sources/OtisShared/Models/
│   ├── Milestone.swift (NEW - replaces HealthMilestone)
│   ├── WeeklyProgress.swift (NEW)
│   └── (keep others)
├── Services/
│   ├── MilestoneStore.swift (NEW)
│   ├── CalendarService.swift (NEW)
│   ├── SocializationStore.swift (UPDATED)
│   └── (keep others)
├── ViewModels/
│   ├── ThisWeekViewModel.swift (NEW)
│   └── (keep others)
├── Views/
│   ├── Cards/
│   │   ├── ThisWeekCard.swift (NEW)
│   │   └── (keep others)
│   ├── Components/
│   │   ├── SocializationWeekTimeline.swift (NEW)
│   │   └── (keep others)
│   ├── Insights/
│   │   ├── PlanSection.swift (NEW)
│   │   └── (keep others)
│   ├── HealthTimelineView.swift (UPDATED)
│   ├── InsightsView.swift (UPDATED)
│   ├── TodayView.swift (UPDATED)
│   ├── MilestoneCompletionSheet.swift (NEW)
│   ├── MilestoneRow.swift (NEW)
│   ├── AddMilestoneSheet.swift (NEW)
│   └── (keep others)
│
│   DELETE:
│   ├── PlanTabView.swift (REMOVE)
└── Utils/Strings/
    └── Strings+Health.swift (UPDATED with milestone keys)
```

---

## Localization Keys

Add to `Strings+Health.swift`:

```swift
enum Milestone {
    // Vaccinations
    static let vaccinationFirst = NSLocalizedString(
        "milestone.vaccination.first",
        value: "1st Vaccination",
        comment: "First puppy vaccination"
    )
    static let vaccinationFirstDetail = NSLocalizedString(
        "milestone.vaccination.first.detail",
        value: "DHP + Lepto vaccine. Protects against distemper, hepatitis, parvovirus, and leptospirosis.",
        comment: "First vaccination description"
    )
    // ... etc for all milestones

    // Developmental
    static let fearPeriodFirst = NSLocalizedString(
        "milestone.fearperiod.first",
        value: "Fear Period 1",
        comment: "First fear period milestone"
    )
    static let fearPeriodFirstDetail = NSLocalizedString(
        "milestone.fearperiod.first.detail",
        value: "Your puppy may be extra cautious. Avoid overwhelming experiences. Keep socialization positive and at your puppy's pace.",
        comment: "First fear period description"
    )
    // ... etc

    // UI
    static let addToCalendar = NSLocalizedString(
        "milestone.action.addToCalendar",
        value: "Add to Calendar",
        comment: "Button to add milestone to calendar"
    )
    static let inCalendar = NSLocalizedString(
        "milestone.status.inCalendar",
        value: "In Calendar",
        comment: "Badge showing milestone is in calendar"
    )
    static let markComplete = NSLocalizedString(
        "milestone.action.markComplete",
        value: "Done",
        comment: "Button to mark milestone complete"
    )
}
```

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| This Week card taps | 30% of daily users | Analytics: `this_week_card_tapped` |
| Socialization completion | 60% hit weekly goals | `weekly_progress.isComplete` |
| Calendar exports | 20% of Otis+ users | `milestone_calendar_added` |
| Custom milestones | 15% of Otis+ create 1+ | `custom_milestone_created` |
| Milestone completion | 80% mark vaccines done | `milestone_completed` where category=health |

---

## Appendix: Developmental Timeline Reference

```
Week 0-2:   Neonatal period (with mother)
Week 2-4:   Transitional period (eyes/ears open)
Week 3-12:  PRIMARY SOCIALIZATION WINDOW
Week 4-8:   With breeder (critical early socialization)
Week 8:     Typical "go home" age
Week 8-10:  FEAR PERIOD 1 (be careful!)
Week 8-16:  CRITICAL SOCIALIZATION WINDOW
Week 12-16: Teething begins (baby teeth fall out)
Week 14:    Socialization window CLOSING
Week 16:    Socialization window CLOSED
Month 4-6:  Juvenile period
Month 6-7:  Adult teeth fully in
Month 6-8:  Adolescence begins
Month 6-14: FEAR PERIOD 2 (varies widely)
Month 6-18: Spay/neuter window (size-dependent)
Month 12-36: Social maturity (breed-dependent)
```

---

## References

- [AVSAB Position Statement on Puppy Socialization](https://avsab.org/resources/position-statements/)
- Dutch LICG vaccination schedule
- Puppy Culture socialization protocols
- Fear periods research (Scott & Fuller, 1965)
