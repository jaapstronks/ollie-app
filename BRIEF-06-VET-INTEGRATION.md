# Brief 06: Vet Integration

> **Status:** Ready for Implementation
> **Priority:** High
> **Dependencies:** Brief 03 (Health Foundation), Brief 04 (Health Logging)
> **Estimated Effort:** Medium

## Objective

Build contextual vet visit support including age-triggered health milestones, breed-risk-aware suggestions, condition-based follow-up reminders, and a health calendar view.

## Features

### 1. Vet Visit Tips Card

Show contextual tips before scheduled vet appointments:

```
┌─────────────────────────────────────┐
│  🩺 Vet Visit Tomorrow              │
├─────────────────────────────────────┤
│                                     │
│  Questions to consider asking:      │
│                                     │
│  Based on Luna's breed (Retriever): │
│  □ Hip screening (recommended at    │
│    2 years for large breeds)        │
│                                     │
│  Based on Luna's age (3 years):     │
│  □ Dental cleaning baseline         │
│  □ Blood work baseline for seniors  │
│                                     │
│  Based on Luna's conditions:        │
│  □ Arthritis: Pain management       │
│    options review                   │
│  □ Allergies: Discuss long-term     │
│    management strategy              │
│                                     │
│  Recent concerns to mention:        │
│  • 3 limping episodes this month    │
│  • Appetite lower past week         │
│                                     │
│  [ Prepare Visit Summary ]          │
│                                     │
└─────────────────────────────────────┘
```

### 2. Age-Triggered Health Milestones

Automatic health reminders based on age:

| Age | Milestone | Description |
|-----|-----------|-------------|
| 8-10 weeks | Initial vaccines | First vaccination series |
| 12-14 weeks | Second vaccines | Booster shots |
| 16-18 weeks | Final puppy vaccines | Complete initial series |
| 4-6 months | Spay/neuter discussion | Discuss timing and approach |
| 6 months | Microchip check | Verify registration |
| 12 months | First annual checkup | Transition to adult care |
| 12 months | Adult food transition | Dietary change |
| 2 years | Dental baseline | First professional cleaning |
| 2 years | Hip/elbow screening | For at-risk breeds |
| 5 years (small) | Mid-life wellness | Baseline senior blood work |
| 7 years (large) | Senior wellness | Begin senior monitoring |
| 8 years+ | Bi-annual checkups | Increase visit frequency |

### 3. Health Calendar View

Comprehensive calendar showing all health events:

```
┌─────────────────────────────────────┐
│  Health Calendar              March │
├─────────────────────────────────────┤
│  S   M   T   W   T   F   S          │
│                      1   2          │
│  3   4   5   6   7   8   9          │
│      💊  💊      💊  💊              │
│ 10  11  12  13  14  15  16          │
│  💊  💊  🩺  💊  💊  💊              │
│ 17  18  19  20  21  22  23          │
│  💊  💊  💊  💊  💊  💊              │
│ 24  25  26  27  28  29  30          │
│  💊  💊  💊  🦷  💊  💊              │
│                                     │
│  ────────────────────────────────   │
│  UPCOMING                           │
│  🩺 Mar 12 - Annual checkup         │
│  🦷 Mar 27 - Dental cleaning        │
│  💉 Apr 15 - Vaccination due        │
│                                     │
│  RECURRING                          │
│  💊 Daily - Joint supplement        │
│  💊 Daily - Apoquel                 │
│                                     │
└─────────────────────────────────────┘
```

### 4. Visit Summary Export

Generate a shareable summary for the vet:

```
┌─────────────────────────────────────┐
│  Visit Summary for Luna             │
│  Generated: March 7, 2026           │
├─────────────────────────────────────┤
│                                     │
│  PROFILE                            │
│  Golden Retriever · Female · 3 yrs  │
│  Weight: 28.5 kg (last: Feb 15)     │
│                                     │
│  CURRENT CONDITIONS                 │
│  • Arthritis (diagnosed Jan 2025)   │
│    Severity: Moderate, Managed      │
│  • Environmental Allergies          │
│    Severity: Mild                   │
│                                     │
│  CURRENT MEDICATIONS                │
│  • Apoquel 16mg - Daily             │
│  • Joint supplement - Daily         │
│                                     │
│  RECENT SYMPTOMS (30 days)          │
│  • Limping: 3 episodes              │
│  • Itching: 2 episodes              │
│  • Stiffness: 5 mornings            │
│                                     │
│  RECENT ASSESSMENTS                 │
│  Mobility: 3.5/5 avg (stable)       │
│  Appetite: Good                     │
│                                     │
│  [ Share as PDF ] [ Copy Text ]     │
│                                     │
└─────────────────────────────────────┘
```

### 5. Condition Follow-Up Reminders

Automatic reminders based on diagnosed conditions:

| Condition | Follow-up | Frequency |
|-----------|-----------|-----------|
| Diabetes | Blood glucose curve | Every 3-6 months |
| Hypothyroid | Thyroid panel | Every 6 months |
| Heart disease | Echocardiogram | Every 6-12 months |
| Kidney disease | Blood work (BUN/Cr) | Every 3-6 months |
| Epilepsy | Liver panel | Every 6 months |
| Arthritis | Pain assessment | Every 6 months |
| Cancer (remission) | Recheck | Per vet schedule |

### 6. Breed Risk Awareness

Surface breed-specific screening recommendations:

```
┌─────────────────────────────────────┐
│  Breed Health Awareness             │
├─────────────────────────────────────┤
│                                     │
│  Golden Retrievers are prone to:    │
│                                     │
│  🦴 Hip Dysplasia                   │
│  Screening: Recommended at 24 mo    │
│  Luna's status: Not yet screened    │
│  [ Schedule Screening ]             │
│                                     │
│  ❤️ Heart Conditions                 │
│  Watch for: Exercise intolerance,   │
│  coughing, breathing changes        │
│                                     │
│  🦠 Cancer Risk                      │
│  Regular wellness checks important  │
│  after age 6-7                      │
│                                     │
└─────────────────────────────────────┘
```

## Models

### VetVisitTip

```swift
// OtisShared/Models/VetVisitTip.swift

public struct VetVisitTip: Identifiable, Sendable {
    public let id = UUID()
    public let category: TipCategory
    public let title: String
    public let description: String
    public let source: TipSource
    public let priority: TipPriority

    public enum TipCategory: String, Sendable {
        case breedRisk
        case ageRelated
        case conditionRelated
        case recentSymptom
        case preventive
    }

    public enum TipSource: Sendable {
        case breed(String)
        case age(Int)
        case condition(HealthConditionType)
        case symptom(SymptomType, count: Int)
    }

    public enum TipPriority: Int, Comparable, Sendable {
        case low = 1
        case medium = 2
        case high = 3

        public static func < (lhs: TipPriority, rhs: TipPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}
```

### HealthMilestone (extension)

```swift
// Extend existing Milestone.swift

extension Milestone {
    /// Generate age-triggered health milestones
    public static func healthMilestones(
        for profile: PuppyProfile
    ) -> [Milestone] {
        var milestones: [Milestone] = []

        // Puppy vaccines
        milestones.append(Milestone(
            category: .health,
            labelKey: "health.vaccines.initial",
            targetAgeWeeks: 8,
            isRecurring: false
        ))

        milestones.append(Milestone(
            category: .health,
            labelKey: "health.vaccines.booster1",
            targetAgeWeeks: 12,
            isRecurring: false
        ))

        milestones.append(Milestone(
            category: .health,
            labelKey: "health.vaccines.final",
            targetAgeWeeks: 16,
            isRecurring: false
        ))

        // Annual vaccines (recurring)
        milestones.append(Milestone(
            category: .health,
            labelKey: "health.vaccines.annual",
            targetAgeMonths: 12,
            isRecurring: true,
            recurrenceMonths: 12
        ))

        // Dental baseline
        milestones.append(Milestone(
            category: .health,
            labelKey: "health.dental.baseline",
            targetAgeMonths: 24,
            isRecurring: false
        ))

        // Breed-specific screening
        if let risks = BreedHealthRisk.risks(for: profile.breed) {
            for risk in risks.risks where risk.screeningRecommendedAgeMonths != nil {
                milestones.append(Milestone(
                    category: .health,
                    labelKey: "health.screening.\(risk.conditionType.rawValue)",
                    targetAgeMonths: risk.screeningRecommendedAgeMonths!,
                    isRecurring: false
                ))
            }
        }

        // Senior wellness (size-adjusted)
        milestones.append(Milestone(
            category: .health,
            labelKey: "health.senior.wellness",
            targetAgeMonths: profile.seniorAgeMonths,
            isRecurring: false
        ))

        return milestones
    }
}
```

### ConditionFollowUp

```swift
public struct ConditionFollowUp: Codable, Sendable {
    public let conditionType: HealthConditionType
    public let followUpType: FollowUpType
    public let recommendedIntervalMonths: Int
    public let description: String

    public enum FollowUpType: String, Codable, Sendable {
        case bloodWork
        case imaging
        case specialist
        case generalCheckup
        case monitoring
    }

    public static func followUps(for condition: HealthCondition) -> [ConditionFollowUp] {
        switch condition.type {
        case .diabetes:
            return [
                ConditionFollowUp(
                    conditionType: .diabetes,
                    followUpType: .bloodWork,
                    recommendedIntervalMonths: 3,
                    description: String(localized: "Glucose curve and fructosamine")
                )
            ]
        case .hypothyroidism:
            return [
                ConditionFollowUp(
                    conditionType: .hypothyroidism,
                    followUpType: .bloodWork,
                    recommendedIntervalMonths: 6,
                    description: String(localized: "Thyroid panel (T4, TSH)")
                )
            ]
        case .epilepsy:
            return [
                ConditionFollowUp(
                    conditionType: .epilepsy,
                    followUpType: .bloodWork,
                    recommendedIntervalMonths: 6,
                    description: String(localized: "Liver panel (if on phenobarbital)")
                ),
                ConditionFollowUp(
                    conditionType: .epilepsy,
                    followUpType: .monitoring,
                    recommendedIntervalMonths: 3,
                    description: String(localized: "Seizure frequency review")
                )
            ]
        case .chronicKidneyDisease:
            return [
                ConditionFollowUp(
                    conditionType: .chronicKidneyDisease,
                    followUpType: .bloodWork,
                    recommendedIntervalMonths: 3,
                    description: String(localized: "Kidney values (BUN, creatinine, SDMA)")
                )
            ]
        case .heartMurmur, .congestiveHeartFailure:
            return [
                ConditionFollowUp(
                    conditionType: condition.type,
                    followUpType: .imaging,
                    recommendedIntervalMonths: 6,
                    description: String(localized: "Echocardiogram")
                ),
                ConditionFollowUp(
                    conditionType: condition.type,
                    followUpType: .monitoring,
                    recommendedIntervalMonths: 1,
                    description: String(localized: "Resting respiratory rate tracking")
                )
            ]
        default:
            return [
                ConditionFollowUp(
                    conditionType: condition.type,
                    followUpType: .generalCheckup,
                    recommendedIntervalMonths: 6,
                    description: String(localized: "General wellness check")
                )
            ]
        }
    }
}
```

## Implementation

### Files to Create

```
OtisShared/Sources/OtisShared/Models/
├── VetVisitTip.swift
├── ConditionFollowUp.swift

Ollie-app/Views/Health/Vet/
├── VetVisitTipsCard.swift
├── VetVisitTipsSheet.swift
├── HealthCalendarView.swift
├── VisitSummaryView.swift
├── BreedRiskCard.swift
├── FollowUpRemindersCard.swift

Ollie-app/Services/
├── VetVisitTipGenerator.swift
├── HealthMilestoneStore.swift

Ollie-app/Utils/Strings/
├── Strings+VetVisit.swift
```

### Files to Modify

```
Ollie-app/Views/Timeline/TodayView.swift
  - Show VetVisitTipsCard when vet appointment is upcoming

Ollie-app/Views/Health/HealthView.swift
  - Add Health Calendar section
  - Add Breed Risk awareness section

OtisShared/Models/Milestone.swift
  - Add health milestone generation
```

### Tip Generation Logic

```swift
// VetVisitTipGenerator.swift

class VetVisitTipGenerator {
    func generateTips(
        for profile: PuppyProfile,
        appointment: DogAppointment,
        recentSymptoms: [HealthSymptomLog],
        conditions: [HealthCondition]
    ) -> [VetVisitTip] {
        var tips: [VetVisitTip] = []

        // Age-based tips
        tips.append(contentsOf: ageTips(for: profile))

        // Breed-based tips
        tips.append(contentsOf: breedTips(for: profile))

        // Condition-based tips
        tips.append(contentsOf: conditionTips(for: conditions))

        // Recent symptom tips
        tips.append(contentsOf: symptomTips(from: recentSymptoms))

        // Sort by priority
        return tips.sorted { $0.priority > $1.priority }
    }

    private func ageTips(for profile: PuppyProfile) -> [VetVisitTip] {
        var tips: [VetVisitTip] = []
        let ageMonths = profile.ageInMonths

        // Spay/neuter discussion age
        if ageMonths >= 4 && ageMonths <= 12 {
            tips.append(VetVisitTip(
                category: .ageRelated,
                title: String(localized: "Spay/Neuter Timing"),
                description: String(localized: "Discuss optimal timing for spay/neuter based on breed and lifestyle"),
                source: .age(ageMonths),
                priority: .medium
            ))
        }

        // Dental baseline
        if ageMonths >= 20 && ageMonths <= 30 {
            tips.append(VetVisitTip(
                category: .preventive,
                title: String(localized: "Dental Health Baseline"),
                description: String(localized: "Consider a dental cleaning to establish baseline oral health"),
                source: .age(ageMonths),
                priority: .low
            ))
        }

        // Senior wellness
        if ageMonths >= profile.seniorAgeMonths - 6 {
            tips.append(VetVisitTip(
                category: .ageRelated,
                title: String(localized: "Senior Wellness Planning"),
                description: String(localized: "Discuss senior screening blood work and increased monitoring"),
                source: .age(ageMonths),
                priority: .high
            ))
        }

        return tips
    }

    private func breedTips(for profile: PuppyProfile) -> [VetVisitTip] {
        guard let breedRisks = BreedHealthRisk.risks(for: profile.breed) else {
            return []
        }

        return breedRisks.risks.compactMap { risk in
            // Only suggest if dog is approaching or past screening age
            guard let screeningAge = risk.screeningRecommendedAgeMonths,
                  profile.ageInMonths >= screeningAge - 6 else {
                return nil
            }

            return VetVisitTip(
                category: .breedRisk,
                title: risk.conditionType.label + " " + String(localized: "Screening"),
                description: String(localized: "Recommended for \(profile.breed ?? "this breed") at this age"),
                source: .breed(profile.breed ?? ""),
                priority: risk.riskLevel == .veryHigh ? .high : .medium
            )
        }
    }

    private func conditionTips(for conditions: [HealthCondition]) -> [VetVisitTip] {
        conditions.flatMap { condition in
            ConditionFollowUp.followUps(for: condition).map { followUp in
                VetVisitTip(
                    category: .conditionRelated,
                    title: condition.type.label + " " + String(localized: "Follow-up"),
                    description: followUp.description,
                    source: .condition(condition.type),
                    priority: condition.severity == .severe ? .high : .medium
                )
            }
        }
    }

    private func symptomTips(from symptoms: [HealthSymptomLog]) -> [VetVisitTip] {
        // Group symptoms by type and count
        let grouped = Dictionary(grouping: symptoms) { $0.symptomType }

        return grouped.compactMap { type, logs in
            guard logs.count >= 2 else { return nil }  // Only mention recurring symptoms

            return VetVisitTip(
                category: .recentSymptom,
                title: String(localized: "Recent: \(type.label)"),
                description: String(localized: "\(logs.count) episodes in the past month"),
                source: .symptom(type, count: logs.count),
                priority: type.urgencyLevel == .emergency ? .high : .medium
            )
        }
    }
}
```

## Strings to Add

```swift
// Strings+VetVisit.swift
enum VetVisit {
    static let upcomingVisit = String(localized: "Vet Visit")
    static let questionsToConsider = String(localized: "Questions to consider asking")
    static let basedOnBreed = String(localized: "Based on breed")
    static let basedOnAge = String(localized: "Based on age")
    static let basedOnConditions = String(localized: "Based on conditions")
    static let recentConcerns = String(localized: "Recent concerns to mention")
    static let prepareVisitSummary = String(localized: "Prepare Visit Summary")

    enum Calendar {
        static let title = String(localized: "Health Calendar")
        static let upcoming = String(localized: "Upcoming")
        static let recurring = String(localized: "Recurring")
    }

    enum Summary {
        static let title = String(localized: "Visit Summary")
        static let profile = String(localized: "Profile")
        static let currentConditions = String(localized: "Current Conditions")
        static let currentMedications = String(localized: "Current Medications")
        static let recentSymptoms = String(localized: "Recent Symptoms")
        static let recentAssessments = String(localized: "Recent Assessments")
        static let shareAsPDF = String(localized: "Share as PDF")
        static let copyText = String(localized: "Copy Text")
    }

    enum Milestones {
        static let vaccinesInitial = String(localized: "Initial puppy vaccines")
        static let vaccinesBooster = String(localized: "Booster vaccines")
        static let vaccinesFinal = String(localized: "Final puppy vaccines")
        static let vaccinesAnnual = String(localized: "Annual vaccinations")
        static let dentalBaseline = String(localized: "Dental cleaning baseline")
        static let seniorWellness = String(localized: "Senior wellness exam")
    }
}
```

## Testing

- [ ] Verify tips generate correctly based on age
- [ ] Test breed-specific tips for common breeds
- [ ] Verify condition follow-up recommendations
- [ ] Test symptom aggregation in tips
- [ ] Verify health calendar displays all event types
- [ ] Test visit summary export
- [ ] Verify tips show X days before appointment

## Notes

- Tips should show 1-3 days before scheduled vet appointments
- Visit summary should be exportable as PDF for sharing
- Consider integration with Apple Health (export health data)
- Breed risk data can be expanded from veterinary databases
- Follow-up frequencies are guidelines - user can customize
