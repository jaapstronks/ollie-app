# Brief 05: Senior Wellness

> **Status:** Ready for Implementation
> **Priority:** High
> **Dependencies:** Brief 02 (Medication UI), Brief 03 (Health Foundation), Brief 04 (Health Logging)
> **Estimated Effort:** Medium-High

## Objective

Build senior-specific wellness features including mobility tracking, cognitive dysfunction screening, and quality of life assessment tools.

## Features

### 1. Senior Wellness Dashboard

Central hub for senior dog health:

```
┌─────────────────────────────────────┐
│  Luna's Wellness                🐕  │
├─────────────────────────────────────┤
│                                     │
│  DAILY CHECK-INS                    │
│  ┌─────────────────────────────┐    │
│  │ Mobility    [●●●●○]  Good   │    │
│  │ Energy      [●●●○○]  OK     │    │
│  │ Appetite    [●●●●●]  Great  │    │
│  │ Comfort     [●●●●○]  Good   │    │
│  └─────────────────────────────┘    │
│                                     │
│  TODAY'S MEDICATIONS                │
│  ✓ Apoquel (8 AM)                   │
│  ○ Joint Supplement (6 PM)          │
│                                     │
│  RECENT                             │
│  • Mobility improved this week ↑    │
│  • 2 stiff mornings logged          │
│                                     │
│  ────────────────────────────────   │
│  [ Full Health History ]            │
│  [ Quality of Life Assessment ]     │
│                                     │
└─────────────────────────────────────┘
```

### 2. Mobility Assessment

Weekly mobility scoring with trend tracking:

```
┌─────────────────────────────────────┐
│  Mobility Assessment                │
├─────────────────────────────────────┤
│                                     │
│  Rate Luna's mobility today:        │
│                                     │
│  [1] [2] [3] [4] [5]                │
│                                     │
│  1 - Cannot walk without help       │
│  2 - Struggles significantly        │
│  3 - Moderate difficulty            │
│  4 - Mild stiffness/slowness        │
│  5 - Moving well for age            │
│                                     │
│  ────────────────────────────────   │
│                                     │
│  Observations (check all that apply)│
│  □ Stiff after rest                 │
│  □ Difficulty rising                │
│  □ Reluctant to climb stairs        │
│  □ Bunny hopping                    │
│  □ Limping                          │
│  □ Slower on walks                  │
│  □ Trouble with slippery floors     │
│                                     │
│         [ Save Assessment ]         │
└─────────────────────────────────────┘
```

### 3. Cognitive Dysfunction Screening (CCD)

Monthly cognitive assessment using DISHAA framework:

```
┌─────────────────────────────────────┐
│  Cognitive Check-In                 │
├─────────────────────────────────────┤
│                                     │
│  In the past month, has Luna...     │
│                                     │
│  DISORIENTATION                     │
│  □ Gotten lost in familiar places   │
│  □ Stared at walls or into space    │
│  □ Gone to wrong side of door       │
│                                     │
│  INTERACTIONS                       │
│  □ Seemed less interested in you    │
│  □ Not greeted you as usual         │
│  □ Avoided petting/interaction      │
│                                     │
│  SLEEP                              │
│  □ Paced at night                   │
│  □ Slept more during day            │
│  □ Woken you up at night            │
│                                     │
│  HOUSE SOILING                      │
│  □ Had accidents (was housetrained) │
│  □ Forgotten to signal to go out    │
│                                     │
│  ACTIVITY                           │
│  □ Less interested in play          │
│  □ Aimless wandering                │
│  □ Repetitive behaviors             │
│                                     │
│  ANXIETY                            │
│  □ Seemed more anxious              │
│  □ New fears or phobias             │
│  □ Increased vocalization           │
│                                     │
│  ────────────────────────────────   │
│  Score: 4/18 - Mild signs           │
│  Consider discussing with your vet  │
│                                     │
│         [ Save & Get Guidance ]     │
└─────────────────────────────────────┘
```

### 4. Quality of Life Assessment

Comprehensive HHHHHMM scale or similar:

```
┌─────────────────────────────────────┐
│  Quality of Life Assessment         │
├─────────────────────────────────────┤
│                                     │
│  Rate each area 1-10:               │
│                                     │
│  HURT (Pain)                        │
│  Is pain well managed?              │
│  [1][2][3][4][5][6][7][8][9][10]    │
│                                     │
│  HUNGER                             │
│  Is Luna eating enough?             │
│  [1][2][3][4][5][6][7][8][9][10]    │
│                                     │
│  HYDRATION                          │
│  Is Luna drinking enough?           │
│  [1][2][3][4][5][6][7][8][9][10]    │
│                                     │
│  HYGIENE                            │
│  Can Luna be kept clean/groomed?    │
│  [1][2][3][4][5][6][7][8][9][10]    │
│                                     │
│  HAPPINESS                          │
│  Does Luna show joy?                │
│  [1][2][3][4][5][6][7][8][9][10]    │
│                                     │
│  MOBILITY                           │
│  Can Luna get around?               │
│  [1][2][3][4][5][6][7][8][9][10]    │
│                                     │
│  MORE GOOD DAYS THAN BAD?           │
│  Overall quality of life            │
│  [1][2][3][4][5][6][7][8][9][10]    │
│                                     │
│  ────────────────────────────────   │
│  Total: 52/70                       │
│  Luna is doing well overall.        │
│                                     │
│  [ Save ] [ Share with Vet ]        │
└─────────────────────────────────────┘
```

### 5. Resting Respiratory Rate (RRR) Tracker

Critical for heart condition monitoring:

```
┌─────────────────────────────────────┐
│  Resting Respiratory Rate           │
├─────────────────────────────────────┤
│                                     │
│  Count breaths for 30 seconds       │
│  while Luna is resting/sleeping     │
│                                     │
│  [ Start Timer ]                    │
│                                     │
│  Breaths counted: [____]            │
│                                     │
│  ────────────────────────────────   │
│                                     │
│  Recent readings:                   │
│  Today:     --                      │
│  Yesterday: 14 bpm ✓ Normal         │
│  Feb 26:    16 bpm ✓ Normal         │
│  Feb 25:    22 bpm ⚠️ Elevated      │
│                                     │
│  ⚠️ Alert: >30 bpm requires         │
│     immediate vet attention         │
│                                     │
└─────────────────────────────────────┘
```

### 6. Senior-Adapted Today View

For senior dogs, prioritize wellness:

```
┌─────────────────────────────────────┐
│  Good morning! How is Luna today?   │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 💊 Medications Due          │    │
│  │ Apoquel · Joint supplement  │    │
│  │ [ Log All ]                 │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ How is Luna's mobility?     │    │
│  │ [1] [2] [3] [4] [5]         │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 📊 This Week                │    │
│  │ Mobility: Stable (avg 3.8)  │    │
│  │ 3 walks · 45 min total      │    │
│  │ 2 symptoms logged           │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 💡 Senior Care Tip          │    │
│  │ Cold weather can worsen     │    │
│  │ joint stiffness. Consider   │    │
│  │ a sweater for walks.        │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

## Models

### MobilityAssessment

```swift
// OtisShared/Models/MobilityAssessment.swift

public struct MobilityAssessment: Codable, Identifiable, Sendable {
    public let id: UUID
    public var score: Int  // 1-5
    public var observations: [MobilityObservation]
    public var note: String?
    public var createdAt: Date

    public init(score: Int, observations: [MobilityObservation] = []) {
        self.id = UUID()
        self.score = score
        self.observations = observations
        self.note = nil
        self.createdAt = Date()
    }
}

public enum MobilityObservation: String, Codable, CaseIterable, Sendable {
    case stiffAfterRest
    case difficultyRising
    case reluctantStairs
    case bunnyHopping
    case limping
    case slowerWalks
    case troubleSlipperyFloors
    case collapsingRearLegs
    case dragginPaws

    public var label: String {
        switch self {
        case .stiffAfterRest: return String(localized: "Stiff after rest")
        case .difficultyRising: return String(localized: "Difficulty rising")
        case .reluctantStairs: return String(localized: "Reluctant to climb stairs")
        case .bunnyHopping: return String(localized: "Bunny hopping")
        case .limping: return String(localized: "Limping")
        case .slowerWalks: return String(localized: "Slower on walks")
        case .troubleSlipperyFloors: return String(localized: "Trouble with slippery floors")
        case .collapsingRearLegs: return String(localized: "Rear legs collapsing")
        case .dragginPaws: return String(localized: "Dragging paws")
        }
    }
}
```

### CognitiveAssessment

```swift
public struct CognitiveAssessment: Codable, Identifiable, Sendable {
    public let id: UUID
    public var disorientation: [CCDSymptom]
    public var interactions: [CCDSymptom]
    public var sleep: [CCDSymptom]
    public var houseSoiling: [CCDSymptom]
    public var activity: [CCDSymptom]
    public var anxiety: [CCDSymptom]
    public var note: String?
    public var createdAt: Date

    public var totalScore: Int {
        disorientation.count + interactions.count + sleep.count +
        houseSoiling.count + activity.count + anxiety.count
    }

    public var severity: CCDSeverity {
        switch totalScore {
        case 0: return .none
        case 1...3: return .mild
        case 4...8: return .moderate
        default: return .severe
        }
    }
}

public enum CCDSymptom: String, Codable, CaseIterable, Sendable {
    // Disorientation
    case lostFamiliarPlaces
    case staresAtWalls
    case wrongSideOfDoor

    // Interactions
    case lessInterested
    case notGreeting
    case avoidsPetting

    // Sleep
    case pacesAtNight
    case sleepsMoreDay
    case wakesYouUp

    // House soiling
    case accidents
    case forgetsToSignal

    // Activity
    case lessPlayInterest
    case aimlessWandering
    case repetitiveBehaviors

    // Anxiety
    case moreAnxious
    case newFears
    case increasedVocalization

    public var category: CCDCategory {
        switch self {
        case .lostFamiliarPlaces, .staresAtWalls, .wrongSideOfDoor:
            return .disorientation
        case .lessInterested, .notGreeting, .avoidsPetting:
            return .interactions
        case .pacesAtNight, .sleepsMoreDay, .wakesYouUp:
            return .sleep
        case .accidents, .forgetsToSignal:
            return .houseSoiling
        case .lessPlayInterest, .aimlessWandering, .repetitiveBehaviors:
            return .activity
        case .moreAnxious, .newFears, .increasedVocalization:
            return .anxiety
        }
    }

    public var label: String {
        switch self {
        case .lostFamiliarPlaces:
            return String(localized: "Gotten lost in familiar places")
        case .staresAtWalls:
            return String(localized: "Stared at walls or into space")
        case .wrongSideOfDoor:
            return String(localized: "Gone to wrong side of door")
        // ... etc
        default: return rawValue
        }
    }
}

public enum CCDCategory: String, Codable, Sendable {
    case disorientation
    case interactions
    case sleep
    case houseSoiling
    case activity
    case anxiety
}

public enum CCDSeverity: String, Codable, Sendable {
    case none
    case mild
    case moderate
    case severe

    public var guidance: String {
        switch self {
        case .none:
            return String(localized: "No signs of cognitive decline detected.")
        case .mild:
            return String(localized: "Mild signs detected. Consider discussing with your vet at the next visit.")
        case .moderate:
            return String(localized: "Moderate signs detected. We recommend scheduling a vet appointment to discuss cognitive support options.")
        case .severe:
            return String(localized: "Significant cognitive changes detected. Please consult your vet soon about management options.")
        }
    }
}
```

### QualityOfLifeAssessment

```swift
public struct QualityOfLifeAssessment: Codable, Identifiable, Sendable {
    public let id: UUID
    public var hurt: Int        // 1-10 (10 = no pain)
    public var hunger: Int      // 1-10 (10 = eating well)
    public var hydration: Int   // 1-10 (10 = drinking well)
    public var hygiene: Int     // 1-10 (10 = can be kept clean)
    public var happiness: Int   // 1-10 (10 = showing joy)
    public var mobility: Int    // 1-10 (10 = moving well)
    public var moreDays: Int    // 1-10 (10 = mostly good days)
    public var note: String?
    public var createdAt: Date

    public var totalScore: Int {
        hurt + hunger + hydration + hygiene + happiness + mobility + moreDays
    }

    public var maxScore: Int { 70 }

    public var interpretation: QoLInterpretation {
        let percentage = Double(totalScore) / Double(maxScore)
        switch percentage {
        case 0.8...: return .good
        case 0.5..<0.8: return .acceptable
        case 0.35..<0.5: return .compromised
        default: return .poor
        }
    }
}

public enum QoLInterpretation: String, Codable, Sendable {
    case good
    case acceptable
    case compromised
    case poor

    public var message: String {
        switch self {
        case .good:
            return String(localized: "Quality of life is good. Continue current care.")
        case .acceptable:
            return String(localized: "Quality of life is acceptable. Monitor closely and discuss comfort measures with your vet.")
        case .compromised:
            return String(localized: "Quality of life may be compromised. Please discuss with your vet about management options.")
        case .poor:
            return String(localized: "Quality of life appears significantly impacted. We recommend an urgent conversation with your vet about your dog's comfort.")
        }
    }
}
```

### RespiratoryRateReading

```swift
public struct RespiratoryRateReading: Codable, Identifiable, Sendable {
    public let id: UUID
    public var breathsPerMinute: Int
    public var wasResting: Bool
    public var note: String?
    public var createdAt: Date

    public var status: RRRStatus {
        switch breathsPerMinute {
        case 0..<20: return .normal
        case 20..<30: return .elevated
        default: return .emergency
        }
    }
}

public enum RRRStatus: String, Codable, Sendable {
    case normal
    case elevated
    case emergency

    public var message: String {
        switch self {
        case .normal:
            return String(localized: "Normal resting rate")
        case .elevated:
            return String(localized: "Elevated - monitor closely")
        case .emergency:
            return String(localized: "Very high - contact vet immediately")
        }
    }

    public var color: String {
        switch self {
        case .normal: return "green"
        case .elevated: return "yellow"
        case .emergency: return "red"
        }
    }
}
```

## Implementation

### Files to Create

```
OtisShared/Sources/OtisShared/Models/
├── MobilityAssessment.swift
├── CognitiveAssessment.swift
├── QualityOfLifeAssessment.swift
├── RespiratoryRateReading.swift

Ollie-app/Views/Health/Senior/
├── SeniorWellnessView.swift
├── MobilityAssessmentSheet.swift
├── CognitiveAssessmentSheet.swift
├── QualityOfLifeSheet.swift
├── RespiratoryRateSheet.swift
├── SeniorWellnessCard.swift
├── MobilityTrendCard.swift

Ollie-app/Services/
├── SeniorWellnessStore.swift

Ollie-app/Utils/Strings/
├── Strings+SeniorWellness.swift
```

### Files to Modify

```
Ollie-app/Views/Timeline/TodayView.swift
  - Add senior-specific cards for senior phase dogs

Ollie-app/Views/Health/HealthView.swift
  - Add senior wellness section

Ollie-app/Services/AI/AIContextComponents.swift
  - Add SeniorWellnessContext
```

### AI Context

```swift
struct SeniorWellnessContext: AIContextComponent {
    let isSenior: Bool
    let latestMobilityScore: Int?
    let mobilityTrend: String?  // improving/stable/declining
    let latestCCDScore: Int?
    let ccdSeverity: String?
    let latestQoLScore: Int?
    let activeConditions: [String]
    let medicationCount: Int
    let daysWithSymptoms: Int  // in last 7 days
}
```

## Senior Care Tips

Contextual tips based on conditions, weather, and time:

```swift
struct SeniorCareTip {
    let title: String
    let message: String
    let icon: String

    static func tips(for profile: PuppyProfile, weather: Weather?) -> [SeniorCareTip] {
        var tips: [SeniorCareTip] = []

        // Cold weather + arthritis
        if weather?.temperature < 10 && profile.hasCondition(.arthritis) {
            tips.append(SeniorCareTip(
                title: "Cold Weather Care",
                message: "Cold weather can worsen joint stiffness. Consider a sweater for walks and warm up slowly.",
                icon: "thermometer.snowflake"
            ))
        }

        // Morning stiffness reminder
        if profile.hasCondition(.arthritis) {
            tips.append(SeniorCareTip(
                title: "Morning Routine",
                message: "Senior dogs often need extra time to warm up in the morning. Start with gentle movement before a walk.",
                icon: "sunrise"
            ))
        }

        // Cognitive enrichment
        if profile.ageInMonths >= 84 {
            tips.append(SeniorCareTip(
                title: "Mental Enrichment",
                message: "Puzzle feeders and sniff walks help keep senior minds sharp.",
                icon: "brain"
            ))
        }

        return tips
    }
}
```

## Testing

- [ ] Verify senior dashboard shows for senior phase dogs only
- [ ] Test mobility assessment saves and trends correctly
- [ ] Verify CCD scoring calculates properly
- [ ] Test QoL interpretation thresholds
- [ ] Verify RRR emergency threshold triggers alert
- [ ] Test senior-specific Today view cards appear correctly
- [ ] Verify AI context includes senior wellness data

## Notes

- Quality of Life assessment should be suggested monthly for dogs with chronic conditions
- RRR tracking is especially important for heart conditions
- CCD screening should be offered annually for dogs 7+ years
- Consider integrating with vet appointment suggestions based on assessment results
- Export assessments for vet visits
