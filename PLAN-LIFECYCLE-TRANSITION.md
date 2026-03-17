# Lifecycle Transition Plan

> **Status:** Phase A Complete | Phase B Complete (All Features)
> **Last Updated:** 2026-03-07

## The Retention Challenge

```
Puppy Phase (0-8 mo)      → High engagement, daily logging, app feels essential
Teenage Phase (8-18 mo)   → DANGER ZONE: puppy features feel irrelevant
Adult Phase (18mo-7yr)    → Need new value proposition
Senior Phase (7+ yr)      → Health monitoring becomes critical again
```

**Goal:** Keep users subscribed at €54.99/year through lifecycle transitions by shifting app personality and feature emphasis.

---

## Current Implementation Status

### ✅ Phase A: Foundation (COMPLETE)

| Component | Status | Files Changed |
|-----------|--------|---------------|
| LifecyclePhase enum | ✅ Done | `OtisShared/Models/PuppyProfile.swift` |
| lifecyclePhase computed property | ✅ Done | `OtisShared/Models/PuppyProfile.swift` |
| Breed-adjusted senior thresholds | ✅ Done | `OtisShared/Models/PuppyProfile.swift` |
| petTerm / petTermPossessive helpers | ✅ Done | `OtisShared/Models/PuppyProfile.swift` |
| Strings.Lifecycle namespace | ✅ Done | `OtisShared/Utils/Strings.swift` |
| AI context lifecycle awareness | ✅ Done | `Ollie-app/Services/AI/AIContextComponents.swift` |
| AI instructions lifecycle guidance | ✅ Done | `Ollie-app/Services/AI/AIInstructions.swift` |
| High-impact string updates | ✅ Done | Multiple Strings+*.swift files |

**What's working now:**
- `profile.lifecyclePhase` returns `.puppy`, `.teenage`, `.adult`, or `.senior`
- `profile.petTerm` returns "puppy" or "dog" based on phase
- AI nudges receive lifecycle context and adjust terminology automatically
- Breed-size-aware senior thresholds (small dogs live longer)

### 🔄 Remaining Phase A Polish (Optional)

| Task | Priority | Effort | Notes |
|------|----------|--------|-------|
| Wire function strings to views | Low | Low | Views should call `heroSubtitle(name:)` instead of static version |
| Update ~150 remaining "puppy" strings | Low | Medium | Training content is puppy-focused anyway |
| Add phase transition UI prompts | Medium | Medium | "Your puppy is growing up!" sheets |

### ✅ Phase B: Teenage Retention (COMPLETE)

This was the most critical phase for reducing churn. All core features implemented.

**Completed:**
- ✅ Lifecycle-Aware Quick Log Bar - Phase-specific quick log buttons
- ✅ Behavior Incident Logging System - Full behavior tracking with categories, triggers, intensity
- ✅ Walks This Week Summary Card - Weekly walk stats for teenage+ dogs
- ✅ Behavior Support Module - Phase 1 (Train Tab card + full view with professional disclaimer)
- ✅ Behavior Support Module - Phase 2 (Interventions logging with 18 templates)
- ✅ Behavior Support Module - Phase 3 (Progress summary, trends, AI context integration)
- ✅ Monthly Recap - Auto-generated summaries with photo grid, shareable cards
- ✅ Training Maintenance Mode - Simplified skill maintenance with weekly reminders

**All Phase B features are now implemented and building successfully.**

### ⬜ Phase C: Adult Features (NOT STARTED)

### ⬜ Phase D: Senior Features (NOT STARTED)

### ⬜ Phase E: Health Calendar (NOT STARTED)

---

## Recommended Next Steps

### Option 1: Quick Wins (1-2 days each)

These can ship independently and provide immediate value:

#### 1A. Walks This Week Summary Card ✅ COMPLETE
**Impact:** Medium | **Effort:** Low | **Phase:** B

Add a card showing weekly walk stats for teenage+ dogs:
```
┌─────────────────────────────────┐
│ 🚶 This Week                    │
│ 5 walks · 3.2 hours             │
│ ▓▓▓▓▓░░ (5/7 days)              │
└─────────────────────────────────┘
```

**Implementation:**
- [x] Create `WeeklyWalkSummaryCard` view component
- [x] Add to Today view for teenage+ dogs (based on lifecyclePhase)
- [x] Calculate from existing walk events (uses TimelineStatsCache)
- [ ] Show distance if GPS walks are logged (deferred - no GPS data currently)

**Files modified:**
- `Ollie-app/Views/TodayView.swift` - Added card to statusCardsSection
- `Ollie-app/Views/Cards/WeeklyWalkSummaryCard.swift` (new)
- `Ollie-app/Utils/Strings/Strings+Walks.swift` - Added WalkSummary namespace

#### 1B. Phase Transition Celebration Sheet
**Impact:** Medium | **Effort:** Low | **Phase:** A polish

Show a celebratory sheet when dog transitions phases:

```
┌─────────────────────────────────┐
│      🎉 Luna is Growing Up!     │
│                                 │
│  Luna has entered the teenage   │
│  phase! Here's what changes:    │
│                                 │
│  • Less potty reminders         │
│  • More focus on adventures     │
│  • Training maintenance mode    │
│                                 │
│       [ Got it! ]               │
└─────────────────────────────────┘
```

**Implementation:**
- [ ] Create `PhaseTransitionSheet` view
- [ ] Store `lastAcknowledgedPhase` in profile
- [ ] Check on app launch if phase changed
- [ ] Show sheet once per transition

**Files to modify:**
- New: `Ollie-app/Views/Onboarding/PhaseTransitionSheet.swift`
- `OtisShared/Models/PuppyProfile.swift` - Add `lastAcknowledgedPhase`
- `Ollie-app/OllieApp.swift` - Check on launch

#### 1C. Lifecycle-Aware Quick Log Bar ✅ COMPLETE
**Impact:** High | **Effort:** Low | **Phase:** B

Adjust quick-log buttons based on lifecycle phase:

**Puppy:** Uses smart time-window visibility (meals near mealtime, walks near walk windows)
**Teenage:** 🚶 Walk | ⚠️ Behavior | 🎓 Training | 🐕 Social | 💧 Potty | 😴 Sleep
**Adult:** 🚶 Walk | 📸 Moment | 🐕 Social | 💧 Potty | 😴 Sleep
**Senior:** 🚶 Walk | 💊 Meds | 📸 Moment | 💧 Potty | 😴 Sleep

**Implementation:**
- [x] Create `quickLogTypes(for: LifecyclePhase)` in Constants
- [x] Add `usesSmartVisibility(for: LifecyclePhase)` flag
- [x] Add `lifecyclePhase` to `QuickLogContext`
- [x] Update `QuickLogBar.visibleItems` to use phase-based configuration
- [x] Pass lifecycle phase from `TimelineViewModel.quickLogContext`

**Files modified:**
- `OtisShared/Utils/Constants.swift` - Added lifecycle quick log configuration
- `Ollie-app/Views/Components/QuickLogBar.swift` - Added lifecycle-aware visibility
- `Ollie-app/ViewModels/TimelineViewModel+Events.swift` - Pass lifecycle phase to context

---

### Option 2: Behavior Logging ✅ COMPLETE

The flagship teenage retention feature. Owners dealing with adolescent behavior issues need to track patterns.

#### 2A. BehaviorIncident Model & Event Type ✅ COMPLETE
**Impact:** High | **Effort:** Medium | **Phase:** B

Enhanced behavior incident logging with detailed tracking:

**BehaviorCategory** (10 categories):
- `reactivity` - Lunging, barking at triggers
- `anxiety` - Panting, pacing, whining
- `destructive` - Chewing, digging inappropriately
- `barking` - Excessive vocalization
- `guarding` - Resource guarding behavior
- `jumping` - Jumping on people
- `pulling` - Leash pulling
- `recall` - Not coming when called
- `mouthing` - Inappropriate mouthing/nipping
- `fearful` - Cowering, hiding, trembling

**BehaviorIntensity** (1-5 scale):
- Mild → Severe with descriptions

**BehaviorOutcome**:
- Redirected, Escalated, Self-resolved, Removed, Managed

**BehaviorContext**:
- Home, Walk, Park, Vet, Car, Public place

**Implementation completed:**
- [x] Add `BehaviorCategory`, `BehaviorIntensity`, `BehaviorOutcome`, `BehaviorContext` enums to OtisShared
- [x] Extend `PuppyEvent` with behavior incident fields (category, trigger, intensity, outcome, context)
- [x] Add `PuppyEvent.behaviorIncident()` factory method
- [x] Add `Strings.Behavior` namespace with 100+ localized strings
- [x] Create `BehaviorLogSheet` with multi-step logging flow
- [x] Add `.behaviorLog` sheet case to `SheetCoordinator`
- [x] Wire up behavior logging in `TimelineSheetModifiers`
- [x] Route `.gedrag` taps to `BehaviorLogSheet` in `quickLog()` function
- [x] Add `.gedrag` to teenage quick log configuration
- [x] Update event icon/color for behavior (warning triangle, orange)
- [x] Enable behavior logging in `AllEventsSheet`

**Files created:**
- `OtisShared/Models/BehaviorIncident.swift` - Enums for behavior tracking
- `Ollie-app/Views/Behavior/BehaviorLogSheet.swift` - Detailed logging UI

**Files modified:**
- `OtisShared/Utils/Strings.swift` - Added Strings.Behavior namespace
- `OtisShared/Models/PuppyEvent.swift` - Added behavior fields and factory method
- `OtisShared/Utils/Constants.swift` - Added .gedrag to teenage phase
- `Ollie-app/ViewModels/SheetCoordinator.swift` - Added .behaviorLog case
- `Ollie-app/Views/Components/TimelineSheetModifiers.swift` - Wire up sheet
- `Ollie-app/ViewModels/TimelineViewModel+Events.swift` - Route to behavior sheet
- `Ollie-app/Views/Timeline/AllEventsSheet.swift` - Enable behavior logging
- `Ollie-app/Views/Timeline/EventIcon.swift` - Updated icon and color

#### 2B. Behavior Pattern Detection (AI Enhancement)
**Impact:** High | **Effort:** Medium | **Phase:** B

Enhance AI to detect behavior patterns and provide guidance:

```
"We noticed 3 reactivity incidents this week, all triggered by
other dogs during morning walks. Consider working on counter-
conditioning during quieter times."
```

**Implementation:**
- [ ] Add `BehaviorContext` to AIContextComponents
- [ ] Create behavior analysis AI surface
- [ ] Generate weekly behavior insights
- [ ] Link to relevant training suggestions

---

### Option 2C: Behavior Support Module (NEW - Train Tab Integration) ✅ PHASES 1 & 2 COMPLETE
**Impact:** High | **Effort:** Medium | **Phase:** B

A dedicated module in the Train tab for managing behavior challenges. Builds on the existing behavior logging system to provide ongoing support.

**Key Principles:**
1. **Professional Disclaimer Required** - Clear messaging that professional guidance (trainer/vet) is recommended for persistent issues
2. **Flexible Logging** - Support user-defined interventions from their trainer
3. **Pattern Recognition** - Surface insights from logged incidents
4. **Progress Tracking** - Show improvement over time

**UI Structure:**
```
Train Tab
├── AI Training Guidance (existing)
├── Skills Section (existing)
├── Socialization Section (existing)
└── Behavior Support (NEW) ← Only shows for teenage+ OR if incidents logged
    ├── ⚠️ Professional Disclaimer Banner (collapsible)
    ├── Active Issues (aggregated from logged incidents)
    │   └── [Reactivity] - 3 incidents this week
    │       ├── Trend indicator (↑ worse / → stable / ↓ improving)
    │       ├── Common triggers
    │       └── Quick log button
    ├── Recent Incidents (last 7 days)
    ├── Interventions Log (what you're trying)
    │   ├── "Counter-conditioning" - practicing daily
    │   └── "Shorter walks, quieter routes"
    └── Progress Notes
```

**Implementation - Phase 1 (Scaffolding):** ✅ COMPLETE
- [x] Create `BehaviorSupportCard` for TrainTabView (compact card)
- [x] Create `BehaviorSupportView` (full view with all features)
- [x] Add professional disclaimer banner
- [x] Show active issues from recent incidents
- [x] Link to BehaviorLogSheet for quick logging
- [x] Add strings for the module (Strings.BehaviorSupport namespace)
- [x] Add PuppyEvent behavior fields and factory method
- [x] Add trend indicators (improving/stable/worsening/new)

**Implementation - Phase 2 (Interventions):** ✅ COMPLETE
- [x] Create `BehaviorIntervention` model (name, category, notes, isActive, practicedDates)
- [x] Create `InterventionTemplate` enum with 18 common intervention types
- [x] Create `InterventionLogSheet` for adding interventions from templates or custom
- [x] Store interventions in PuppyProfile (behaviorInterventions array)
- [x] Create ProfileStore+BehaviorInterventions extension for CRUD operations
- [x] Display active interventions in BehaviorSupportView with InterventionRow
- [x] Track when interventions were practiced (markPracticed button + context menu)
- [x] Add ~40 intervention-related strings to Strings.BehaviorSupport

**Implementation - Phase 3 (Progress & Insights):** ✅ COMPLETE
- [x] Calculate trend indicators (incidents this week vs last week)
- [x] Show common trigger patterns (triggerPatternsView)
- [x] Generate progress summary (weekComparisonView)
- [x] Add AI-powered insights (BehaviorChallengesContext in AIContextComponents)
- [x] Show intervention effectiveness (interventionEffectivenessView)

**Files Created:**
- `Ollie-app/Views/Behavior/BehaviorSupportCard.swift` - Compact card for Train tab
- `Ollie-app/Views/Behavior/BehaviorSupportView.swift` - Full view with interventions
- `Ollie-app/Views/Behavior/InterventionLogSheet.swift` - Sheet for adding interventions
- `Ollie-app/Services/ProfileStore+BehaviorInterventions.swift` - Intervention CRUD operations

**Files Modified:**
- `Ollie-app/Views/Training/TrainTabView.swift` - Add behavior support section
- `OtisShared/Sources/OtisShared/Utils/Strings.swift` - Add BehaviorSupport namespace (~60 strings)
- `OtisShared/Sources/OtisShared/Models/BehaviorIncident.swift` - Add BehaviorIntervention model + InterventionTemplate enum
- `OtisShared/Sources/OtisShared/Models/PuppyProfile.swift` - Add behaviorInterventions array
- `OtisShared/Sources/OtisShared/Models/PuppyEvent.swift` - Add behavior incident fields

---

### Option 3: Training Maintenance Mode ✅ COMPLETE

Keep training relevant for older dogs without the intensity.

#### 3A. Skill Maintenance Toggle ✅ COMPLETE
**Impact:** Medium | **Effort:** Low | **Phase:** B

Allow marking skills as "learned" to switch to maintenance mode:

```
┌─────────────────────────────────┐
│ ✅ Sit                          │
│ Mastered · Last practiced 5d   │
│                                 │
│ [ Practice Now ] [ Maintenance ]│
└─────────────────────────────────┘
```

In maintenance mode:
- Weekly reminder to practice (instead of daily)
- Simpler UI (no phases, just "refresh" prompts)
- Track for regression (overdue after 14 days)

**Implementation:**
- [x] Add `isInMaintenanceMode` flag to SkillProgress
- [x] Add computed properties: `daysSinceLastPractice`, `needsMaintenanceRefresh`, `isMaintenanceOverdue`
- [x] Add methods: `enableMaintenanceMode()`, `disableMaintenanceMode()`, `recordMaintenanceRefresh()`
- [x] Add `isInMaintenanceMode` to Core Data model (CDSkillProgress)
- [x] Add SkillProgressStore methods for maintenance mode management
- [x] Create `MaintenanceSkillCard` component (shows last practiced, refresh action)
- [x] Create `MaintenanceSkillsSection` for displaying maintained skills
- [x] Create `SkillRefresherSheet` for quick skill refreshers
- [x] Integrate MaintenanceSkillsSection into TrainingView
- [x] Add maintenance mode strings (~15 new strings)

**Files Created:**
- `Ollie-app/Views/Training/MaintenanceSkillCard.swift` - Card for skills in maintenance
- `Ollie-app/Views/Training/MaintenanceSkillsSection.swift` - Section showing maintained skills
- `Ollie-app/Views/Training/SkillRefresherSheet.swift` - Quick refresher sheet for maintenance reviews

**Files Modified:**
- `OtisShared/Models/SkillProgress.swift` - Added maintenance mode flag and methods
- `Ollie-app/Models/CoreData/CDSkillProgress+Extensions.swift` - Added persistence
- `Ollie-app/Ollie.xcdatamodeld/Ollie.xcdatamodel/contents` - Added attribute
- `Ollie-app/Services/SkillProgressStore.swift` - Added maintenance mode methods
- `Ollie-app/Utils/Strings/Strings+Training.swift` - Added maintenance strings
- `Ollie-app/Views/Training/TrainingView.swift` - Integrated MaintenanceSkillsSection and SkillRefresherSheet

#### 3B. Fun Tricks Library
**Impact:** Medium | **Effort:** Medium | **Phase:** B

New category of tricks for bonding (not obedience):

- Spin / Twirl
- High five / Wave
- Play dead
- Roll over
- Bow
- Speak / Quiet
- Find it (scent game)
- Touch (target training)

**Implementation:**
- [ ] Add "Tricks" skill category
- [ ] Create trick content (instructions, videos)
- [ ] Separate from core obedience in UI
- [ ] Fun achievement badges for tricks

---

### Option 4: Monthly Recap ✅ COMPLETE

Retention hook that reminds users of value they're getting.

#### 4A. Auto-Generated Monthly Summary ✅ COMPLETE
**Impact:** High | **Effort:** Medium | **Phase:** B

End-of-month summary view:

```
┌─────────────────────────────────┐
│     February with Luna 🐕       │
│                                 │
│  📸 12 moments captured         │
│  🚶 28 walks · 42 hours         │
│  🐕 8 social interactions       │
│  🎓 3 skills practiced          │
│                                 │
│  Highlight: First beach trip!   │
│                                 │
│    [ View Full Recap ]          │
│    [ Share ]                    │
└─────────────────────────────────┘
```

**Implementation:**
- [x] Create `MonthSummaryStats` model with aggregated stats
- [x] Create `MonthCalculations` with stats calculation methods
- [x] Create `MonthRecapViewModel` with month navigation
- [x] Create `MonthRecapTeaseCard` for Today view (shown days 28-31 and 1-3)
- [x] Create `MonthRecapSheet` with full stats, photo grid, activity breakdown
- [x] Create `MonthRecapShareView` (1080x1080 shareable card)
- [x] Wire card to TodayStatusCardsSection
- [x] Add Recap.xcstrings for localization
- [x] Create Strings+Recap.swift with all strings

**Files Created:**
- `OtisShared/Calculations/MonthCalculations.swift` - Stats calculation
- `Ollie-app/ViewModels/MonthRecapViewModel.swift` - ViewModel with navigation
- `Ollie-app/Views/Cards/MonthRecapTeaseCard.swift` - Tease card for Today
- `Ollie-app/Views/Recap/MonthRecapSheet.swift` - Full recap view
- `Ollie-app/Views/Recap/MonthRecapShareView.swift` - Shareable card
- `Ollie-app/Utils/Strings/Strings+Recap.swift` - Recap strings
- `Ollie-app/Recap.xcstrings` - Localization catalog

**Files Modified:**
- `Ollie-app/Views/Timeline/TodayView.swift` - Added sheet and state
- `Ollie-app/Views/Timeline/TodayStatusCardsSection.swift` - Added recap card

---

## Detailed Feature Specifications

### Part 1: Lifecycle-Aware App Personality

#### 1.1 Terminology Shifts ✅ IMPLEMENTED

| Original | Puppy (0-8mo) | Teenage (8-18mo) | Adult (18mo+) |
|----------|---------------|------------------|---------------|
| "Your puppy" | ✅ Use | "Your dog" | "Your dog" |
| "Puppy's day" | ✅ Use | "{Name}'s day" | "{Name}'s day" |
| "Potty training" | ✅ Use | "Potty habits" | Hide if trained |
| "Socialization window" | ✅ Use | "Social experiences" | "Social life" |

**Implementation:** ✅ `PuppyProfile.lifecyclePhase` and `petTerm` properties

#### 1.2 Development Phase Card Adaptation

| Phase | Card Content |
|-------|-------------|
| Puppy | Development stages, milestones |
| Teenage | Adolescence guide, regression warnings, second fear period |
| Adult | Health & Wellness, upcoming checkups |
| Senior | Senior Wellness, mobility/cognitive tips |

#### 1.3 Today View Card Priority

**Puppy Mode:**
1. Potty status/predictions
2. Sleep tracking
3. Training nudge
4. Socialization progress

**Teenage Mode:**
1. Walk/exercise tracking
2. Training maintenance
3. Behavior check-in
4. Upcoming health events

**Adult Mode:**
1. Daily routine status
2. Walk tracking
3. Health reminders
4. Memory/moment prompts

**Senior Mode:**
1. Wellness check-in
2. Medication reminders
3. Activity level monitoring
4. Comfort tips

---

### Part 2: Teenage Phase Retention Features

#### 2.1 Explore Tab Enhancement

Make "Places" the hero feature for teenage/adult dogs.

| Feature | Status | Priority |
|---------|--------|----------|
| Trip planner | ⬜ Not started | Medium |
| Walk route history | ⬜ Not started | High |
| Dog-friendly venues | ⬜ Not started | Low |
| Adventure log | ⬜ Not started | Medium |
| Seasonal suggestions | ⬜ Not started | Low |
| Walks this week summary | ✅ Done | **High - Quick Win** |

#### 2.2 Moments Tab Enhancement

Shift from "logging" to "capturing memories."

| Feature | Status | Priority |
|---------|--------|----------|
| Monthly recap | ✅ Done | **High** |
| Milestone suggestions | ⬜ Not started | Medium |
| Year in review | ⬜ Not started | High (Jan retention) |
| Memory book v2 | ⬜ Not started | Low |

#### 2.3 Training Maintenance Mode

| Feature | Status | Priority |
|---------|--------|----------|
| Maintenance toggle | ✅ Done | **High** |
| Trick library | ⬜ Not started | Medium |
| Proofing challenges | ⬜ Not started | Low |
| Regression detection | ✅ Done (via overdue tracking) | Medium |

#### 2.4 Behavior Logging

| Feature | Status | Priority |
|---------|--------|----------|
| BehaviorIncident model | ✅ Done | **High** |
| Behavior log sheet | ✅ Done | **High** |
| Pattern detection | ⬜ Not started | Medium |
| Trainer export | ⬜ Not started | Low |

---

### Part 3: Health Checkup Reminders

| Age | Health Event | Status |
|-----|--------------|--------|
| 4 months | Puppy vaccines complete | ⬜ Not started |
| 6 months | Spay/neuter discussion | ⬜ Not started |
| 12 months | First annual checkup | ⬜ Not started |
| 12 months | Transition to adult food | ⬜ Not started |
| 2 years | Dental cleaning baseline | ⬜ Not started |
| 7 years | Senior wellness exam | ⬜ Not started |
| 7+ years | Bi-annual checkups | ⬜ Not started |

---

### Part 4: Notification Strategy by Phase

| Notification Type | Puppy | Teenage | Adult | Senior |
|-------------------|-------|---------|-------|--------|
| Potty predictions | Every 2-3h | Off by default | Off | Off |
| Walk reminders | 2-3x daily | 2-3x daily | Per schedule | Per schedule |
| Training nudges | 1-2x daily | Weekly | Off | Off |
| Meal reminders | Per schedule | Per schedule | Per schedule | Per schedule |
| Medication | - | - | - | Per schedule |
| Memory prompts | - | Weekly | Weekly | Weekly |

**Implementation:**
- [ ] Add notification profile selection in settings
- [ ] Auto-suggest profile change at phase transitions
- [ ] Allow granular override per notification type

---

### Part 5: Adult Dog Features

| Feature | Status | Priority |
|---------|--------|----------|
| Routine tracker | ⬜ Not started | Medium |
| Weight goal tracking | ⬜ Not started | Medium |
| Body condition scoring | ⬜ Not started | Low |
| Grooming schedule | ⬜ Not started | Low |
| Enrichment library | ⬜ Not started | Low |

---

### Part 6: Senior Dog Features

| Feature | Status | Priority |
|---------|--------|----------|
| Senior mode activation | ⬜ Not started | High |
| Mobility tracking | ⬜ Not started | High |
| CCD screening | ⬜ Not started | Medium |
| Medication tracker | 🔄 Partially exists | Medium |
| Quality of life tools | ⬜ Not started | Medium |

---

## Technical Implementation Details

### 7.1 Profile Model Extensions ✅ IMPLEMENTED

```swift
// Already implemented in OtisShared/Models/PuppyProfile.swift

public enum LifecyclePhase: String, Codable, Sendable {
    case puppy, teenage, adult, senior

    public var usesPuppyTerminology: Bool { self == .puppy }
}

extension PuppyProfile {
    public var lifecyclePhase: LifecyclePhase {
        let months = ageInMonths
        if months >= seniorAgeMonths { return .senior }
        if months >= 18 { return .adult }
        if months >= 8 { return .teenage }
        return .puppy
    }

    public var seniorAgeMonths: Int {
        switch sizeCategory {
        case .small: return 120      // 10 years
        case .medium: return 96      // 8 years
        case .large: return 84       // 7 years
        case .extraLarge: return 72  // 6 years
        }
    }

    public var petTerm: String {
        lifecyclePhase.usesPuppyTerminology ? "puppy" : "dog"
    }
}
```

### 7.2 AI Context ✅ IMPLEMENTED

```swift
// Already implemented in Ollie-app/Services/AI/AIContextComponents.swift

struct DogIdentityContext: AIContextComponent {
    let lifecyclePhase: String        // "puppy", "teenage", "adult", "senior"
    let usesPuppyTerminology: Bool    // true only for puppy phase
    let lifeStage: String             // fine-grained: "neonatal", "early_puppy", etc.
    // ... other fields
}
```

### 7.3 New Models Needed

| Model | Purpose | Phase | Status |
|-------|---------|-------|--------|
| `BehaviorIncident` | Behavior logging | B | ✅ Done |
| `HealthMilestone` | Age-triggered health events | E | ⬜ |
| `Routine` | Daily routine configuration | C | ⬜ |
| `MobilityAssessment` | Senior mobility checks | D | ⬜ |
| `CognitiveAssessment` | CCD screening | D | ⬜ |

### 7.4 UI Components Needed

| Component | Purpose | Phase | Status |
|-----------|---------|-------|--------|
| `PhaseTransitionSheet` | Celebrate phase changes | A polish | ⬜ |
| `WeeklyWalkSummaryCard` | Walk stats for teenage+ | B | ✅ Done |
| `BehaviorLogSheet` | Log behavior incidents | B | ✅ Done |
| `BehaviorSupportCard` | Compact card for Train tab | B | ✅ Done |
| `BehaviorSupportView` | Full behavior management view | B | ✅ Done |
| `BehaviorTrendsView` | Visualize patterns | B | ✅ Done (integrated in BehaviorSupportView) |
| `MonthlyRecapView` | Month summary | B | ✅ Done |
| `MaintenanceTrainingCard` | Simplified training | B | ✅ Done |
| `MaintenanceSkillsSection` | Section for maintained skills | B | ✅ Done |
| `SkillRefresherSheet` | Quick refresh for skills | B | ✅ Done |

---

## Files Changed (Phase A)

```
✅ OtisShared/Sources/OtisShared/Models/PuppyProfile.swift
   - Added LifecyclePhase enum
   - Added lifecyclePhase, seniorAgeMonths, petTerm, petTermPossessive

✅ OtisShared/Sources/OtisShared/Utils/Strings.swift
   - Added Strings.Lifecycle namespace with phase labels and terms

✅ Ollie-app/Services/AI/AIContextComponents.swift
   - Added lifecyclePhase and usesPuppyTerminology to DogIdentityContext
   - Updated lifeStage calculation to include senior

✅ Ollie-app/Services/AI/AIInstructions.swift
   - Added lifecycleGuidance shared section
   - Updated all 6 system instructions with lifecycle awareness
   - Changed "puppy" → "dog" in generic descriptions

✅ Ollie-app/Utils/Strings/Strings+Health.swift
   - Added yourPet(isPuppy:) function

✅ Ollie-app/Utils/Strings/Strings+Settings.swift
   - Added lifecycle-aware string functions
   - Renamed puppyState → activityState

✅ Ollie-app/Utils/Strings/Strings+OtisPlus.swift
   - Added personalized string functions with name parameter

✅ Ollie-app/Utils/Strings/Strings+Profile.swift
   - Changed "puppy profile" → "dog profile"

✅ Ollie-app/Models/Enums/PremiumFeature.swift
   - Updated to use static fallback versions

✅ Ollie-app/Views/Settings/AppSettingsView.swift
   - Updated to use activityState instead of puppyState
```

---

## Success Metrics

| Metric | Current (Est.) | Target | Measurement |
|--------|----------------|--------|-------------|
| 12-month retention | ~40% | >60% | Subscription renewals |
| 18-month retention | ~25% | >45% | Subscription renewals |
| Active users at dog age 2+ | ~15% | >30% | DAU/MAU by cohort |
| Senior mode adoption | N/A | >70% | Feature flag adoption |
| NPS for adult dog owners | Unknown | >40 | In-app survey |

---

## Priority Recommendation

**For maximum impact with minimum effort, implement in this order:**

1. **Quick Win: Lifecycle-Aware Quick Log Bar** (1 day)
   - Immediate visibility of lifecycle awareness
   - Simple implementation
   - Sets foundation for behavior logging

2. **Quick Win: Walks This Week Summary** (1 day)
   - High-value for teenage/adult dogs
   - Uses existing data
   - Makes app feel relevant

3. **Behavior Logging** (3-5 days)
   - Core teenage retention feature
   - High user value
   - Foundation for AI behavior insights

4. **Monthly Recap** (3-4 days)
   - Strong retention hook
   - Shareable content
   - Builds toward Year in Review

5. **Training Maintenance Mode** (2-3 days)
   - Keeps training relevant
   - Lower effort than new features
   - Natural evolution of existing system

---

## Notes

- Large breeds age faster—breed-adjusted phase transitions already implemented
- Some users may want to stay in "puppy mode" (consider manual override)
- Multi-dog support would compound retention value (future consideration)
- Annual "Year with {Name}" feature is a strong January renewal driver
- Consider A/B testing phase transition timing

---

## Progress Log

### 2026-03-07: Phase A Foundation + AI Context Complete

**Completed:**

1. **LifecyclePhase Model** (`OtisShared/Models/PuppyProfile.swift`)
   - [x] Added `LifecyclePhase` enum: `.puppy`, `.teenage`, `.adult`, `.senior`
   - [x] Added `lifecyclePhase` computed property based on `ageInMonths`
   - [x] Breed-size-aware senior thresholds (small: 10yr, medium: 8yr, large: 7yr, XL: 6yr)
   - [x] Added `petTerm` → "puppy" or "dog" based on phase
   - [x] Added `petTermPossessive` → "puppy's" or "dog's"

2. **Lifecycle Strings Infrastructure** (`OtisShared/Utils/Strings.swift`)
   - [x] Added `Strings.Lifecycle` namespace with phase labels
   - [x] Added `Strings.Lifecycle.Terms` for "puppy"/"dog" variants
   - [x] Added `Strings.Lifecycle.Phrases` for "your puppy"/"your dog" patterns

3. **Updated High-Impact Strings** (pattern: function + static fallback)
   - [x] Settings, OtisPlus, Health, Profile strings updated
   - [x] Share messages and milestone terminology updated

4. **AI Context Builder** (`Ollie-app/Services/AI/AIContextComponents.swift`)
   - [x] Added `lifecyclePhase` to `DogIdentityContext`
   - [x] Added `usesPuppyTerminology` boolean flag
   - [x] Updated `lifeStage` calculation to include "senior" stage

5. **AI Instructions** (`Ollie-app/Services/AI/AIInstructions.swift`)
   - [x] Added `lifecycleGuidance` shared guidance section
   - [x] Updated all 6 system instructions with lifecycle awareness
   - [x] Added phase-specific guidance for potty, socialization, health

**Build Status:** ✅ Compiles successfully

---

### 2026-03-07: Phase B - Quick Log Bar & Behavior Logging Complete

**Completed:**

1. **Lifecycle-Aware Quick Log Bar** (`OtisShared/Utils/Constants.swift`, `Ollie-app/Views/Components/QuickLogBar.swift`)
   - [x] Added `quickLogTypes(for: LifecyclePhase)` function
   - [x] Added `usesSmartVisibility(for: LifecyclePhase)` - puppies use time-window logic, older dogs get consistent buttons
   - [x] Extended `QuickLogContext` with `lifecyclePhase` property
   - [x] Updated `visibleItems` in `QuickLogBar` to use phase-based configuration
   - [x] Added SwiftUI previews for puppy, teenage, and senior phases

2. **Behavior Incident Logging System** (Full implementation)
   - [x] Created `BehaviorIncident.swift` with comprehensive enums:
     - `BehaviorCategory` (10 types: reactivity, anxiety, destructive, etc.)
     - `BehaviorIntensity` (1-5 scale with descriptions)
     - `BehaviorOutcome` (redirected, escalated, self-resolved, removed, managed)
     - `BehaviorContext` (home, walk, park, vet, car, public, other)
   - [x] Extended `PuppyEvent` with behavior fields (category, trigger, intensity, outcome, context)
   - [x] Added `PuppyEvent.behaviorIncident()` factory method
   - [x] Added `Strings.Behavior` namespace with 100+ localized strings
   - [x] Created `BehaviorLogSheet` with:
     - Category selection grid
     - Trigger chip selection with common triggers per category
     - Intensity picker (1-5 visual scale)
     - Context picker with icons
     - Outcome selection
     - Time adjustment
     - Notes field
   - [x] Integrated with sheet coordinator and timeline
   - [x] Added `.gedrag` to teenage quick log configuration
   - [x] Updated behavior event icon (exclamationmark.triangle.fill) and color (warning orange)

**Files changed:**
```
OtisShared/Sources/OtisShared/Utils/Constants.swift
OtisShared/Sources/OtisShared/Utils/Strings.swift
OtisShared/Sources/OtisShared/Models/PuppyEvent.swift
OtisShared/Sources/OtisShared/Models/BehaviorIncident.swift (new)
Ollie-app/Views/Components/QuickLogBar.swift
Ollie-app/Views/Behavior/BehaviorLogSheet.swift (new)
Ollie-app/Views/Timeline/AllEventsSheet.swift
Ollie-app/Views/Timeline/EventIcon.swift
Ollie-app/ViewModels/SheetCoordinator.swift
Ollie-app/ViewModels/TimelineViewModel+Events.swift
Ollie-app/Views/Components/TimelineSheetModifiers.swift
```

**Build Status:** ✅ Compiles successfully

---

### 2026-03-07: Phase B - Walks This Week Summary Card Complete

**Completed:**

1. **WeeklyWalkSummaryCard** (`Ollie-app/Views/Cards/WeeklyWalkSummaryCard.swift`)
   - [x] Created new card showing weekly walk statistics
   - [x] Shows walk count and total duration (when available)
   - [x] Visual progress indicator (7 blocks showing days with walks)
   - [x] Days count label (e.g., "5/7 days")
   - [x] Uses existing `cachedWeekStats` and `cachedWeekWalkStats` from TimelineViewModel

2. **Lifecycle-Aware Integration** (`Ollie-app/Views/TodayView.swift`)
   - [x] Card only shows for teenage+ dogs (not puppies)
   - [x] Card only shows when there's walk data (count > 0)
   - [x] Positioned after trial cards in statusCardsSection

3. **Localization** (`Ollie-app/Utils/Strings/Strings+Walks.swift`)
   - [x] Added `WalkSummary` namespace with title, minutes, hours, daysProgress, accessibilityLabel

**Files changed:**
```
Ollie-app/Views/Cards/WeeklyWalkSummaryCard.swift (new)
Ollie-app/Views/TodayView.swift
Ollie-app/Utils/Strings/Strings+Walks.swift
```

**Build Status:** ✅ Compiles successfully

**Next Session:**
- Phase Transition Celebration Sheet (optional polish)
- Behavior Pattern Detection (AI enhancement)
- Phase C: Adult Features
- Phase D: Senior Features

---

### 2026-03-07: Phase B - MaintenanceSkillsSection Integration Complete

**Completed:**

1. **Integrated MaintenanceSkillsSection into TrainingView**
   - [x] Added `skillForRefresher` state variable
   - [x] Added `MaintenanceSkillsSection` to training content
   - [x] Wired up `onSkillTap` to open skill detail sheet
   - [x] Wired up `onRefresh` to record maintenance refresh
   - [x] Wired up `onShowRefresher` to open SkillRefresherSheet
   - [x] Added sheet for `SkillRefresherSheet` with practice initiation

**Files changed:**
```
Ollie-app/Views/Training/TrainingView.swift
```

**Build Status:** ✅ Compiles successfully

**Phase B Status:** All features complete. The following are implemented:
- Lifecycle-Aware Quick Log Bar
- Behavior Incident Logging System
- Walks This Week Summary Card
- Behavior Support Module (Phases 1-3)
- Monthly Recap
- Training Maintenance Mode (with UI integration)
