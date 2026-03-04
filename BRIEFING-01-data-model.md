# Briefing 01: Data Model Unification

## Current State

Two parallel models represent overlapping developmental realities:

### DevelopmentStage (6 stages)
Used in: `DevelopmentRoadmapView`, `DevelopmentPhaseCard`
```
neonatal      (weeks 0-2)
transitional  (weeks 2-3)
socialization (weeks 3-12)
juvenile      (weeks 12-24)
adolescent    (weeks 24-72)
adult         (72+ weeks)
```

### SocializationPhase (5 phases)
Used in: `SocializationJourneyView`, `SocializationJourneyCard`
```
settlingIn        (first ~1 week home)
firstSteps        (weeks 1-2 home)
buildingConfidence (weeks 2-4 home)
peakWindow        (weeks 4-8 home, roughly)
maintenance       (after peak window)
```

### The Problem

- Different terminology for overlapping time periods
- `SocializationPhase` is based on "weeks home" while `DevelopmentStage` is based on age
- Both calculate similar things independently
- UI components choose one or the other arbitrarily

## Target State

### Keep: DevelopmentStage as the canonical model

The 6-stage model is:
- Based on actual developmental science
- Age-based (objective, not dependent on home date)
- Comprehensive (covers entire lifespan)

### Transform: SocializationPhase becomes a computed view

`SocializationPhase` should not be a separate enum/model. Instead:
- It becomes a **computed property** on `PuppyProfile` or a **UI helper**
- It represents "where are we in the socialization training journey"
- It's a lens into the socialization stage, not a parallel structure

## Implementation Details

### Step 1: Audit current usage

Find all references to:
- `SocializationPhase` enum
- `DevelopmentStage` enum
- Any computed properties that derive phases/stages

Files likely affected:
- `Models/` — enum definitions
- `ViewModels/` — phase/stage calculations
- `Views/Socialization/` — phase-based UI
- `Views/Calendar/` — stage-based UI
- `Views/Health/` — both

### Step 2: Create unified access layer

Create a service or extension that provides:
```swift
// On PuppyProfile or a DevelopmentService
var currentDevelopmentStage: DevelopmentStage  // canonical
var isInSocializationWindow: Bool              // weeks 3-16
var socializationWindowWeeksRemaining: Int?    // nil if closed
var activeSensitivePeriods: [SensitivePeriod]  // fear periods, etc.

// For Train tab's socialization UI (computed, not stored)
var socializationTrainingPhase: SocializationTrainingPhase  // UI concern
```

### Step 3: Rename for clarity

Consider renaming to make the hierarchy clear:
- `DevelopmentStage` → keep as-is (it's the canonical model)
- `SocializationPhase` → `SocializationTrainingPhase` (makes clear it's for training UI)

Or eliminate the phase enum entirely and just use computed states:
```swift
enum SocializationJourneyState {
    case settlingIn       // first week home
    case earlyWindow      // in window, < 50% through
    case peakWindow       // in window, 50-80% through
    case windowClosing    // in window, > 80% through
    case windowClosed     // past week 16
}
```

### Step 4: Single source for window calculations

Create ONE place that calculates:
- Weeks remaining in socialization window
- Window status (open/closing/closed)
- Current position in window (for progress bars)

Currently this is calculated in multiple places. Consolidate to:
```swift
struct SocializationWindowStatus {
    let isOpen: Bool
    let weeksRemaining: Int?
    let progressPercentage: Double  // 0.0 to 1.0
    let urgency: Urgency  // normal, closing, closed
}

// Single source of truth
extension PuppyProfile {
    var socializationWindowStatus: SocializationWindowStatus { ... }
}
```

## Migration Strategy

1. **Add** the new unified access layer alongside existing code
2. **Migrate** views one by one to use the new layer
3. **Remove** the old scattered calculations
4. **Keep** `SocializationPhase` enum temporarily if needed for Train tab UI
5. **Eventually** inline or rename it to clarify it's a UI concern

## Files to Modify

### Models
- `DevelopmentStage.swift` — may need new computed properties
- `SocializationPhase.swift` — demote to UI helper or delete
- `PuppyProfile.swift` — add unified access properties

### New Files
- `Services/DevelopmentService.swift` or `Extensions/PuppyProfile+Development.swift`
  - Consolidates all stage/phase/window calculations

### Views (later, during tab restructuring)
- Update to use unified access layer
- Remove direct phase/stage calculations

## Success Criteria

After this phase:
- ONE way to ask "what development stage is the puppy in?"
- ONE way to ask "how much time left in socialization window?"
- No duplicate calculations of the same values
- `SocializationPhase` is clearly subordinate to `DevelopmentStage` (or eliminated)

## Risks

- Breaking existing UI during migration
- Subtle differences in how phases vs stages were calculated

Mitigation: Add new code alongside old, migrate incrementally, test each view.
