# TODO: Health & Weight Tracking View

## Overview
Port the web app's "Gezondheid" view to iOS. Tracks Ollie's weight over time with a growth curve chart, and shows a health milestones timeline (vaccinations, deworming, vet visits).

## Priority: Medium-High
Weight tracking becomes more important as Ollie grows — the growth curve helps spot under/overweight early. Health milestones are time-sensitive (vaccination schedule).

## Where It Lives (App Navigation)
**Pushed from Inzichten tab** via a navigation link card ("⚖️ Gezondheid →"). This is a detail view, not a tab. See `TODO-app-navigation.md` for the overall structure.

## Features

### 1. Weight Tracker
**What it does:** Log weight measurements, display current weight + change since last measurement, show growth curve chart.

**Data model:**
- New event type `gewicht` in `PuppyEvent.swift`
- Required field: `weight_kg: Double`
- Stored as regular event with `type: "gewicht"`

**UI components:**
- **Weight hero card:** Current weight (big number), date of measurement, delta since previous ("+0.3 kg since last")
- **Growth curve chart (Swift Charts):** X-axis = weeks since birth, Y-axis = kg
  - Ollie's actual data points (line + dots)
  - Reference band: Golden Retriever female growth curve ±15% (shaded area)
  - Reference center line (dashed)
- **Quick-log button:** Simple number input for weight

**Reference data (Golden Retriever female):**
```swift
struct GrowthReference {
    let weeks: Int
    let kg: Double
    let label: String
}

static let goldenRetrieverFemale: [GrowthReference] = [
    (0, 1.3, "Geboorte"),
    (4, 3.0, "4 weken"),
    (8, 4.5, "8 weken"),
    (12, 8.0, "12 weken"),
    (16, 11.0, "16 weken"),
    (20, 14.0, "20 weken"),
    (26, 17.0, "6 maanden"),
    (34, 20.0, "8 maanden"),
    (42, 23.0, "10 maanden"),
    (52, 25.0, "12 maanden"),
    (78, 27.0, "18 maanden")
]
```

**Chart implementation:** Use Swift Charts framework. Area mark for the reference band, line mark for Ollie's data, point mark for individual measurements.

### 2. Health Milestones Timeline
**What it does:** Visual timeline of health events — vaccinations, deworming, vet visits. Shows done/upcoming/overdue status.

**Data (hardcoded initially, later configurable):**
```swift
struct HealthMilestone: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
    let period: String?     // "Week 8", "6 maanden", etc.
    var isDone: Bool
}

static let defaultMilestones: [HealthMilestone] = [
    // See config.js HEALTH_MILESTONES for full list
    ("2026-01-31", "Eerste ontworming bij fokker", "Week 6", true),
    ("2026-02-14", "Eerste vaccinatie (DHP + Lepto)", "Week 8", false),
    ("2026-02-18", "Eerste dierenartsbezoek (Almaar)", "Week 8.5", true),
    ("2026-02-21", "Eerste ontworming thuis", "Week 9", false),
    ("2026-03-14", "Tweede vaccinatie (DHP + Lepto + Rabiës)", "Week 12", false),
    ("2026-04-11", "Derde vaccinatie (cocktail)", "Week 16", false),
    ("2026-06-20", "Castratie/sterilisatie gesprek dierenarts", "6 maanden", false),
    ("2026-12-20", "Jaarlijkse vaccinatie", "12 maanden", false)
]
```

**UI:** Vertical timeline with status indicators:
- ✅ Done (green checkmark)
- 👉 Next up (highlighted, accent color)
- ○ Future (muted)
- ⏳ Overdue (orange warning)

## Files to Create/Modify
- `Models/PuppyEvent.swift` — add `gewicht` type + `weightKg` field
- `Models/HealthMilestone.swift` — new model
- `Models/GrowthReference.swift` — new model with reference data
- `Views/HealthView.swift` — main health view (pushed from InsightsView)
- `Views/WeightChartView.swift` — Swift Charts growth curve
- `Views/HealthTimelineView.swift` — milestones timeline
- `Views/WeightLogSheet.swift` — quick weight entry
- `Calculations/WeightCalculations.swift` — weight deltas, growth comparison

## Design Notes
- Use the existing glass card style for weight hero and chart
- Chart colors: accent color for Ollie's line, muted for reference band
- Keep the chart interactive: tap a dot to see exact weight + date
- Empty state: show only reference curve with "Nog geen gewichtsmetingen" message
- Nav bar title: "Gezondheid" with back button to Inzichten
