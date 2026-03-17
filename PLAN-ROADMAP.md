# Feature Roadmap: Post-Phase B

> **Status:** Active Planning
> **Created:** 2026-03-07
> **Supersedes:** Phases C-E of `PLAN-LIFECYCLE-TRANSITION.md`

## Context

Phases A (Foundation) and B (Teenage Retention) are complete. This roadmap covers the remaining work, reorganized into focused briefings with clear dependencies.

## The Big Picture

```
COMPLETED                    REMAINING (this roadmap)
─────────────────────────    ────────────────────────────────────────
Phase A: Lifecycle Foundation
Phase B: Teenage Retention   → Brief 01: Phase Transitions (polish)
                             → Brief 02: Medication UI
                             → Brief 03: Health Foundation
                             → Brief 04: Health Logging
                             → Brief 05: Senior Wellness
                             → Brief 06: Vet Integration
                             → Brief 07: Adult Routines
                             → Brief 08: Year in Review
```

## Briefing Index

| # | Briefing | Focus | Dependencies | Priority |
|---|----------|-------|--------------|----------|
| 01 | Phase Transitions | Celebration sheets, notification profiles | None | Medium |
| 02 | Medication UI | Log meds, reminders, adherence | None | High |
| 03 | Health Foundation | Condition models, breed risks, symptom types | None | High |
| 04 | Health Logging | Symptom logging, health check-ins | Brief 03 | High |
| 05 | Senior Wellness | Mobility, CCD screening, quality of life | Briefs 02, 03, 04 | High |
| 06 | Vet Integration | Vet tips, health calendar, checkup reminders | Briefs 03, 04 | High |
| 07 | Adult Routines | Daily routines, weight goals, grooming | Brief 02 | Medium |
| 08 | Year in Review | Annual recap, memory book | None | Medium |

## Dependency Graph

```
                    ┌─────────────────┐
                    │  Brief 01       │
                    │  Transitions    │ (standalone)
                    └─────────────────┘

┌─────────────────┐     ┌─────────────────┐
│  Brief 02       │     │  Brief 03       │
│  Medication UI  │     │  Health Found.  │
└────────┬────────┘     └────────┬────────┘
         │                       │
         │              ┌────────┴────────┐
         │              │  Brief 04       │
         │              │  Health Logging │
         │              └────────┬────────┘
         │                       │
         ├───────────────┬───────┴───────┐
         │               │               │
┌────────▼────────┐ ┌────▼────────┐ ┌────▼────────┐
│  Brief 05       │ │  Brief 06   │ │  Brief 07   │
│  Senior Wellness│ │  Vet Integ. │ │  Adult Rout.│
└─────────────────┘ └─────────────┘ └─────────────┘

                    ┌─────────────────┐
                    │  Brief 08       │
                    │  Year in Review │ (standalone)
                    └─────────────────┘
```

## Recommended Execution Order

### Track A: Health & Senior (Critical Path)
1. **Brief 02: Medication UI** - Unlocks health tracking
2. **Brief 03: Health Foundation** - Core models for everything health
3. **Brief 04: Health Logging** - Symptom tracking, check-ins
4. **Brief 05: Senior Wellness** - Senior-specific features
5. **Brief 06: Vet Integration** - Contextual vet visit support

### Track B: Parallel Work (Can Start Anytime)
- **Brief 01: Phase Transitions** - Quick polish win
- **Brief 08: Year in Review** - January retention driver

### Track C: After Health Foundation
- **Brief 07: Adult Routines** - Lower priority, depends on medication

## What Each Brief Contains

### Brief 01: Phase Transitions
- `PhaseTransitionSheet` - Celebrate puppy → teenage → adult → senior
- `lastAcknowledgedPhase` tracking in profile
- Lifecycle-aware notification profiles
- Auto-suggest notification changes at transitions

### Brief 02: Medication UI
- `MedicationLogSheet` - Log medication completion
- `MedicationReminderCard` - Due/overdue reminders
- `MedicationAdherenceView` - Compliance stats
- Wire up existing `MedicationSchedule` and `MedicationCompletion` models

### Brief 03: Health Foundation
- `HealthCondition` model - Diagnoses, severity, status
- `HealthConditionType` enum - 15+ chronic conditions
- `BreedHealthRisk` model - Breed-specific predispositions
- `SymptomType` enum - 30+ symptom categories
- Extend `PuppyProfile` with `conditions: [HealthCondition]`

### Brief 04: Health Logging
- `HealthSymptomLog` model - Clone of BehaviorIncident pattern
- `SymptomLogSheet` - Multi-step logging (clone BehaviorLogSheet)
- `HealthCheckIn` model - Clone of SentimentCheckIn pattern
- `HealthCheckInCard` - Likert scale for health symptoms
- Condition-specific check-in categories

### Brief 05: Senior Wellness
- `MobilityAssessment` model - Track mobility over time
- `MobilityCheckInCard` - Weekly mobility rating
- `CognitiveAssessment` - CCD (Canine Cognitive Dysfunction) screening
- `QualityOfLifeView` - HHHHHMM scale or similar
- Senior-specific Today view cards
- AI context for senior care

### Brief 06: Vet Integration
- `VetVisitTip` model - Contextual suggestions
- `VetVisitTipsCard` - Show before vet appointments
- Age-triggered health milestones (vaccines, annual checkups, senior exams)
- Breed-risk-aware suggestions
- Condition-aware follow-up reminders
- Health calendar view

### Brief 07: Adult Routines
- `DailyRoutine` model - Configurable daily schedule
- `RoutineStatusCard` - Show routine completion
- Weight goal tracking with target weight
- Body condition scoring (1-9 scale)
- Grooming schedule reminders
- Enrichment activity suggestions

### Brief 08: Year in Review
- `YearRecapViewModel` - Annual statistics
- `YearRecapView` - Full year summary with photos
- `YearRecapShareView` - Shareable annual card
- Milestone highlights
- Growth journey visualization
- Activity trends year-over-year

## Reusable Patterns

Each brief should leverage these existing patterns:

| Pattern | Source | Reuse For |
|---------|--------|-----------|
| Likert check-in | `SentimentCheckIn` | Health check-ins |
| Incident logging | `BehaviorIncident` | Symptom logging |
| Multi-step sheet | `BehaviorLogSheet` | Symptom/condition logging |
| Support card | `BehaviorSupportCard` | Condition status card |
| Intervention tracking | `BehaviorIntervention` | Treatment plans |
| Age-conditional logic | `SentimentCategory.ageRelevant` | Health condition relevance |
| AI context component | `BehaviorChallengesContext` | Health condition context |
| Trend calculations | `BehaviorSupportView` trends | Symptom trends |

## Files to Create

```
Briefings:
├── BRIEF-01-PHASE-TRANSITIONS.md
├── BRIEF-02-MEDICATION-UI.md
├── BRIEF-03-HEALTH-FOUNDATION.md
├── BRIEF-04-HEALTH-LOGGING.md
├── BRIEF-05-SENIOR-WELLNESS.md
├── BRIEF-06-VET-INTEGRATION.md
├── BRIEF-07-ADULT-ROUTINES.md
└── BRIEF-08-YEAR-IN-REVIEW.md
```

## Success Metrics (from original plan)

| Metric | Current (Est.) | Target |
|--------|----------------|--------|
| 12-month retention | ~40% | >60% |
| 18-month retention | ~25% | >45% |
| Active users at dog age 2+ | ~15% | >30% |
| Senior mode adoption | N/A | >70% |

## Notes

- Briefs 02-06 form the "Health Track" - core value prop for senior retention
- Brief 08 (Year in Review) should ship before January for maximum retention impact
- Multi-dog support remains a future consideration
- Each brief is sized to be completable in 2-5 days
