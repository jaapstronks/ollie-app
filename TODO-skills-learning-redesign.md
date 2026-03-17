# Skills Learning UI Redesign

## Overview

This document captures the analysis, design decisions, and implementation plan for redesigning the skills learning experience in Ollie. The goal is to create a clearer, more focused UI that reflects how dog training actually works: theory first, then practice across increasing complexity (phases × locations).

---

## Problem Statement

The current skills learning UI has several UX issues:

1. **Horizontal swipe navigation is disorienting** — Users see a full page of content and can swipe sideways, but it's unclear this is the navigation method
2. **"I've practiced this" is ambiguous** — Does it mean "I read this" or "my dog can do this"?
3. **"Continue" vs "Start Training" vs "Log Session" confusion** — Three similar-sounding actions that do very different things
4. **Location is an afterthought** — Training location is logged separately, not integrated into progression
5. **Phases aren't visualized as a progression matrix** — The additive nature of skills isn't clear (phase 5 builds on 1-4)
6. **Rep counting is friction** — People don't remember precise counts; binary states matter more
7. **Theory and practice are mixed** — No clear separation between learning about a skill and practicing it

---

## Key Design Decisions (From Discussion)

### Training Philosophy
- **Only log successes** — If dog struggles, user should stop or go back to easier phase, not log a failure
- **Soft gating, not hard locks** — Nudge users toward ideal progression but allow flexibility
- **2-3 active skills is healthy** — UI should surface what's "next up" across skills
- **Phone-free training is common** — People read theory, train without phone, then log later

### Data Model
- **Two locations: Inside vs Outside** — Simpler than three; copy explains to vary outdoor locations
- **Three states per cell: Not Started / In Progress / Mastered** — No "struggled" state
- **Phase × Location matrix** — Each phase is practiced inside, then outside
- **Theory is per-human, practice is per-dog** — Theory completion stored locally, skill progress synced via CloudKit

### UI Structure
- **Theory is Phase 0** — All phases explained upfront before any practice
- **Shorter summaries on practice pages** — Full explanation in theory, reminders when practicing
- **List-based, not horizontal swipe** — Phases shown as tappable rows in a matrix
- **One-tap mastery** — User decides when their dog has mastered something

### Refresh/Maintenance
- **Three options when refresh is due:** Practice, "Still Mastered", or "Snooze for 1 week"
- **Snooze = "don't bug me now"** — Will nudge again after at least 1 week

---

## Current Architecture Summary

### Data Models

**SkillProgress** (OtisShared):
```swift
struct SkillProgress {
    var phase: SkillLearningPhase     // notStarted → luring → addingCue → proofing → generalizing → maintaining
    var proofingLevels: ProofingLevels // duration, distance, distraction (0-5)
    var confidenceScore: Double        // 0.0-1.0
    var practicedContexts: [TrainingContext]  // Flat array, NOT per-phase
    var maintenanceTier: Int           // 1-6 for spaced repetition
    var nextReviewDate: Date?
}
```

**TrainingProgressStore** (App):
```swift
class TrainingProgressStore {
    var completedPreparationItems: Set<String>  // Equipment + concepts
    var seenRules: Set<String>                   // Training rules acknowledged
    var completedPhases: [String: Set<String>]  // skillId → Set of completed phase IDs (binary)
}
```

**Key Gap:** Current model tracks phases and contexts separately. No phase × location matrix exists.

### Training Plan JSON

Skills are defined in `training-plan.json` with:
- `phases[]` — Array of phases, each with `howToStepIndices` and `tipIndices`
- Content in `Strings.swift` — Names, subtitles, howTo steps, tips, mistakes

Example for "sit":
```
Phase 1: Lure to Position (steps 0-2, tips 0-1)
Phase 2: Capture & Strengthen (steps 3-4, tip 2)
Phase 3: Add Verbal Cue (steps 5-7, tip 3)
Phase 4: Proof with 3 D's (steps 8-10, tips 4-5)
```

### Existing UI Components

**Highly Reusable:**
- `ConceptSheetView` — Rich educational template (icon, title, explanation, key points, example)
- `NumberedStepsSection`, `BulletedListSection` — Content containers
- `SkillProgressRow` — Flexible list row with swipe actions and context menu
- `PreparationSection` — Equipment/concept gating logic

**Needs Adaptation:**
- `SkillLearningFlowSheet` — Replace TabView with new navigation
- `SkillDetailSheet` — Keep content structure, change container
- `SkillCard` — Adapt for new layout (remove expand/collapse)

### Copy Quality

- **Strengths:** Detailed, friendly, educational, explains the "why"
- **Volume:** 10-12 howTo steps per skill, 4-6 tips, 2-4 mistakes
- **Structure:** Phase names are short (5-10 words), subtitles describe the goal

---

## Proposed Data Model Changes

### New: Location Tier Enum
```swift
public enum LocationTier: String, Codable, CaseIterable {
    case inside       // Home, indoor public spaces
    case outside      // Garden, street, park (copy explains to vary)
}
```

### New: Cell State Enum
```swift
public enum PhaseLocationState: String, Codable {
    case locked       // Prior phase not mastered inside yet
    case notStarted   // Available but not attempted
    case inProgress   // Practiced but not mastered
    case mastered     // Dog reliably performs here
}
```

### New: Phase Location Cell
```swift
public struct PhaseLocationCell: Codable, Identifiable {
    public var id: String { "\(phaseId)_\(location.rawValue)" }
    public var phaseId: String
    public var location: LocationTier
    public var state: PhaseLocationState
    public var lastPracticedAt: Date?
}
```

### Updated: SkillProgress
```swift
public struct SkillProgress {
    // Keep existing fields for backwards compatibility

    // NEW: Phase × Location matrix
    public var phaseLocationMatrix: [PhaseLocationCell]

    // Computed helper
    public var overallState: SkillOverallState {
        if phaseLocationMatrix.allSatisfy({ $0.state == .notStarted || $0.state == .locked }) {
            return .notStarted
        }
        if phaseLocationMatrix.filter({ $0.phaseId == finalPhaseId }).allSatisfy({ $0.state == .mastered }) {
            return .mastered
        }
        return .inProgress
    }
}
```

### New: Per-Human Theory Tracking
```swift
// Stored in UserDefaults (NOT CloudKit synced)
public struct TheoryProgress: Codable {
    public var visitorId: String      // Device identifier or local user ID
    public var skillId: String
    public var pagesRead: Set<Int>    // Which theory pages have been read (0-indexed)
    public var isComplete: Bool       // All pages read
    public var completedAt: Date?
}

// New store (local only)
@Observable
final class TrainingTheoryStore {
    private(set) var theoryProgress: [String: TheoryProgress] = [:]  // skillId → progress

    func markPageRead(_ pageIndex: Int, forSkill skillId: String) { ... }
    func isTheoryComplete(forSkill skillId: String) -> Bool { ... }
}
```

---

## Proposed UI Flow

### Flow 1: Theory (First Time)

When user opens a skill they haven't read theory for:

```
┌─────────────────────────────────────────┐
│  Sit                                    │
│  "The easiest and most useful command"  │
├─────────────────────────────────────────┤
│                                         │
│  Before you begin training, learn about │
│  each phase:                            │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  📖  Phase 1: Lure to Position      ││
│  │      Guide your puppy into a sit    ││
│  │                        [Read →]     ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │  🔒  Phase 2: Capture & Strengthen  ││
│  │      Read Phase 1 first             ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │  🔒  Phase 3: Add Verbal Cue        ││
│  │      Read previous phases first     ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │  🔒  Phase 4: Proof with 3 D's      ││
│  │      Read previous phases first     ││
│  └─────────────────────────────────────┘│
│                                         │
│  ─────────── OR ───────────────────────│
│                                         │
│  [I already know how to teach this →]   │
│                                         │
└─────────────────────────────────────────┘
```

**Theory page (horizontal swipe within a phase):**

```
┌─────────────────────────────────────────┐
│  ← Phase 1: Lure to Position   (1 of 4) │
│  ━━━━○○○○                               │
├─────────────────────────────────────────┤
│                                         │
│  In this phase, you'll guide your puppy │
│  into a sitting position using a treat  │
│  as a lure.                             │
│                                         │
│  WHY THIS WORKS                         │
│  Dogs naturally follow food with their  │
│  nose. When you move the treat up and   │
│  back, physics takes over — their butt  │
│  goes down.                             │
│                                         │
│  HOW TO DO IT                           │
│  1. Hold a treat between your thumb     │
│     and finger, right at nose level     │
│  2. Move your hand slowly up and        │
│     slightly back, over their head      │
│  3. The moment their bottom touches     │
│     the floor: mark (click or "yes!")   │
│  4. Give the treat immediately          │
│                                         │
│  COMMON MISTAKES                        │
│  ✗ Holding the treat too high           │
│    (causes jumping instead of sitting)  │
│  ✗ Moving too fast                      │
│    (puppy can't follow)                 │
│                                         │
│  ← Swipe to continue →                  │
├─────────────────────────────────────────┤
│  [Skip to last page]                    │
└─────────────────────────────────────────┘
```

**Last theory page unlocks practice matrix:**

```
┌─────────────────────────────────────────┐
│  ← Phase 4: Proof with 3 D's   (4 of 4) │
│  ━━━━━━━━━━━━                           │
├─────────────────────────────────────────┤
│                                         │
│  [...theory content...]                 │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  ✓ You've read all phases!              │
│                                         │
│  [Start Practicing →]                   │
│                                         │
└─────────────────────────────────────────┘
```

### Flow 2: Practice Matrix

After theory is complete (or user tapped "I know this"):

```
┌─────────────────────────────────────────┐
│  Sit                     [📖 Re-read]   │
│  2 of 4 phases mastered                 │
├─────────────────────────────────────────┤
│                                         │
│  Tap a cell to practice or log progress │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │              Inside    Outside      ││
│  ├─────────────────────────────────────┤│
│  │ 1. Lure        ✓          ✓         ││
│  │ 2. Capture     ✓          ◐         ││
│  │ 3. Add Cue     ◐          ○         ││
│  │ 4. Proof       ○          🔒        ││
│  └─────────────────────────────────────┘│
│                                         │
│  Legend: ✓ Mastered  ◐ In Progress      │
│          ○ Not Started  🔒 Locked       │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  💡 SUGGESTED NEXT                  ││
│  │                                     ││
│  │  You've mastered Phase 2 inside.    ││
│  │  Try practicing it outside, or      ││
│  │  start Phase 3 inside.              ││
│  │                                     ││
│  │  [Phase 2 Outside]  [Phase 3 Inside]││
│  └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
```

**Visual styling:**
- ✓ Mastered = Green background/icon
- ◐ In Progress = Yellow/amber background/icon
- ○ Not Started = Gray/neutral
- 🔒 Locked = Dimmed, with lock icon

### Flow 3: Practice a Cell

When user taps a cell:

```
┌─────────────────────────────────────────┐
│  ← Back                                 │
│                                         │
│  Phase 2: Capture & Strengthen          │
│  Location: Outside                      │
│  Status: In Progress                    │
├─────────────────────────────────────────┤
│                                         │
│  QUICK REMINDER                         │
│  • Wait for your dog to sit naturally   │
│    (no luring)                          │
│  • Click the moment butt hits ground    │
│  • Treat immediately after the click    │
│                                         │
│  TIP                                    │
│  💡 If your dog doesn't sit within 30   │
│     seconds, end the session — they     │
│     may not be ready or are too         │
│     distracted in this environment.     │
│                                         │
│  BUILDING ON                            │
│  ✓ Phase 1: Dog follows lure to sit     │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  After your training session:           │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  [I practiced this]                 ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │  [My dog has mastered this ✓]       ││
│  └─────────────────────────────────────┘│
│                                         │
│  "Mastered" means your dog performs     │
│  reliably in this environment without   │
│  extra help or luring.                  │
│                                         │
└─────────────────────────────────────────┘
```

**Actions:**
- **"I practiced this"** → Cell state becomes `inProgress`, logs a practice event
- **"My dog has mastered this"** → Cell state becomes `mastered`, logs completion

### Flow 4: Locked Cell (Soft Gate)

When user taps a locked cell:

```
┌─────────────────────────────────────────┐
│  Phase 4: Proof with 3 D's              │
│  Location: Outside                      │
├─────────────────────────────────────────┤
│                                         │
│  ⚠️ Not quite ready yet                 │
│                                         │
│  Before practicing Phase 4 outside,     │
│  we recommend mastering Phase 4 inside  │
│  first.                                 │
│                                         │
│  This helps your dog build a strong     │
│  foundation before adding distractions. │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  [Go to Phase 4 Inside]             ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │  [Practice anyway]                  ││  ← Allows override
│  └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
```

### Flow 5: Refresh/Maintenance

When a skill is due for refresh:

```
┌─────────────────────────────────────────┐
│  🔄 NEEDS ATTENTION                     │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐│
│  │ 🪑 Sit                               ││
│  │    Last practiced 3 weeks ago       ││
│  │                                     ││
│  │  [Practice]                         ││
│  │  [Still knows it ✓]                 ││
│  │  [Remind me later]                  ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

**Actions:**
- **"Practice"** → Opens skill practice matrix, focused on last phase
- **"Still knows it ✓"** → Marks as still mastered, resets refresh timer
- **"Remind me later"** → Snoozes for 1 week, nudges again after

---

## Unlocking/Gating Rules

### Matrix Cell Unlock Rules (Soft)

| Cell | Unlocks When |
|------|--------------|
| Phase 1, Inside | Always unlocked (first cell) |
| Phase 1, Outside | Phase 1 mastered Inside |
| Phase N, Inside | Phase N-1 mastered Inside |
| Phase N, Outside | Phase N mastered Inside |

**Unlock flow visual:**
```
           Inside     Outside
Phase 1      1    →      2
             ↓
Phase 2      3    →      4
             ↓
Phase 3      5    →      6
             ↓
Phase 4      7    →      8
```

### Theory Unlock Rules

- Phase 1 theory: Always available
- Phase N theory: Unlocks when Phase N-1 theory is read
- "I know this already" skips all theory and unlocks full practice matrix

---

## Cross-Skill Dashboard

```
┌─────────────────────────────────────────┐
│  Training                               │
├─────────────────────────────────────────┤
│                                         │
│  🔴 NEEDS ATTENTION                     │
│  ┌─────────────────────────────────────┐│
│  │ 🪑 Sit — refresh due                ││
│  │   [Practice] [Still knows it]       ││
│  │   [Remind me later]                 ││
│  └─────────────────────────────────────┘│
│                                         │
│  🟡 CURRENTLY TRAINING                  │
│  ┌─────────────────────────────────────┐│
│  │ 🐕 Follow — Phase 2, Inside         ││
│  │   ████████░░ 4 of 5 cells           ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │ 🛑 Stay — Phase 1, Outside          ││
│  │   ████░░░░░░ 2 of 5 cells           ││
│  └─────────────────────────────────────┘│
│                                         │
│  💡 UP NEXT                             │
│  ┌─────────────────────────────────────┐│
│  │ 👀 Watch Me                         ││
│  │   Builds focus • Recommended after  ││
│  │   mastering luring                  ││
│  │                    [Start →]        ││
│  └─────────────────────────────────────┘│
│                                         │
│  [See all skills ↓]                     │
│                                         │
└─────────────────────────────────────────┘
```

**Categorization logic:**
- **Needs Attention:** `isDueForReview == true` or `phase == .needsWork`
- **Currently Training:** Any cell is `inProgress`, not all cells mastered
- **Up Next:** First skill where `hasUnmetPrerequisites == false` and `notStarted`
- **All skills:** Everything else, expandable section

---

## Component Mapping

### Reuse Existing Components

| Component | Usage in New Design |
|-----------|---------------------|
| `ConceptSheetView` | Theory pages (adapt for horizontal swipe) |
| `NumberedStepsSection` | "How To" in theory pages |
| `BulletedListSection` | Tips, mistakes |
| `SkillProgressRow` | Cross-skill dashboard rows |
| `PreparationSection` | Keep for equipment/concept gate |

### New Components Needed

| Component | Purpose |
|-----------|---------|
| `TheoryFlowSheet` | Horizontal swipe theory pages |
| `TheoryPageView` | Individual theory page content |
| `PracticeMatrixView` | 2D grid of phase × location |
| `MatrixCellView` | Individual cell (state indicator) |
| `PracticeCellSheet` | Detail view when tapping a cell |
| `RefreshCard` | Refresh nudge with three actions |
| `TrainingDashboard` | Updated training tab layout |

### Remove/Replace

| Current Component | Replacement |
|-------------------|-------------|
| `SkillLearningFlowSheet` (TabView paging) | `TheoryFlowSheet` + `PracticeMatrixView` |
| `SkillPhasePage` | `TheoryPageView` (theory) + `PracticeCellSheet` (practice) |
| `PhaseProgressIndicator` | Progress dots in `TheoryFlowSheet` |
| Rep counter in `TrainingLogSheet` | Remove entirely |

---

## Copy Changes Needed

### New Copy

1. **Matrix intro text:** "Tap a cell to practice or log progress"
2. **Legend:** Explain the four states (✓ ◐ ○ 🔒)
3. **Suggested next:** Dynamic text based on matrix state
4. **Locked cell explanation:** Why we recommend the order
5. **"Practice anyway" label:** For soft gate override
6. **Refresh actions:** "Still knows it ✓", "Remind me later"
7. **Theory header:** "Before you begin training, learn about each phase"
8. **Skip theory:** "I already know how to teach this"
9. **After session:** "I practiced this", "My dog has mastered this"

### Existing Copy to Condense

Theory pages will have two versions:
1. **Full (in theory flow):** Current verbose content with why/how/mistakes
2. **Summary (in practice cell):** 3-4 bullet points as "Quick Reminder"

Example for "Sit, Phase 1":

**Full (theory):**
> In this phase, you'll guide your puppy into a sitting position using a treat as a lure. This works because dogs naturally follow food with their nose — when you move the treat up and back, physics takes over and their butt goes down.
>
> 1. Hold a treat between your thumb and finger, right at nose level
> 2. Move your hand slowly up and slightly back, over their head
> 3. The moment their bottom touches the floor: mark (click or "yes!")
> 4. Give the treat immediately

**Summary (practice cell):**
> • Hold treat at nose level, move up and back
> • Click the moment butt touches floor
> • Treat immediately after click

### Add to General Training Theory

At the start of training (before first skill), add explanation:

> **Only log successes**
> If your dog can't do what you're asking, it means it's not the right time or it's too difficult. Stop the session or go back to an easier step. You should only ever log successful sessions — that's how we know your dog is progressing.
>
> **Location progression**
> Master each phase inside your home first. Then practice the same thing outside — start with quiet environments (garden, quiet street) before busy ones (park, busy street).

---

## Implementation Phases

### Phase 1: Data Model
- [ ] Add `LocationTier` enum
- [ ] Add `PhaseLocationState` enum
- [ ] Add `PhaseLocationCell` struct
- [ ] Update `SkillProgress` with `phaseLocationMatrix`
- [ ] Create `TrainingTheoryStore` (local only)
- [ ] Add `TheoryProgress` struct
- [ ] Update Core Data entities if needed

### Phase 2: Theory Flow
- [ ] Create `TheoryFlowSheet` (horizontal swipe container)
- [ ] Create `TheoryPageView` (individual page)
- [ ] Implement theory unlock logic (sequential)
- [ ] Add "Skip to practice" escape hatch
- [ ] Connect to `TrainingTheoryStore`

### Phase 3: Practice Matrix
- [ ] Create `PracticeMatrixView` (2D grid)
- [ ] Create `MatrixCellView` (state indicator)
- [ ] Implement unlock/lock logic
- [ ] Create `PracticeCellSheet` (drill-down)
- [ ] Add "I practiced this" / "Mastered" actions
- [ ] Add suggested next logic

### Phase 4: Dashboard Integration
- [ ] Update `TrainingView` layout
- [ ] Create "Needs Attention" section
- [ ] Create "Currently Training" section
- [ ] Create "Up Next" section
- [ ] Add refresh actions (practice, still knows it, remind later)

### Phase 5: Polish
- [ ] Write/condense copy for theory summaries
- [ ] Add progress animations
- [ ] Test multi-dog / family sharing
- [ ] Verify CloudKit sync for practice (not theory)

---

## Open Questions

1. **Multi-page theory vs single scroll?** — Current sketch shows swipe pages; alternative is one long scrollable page per phase. Swipe feels more focused but adds friction.

2. **Matrix visual design** — Current sketch shows a grid. Alternative: stacked rows that expand to show location options. Grid is more scannable but may feel cramped on smaller phones.

3. **Floating clicker** — Mentioned as nice-to-have. Should it be in scope for this redesign, or separate?

4. **Phase names in matrix** — Current sketch abbreviates (1. Lure, 2. Capture). Should we show full names or keep compact?

5. **Theory re-read flow** — When user taps "Re-read" on practice matrix, do they see all phases or just the current one?

---

## Success Metrics

After redesign, we expect:
- Users complete theory before practicing (trackable)
- Users progress through phases × locations systematically (matrix completion patterns)
- Fewer abandoned skills (more skills reach mastered state)
- Refresh prompts are acted on (not ignored)
- Multi-human households each complete their own theory

---

## Appendix: Current File Structure

### Views/Training/ (Key Files)

```
Views/Training/
├── SkillLearning/
│   ├── SkillLearningFlowSheet.swift   ← Replace with TheoryFlowSheet + PracticeMatrixView
│   ├── SkillOverviewPage.swift        ← Remove (content moves to matrix header)
│   ├── SkillPhasePage.swift           ← Replace with TheoryPageView + PracticeCellSheet
│   └── PhaseProgressIndicator.swift   ← Reuse for theory flow
├── Components/
│   ├── SkillCard.swift                ← Adapt for new layout
│   ├── SkillProgressRow.swift         ← Reuse for dashboard
│   └── ConceptSheets/                 ← Reuse ConceptSheetView
├── TrainingView.swift                 ← Update dashboard sections
├── TrainingLogSheet.swift             ← Simplify (remove rep counter)
└── SkillDetailSheet.swift             ← May replace with PracticeCellSheet
```

### Services/Stores/ (Key Files)

```
Services/Stores/
├── TrainingProgressStore.swift        ← Update for new states
├── SkillProgressStore.swift           ← Update for matrix model
└── [NEW] TrainingTheoryStore.swift    ← Per-human theory tracking
```

### Models/ (Key Files)

```
Models/
├── Domain/TrainingPlan.swift          ← Add location tier
├── Domain/TrainingModels.swift        ← Add new types
└── Enums/SkillStatus.swift            ← May need update

OtisShared/Sources/OtisShared/Models/
├── SkillProgress.swift                ← Add phaseLocationMatrix
└── SkillProgressTypes.swift           ← Add new types
```
