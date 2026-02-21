# TODO: Week Overview

## Overview
Port the web app's week grid view — a 7-day table showing daily counts for key metrics, plus a potty trend chart and per-day detail cards.

## Priority: Medium
Nice for spotting patterns over the week. Less urgent than health/training since StatsView already covers some of this.

## Features

### 1. Week Grid Table
A compact 7-column grid (last 7 days) with rows for each metric:

| Row | Emoji | Key | Color |
|-----|-------|-----|-------|
| Buiten | 🚽 | Outdoor potty count | Green |
| Binnen | ⚠️ | Indoor potty count | Red |
| Eten | 🍽️ | Meal count | Orange |
| Uitlaten | 🚶 | Walk count | Teal |
| Slapen | 😴 | Sleep duration (hours) | Blue |
| Training | 🎓 | Training session count | Purple |

**Column headers:** Short date labels (e.g., "ma 17", "di 18"), today highlighted.

**Cell styling:** Zero values dimmed ("–"), non-zero values colored per row. Today's column has accent background.

### 2. Potty Trend Chart
Line chart showing outdoor potty percentage per day over the last 7 days.

**Implementation (Swift Charts):**
- X-axis: dates
- Y-axis: 0–100%
- Line + area fill
- Dot color: green (≥70%), orange (40–69%), red (<40%)
- Value labels on dots

### 3. Sleep Calculation
The web app pairs `slapen`/`bench` events with `ontwaken` events to calculate actual sleep minutes per day. This includes overnight sleep from previous day.

```swift
func calculateDaySleepMinutes(date: Date, events: [PuppyEvent]) -> Int {
    // Sort events by time
    // Track sleep start times
    // Pair with ontwaken events
    // Handle overnight: check previous day's last sleep event
    // If currently sleeping (today): count up to now
}
```

### 4. Per-Day Detail Cards (Optional)
Scrollable list of daily cards showing:
- Day number ("Dag 5")
- Date
- Potty percentage with mini progress bar
- Chip badges: ✅ X buiten, X binnen, 🚶 X walks, 🎓 X training, 📸 X photos
- Tap to navigate to that day's timeline

## Files to Create/Modify
- `Views/WeekOverviewView.swift` — main week view
- `Views/WeekGridView.swift` — the 7-day table component
- `Views/PottyTrendChart.swift` — Swift Charts trend line
- `Calculations/SleepCalculations.swift` — likely already exists, extend if needed

## Integration
- This could be a section within StatsView or a separate tab
- Reuses existing calculation modules (SleepCalculations, etc.)
- Data comes from EventStore's existing date-based event storage

## Design Notes
- The grid works well on mobile — compact layout, easy to scan
- Use SwiftUI's `Grid` or `LazyVGrid` for the table
- Highlight today's column
- The web app's colored counts (green for good, red for bad) translate well to iOS
- Consider making it swipeable: swipe left/right to shift the 7-day window
