# AI Services Architecture

This directory contains the refactored, modular AI context system for Ollie.

## Architecture Overview

```
AI/
├── AI.swift                  # Main entry point and namespace
├── AIContextComponents.swift # Modular context components
├── AIContextBuilder.swift    # Assembles components into payloads
├── AISurfaces.swift          # Surface definitions and response types
├── AISurfacePayloads.swift   # Surface-specific request payloads
├── AIInstructions.swift      # System prompts and output formats
├── AIOrchestrator.swift      # Request orchestration, caching, budgets
└── README.md                 # This file
```

## Key Concepts

### Context Components

Each component encapsulates a specific domain of puppy data:

| Component | Key | ~Tokens | Description |
|-----------|-----|---------|-------------|
| `DogIdentityContext` | dog_identity | 50 | Pseudonymized name, age, size, life stage |
| `HouseholdContext` | household | 30 | Member count, pseudonymized roles |
| `PottyPatternsContext` | potty_patterns | 120 | Gaps, streaks, success rate, predictions |
| `SleepContext` | sleep | 60 | Sleep state, nap tracking |
| `FeedingContext` | feeding | 50 | Meal schedule, logging |
| `ExerciseContext` | exercise | 60 | Walks, limits, yard visits |
| `TrainingProgressContext` | training | 200 | Skills summary, pace warnings |
| `TrainingDetailContext` | training_detail | 400 | Full skill details, sessions |
| `SocializationContext` | socialization | 100 | Window status, exposures |
| `RecentEventsSummary` | recent_events | 80 | Event counts, logging patterns |
| `HealthContext` | health | 70 | Weight, medications |

### Surfaces

Each surface (type of AI call) declares which components it needs:

```swift
enum AISurface {
    case insightBundle      // Daily status, activity ordering
    case notificationPolicy // Notification timing
    case trainingGuidance   // Training session advice
    case pottyAnalysis      // Potty training insights
    case socializationGuidance // Socialization recommendations
    case healthInsights     // Wellness observations

    var requiredComponents: Set<AIContextComponentKey> { ... }
    var optionalComponents: Set<AIContextComponentKey> { ... }
}
```

### Usage

```swift
// Simple usage via AI namespace
let result = await AI.requestTrainingGuidance(
    profile: profile,
    events: recentEvents
)

switch result {
case .success(let guidance):
    print(guidance.suggestedSkill)
case .shadow(let guidance):
    // Log for validation, don't apply
case .fallback(let reason):
    // Use deterministic fallback
}
```

## Migration from AINudgeOrchestrator

The new system is designed to work alongside the existing `AINudgeOrchestrator`.
You can migrate gradually:

### Phase 1: Add new surfaces (parallel)

New AI features (training guidance, potty analysis, etc.) use the new system:

```swift
// New features use new system
let trainingResult = await AI.requestTrainingGuidance(...)

// Existing features continue using AINudgeOrchestrator
let dailyStatus = orchestrator.dailyStatusCopy(...)
```

### Phase 2: Migrate insight bundle

Replace inline context building in `AINudgeOrchestrator` with component-based approach:

```swift
// Before (in AINudgeOrchestrator)
func buildContext(...) -> AINudgeContextSummary {
    .init(
        ageWeeks: profile.ageInWeeks,
        daysHome: profile.daysHome,
        recentEventCount: recentEvents.count,
        // ...
    )
}

// After (delegates to AIContextBuilder)
let context = contextBuilder.buildContext(
    for: .insightBundle,
    profile: profile,
    recentEvents: events,
    ...
)
```

### Phase 3: Deprecate AINudgeOrchestrator

Once all surfaces are migrated, mark `AINudgeOrchestrator` as deprecated
and route all calls through `AI.orchestrator`.

## Adding a New Surface

1. **Add case to `AISurface`** in `AISurfaces.swift`:
   ```swift
   case behaviorAnalysis = "behavior_analysis"
   ```

2. **Define components** in the `requiredComponents` switch:
   ```swift
   case .behaviorAnalysis:
       return [.dogIdentity, .recentEvents, .health]
   ```

3. **Add response type**:
   ```swift
   struct BehaviorAnalysisResponse: AISurfaceResponse {
       let confidence: Double
       let assessment: String
       // ...
   }
   ```

4. **Add instructions** in `AIInstructions.swift`:
   ```swift
   case .behaviorAnalysis:
       return behaviorAnalysisSystemInstruction
   // ... and output format
   ```

5. **Add convenience method** in `AI.swift`:
   ```swift
   static func requestBehaviorAnalysis(...) async -> AIResult<BehaviorAnalysisResponse>
   ```

## Adding a New Context Component

1. **Create struct** in `AIContextComponents.swift`:
   ```swift
   struct VetVisitsContext: AIContextComponent {
       static let componentKey = "vet_visits"
       static let estimatedTokens = 40
       // ...
   }
   ```

2. **Add key** to `AIContextComponentKey`:
   ```swift
   case vetVisits = "vet_visits"
   ```

3. **Add build case** in `AIContextBuilder.buildComponent()`:
   ```swift
   case .vetVisits:
       return AnyCodable(VetVisitsContext(...))
   ```

4. **Register provider** if needed:
   ```swift
   AI.orchestrator.registerVetVisitsProvider { ... }
   ```

## Data Flow

```
┌─────────────┐     ┌──────────────────┐     ┌──────────────┐
│   View      │────▶│  AI.request...() │────▶│ AIOrchestrator│
└─────────────┘     └──────────────────┘     └──────┬───────┘
                                                    │
                    ┌──────────────────┐           │
                    │ AIContextBuilder │◀──────────┘
                    └──────────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ DogIdentity     │ │ PottyPatterns   │ │ Training        │
│ Context         │ │ Context         │ │ Context         │
└─────────────────┘ └─────────────────┘ └─────────────────┘
                             │
                    ┌────────▼─────────┐
                    │ AIBrokerRequest  │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ AI Broker Server │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ AIBrokerResponse │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ Surface Response │
                    └──────────────────┘
```

## Token Budget Estimation

Each surface estimates its token cost:

```swift
surface.estimatedRequiredTokens  // Sum of required component tokens
```

This helps with cost monitoring and allows the broker to select
appropriate models based on context size.

## Caching Strategy

- Responses cached by surface + profile + time window
- Each surface defines `cacheDurationMinutes`
- Cache key: `{profileId}-{surface}-{windowStamp}`

## Budget Limits

- Per-surface daily limits in `AISurface.maxCallsPerDay`
- Global daily limit in `AINudgeRollout.maxTotalCallsPerDay`
- Budget tracked per profile per day in UserDefaults

## Privacy

- Dog names pseudonymized (first + last letter)
- Household members identified by index (M1, M2, etc.)
- Profile IDs are UUIDs (not tied to personal identity)
- No location data, no photos, no raw notes sent to AI
