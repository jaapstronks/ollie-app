# Brief 04: Health Logging

> **Status:** Ready for Implementation
> **Priority:** High
> **Dependencies:** Brief 03 (Health Foundation)
> **Estimated Effort:** Medium

## Objective

Build the logging infrastructure for health symptoms and periodic health check-ins. This mirrors the existing BehaviorIncident and SentimentCheckIn patterns.

## Features

### 1. Health Symptom Log

Log individual symptom occurrences (mirrors BehaviorLogSheet):

```
┌─────────────────────────────────────┐
│          Log Symptom                │
├─────────────────────────────────────┤
│                                     │
│  What did you notice?               │
│  ┌─────────────────────────────┐    │
│  │ 🦵 Limping              ✓   │    │
│  │ 😴 Lethargy                 │    │
│  │ 🤢 Vomiting                 │    │
│  │ 🦴 Stiffness                │    │
│  └─────────────────────────────┘    │
│                                     │
│  Severity:                          │
│  [1] [2] [3] [4] [5]                │
│   ○   ○   ●   ○   ○                 │
│  Mild      Moderate     Severe      │
│                                     │
│  Body location (optional):          │
│  [ Left rear leg ▼ ]                │
│                                     │
│  When did it start?                 │
│  ○ Just now  ● Earlier today        │
│  ○ Yesterday ○ Been ongoing         │
│                                     │
│  Duration:                          │
│  ○ Brief (<15 min)                  │
│  ● Ongoing (still present)          │
│  ○ Resolved                         │
│                                     │
│  Related to:                        │
│  [After walk] [After eating] [...]  │
│                                     │
│  Notes:                             │
│  ┌─────────────────────────────┐    │
│  │ Noticed after long walk     │    │
│  └─────────────────────────────┘    │
│                                     │
│  📷 Add photo                       │
│                                     │
│         [ Log Symptom ]             │
└─────────────────────────────────────┘
```

### 2. Health Check-In Card

Periodic Likert-scale health assessment (mirrors SentimentCheckInCard):

```
┌─────────────────────────────────────┐
│  How is Luna's mobility today?      │
│                                     │
│  [1] [2] [3] [4] [5]                │
│  Poor     OK      Great             │
│                                     │
│  Context: Luna has arthritis and    │
│  was stiff yesterday morning.       │
│                                     │
└─────────────────────────────────────┘
```

**Categories for health check-ins** (condition-dependent):

| Category | When to Show | Question |
|----------|--------------|----------|
| Mobility | Arthritis, hip dysplasia | "How is {name}'s mobility today?" |
| Energy | Senior, heart conditions | "How is {name}'s energy level?" |
| Appetite | Any condition, senior | "How is {name}'s appetite?" |
| Breathing | Heart/respiratory conditions | "How is {name}'s breathing?" |
| Comfort | Arthritis, chronic pain | "How comfortable does {name} seem?" |
| Cognition | CCD, senior | "How alert is {name} today?" |
| Skin | Allergies, dermatitis | "How is {name}'s skin/itching?" |
| Digestion | IBD, pancreatitis | "How is {name}'s digestion?" |

### 3. Condition-Specific Quick Logs

For diagnosed conditions, show relevant quick symptom buttons:

```
┌─────────────────────────────────────┐
│  Arthritis Quick Log                │
├─────────────────────────────────────┤
│                                     │
│  [🦵 Limping]  [💤 Stiff Morning]   │
│  [🚶 Good Day] [😔 Flare-up]        │
│                                     │
└─────────────────────────────────────┘
```

### 4. Symptom Trend Card

Show patterns over time:

```
┌─────────────────────────────────────┐
│  Arthritis Symptoms                 │
├─────────────────────────────────────┤
│                                     │
│  This Week: 3 episodes              │
│  Last Week: 5 episodes   ↓ Better   │
│                                     │
│  Common triggers:                   │
│  • After long walks (2x)            │
│  • Cold mornings (1x)               │
│                                     │
│  [ View Details ]                   │
└─────────────────────────────────────┘
```

## Models

### HealthSymptomLog

```swift
// OtisShared/Models/HealthSymptomLog.swift

public struct HealthSymptomLog: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var symptomType: SymptomType
    public var severity: Int  // 1-5
    public var bodyLocation: BodyLocation?
    public var startTime: Date
    public var duration: SymptomDuration
    public var status: SymptomStatus
    public var triggers: [String]
    public var relatedConditionId: UUID?  // Link to diagnosed condition
    public var note: String?
    public var photoPath: String?
    public var loggedBy: UUID?
    public var createdAt: Date
    public var modifiedAt: Date

    public init(
        symptomType: SymptomType,
        severity: Int = 3,
        startTime: Date = Date()
    ) {
        self.id = UUID()
        self.symptomType = symptomType
        self.severity = severity
        self.bodyLocation = nil
        self.startTime = startTime
        self.duration = .ongoing
        self.status = .active
        self.triggers = []
        self.relatedConditionId = nil
        self.note = nil
        self.photoPath = nil
        self.loggedBy = nil
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

public enum BodyLocation: String, Codable, CaseIterable, Sendable {
    // Legs
    case frontLeftLeg
    case frontRightLeg
    case rearLeftLeg
    case rearRightLeg

    // Body
    case head
    case neck
    case chest
    case back
    case abdomen
    case tail

    // Ears/Eyes
    case leftEar
    case rightEar
    case leftEye
    case rightEye

    // Paws
    case frontLeftPaw
    case frontRightPaw
    case rearLeftPaw
    case rearRightPaw

    // General
    case wholeBody
    case unspecified

    public var label: String {
        switch self {
        case .frontLeftLeg: return String(localized: "Front left leg")
        case .frontRightLeg: return String(localized: "Front right leg")
        case .rearLeftLeg: return String(localized: "Rear left leg")
        case .rearRightLeg: return String(localized: "Rear right leg")
        case .abdomen: return String(localized: "Abdomen/Belly")
        case .wholeBody: return String(localized: "Whole body")
        // ... etc
        default: return rawValue.capitalized
        }
    }
}

public enum SymptomDuration: String, Codable, CaseIterable, Sendable {
    case brief          // < 15 minutes
    case shortTerm      // 15 min - 2 hours
    case hours          // 2-24 hours
    case days           // Multiple days
    case ongoing        // Currently happening
    case resolved       // Was happening, now stopped

    public var label: String {
        switch self {
        case .brief: return String(localized: "Brief (< 15 min)")
        case .shortTerm: return String(localized: "15 min - 2 hours")
        case .hours: return String(localized: "Several hours")
        case .days: return String(localized: "Multiple days")
        case .ongoing: return String(localized: "Ongoing")
        case .resolved: return String(localized: "Resolved")
        }
    }
}

public enum SymptomStatus: String, Codable, Sendable {
    case active     // Currently experiencing
    case resolved   // Symptom has stopped
    case recurring  // Comes and goes
}
```

### HealthCheckIn (mirrors SentimentCheckIn)

```swift
// OtisShared/Models/HealthCheckIn.swift

public struct HealthCheckIn: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var category: HealthCheckInCategory
    public var score: Int  // 1-5
    public var relatedConditionId: UUID?
    public var note: String?
    public var createdAt: Date

    public var isStruggling: Bool { score <= 2 }
    public var isOkay: Bool { score == 3 }
    public var isDoingWell: Bool { score >= 4 }
}

public enum HealthCheckInCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case mobility
    case energy
    case appetite
    case breathing
    case comfort
    case cognition
    case skin
    case digestion
    case vision
    case hearing
    case overall

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .mobility: return String(localized: "Mobility")
        case .energy: return String(localized: "Energy Level")
        case .appetite: return String(localized: "Appetite")
        case .breathing: return String(localized: "Breathing")
        case .comfort: return String(localized: "Comfort")
        case .cognition: return String(localized: "Alertness")
        case .skin: return String(localized: "Skin/Coat")
        case .digestion: return String(localized: "Digestion")
        case .vision: return String(localized: "Vision")
        case .hearing: return String(localized: "Hearing")
        case .overall: return String(localized: "Overall")
        }
    }

    public func question(for name: String) -> String {
        switch self {
        case .mobility:
            return String(localized: "How is \(name)'s mobility today?")
        case .energy:
            return String(localized: "How is \(name)'s energy level?")
        case .appetite:
            return String(localized: "How is \(name)'s appetite?")
        case .breathing:
            return String(localized: "How is \(name)'s breathing?")
        case .comfort:
            return String(localized: "How comfortable does \(name) seem?")
        case .cognition:
            return String(localized: "How alert is \(name) today?")
        case .skin:
            return String(localized: "How is \(name)'s skin/itching?")
        case .digestion:
            return String(localized: "How is \(name)'s digestion?")
        case .vision:
            return String(localized: "How is \(name)'s vision?")
        case .hearing:
            return String(localized: "How does \(name) respond to sounds?")
        case .overall:
            return String(localized: "How is \(name) doing overall?")
        }
    }

    /// Which conditions trigger this check-in category
    public var relevantConditions: [HealthConditionType] {
        switch self {
        case .mobility:
            return [.hipDysplasia, .elbowDysplasia, .arthritis, .luxatingPatella, .ivdd]
        case .breathing:
            return [.heartMurmur, .congestiveHeartFailure, .collapsedTrachea, .brachycephalicSyndrome]
        case .cognition:
            return [.canineCognitiveDysfunction]
        case .skin:
            return [.foodAllergy, .environmentalAllergy, .atopicDermatitis]
        case .digestion:
            return [.ibd, .pancreatitis, .foodAllergy]
        case .energy:
            return [.hypothyroidism, .diabetes, .heartMurmur]
        default:
            return []
        }
    }

    /// Is this category relevant given the dog's conditions and lifecycle phase?
    public static func relevantCategories(
        conditions: [HealthCondition],
        lifecyclePhase: LifecyclePhase
    ) -> [HealthCheckInCategory] {
        var categories = Set<HealthCheckInCategory>()

        // Add condition-specific categories
        for condition in conditions where condition.status == .active {
            for category in HealthCheckInCategory.allCases {
                if category.relevantConditions.contains(condition.type) {
                    categories.insert(category)
                }
            }
        }

        // Senior dogs always get certain categories
        if lifecyclePhase == .senior {
            categories.insert(.mobility)
            categories.insert(.energy)
            categories.insert(.cognition)
            categories.insert(.appetite)
        }

        // Everyone gets overall if they have any conditions
        if !conditions.isEmpty || lifecyclePhase == .senior {
            categories.insert(.overall)
        }

        return Array(categories).sorted { $0.rawValue < $1.rawValue }
    }
}
```

## Implementation

### Files to Create

```
OtisShared/Sources/OtisShared/Models/
├── HealthSymptomLog.swift
├── HealthCheckIn.swift

Ollie-app/Views/Health/
├── SymptomLogSheet.swift         (clone of BehaviorLogSheet)
├── HealthCheckInCard.swift       (clone of SentimentCheckInCard)
├── SymptomTrendCard.swift
├── ConditionQuickLogCard.swift

Ollie-app/Services/
├── HealthSymptomStore.swift
├── HealthCheckInStore.swift

Ollie-app/Utils/Strings/
├── Strings+HealthSymptoms.swift
```

### Files to Modify

```
Ollie-app/ViewModels/SheetCoordinator.swift
  - Add .symptomLog case

Ollie-app/Views/Components/TimelineSheetModifiers.swift
  - Wire up SymptomLogSheet

Ollie-app/Views/Timeline/TodayView.swift
  - Add HealthCheckInCard for dogs with conditions
  - Add SymptomTrendCard

OtisShared/Models/PuppyEvent.swift
  - Add symptom event fields (or create new .symptom event type)
```

### Service Layer

```swift
// HealthSymptomStore.swift
@Observable
class HealthSymptomStore {
    // Storage (could be JSONL like events, or Core Data)
    func log(_ symptom: HealthSymptomLog) { }
    func update(_ symptom: HealthSymptomLog) { }
    func delete(id: UUID) { }

    // Queries
    func symptoms(for conditionId: UUID?, days: Int) -> [HealthSymptomLog] { }
    func symptomsToday() -> [HealthSymptomLog] { }
    func symptomCount(type: SymptomType, days: Int) -> Int { }

    // Analysis
    func trend(for conditionId: UUID) -> SymptomTrend { }
    func commonTriggers(for conditionId: UUID) -> [String: Int] { }
}

// HealthCheckInStore.swift
@Observable
class HealthCheckInStore {
    func log(_ checkIn: HealthCheckIn) { }
    func latestCheckIn(for category: HealthCheckInCategory) -> HealthCheckIn? { }
    func checkInsThisWeek() -> [HealthCheckIn] { }

    // Which category should we ask about today?
    func nextCheckInCategory(
        conditions: [HealthCondition],
        lifecyclePhase: LifecyclePhase
    ) -> HealthCheckInCategory? {
        let relevant = HealthCheckInCategory.relevantCategories(
            conditions: conditions,
            lifecyclePhase: lifecyclePhase
        )

        // Find the category we haven't checked recently
        for category in relevant {
            if let latest = latestCheckIn(for: category) {
                let daysSince = Calendar.current.dateComponents(
                    [.day], from: latest.createdAt, to: Date()
                ).day ?? 0
                if daysSince >= 3 { return category }  // Ask every 3 days
            } else {
                return category  // Never asked
            }
        }

        return nil
    }
}
```

### View Implementation Pattern

```swift
// SymptomLogSheet.swift - Follow BehaviorLogSheet pattern
struct SymptomLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSymptom: SymptomType?
    @State private var severity: Int = 3
    @State private var bodyLocation: BodyLocation?
    @State private var duration: SymptomDuration = .ongoing
    @State private var triggers: [String] = []
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Symptom selection grid
                    symptomSelectionGrid

                    if selectedSymptom != nil {
                        // Severity picker (1-5)
                        severityPicker

                        // Body location (optional)
                        bodyLocationPicker

                        // Duration
                        durationPicker

                        // Triggers (chips)
                        triggerSelection

                        // Notes
                        notesField
                    }
                }
                .padding()
            }
            .navigationTitle(Strings.Health.logSymptom)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) { saveSymptom() }
                        .disabled(selectedSymptom == nil)
                }
            }
        }
    }

    private var symptomSelectionGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
            ForEach(relevantSymptoms) { symptom in
                SymptomChip(
                    symptom: symptom,
                    isSelected: selectedSymptom == symptom
                ) {
                    selectedSymptom = symptom
                }
            }
        }
    }

    // Filter symptoms relevant to user's conditions
    private var relevantSymptoms: [SymptomType] {
        // Show common symptoms + condition-specific ones
        var symptoms = Set<SymptomType>([
            .limping, .lethargy, .vomiting, .diarrhea,
            .coughing, .itching, .appetiteLoss
        ])

        for condition in profileStore.activeConditions {
            symptoms.formUnion(condition.type.commonSymptoms)
        }

        return Array(symptoms).sorted { $0.label < $1.label }
    }
}
```

## Strings to Add

```swift
// Strings+HealthSymptoms.swift
enum Health {
    static let logSymptom = String(localized: "Log Symptom")
    static let whatDidYouNotice = String(localized: "What did you notice?")
    static let severity = String(localized: "Severity")
    static let mild = String(localized: "Mild")
    static let moderate = String(localized: "Moderate")
    static let severe = String(localized: "Severe")
    static let bodyLocation = String(localized: "Body location")
    static let whenDidItStart = String(localized: "When did it start?")
    static let justNow = String(localized: "Just now")
    static let earlierToday = String(localized: "Earlier today")
    static let yesterday = String(localized: "Yesterday")
    static let beenOngoing = String(localized: "Been ongoing")
    static let duration = String(localized: "Duration")
    static let relatedTo = String(localized: "Related to")
    static let addPhoto = String(localized: "Add photo")

    enum Triggers {
        static let afterWalk = String(localized: "After walk")
        static let afterEating = String(localized: "After eating")
        static let afterWaking = String(localized: "After waking")
        static let coldWeather = String(localized: "Cold weather")
        static let hotWeather = String(localized: "Hot weather")
        static let stress = String(localized: "Stress")
        static let exercise = String(localized: "Exercise")
    }

    enum Trends {
        static let thisWeek = String(localized: "This week")
        static let lastWeek = String(localized: "Last week")
        static let episodes = String(localized: "episodes")
        static let commonTriggers = String(localized: "Common triggers")
        static let improving = String(localized: "Improving")
        static let stable = String(localized: "Stable")
        static let worsening = String(localized: "Worsening")
    }

    enum CheckIn {
        static let poor = String(localized: "Poor")
        static let notGreat = String(localized: "Not great")
        static let okay = String(localized: "Okay")
        static let good = String(localized: "Good")
        static let great = String(localized: "Great")
    }
}
```

## AI Context Integration

```swift
// AIContextComponents.swift - Add HealthSymptomsContext
struct HealthSymptomsContext: AIContextComponent {
    let activeConditions: [ConditionSummary]
    let recentSymptoms: [SymptomSummary]
    let symptomTrends: [TrendSummary]
    let checkInScores: [String: Int]  // category -> latest score

    struct ConditionSummary: Codable {
        let type: String
        let severity: String
        let daysSinceDiagnosis: Int
    }

    struct SymptomSummary: Codable {
        let type: String
        let severity: Int
        let daysAgo: Int
        let trigger: String?
    }

    struct TrendSummary: Codable {
        let conditionType: String
        let episodesThisWeek: Int
        let episodesLastWeek: Int
        let trend: String  // improving/stable/worsening
    }
}
```

## Testing

- [ ] Log symptom with all fields
- [ ] Verify severity scale saves correctly
- [ ] Test body location selection
- [ ] Verify trigger chips work
- [ ] Test health check-in card appears for dogs with conditions
- [ ] Verify check-in score persists
- [ ] Test trend calculation accuracy
- [ ] Verify symptom-condition linking
- [ ] Test AI context includes health data

## Notes

- Photo attachment useful for skin conditions, swelling
- Consider urgent symptom detection (seizure > 5 min → show emergency guidance)
- Symptoms can be logged without a diagnosed condition (for tracking pre-diagnosis)
- Check-in frequency should be configurable per condition
