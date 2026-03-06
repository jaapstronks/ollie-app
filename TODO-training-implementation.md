# Smart Training Logic: Implementation Status & Next Steps

**Date: March 2026**
**Builds on:** `training-logic-briefing.md` (the dog training expert's requirements document)

---

## Context

The `training-logic-briefing.md` document defines the scientific approach to dog training we want to implement: skill lifecycle phases, spaced repetition, regression handling, session composition, and the 3Ds (Duration, Distance, Distraction). This document tracks our implementation progress.

---

## What's Been Implemented (Data Layer)

### 1. SkillProgress Model
**File:** `OtisShared/Sources/OtisShared/Models/SkillProgress.swift`

The core data model replacing the simple `MasteredSkill` with full lifecycle tracking:

```swift
struct SkillProgress {
    var skillId: String
    var phase: SkillLearningPhase      // notStarted → luring → addingCue → proofing → generalizing → maintaining → needsWork
    var proofingLevels: ProofingLevels // Duration, Distance, Distraction (0-5 each)
    var confidenceScore: Double        // Rolling average from recent sessions
    var totalSuccessReps: Int
    var totalFailedReps: Int
    var recentSessions: [SessionOutcome]  // Last 10 sessions for rolling average
    var maintenanceTier: Int           // 1-6+ for spaced repetition intervals
    var nextReviewDate: Date?
    var lastPracticedAt: Date?
    var practicedContexts: [TrainingContext]  // For generalization tracking
}
```

**Key enums:**
- `SkillLearningPhase`: The 7 phases from the briefing
- `ProofingDimension`: duration, distance, distraction
- `StandardTrainingContext`: home, garden, park, etc. (for generalization)
- `MaintenanceIntervals`: 1d → 3d → 1w → 2w → 1m → 2m intervals

### 2. PuppyEvent Training Fields
**File:** `OtisShared/Sources/OtisShared/Models/PuppyEvent.swift`

Added to support session outcome tracking:
```swift
var successReps: Int?
var failedReps: Int?
var trainingContext: String?  // Where training happened
var skillPhase: String?       // Which phase was practiced
```

Plus helper computed properties: `trainingSuccessRate`, `trainingMetThreshold`, and factory method `PuppyEvent.training(...)`.

### 3. Core Data Entity
**File:** `Ollie-app/Ollie.xcdatamodeld/Ollie.xcdatamodel/contents`

Added `CDSkillProgress` entity with all progress fields. Complex types (recentSessions, practicedContexts) stored as JSON binary data.

**File:** `Ollie-app/Models/CoreData/CDSkillProgress+Extensions.swift`

Conversion between `SkillProgress` ↔ `CDSkillProgress`, plus fetch helpers:
- `fetchDueForReview()` - skills needing maintenance check
- `fetchNeedsWork()` - skills in regression
- `fetchActiveLearning()` - skills being learned

### 4. TrainingEngine (Business Logic)
**File:** `Ollie-app/Services/TrainingEngine.swift`

Implements the algorithms from the briefing:

```swift
// Priority queue (from briefing section 5)
enum TrainingPriority {
    case regressionRecovery = 1  // Highest - slipping skills
    case activeLearning = 2      // Currently being taught
    case scheduledMaintenance = 3 // Due for spaced repetition
    case generalization = 4      // New contexts
    case enrichment = 5          // Fun/optional
}

// Session composition (from briefing section 3)
struct TrainingSessionPlan {
    var warmup: PrioritizedSkill?      // ~10% - easy win to start
    var primaryFocus: [PrioritizedSkill] // ~60-70% - new learning or regression
    var maintenance: [PrioritizedSkill]  // ~20-30% - spaced repetition
    var easyFinish: PrioritizedSkill?    // End on success
}

// Key methods:
static func generateSessionPlan(from:targetDurationMinutes:) -> TrainingSessionPlan
static func processSessionResult(progress:successReps:failedReps:context:) -> SessionFeedback
static func processMaintenanceCheck(progress:successReps:failedReps:) -> Bool
```

**Thresholds implemented (from briefing section 2):**
| Success Rate | Action |
|--------------|--------|
| 90-100% | Advance, lighter maintenance |
| 80-89% | Advance, confirm in 48h |
| 50-79% | Stay at current stage |
| <50% | Step back one stage |

### 5. SkillProgressStore (Persistence Service)
**File:** `Ollie-app/Services/SkillProgressStore.swift`

Manages skill progress with Core Data + CloudKit sync:

```swift
// Core operations
func recordTrainingSession(skillId:successReps:failedReps:context:) -> SessionFeedback
func processMaintenanceCheck(skillId:successReps:failedReps:) -> Bool
func generateSessionPlan(targetDurationMinutes:) -> TrainingSessionPlan

// Queries
var skillsNeedingWork: [SkillProgress]
var skillsDueForReview: [SkillProgress]
var skillsInActiveLearning: [SkillProgress]
func prioritizedSkills() -> [PrioritizedSkill]
```

### 6. AI/LLM Integration Data Model
**File:** `OtisShared/Sources/OtisShared/Models/TrainingAISummary.swift`

Structured data for daily AI check-ins:

```swift
struct TrainingAISummary {
    let profileId: UUID              // Anonymized dog ID
    let ageInWeeks: Int
    let stats: TrainingStats
    let skillsByPhase: [String: [SkillSnapshot]]
    let skillsNeedingWork: [SkillSnapshot]
    let skillsDueForReview: [SkillSnapshot]
    let recentSessions: [SessionSummary]      // With loggedById for household member
    let recentRegressions: [RegressionEvent]
    let sessionsByMember: [String: Int]       // Sessions per household member
    let regressionHistory: [String: Int]      // Total regressions per skill
    let paceWarning: PaceWarning?             // too_fast, inconsistent, too_slow, over_training
    let staleSkills: [StaleSkillInfo]
    let suggestedNextSkill: String?
}
```

Also includes `RegressionLogEntry` for persistent regression history tracking.

### 7. Localization
**File:** `Ollie-app/Utils/Strings/Strings+Training.swift`

Added strings for session feedback, priority labels, regression messages, training contexts, etc.

---

## What's NOT Yet Implemented

### UI Layer

1. **Session Logging UI Enhancement** ✅ DONE (March 2026)
   - ~~Current: Simple "log session" with duration/note~~
   - ~~Needed: Rep counter (success/fail taps), context picker, phase indicator~~
   - Added: Success/fail rep counter with + / - buttons
   - Added: Horizontal context picker (home, garden, park, etc.)
   - Added: Success rate indicator showing percentage
   - Added: `onRecordProgress` callback for SkillProgressStore integration

2. **"Today's Training" View**
   - Dynamic session plan display (warm-up → focus → maintenance → finish)
   - Progress through session with visual indicators

3. **Skill Card Enhancements** ✅ DONE (March 2026)
   - ~~Show current phase, confidence score, next review date~~
   - Extended `SkillProgressInfo` with `learningPhase`, `confidenceScore`, `isDueForReview`, `daysUntilReview`
   - Added confidence indicator (mini progress ring + percentage)
   - Added priority badges: "Refresher needed" (regression), "Due for review", "Next Up"
   - Added phase-specific icons and colors
   - Added localized phase labels (Luring, Adding cue, Proofing, Generalizing)
   - Still TODO: 3D progress indicators, context badges (where skill has been practiced)

4. **Regression Alerts**
   - Non-alarming notification when skill regresses
   - "Recall needs some love — we've moved it to your focus list"

5. **Progress Visualization**
   - Not just complete/incomplete but full phase visualization
   - Maintenance schedule calendar view

### Service Integration

1. **Migration from MasteredSkill**
   - `SkillProgressStore.migrateFromMasteredSkills()` exists but needs to be called during app update
   - Need to decide: wipe and restart, or migrate with assumptions?

2. **AI Nudge Integration**
   - Wire `TrainingAISummary` into existing AI broker
   - Create function call schema for training check-ins
   - Design prompt for generating encouragement messages

3. **Regression Log Persistence**
   - `RegressionLogEntry` model exists but needs Core Data entity
   - Need `CDRegressionLog` entity and store

4. **Location Detection**
   - `StandardTrainingContext` exists but no automatic detection
   - Could use GPS + user confirmation ("Training at the park?")

### Algorithm Refinements

1. **Ping-pong pattern for 3Ds**
   - Briefing says: "hold for 10 seconds, then 5, then 15, then 8, then 20"
   - Not yet implemented - currently just tracks level 0-5

2. **Puppy age adjustments**
   - `TrainingEngine.recommendedSessionDuration()` exists
   - Need to integrate with profile age for automatic adjustments

3. **Variable reinforcement scheduling**
   - Briefing mentions rewarding randomly, not every time
   - Could add coaching tips during maintenance phase

---

## Recommended Next Steps

### Phase 1: Core UI (enables user testing) ✅ COMPLETE
1. ✅ Update training log sheet to capture success/failure reps
2. ✅ Add context picker to training log
3. ✅ Show confidence score and phase on skill cards
4. ✅ Display "due for review" badge on skills

**Files modified:**
- `Ollie-app/Views/Training/TrainingLogSheet.swift` - rep counter, context picker
- `Ollie-app/Views/Training/SkillProgressRow.swift` - enhanced with phase, confidence, badges
- `Ollie-app/Utils/Strings/Strings+Training.swift` - added phase label strings

### Phase 2: Session Planning UI ✅ COMPLETE
1. ✅ Create "Today's Training" view using `generateSessionPlan()`
2. ✅ Session timer with puppy-age-aware limits
3. Quick-log gestures (swipe for success/fail) - deferred to Phase 4

**Files created/modified:**
- `Ollie-app/Views/Training/TodaysTrainingView.swift` - NEW: dynamic session plan view
  - Warm-up section with easy mastered skills
  - Primary focus section (regression recovery or active learning)
  - Maintenance section for spaced repetition reviews
  - Easy finish section to end on success
  - Session timer with age-aware duration recommendations
  - Visual progress tracking through the session
- `Ollie-app/Views/Training/TrainTabView.swift` - Added entry point to TodaysTrainingView
- `Ollie-app/Utils/Strings/Strings+Training.swift` - Added session-related strings

### Phase 3: AI Integration ✅ COMPLETE
1. ✅ Add `CDRegressionLog` entity for persistent history
2. ✅ Wire `TrainingAISummary` to AI broker
3. ✅ Create daily training check-in prompt (via trainingGuidance surface)
4. ✅ Add encouragement message generation to TrainingGuidanceResponse

**Files created/modified:**
- `Ollie-app/Ollie.xcdatamodeld/Ollie.xcdatamodel/contents` - Added CDRegressionLog entity
- `Ollie-app/Models/CoreData/CDRegressionLog+Extensions.swift` - NEW: Core Data extensions
- `Ollie-app/Services/RegressionLogStore.swift` - NEW: Regression log persistence store
- `Ollie-app/Services/AI/AISetup.swift` - Wired RegressionLogStore to AI broker
- `Ollie-app/Services/AI/AISurfaces.swift` - Added encouragement fields to TrainingGuidanceResponse
- `Ollie-app/Services/AI/AIInstructions.swift` - Added encouragement principles and output format

**AI Encouragement Features:**
- `encouragementMessage`: Personalized motivational message based on progress
- `encouragementType`: "celebration" | "motivational" | "supportive" | "reminder"
- `recentAchievement`: Specific achievement to celebrate (skill mastered, streak, etc.)

### Phase 4: Polish ✅ COMPLETE
1. ✅ Regression alerts with friendly UX
   - Created `RegressionAlertView.swift` with non-alarming UI components
   - `RegressionAlertBanner`: Shows skills needing refresher with supportive messaging
   - `RegressionRecoveryCard`: Celebrates when skills are back on track
   - `RegressionBadge`: Inline indicator for skill rows
   - `AdolescenceInfoCard`: Normalizes regression during 6-18 months
   - Added FlowLayout helper for skill chip display

2. Location-aware training suggestions - DEFERRED (future enhancement)

3. ✅ Progress visualization improvements
   - Created `ProgressVisualization.swift` with advanced components:
   - `SkillPhaseTimeline`: Visual timeline showing 7 learning phases
   - `Proofing3DIndicator`: Visual bars for Duration/Distance/Distraction (0-5)
   - `ContextBadges`: Icons showing where skill has been practiced
   - `MaintenanceScheduleIndicator`: Shows maintenance tier and next review date
   - `SkillProgressCard`: Combined full progress visualization
   - `InlineProgressSummary`: Compact inline version for skill rows
   - Extended `SkillProgressInfo` with proofingLevels, practicedContexts, maintenanceTier, nextReviewDate

4. ✅ Multi-household-member attribution display
   - Created `MemberAttributionView.swift` with household member components:
   - `MemberAvatar`: Displays member photo or colored initial
   - `TrainingContributionCard`: Shows contributions by member with progress bars
   - `SessionAttributionLabel`: Inline label showing who logged a session
   - `RecentSessionsByMember`: Sessions grouped by household member
   - `MemberStreakBadge`: Shows individual training streaks
   - `TrainingLeaderboard`: Fun weekly ranking display
   - Added strings: teamContributions, sessions, sessionsThisWeek, weeklyLeaderboard

---

## Key Files Reference

| Purpose | File |
|---------|------|
| Core progress model | `OtisShared/Sources/OtisShared/Models/SkillProgress.swift` |
| AI summary model | `OtisShared/Sources/OtisShared/Models/TrainingAISummary.swift` |
| Training event fields | `OtisShared/Sources/OtisShared/Models/PuppyEvent.swift` |
| Business logic | `Ollie-app/Services/TrainingEngine.swift` |
| Persistence service | `Ollie-app/Services/SkillProgressStore.swift` |
| Core Data model | `Ollie-app/Ollie.xcdatamodeld/Ollie.xcdatamodel/contents` |
| CD extensions | `Ollie-app/Models/CoreData/CDSkillProgress+Extensions.swift` |
| Today's Training view | `Ollie-app/Views/Training/TodaysTrainingView.swift` |
| Training Log Sheet | `Ollie-app/Views/Training/TrainingLogSheet.swift` |
| Skill Progress Row | `Ollie-app/Views/Training/SkillProgressRow.swift` |
| Regression Log Store | `Ollie-app/Services/RegressionLogStore.swift` |
| CD Regression Log | `Ollie-app/Models/CoreData/CDRegressionLog+Extensions.swift` |
| AI Setup | `Ollie-app/Services/AI/AISetup.swift` |
| AI Instructions | `Ollie-app/Services/AI/AIInstructions.swift` |
| Regression Alerts | `Ollie-app/Views/Training/RegressionAlertView.swift` |
| Progress Visualization | `Ollie-app/Views/Training/ProgressVisualization.swift` |
| Member Attribution | `Ollie-app/Views/Training/MemberAttributionView.swift` |
| Strings | `Ollie-app/Utils/Strings/Strings+Training.swift` |
| Requirements doc | `training-logic-briefing.md` |

---

## Testing Notes

- Build succeeds on `ai-improvements` branch
- No existing users, so breaking changes to data model are acceptable
- New Core Data entities will be auto-created on first launch
- CloudKit sync should work automatically via existing infrastructure

---

*Delete this file when implementation is complete.*
