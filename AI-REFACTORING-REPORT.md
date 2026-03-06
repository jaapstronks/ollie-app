# AI Context System Refactoring Report

**Date:** March 6, 2026
**Updated:** March 6, 2026 (broker updated, ready for testing)
**Branch:** `ai-improvements`
**Status:** Implementation complete - iOS client and broker server both updated, ready for integration testing

---

## Executive Summary

Refactored the AI integration to use a modular, component-based context system. This enables efficient, DRY context assembly for different AI function calls (training guidance, potty analysis, notifications, etc.) while keeping token usage tight and focused.

**Foundation ready for expansion:** The 6 implemented surfaces and modular architecture now support a prioritized feature roadmap including Daily Digest, Contextual Micro-Copy, and Training Regression Narratives - see [Feature Roadmap](#feature-roadmap) section.

---

## Problem Statement

The existing `AINudgeOrchestrator` had several issues:

1. **Tightly coupled context building** - `buildContext()` only built a minimal `AINudgeContextSummary` with basic event counts
2. **Inline payload construction** - Each surface type built its payload inline with lots of duplication
3. **Not modular** - Adding new AI surfaces required duplicating code
4. **No shared components** - Training context (`TrainingAISummary`) existed but wasn't integrated
5. **Prompt/instructions not visible** - Server handled prompts, client had no clarity on what context each surface needs

---

## Solution Architecture

### Directory Structure

```
Ollie-app/Services/AI/
├── AI.swift                  # Main entry point, namespace, convenience methods
├── AIContextComponents.swift # 10 modular context components
├── AIContextBuilder.swift    # Assembles components into payloads per surface
├── AISurfaces.swift          # 6 surface definitions with response types
├── AISurfacePayloads.swift   # Surface-specific payloads + response helpers
├── AIInstructions.swift      # System prompts and output format specs
├── AIOrchestrator.swift      # Request orchestration, caching, budgets
├── AISetup.swift             # App initialization, provider registration
└── README.md                 # Architecture documentation
```

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

### AI Surfaces

Each surface declares which components it needs:

| Surface | Required Components | Optional | Use Case |
|---------|---------------------|----------|----------|
| `insightBundle` | dog_identity, potty_patterns, sleep, feeding, exercise, recent_events | training, socialization, health, household | Daily status, activity ordering |
| `notificationPolicy` | dog_identity, potty_patterns, sleep, exercise, recent_events | household | Notification timing adjustments |
| `trainingGuidance` | dog_identity, training, training_detail, recent_events | household | Training session advice |
| `pottyAnalysis` | dog_identity, potty_patterns, sleep, feeding, recent_events | household | Potty training insights |
| `socializationGuidance` | dog_identity, socialization, recent_events | household | Socialization recommendations |
| `healthInsights` | dog_identity, health, feeding, exercise, sleep, recent_events | household | Wellness observations |

### Response Types

Each surface has a typed response:

- `InsightBundleResponse` - headline, subtitle, activity ordering, logging recommendations
- `NotificationPolicyResponse` - timing deltas, suppression flags
- `TrainingGuidanceResponse` - suggested skill, rationale, session advice, warm-up skills, encouragement
- `PottyAnalysisResponse` - progress assessment, reliability prediction, risk factors
- `SocializationGuidanceResponse` - assessment, priority category, exposure suggestions
- `HealthInsightsResponse` - wellness assessment, insights, recommendations

---

## Files Changed

### New Files Created

| File | Lines | Purpose |
|------|-------|---------|
| `Services/AI/AI.swift` | ~200 | Main entry point with convenience methods |
| `Services/AI/AIContextComponents.swift` | ~550 | 10 modular context components |
| `Services/AI/AIContextBuilder.swift` | ~300 | Component assembly logic |
| `Services/AI/AISurfaces.swift` | ~250 | Surface definitions + response types |
| `Services/AI/AISurfacePayloads.swift` | ~250 | Surface-specific payloads |
| `Services/AI/AIInstructions.swift` | ~380 | System prompts and output formats |
| `Services/AI/AIOrchestrator.swift` | ~380 | Request orchestration |
| `Services/AI/AISetup.swift` | ~130 | App initialization |
| `Services/AI/README.md` | ~200 | Architecture docs |
| `Views/Training/AITrainingGuidanceCard.swift` | ~190 | Example view using new system |

### Modified Files

| File | Change |
|------|--------|
| `Otis_appApp.swift` | Added `skillProgressStore` and `regressionLogStore` to environment, updated `AI.setup()` call |
| `Views/Training/TrainingView.swift` | Changed from `@StateObject` to `@EnvironmentObject` for `skillProgressStore` |
| `Views/Training/TrainTabView.swift` | Added `skillProgressStore` to environment, passed to `SkillsPreviewCard` |
| `ai-broker-server/src/index.ts` | Added support for new surfaces and modern request format (see below) |

### Broker Server Changes

The AI broker server (`ai-broker-server/src/index.ts`) was updated to support the new modular context system:

**New Surfaces Added:**
- `training_guidance` - Training session planning and skill recommendations
- `potty_analysis` - Potty training progress analysis
- `socialization_guidance` - Socialization planning and recommendations
- `health_insights` - Wellness observations and recommendations

**Request Format (Modern Surfaces):**
```json
{
  "surface": "training_guidance",
  "profileId": "...",
  "locale": "en",
  "policyVersion": "v2",
  "promptVersion": "training_guidance_v1",
  "providerPolicy": { "preferredOrder": ["anthropic"], "allowFailover": true },
  "shadowMode": false,
  "systemInstruction": "You are an AI assistant...",
  "outputFormat": "Respond with JSON...",
  "context": {
    "dog_identity": { ... },
    "training": { ... },
    "training_detail": { ... }
  },
  "surfacePayload": { ... }
}
```

**Response Format (Modern Surfaces):**
```json
{
  "providerUsed": "anthropic",
  "modelUsed": "claude-3-5-haiku-latest",
  "reasoningTags": ["training_guidance", "schema_validated", "modern_format"],
  "response": { "confidence": 0.85, "suggestedSkill": "sit", ... },
  "rawResponse": "...",
  "error": null
}
```

**Backwards Compatibility:**
- Legacy surfaces (`insight_bundle`, `notification_policy`) continue to work unchanged
- Old request format with hardcoded prompts still supported
- Response format for legacy surfaces uses existing `insightBundleDecision`/`notificationPolicyDecision` keys

---

## Usage Examples

### Basic Usage

```swift
// Check availability
guard AI.isAvailable(for: profile) else {
    return // Use fallback behavior
}

// Request training guidance
let result = await AI.requestTrainingGuidance(
    profile: profile,
    events: recentEvents
)

switch result {
case .success(let guidance):
    print("Focus on: \(guidance.suggestedSkill ?? "maintenance")")
case .shadow(let guidance):
    // Log for validation, don't apply
case .fallback(let reason):
    print("Fallback: \(reason.description)")
}
```

### Cached Results for UI

```swift
// Get cached result without triggering network request
if let cached = AI.cachedTrainingGuidance(profileId: profile.id) {
    // Use cached guidance for immediate UI display
}
```

### App Initialization

```swift
// In OtisApp.swift .task block:
AI.setup(
    skillProgressStore: skillProgressStore,
    regressionLogStore: regressionLogStore,  // Optional
    socializationStore: socializationStore
)
```

---

## Integration with Legacy System

The new system is designed to work alongside the existing `AINudgeOrchestrator`:

```swift
// Check which system to use
if AI.useNewSystem(for: .trainingGuidance) {
    // New surfaces use new system
    let result = await AI.requestTrainingGuidance(...)
} else {
    // Legacy surfaces continue using AINudgeOrchestrator
    let status = orchestrator.dailyStatusCopy(...)
}
```

Currently:
- **New system:** `trainingGuidance`, `pottyAnalysis`, `socializationGuidance`, `healthInsights`
- **Legacy system:** `insightBundle`, `notificationPolicy` (until broker updated)

---

## Data Flow

```
┌─────────────┐     ┌──────────────────┐     ┌──────────────┐
│   View      │────▶│  AI.request...() │────▶│ AIOrchestrator│
└─────────────┘     └──────────────────┘     └──────┬───────┘
                                                    │
                    ┌──────────────────┐            │
                    │ AIContextBuilder │◀───────────┘
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
                    │ AIBrokerRequest  │  (includes systemInstruction + outputFormat)
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
                    │ Surface Response │ (typed: TrainingGuidanceResponse, etc.)
                    └──────────────────┘
```

---

## Current State

### What Works
- All context components implemented and type-safe
- Surface definitions with required/optional components
- Context builder assembles correct components per surface
- Orchestrator handles caching, budgets, rollout
- App wired up with AI.setup() call
- SkillProgressStore shared via environment
- RegressionLogStore created and wired up to AI.setup()
- CDRegressionLog Core Data entity defined with all required fields
- RegressionLogStore persists regression events with Core Data

### What Needs Work

1. **Integration Testing**
   - Test all 4 new surfaces end-to-end
   - Verify context is being assembled correctly
   - Check response parsing works with real LLM output

2. **Response Parsing Polish**
   - `AIOrchestrator.convertFromLegacyResponse()` may need refinement
   - Monitor for edge cases in LLM output normalization

3. **Unit Tests**
   - No unit tests for context components
   - No integration tests for full flow

---

## Next Steps

### Immediate

1. **Integration Testing**
   - Use debug UI to test all new surfaces (`trainingGuidance`, `pottyAnalysis`, `socializationGuidance`, `healthInsights`)
   - Verify context is being assembled correctly
   - Check response parsing and application works

2. **Deploy Broker Update**
   - Build and deploy updated broker server with new surface support
   - Monitor logs for normalization issues and edge cases

### Short-Term

3. **Migrate Legacy Surfaces**
   - Once tested, set `useNewSystem()` to return true for `insightBundle` and `notificationPolicy`
   - Remove legacy code from `AINudgeOrchestrator`

4. **Add Unit Tests**
   - Test each context component builds correctly
   - Test builder includes correct components per surface
   - Test response application helpers

### Medium-Term

5. **Add More Surfaces** (see Feature Roadmap below for prioritized list)

6. **Optimize Token Usage**
   - Track actual token usage per surface
   - Tune component content to minimize tokens while preserving context quality

---

## Feature Roadmap

The infrastructure is ready for high-impact AI features. Below are prioritized additions that leverage the modular surface architecture.

### Priority 1: High Impact, Low Effort

#### 1. Daily Digest Generation
**New surface: `dailyDigest`**

A morning/evening summary that synthesizes the day's data into a 2-3 sentence narrative. Not generic "you logged 5 events" but:

> "Ollie had a great potty day - 100% outside, with his longest dry stretch yet (4.5 hours). Training is clicking: his sit held through the doorbell distraction. Consider an evening refresher on recall - he missed his check-in yesterday."

The LLM turns data into a story. Appears as a card at the top of the timeline.

**Components needed:** dog_identity, potty_patterns, training, sleep, feeding, exercise, recent_events
**Response tokens:** ~100-150

#### 2. Contextual Micro-Copy
**New surface: `contextualMicrocopy`**

Replace static UI labels with AI-generated contextual text:
- Instead of "Last potty: 2h 15m ago" → "Getting close - typical gap before next is 2h 45m"
- Instead of "Training: Sit - maintaining" → "Sit is solid, but haven't tested with distractions in a week"
- "Log potty" button subtitle → "Good time to try - just woke up"

These are tiny nudges that surface the *why* behind timing.

**Implementation:**
- Returns short text snippets keyed by UI element ID
- Cache aggressively (context doesn't change minute-to-minute)
- Fall back to static strings when AI unavailable
- **Token constraint:** ~50-100 per element to minimize latency/cost

**Components needed:** dog_identity, potty_patterns, training, sleep, recent_events
**Response format:** `{ "element_id": "copy_text", ... }`

### Priority 2: Educational Value

#### 3. Training Regression Narratives
**Enhancement to: `trainingGuidance`**

When a skill regresses (enters `needsWork` phase), generate an encouraging explanation:

> "Recall dropped below 80% in the park - this is normal adolescent 'selective hearing.' The park is high-distraction. Let's rebuild from easier settings first."

Turns what could feel like failure into education. Aligns with design principle: "normalize regression."

**Add to TrainingGuidanceResponse:**
```swift
var regressionExplanation: String?  // Only populated when skill regressed
var regressionIsNormal: Bool?       // True for age-appropriate setbacks
```

#### 4. Pattern Anomaly Surfacing
**Enhancement to: `healthInsights` or new surface: `patternAnomalies`**

LLM-powered detection of unusual patterns that deterministic rules miss:
- "Three indoor accidents this week after 2 weeks clean - all between 2-4 PM. Check if afternoon naps are getting interrupted?"
- "Sleep duration dropped from 7h to 5h average over 10 days. Worth monitoring."

Subtle health/wellness flags that connect dots across domains.

**Components needed:** dog_identity, potty_patterns, sleep, feeding, exercise, health, recent_events (7-day window)

### Priority 3: Developmental Urgency

#### 5. Socialization Window Alerts
**Enhancement to: `socializationGuidance`**

For puppies in the critical 8-16 week window, generate context-aware prompts:

> "Only 3 weeks left in the critical socialization window. Ollie has met 12 new people but hasn't heard loud construction sounds yet. This weekend?"

The LLM understands developmental urgency and exposure gaps.

**Add to SocializationGuidanceResponse:**
```swift
var windowUrgency: WindowUrgency?  // .critical, .closing, .closed, nil
var daysRemaining: Int?
var priorityExposures: [String]    // What's missing
```

### Priority 4: Shareable Output

#### 6. Weekly Journal Auto-Generation
**New surface: `weeklyJournal`**

End-of-week summary suitable for sharing with a trainer, vet, or partner:

> "Week of March 1-7: 42 events logged. Potty training trending up (87% success, up from 72%). Started luring phase for 'down.' Three socialization exposures: neighborhood kids, coffee shop, and a skateboard. Sleep averaging 8h with one 3am wakeup on Thursday."

Saves the user from having to explain their week.

**Components needed:** All components with 7-day event window
**Response tokens:** ~200-300
**UI:** Share button, export to PDF/text

#### 7. Smart Notification Copy
**Enhancement to: `notificationPolicy`**

Instead of "Time for a potty break" → "It's been 2.5 hours since Ollie's nap ended - good time to head outside"

Dynamic notification text that references actual context.

**Add to NotificationPolicyResponse:**
```swift
var notificationCopy: [String: String]  // keyed by notification type
```

---

## Implementation Priorities

Based on impact vs. effort:

| Priority | Feature | Why First |
|----------|---------|-----------|
| **Start here** | Daily Digest (#1) | Visible, demonstrates LLM value, no new UI paradigms |
| **Start here** | Contextual Micro-Copy (#2) | Subtle but powerful, A/B testable |
| **Then** | Regression Narratives (#3) | Aligns with "normalize regression" design principle |
| **Later** | Weekly Journal (#6) | "Wow" feature for share/export, lower daily utility |

All features fit the existing `AISurface` pattern - add surface definition, components, response type, and instructions.

---

## Key Design Decisions

### Why Modular Components?

Each AI call has different context needs:
- Training guidance needs detailed skill progress but doesn't need feeding patterns
- Potty analysis needs potty patterns but doesn't need training details
- This modularity keeps context windows efficient and focused

### Why Typed Responses?

Strong typing catches errors at compile time and enables IDE autocomplete:
```swift
// This works:
guidance.suggestedSkill
guidance.warmupSkills

// This fails to compile:
guidance.nonExistentField
```

### Why Shadow Mode?

Shadow mode allows testing AI decisions without applying them:
- Useful for A/B testing new models/prompts
- Logs decisions for validation without affecting user experience
- Controlled via `AINudgeRollout.isShadowMode`

### Why Environment Object for SkillProgressStore?

Training views were creating their own `@StateObject` instances, leading to:
- Multiple instances with different data
- AI couldn't access the same data as views
- Now shared via environment for consistency

### Why Narrative Over Data?

The LLM's value is turning structured data into human stories:
- **Bad:** "5 potty events, 80% outdoor rate, 2h avg gap"
- **Good:** "Ollie had a great potty day - 100% outside, with his longest dry stretch yet"

Users don't want dashboards; they want a coach who understands their puppy. Design AI outputs as narratives that explain the *why*, not just the *what*.

### Why Micro-Copy Over Cards?

Contextual micro-copy (subtle label changes) is often more valuable than dedicated AI cards:
- Lower cognitive load - information appears where user already looks
- Graceful degradation - falls back to static copy when AI unavailable
- A/B testable - can measure engagement without UI changes
- Token-efficient - 50-100 tokens vs. 300+ for full responses

---

## Files Reference

For detailed implementation, see:

- **Context components:** `Services/AI/AIContextComponents.swift`
- **Surface definitions:** `Services/AI/AISurfaces.swift`
- **System prompts:** `Services/AI/AIInstructions.swift`
- **Usage patterns:** `Services/AI/AI.swift`
- **Architecture docs:** `Services/AI/README.md`
- **Example view:** `Views/Training/AITrainingGuidanceCard.swift`

---

## Related Files (Existing)

- `Services/AINudgeOrchestrator.swift` - Legacy orchestrator (still used for insightBundle, notificationPolicy)
- `Services/AINudgesModels.swift` - Legacy models (AINudgeBrokerRequest, etc.)
- `Services/AIModelBrokerClient.swift` - HTTP client for broker communication
- `OtisShared/Models/TrainingAISummary.swift` - Training data model for AI consumption
- `OtisShared/Models/SkillProgress.swift` - Skill progress tracking model
