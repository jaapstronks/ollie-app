import Foundation

// MARK: - ConditionFollowUp

/// Defines recommended follow-up care schedules for health conditions.
/// Used to generate reminders for condition-specific monitoring.
public struct ConditionFollowUp: Codable, Sendable, Equatable, Identifiable {
    public var id: String { "\(conditionType.rawValue)-\(followUpType.rawValue)" }

    public let conditionType: HealthConditionType
    public let followUpType: FollowUpType
    public let recommendedIntervalMonths: Int
    public let description: String
    public let priority: FollowUpPriority

    public init(
        conditionType: HealthConditionType,
        followUpType: FollowUpType,
        recommendedIntervalMonths: Int,
        description: String,
        priority: FollowUpPriority = .routine
    ) {
        self.conditionType = conditionType
        self.followUpType = followUpType
        self.recommendedIntervalMonths = recommendedIntervalMonths
        self.description = description
        self.priority = priority
    }

    // MARK: - FollowUpType

    public enum FollowUpType: String, Codable, Sendable, CaseIterable {
        case bloodWork
        case imaging
        case specialist
        case generalCheckup
        case monitoring
        case dentalExam
        case eyeExam
        case heartCheck
        case urinalysis

        public var icon: String {
            switch self {
            case .bloodWork: return "drop.fill"
            case .imaging: return "waveform.path.ecg.rectangle"
            case .specialist: return "stethoscope"
            case .generalCheckup: return "heart.text.square"
            case .monitoring: return "chart.line.uptrend.xyaxis"
            case .dentalExam: return "mouth.fill"
            case .eyeExam: return "eye.fill"
            case .heartCheck: return "heart.fill"
            case .urinalysis: return "testtube.2"
            }
        }
    }

    // MARK: - FollowUpPriority

    public enum FollowUpPriority: String, Codable, Sendable {
        case routine
        case important
        case critical

        public var colorName: String {
            switch self {
            case .routine: return "otisInfo"
            case .important: return "otisWarning"
            case .critical: return "otisDestructive"
            }
        }
    }

    // MARK: - Follow-Up Recommendations

    /// Returns recommended follow-ups for a specific condition
    public static func followUps(for condition: HealthCondition) -> [ConditionFollowUp] {
        followUps(for: condition.type, severity: condition.severity)
    }

    /// Returns recommended follow-ups for a condition type and severity
    public static func followUps(
        for conditionType: HealthConditionType,
        severity: ConditionSeverity = .moderate
    ) -> [ConditionFollowUp] {
        var results: [ConditionFollowUp] = []

        // Adjust intervals based on severity
        let intervalMultiplier: Double = {
            switch severity {
            case .mild: return 1.5
            case .moderate: return 1.0
            case .severe: return 0.5
            case .managed: return 1.0
            }
        }()

        func interval(_ months: Int) -> Int {
            max(1, Int(Double(months) * intervalMultiplier))
        }

        switch conditionType {
        // Endocrine conditions
        case .diabetes:
            results.append(ConditionFollowUp(
                conditionType: .diabetes,
                followUpType: .bloodWork,
                recommendedIntervalMonths: interval(3),
                description: "Glucose and fructosamine levels",
                priority: .important
            ))
            results.append(ConditionFollowUp(
                conditionType: .diabetes,
                followUpType: .urinalysis,
                recommendedIntervalMonths: interval(6),
                description: "Check for urinary tract infections",
                priority: .routine
            ))

        case .hypothyroidism:
            results.append(ConditionFollowUp(
                conditionType: .hypothyroidism,
                followUpType: .bloodWork,
                recommendedIntervalMonths: interval(6),
                description: "Thyroid panel (T4, TSH)",
                priority: .important
            ))

        case .cushings:
            results.append(ConditionFollowUp(
                conditionType: .cushings,
                followUpType: .bloodWork,
                recommendedIntervalMonths: interval(3),
                description: "ACTH stimulation or LDDS test",
                priority: .important
            ))
            results.append(ConditionFollowUp(
                conditionType: .cushings,
                followUpType: .urinalysis,
                recommendedIntervalMonths: interval(6),
                description: "Monitor for UTIs",
                priority: .routine
            ))

        case .addisons:
            results.append(ConditionFollowUp(
                conditionType: .addisons,
                followUpType: .bloodWork,
                recommendedIntervalMonths: interval(3),
                description: "Electrolyte panel",
                priority: .critical
            ))

        // Neurological conditions
        case .epilepsy:
            results.append(ConditionFollowUp(
                conditionType: .epilepsy,
                followUpType: .bloodWork,
                recommendedIntervalMonths: interval(6),
                description: "Liver function panel (medication monitoring)",
                priority: .important
            ))
            results.append(ConditionFollowUp(
                conditionType: .epilepsy,
                followUpType: .generalCheckup,
                recommendedIntervalMonths: interval(6),
                description: "Seizure frequency review",
                priority: .routine
            ))

        case .vestibularDisease:
            results.append(ConditionFollowUp(
                conditionType: .vestibularDisease,
                followUpType: .generalCheckup,
                recommendedIntervalMonths: interval(6),
                description: "Balance and coordination assessment",
                priority: .routine
            ))

        // Cardiac conditions
        case .heartMurmur, .dilatedCardiomyopathy, .mitralValveDisease, .congestiveHeartFailure:
            results.append(ConditionFollowUp(
                conditionType: conditionType,
                followUpType: .heartCheck,
                recommendedIntervalMonths: interval(6),
                description: "Cardiac auscultation and assessment",
                priority: .important
            ))
            results.append(ConditionFollowUp(
                conditionType: conditionType,
                followUpType: .imaging,
                recommendedIntervalMonths: interval(12),
                description: "Echocardiogram",
                priority: .routine
            ))

        // Musculoskeletal conditions
        case .hipDysplasia, .elbowDysplasia:
            results.append(ConditionFollowUp(
                conditionType: conditionType,
                followUpType: .imaging,
                recommendedIntervalMonths: interval(12),
                description: "X-ray to monitor progression",
                priority: .routine
            ))
            results.append(ConditionFollowUp(
                conditionType: conditionType,
                followUpType: .generalCheckup,
                recommendedIntervalMonths: interval(6),
                description: "Pain and mobility assessment",
                priority: .routine
            ))

        case .arthritis:
            results.append(ConditionFollowUp(
                conditionType: .arthritis,
                followUpType: .generalCheckup,
                recommendedIntervalMonths: interval(6),
                description: "Pain management review",
                priority: .routine
            ))

        case .ivdd:
            results.append(ConditionFollowUp(
                conditionType: .ivdd,
                followUpType: .generalCheckup,
                recommendedIntervalMonths: interval(6),
                description: "Neurological examination",
                priority: .important
            ))

        // Digestive conditions
        case .ibd, .pancreatitis:
            results.append(ConditionFollowUp(
                conditionType: conditionType,
                followUpType: .bloodWork,
                recommendedIntervalMonths: interval(6),
                description: "GI panel and inflammation markers",
                priority: .routine
            ))

        // Kidney/Urinary conditions
        case .chronicKidneyDisease:
            results.append(ConditionFollowUp(
                conditionType: .chronicKidneyDisease,
                followUpType: .bloodWork,
                recommendedIntervalMonths: interval(3),
                description: "Kidney values (BUN, creatinine, SDMA)",
                priority: .critical
            ))
            results.append(ConditionFollowUp(
                conditionType: .chronicKidneyDisease,
                followUpType: .urinalysis,
                recommendedIntervalMonths: interval(3),
                description: "Urine protein:creatinine ratio",
                priority: .important
            ))

        case .bladderStones:
            results.append(ConditionFollowUp(
                conditionType: .bladderStones,
                followUpType: .imaging,
                recommendedIntervalMonths: interval(6),
                description: "Bladder ultrasound or X-ray",
                priority: .routine
            ))
            results.append(ConditionFollowUp(
                conditionType: .bladderStones,
                followUpType: .urinalysis,
                recommendedIntervalMonths: interval(6),
                description: "Urine pH and crystal analysis",
                priority: .routine
            ))

        // Eye conditions
        case .cataracts, .glaucoma, .progressiveRetinalAtrophy:
            results.append(ConditionFollowUp(
                conditionType: conditionType,
                followUpType: .eyeExam,
                recommendedIntervalMonths: interval(6),
                description: "Ophthalmologic examination",
                priority: conditionType == .glaucoma ? .critical : .important
            ))

        case .dryEye:
            results.append(ConditionFollowUp(
                conditionType: conditionType,
                followUpType: .eyeExam,
                recommendedIntervalMonths: interval(12),
                description: "Eye health check",
                priority: .routine
            ))

        // Skin conditions
        case .atopicDermatitis, .demodeticMange, .sebaceousAdenitis:
            results.append(ConditionFollowUp(
                conditionType: conditionType,
                followUpType: .generalCheckup,
                recommendedIntervalMonths: interval(6),
                description: "Skin condition assessment",
                priority: .routine
            ))

        // Cancer conditions
        case .mastCellTumor, .lymphoma, .osteosarcoma, .hemangiosarcoma:
            results.append(ConditionFollowUp(
                conditionType: conditionType,
                followUpType: .specialist,
                recommendedIntervalMonths: interval(3),
                description: "Oncologist follow-up",
                priority: .critical
            ))
            results.append(ConditionFollowUp(
                conditionType: conditionType,
                followUpType: .imaging,
                recommendedIntervalMonths: interval(3),
                description: "Staging imaging",
                priority: .critical
            ))

        // Cognitive conditions
        case .canineCognitiveDysfunction:
            results.append(ConditionFollowUp(
                conditionType: .canineCognitiveDysfunction,
                followUpType: .generalCheckup,
                recommendedIntervalMonths: interval(6),
                description: "Cognitive function assessment",
                priority: .routine
            ))
            results.append(ConditionFollowUp(
                conditionType: .canineCognitiveDysfunction,
                followUpType: .bloodWork,
                recommendedIntervalMonths: interval(12),
                description: "Senior bloodwork panel",
                priority: .routine
            ))

        // Respiratory conditions
        case .laryngealParalysis, .collapsedTrachea, .brachycephalicSyndrome:
            results.append(ConditionFollowUp(
                conditionType: conditionType,
                followUpType: .generalCheckup,
                recommendedIntervalMonths: interval(6),
                description: "Respiratory assessment",
                priority: .important
            ))

        // Ear conditions
        case .chronicOtitis:
            results.append(ConditionFollowUp(
                conditionType: .chronicOtitis,
                followUpType: .generalCheckup,
                recommendedIntervalMonths: interval(3),
                description: "Ear examination and cleaning assessment",
                priority: .routine
            ))

        default:
            // Generic follow-up for conditions without specific protocols
            results.append(ConditionFollowUp(
                conditionType: conditionType,
                followUpType: .generalCheckup,
                recommendedIntervalMonths: interval(6),
                description: "Condition monitoring",
                priority: .routine
            ))
        }

        return results
    }

    /// Returns all follow-ups for multiple conditions, deduplicated by type
    public static func allFollowUps(for conditions: [HealthCondition]) -> [ConditionFollowUp] {
        var seen: Set<String> = []
        var results: [ConditionFollowUp] = []

        for condition in conditions where condition.status == .active || condition.status == .monitoring {
            let followUps = self.followUps(for: condition)
            for followUp in followUps {
                // Keep the one with shorter interval if duplicate type exists
                if !seen.contains(followUp.followUpType.rawValue) {
                    seen.insert(followUp.followUpType.rawValue)
                    results.append(followUp)
                }
            }
        }

        return results.sorted { $0.priority.colorName > $1.priority.colorName }
    }
}

// MARK: - Follow-Up Status

public struct FollowUpStatus: Sendable, Equatable {
    public let followUp: ConditionFollowUp
    public let lastCompleted: Date?
    public let nextDue: Date
    public let isOverdue: Bool
    public let daysUntilDue: Int

    public init(followUp: ConditionFollowUp, lastCompleted: Date?) {
        self.followUp = followUp
        self.lastCompleted = lastCompleted

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastCompleted = lastCompleted {
            self.nextDue = calendar.date(
                byAdding: .month,
                value: followUp.recommendedIntervalMonths,
                to: lastCompleted
            ) ?? today
        } else {
            // If never completed, it's due now
            self.nextDue = today
        }

        self.isOverdue = nextDue < today
        self.daysUntilDue = calendar.dateComponents([.day], from: today, to: nextDue).day ?? 0
    }

    public var urgencyDescription: String {
        if isOverdue {
            let daysOverdue = abs(daysUntilDue)
            if daysOverdue > 30 {
                return "Overdue by \(daysOverdue / 30) month\(daysOverdue / 30 == 1 ? "" : "s")"
            } else {
                return "Overdue by \(daysOverdue) day\(daysOverdue == 1 ? "" : "s")"
            }
        } else if daysUntilDue == 0 {
            return "Due today"
        } else if daysUntilDue <= 7 {
            return "Due in \(daysUntilDue) day\(daysUntilDue == 1 ? "" : "s")"
        } else if daysUntilDue <= 30 {
            let weeks = daysUntilDue / 7
            return "Due in \(weeks) week\(weeks == 1 ? "" : "s")"
        } else {
            let months = daysUntilDue / 30
            return "Due in \(months) month\(months == 1 ? "" : "s")"
        }
    }
}
