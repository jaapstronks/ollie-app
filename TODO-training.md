# TODO: Training Skill Tracker

## Overview
Port the web app's full training view to iOS. This is a structured 6-week training program with 14 skills organized into categories, dependency trees, progress tracking, and per-week focus areas.

## Priority: High
Training is a daily activity — having the plan and progress in the app means Jaap doesn't have to switch to the web app during training sessions.

## Where It Lives (App Navigation)
**Pushed from Inzichten tab** via a navigation link card ("🎓 Training →"). This is a detail view, not a tab. See `TODO-app-navigation.md` for the overall structure.

## Features

### 1. Training Plan Data
The web app loads `training-plan.json` with the full skill tree. The iOS app should bundle this as a static JSON resource or Swift data.

**Structure:**
- **14 skills** across 5 categories
- **6-week plan** with weekly focus skills
- **Skill dependencies** (e.g., "zit" requires "luring", "kom" requires "naam" + "kijk")
- **Per-skill:** id, name, emoji, description, howTo steps, doneWhen criteria, tips, category, week, priority

**Categories:**
| Category | Emoji | Skills |
|----------|-------|--------|
| Fundamenten | 🏗️ | Clicker, Naam, Luring, Hantering, Halsband |
| Basiscommando's | 🎓 | Zit, Kijk, Touch, Lijnlopen, Af |
| Verzorging | ✋ | Hantering |
| Veiligheid | 🛡️ | Halsband, Kom |
| Impulscontrole | ⏸️ | Wacht, Plek, Blijf |

**Full skill data:** See `data/training-plan.json` in the Ollie web repo. Include all 14 skills with their complete howTo, doneWhen, tips, and requires arrays.

### 2. Skill Status Engine
Calculate skill status from logged training events:

```swift
enum SkillStatus {
    case notStarted    // No sessions logged → "○ Niet gestart"
    case started       // < 4 sessions → "◐ Begonnen"
    case practicing    // 4+ sessions → "◕ Oefenen"
    case mastered      // Manually marked complete → "● Betrouwbaar"
}
```

**Dependency checking:** A skill is locked (🔒) if any of its `requires` skills aren't mastered yet. Show which skills need to be completed first.

### 3. Week Hero / Focus Section
Top of the training view shows:
- Current week number (calculated from `START_DATE = 2026-02-14`)
- Week title (e.g., "Week 2: Eerste commando's")
- Focus skills for this week as chips/tags
- Progress bar: X/Y focus skills started

**Week plan:**
```
Week 1: Fundamenten → [clicker, naam, luring, hantering, halsband]
Week 2: Eerste commando's → [zit, kijk, touch, lijnlopen]
Week 3: Beweging & Recall → [kom, af, lijnlopen]
Week 4: Impulscontrole → [wacht, plek, blijf]
Week 5: Verfijning → [zit, af, blijf, lijnlopen]
Week 6: Samenbrengen → [kom, blijf, plek]
```

### 4. Skill Cards
Each skill is an expandable card showing:

**Collapsed:**
- Emoji + name + status badge
- Session count ("5× (2 deze week)")
- Locked indicator if dependencies not met

**Expanded:**
- "Hoe te oefenen" — step-by-step instructions
- "Klaar wanneer" — mastery criteria
- "Tips" — training tips
- Session history (last 3 sessions with date + result)
- Button to mark as mastered

### 5. Category Grouping
Below the focus section, all skills grouped by category with:
- Category header (emoji + name + mastered count: "3/5")
- Skill cards within each category
- Expandable/collapsible sections

### 6. Quick Training Log
When starting a training session from this view:
- Tap a skill → opens a quick log sheet
- Pre-fills exercise field with skill id
- Fields: duration (minutes), result (free text), notes
- Creates a `training` event with `exercise` field matching skill id

## Files to Create/Modify
- `Models/TrainingPlan.swift` — TrainingPlan, Skill, Category, WeekPlan models
- `Models/SkillStatus.swift` — status enum + calculation logic
- `Services/TrainingPlanStore.swift` — loads bundled plan, calculates statuses
- `Views/TrainingView.swift` — main training view (pushed from InsightsView)
- `Views/WeekHeroCard.swift` — current week focus section
- `Views/SkillCard.swift` — expandable skill card
- `Views/TrainingLogSheet.swift` — quick session logger
- `Resources/training-plan.json` — bundled plan data

## Integration with Existing Code
- Training events already exist in the app (type `training` with `exercise` field)
- `ExerciseEditView.swift` already exists — may need to link to skill cards
- The existing `ExerciseConfig` model might need alignment with the plan data
- `EventStore` already handles training events — SkillStatus just queries these

## Design Notes
- Use SF Symbols instead of emojis where possible (or keep emojis for personality)
- Skill cards should use the glass card style
- Locked skills: dimmed/greyed out with lock icon
- Mastered skills: subtle green accent or checkmark
- The web app's expand/collapse pattern works well on mobile — keep it
- Consider haptic feedback when marking a skill as mastered 🎉
- Nav bar title: "Training" with back button to Inzichten
