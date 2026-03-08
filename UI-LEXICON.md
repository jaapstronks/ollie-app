# Ollie UI Component Lexicon

Quick reference for naming UI elements in conversations. Use these terms and I'll know exactly what you mean.

---

## Tab Bar

| Tab | View File | Icon |
|-----|-----------|------|
| **Today** | TodayView | pawprint.fill |
| **Train** | TrainTabView | graduationcap.fill |
| **Explore** | PlacesTabView | map.fill |
| **Schedule** | CalendarTabView | calendar.badge.clock |
| **Health** | HealthTabView | heart.text.square.fill |

---

## Today Tab

### Layout (top to bottom)
```
┌─────────────────────────────┐
│  ActivityBanner (if active) │  ← Shows during sleep/walk
├─────────────────────────────┤
│  StatusCards Section        │  ← PottyStatusCard, SleepStatusCard
├─────────────────────────────┤
│  NudgeCards (contextual)    │  ← CrateNudge, MedicationReminder, etc.
├─────────────────────────────┤
│  VerticalTimeline           │  ← Hour grid with events
├─────────────────────────────┤
│  QuickLogBar                │  ← Bottom persistent bar
└─────────────────────────────┘
     FAB (floating, right)    ← "+ Log" button
```

### Status Cards
- **PottyStatusCard** - "Time since last pee" with urgency colors
- **PoopStatusCard** - Poop interval tracking
- **SleepStatusCard** - Current/last sleep duration
- **CombinedSleepPottyCard** - Compact combo view

### Timeline Components
- **VerticalTimeline** (or just "Timeline") - The day planner grid
- **TimelineBlock** - Duration blocks (naps, walks) that span hours
- **TimelinePointEvent** - Single-time events (pee, meal, training)
- **TimelineEventMarker** - The dot/icon at a time
- **EventRow** - How events display in the timeline

### Nudge Cards (contextual prompts)
- **CrateNudgeCard** - Sleep location suggestions
- **WalkTargetNudgeCard** - Walk goals
- **MedicationReminderCard** - Medication adherence
- **PostWakePottyCard** - Prompt after sleep ends
- **AppointmentNudgeCard** - Upcoming vet visits

### Quick Log Bar
- **QuickLogBar** - The bottom persistent bar
- **QuickLogIconButton** - Individual event type buttons

### Floating Elements
- **FAB** / **FABButton** - Floating action button (+ button)
- **FloatingClickerButton** - Persistent clicker during training

---

## Train Tab

### Layout
```
┌─────────────────────────────┐
│  AITrainingGuidanceCard     │  ← AI suggestions
├─────────────────────────────┤
│  RegressionAlertView        │  ← Skills needing work
├─────────────────────────────┤
│  TrainingGuideCards         │  ← Potty Guide, Crate Guide
├─────────────────────────────┤
│  SkillsSection              │  ← List of SkillCards
├─────────────────────────────┤
│  MaintenanceSkillsSection   │  ← Mastered skills needing refresh
├─────────────────────────────┤
│  SocializationJourneyCard   │  ← Exposure tracking
└─────────────────────────────┘
```

### Training Components
- **SkillCard** - Expandable skill with icon, status, actions
- **CompactSkillCard** - Minimal skill preview
- **MaintenanceSkillCard** - Skill refresh reminder
- **TrainingGuideEntryCard** - Card linking to guides (Potty, Crate)
- **TrainingSessionView** - Full-screen clicker training
- **SkillDetailSheet** - Skill information modal

### Progress Indicators
- **PhaseProgressIndicator** - Learning phase dots
- **PottyProgressCard** - Potty training phases
- **ProgressRing** - Circular progress

### Socialization
- **SocializationJourneyCard** - Main socialization entry
- **SocializationProgressCard** - Progress by category
- **LogExposureSheet** - Log new exposure

---

## Health Tab

### Layout
```
┌─────────────────────────────┐
│  DevelopmentPhaseCard       │  ← Current life phase
├─────────────────────────────┤
│  GrowthStoryCard            │  ← Weight narrative + chart
├─────────────────────────────┤
│  SocializationStatusCard    │  ← Window progress
├─────────────────────────────┤
│  MedicalTimelineView        │  ← Medical events
├─────────────────────────────┤
│  MedicationAdherenceView    │  ← Medication tracking
├─────────────────────────────┤
│  SeniorWellnessCard         │  ← (older dogs)
└─────────────────────────────┘
```

### Growth & Development
- **DevelopmentPhaseCard** - Puppy/adolescent/adult phase
- **GrowthStoryCard** - Weight chart preview + narrative
- **GrowthProgressArc** - Arc gauge for size
- **WeightChartView** - Full weight history

### Medical
- **MedicalTimelineView** - Medical events list
- **MedicationAdherenceView** - Medication schedule
- **HealthCheckInCard** - Wellness prompts
- **ConditionQuickLogCard** - Symptom logging

### Stats
- **StatsView** - Aggregated statistics
- **StreakCard** - Outdoor potty streak
- **GapStatsCard** - Potty interval stats

---

## Schedule Tab

### Two Modes
- **Calendar Mode** → CalendarGridView
- **Contacts Mode** → ContactsView

### Calendar
- **CalendarGridView** - Month/week calendar
- **CalendarDayCell** - Individual day
- **AppointmentRow** - Single appointment

### Contacts
- **ContactsView** - Vet, trainer, etc. list
- **ContactRow** - Single contact

---

## Explore Tab

### Two Modes
- **Map Mode** → Map with spots/photos
- **Gallery Mode** → MomentsGalleryView

### Map
- **SpotMapView** - Favorite spots on map
- **PhotoPinDetailCard** - Photo cluster detail
- **PuppysWorldSummaryCard** - Coverage summary

### Spots & Walks
- **FavoriteSpotsView** - Spots list
- **SpotRowView** - Single spot
- **WalkLogSheet** - Log walk

### Gallery
- **MomentsGalleryView** - Photo grid
- **DiaryCardView** - Photo with caption

---

## Common Sheets (Modals)

| Sheet | Opens From | Purpose |
|-------|------------|---------|
| **LogEventSheet** | QuickLogBar tap | Log any event |
| **QuickLogSheet** | FAB | Simplified logging |
| **PottyQuickLogSheet** | Potty button | Pee/poop with location |
| **TrainingLogSheet** | Train tab | Manual training log |
| **WeightLogSheet** | Health | Log weight |
| **MedicationLogSheet** | Health | Log medication taken |
| **AddEditAppointmentSheet** | Schedule | Create/edit appointment |
| **LogExposureSheet** | Train | Log socialization |
| **WalkLogSheet** | Explore | Log walk details |
| **StartActivitySheet** | Sleep button | Begin sleep/crate |
| **EndSleepSheet** | Activity banner | End sleep session |

---

## Reusable Components

### Cards
- **glassCard** - Glass morphism styling (`.glassCard(tint:)`)
- **StatusCard** - Status display card
- **DayHeroCard** - Large summary card

### Buttons
- **QuickActionButton** - Reusable action button
- **GlassToggleButton** - Toggle with glass style

### Headers
- **SectionHeader** - Section title with optional action
- **SheetHeader** - Modal header with close button

### Indicators
- **ProgressRing** - Circular progress
- **LinearProgressBar** - Horizontal bar
- **DurationPill** - Time display (e.g., "45m")

### Banners
- **TrialBanner** - Trial countdown
- **StaleLoggingBanner** - "No recent logs" warning
- **CoverageGapBanner** - Coverage gap indicator

---

## Quick Reference Examples

> "The **PottyStatusCard** on the **Today tab** has too much padding"

> "Can we add a nudge card below the **StatusCards** section?"

> "The **SkillCard** expanded state needs a different icon"

> "In the **VerticalTimeline**, the **TimelineBlock** for naps should be darker"

> "The **QuickLogBar** buttons are too small"

> "On the **Health tab**, the **GrowthStoryCard** should link to **WeightChartView**"

---

## Xcode View Debugger (for exact inspection)

When you need to inspect exact frames/constraints:
1. Run app in simulator
2. **Debug → View Debugging → Capture View Hierarchy**
3. Click any element to see its class in the inspector
4. 3D rotation reveals layer stacking

Note: SwiftUI views often show as generic types, so use this lexicon for communication and the debugger for spatial/layout inspection.
