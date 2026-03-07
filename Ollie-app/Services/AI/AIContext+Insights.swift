//
//  AIContext+Insights.swift
//  Ollie-app
//
//  Insights AI context components: Health, User Sentiment, Behavior Challenges
//

import Foundation
import OtisShared

// MARK: - Health Context

/// Health and wellness information.
struct HealthContext: AIContextComponent {
    static let componentKey = "health"
    static let estimatedTokens = 70

    let currentWeightKg: Double?
    let daysSinceLastWeight: Int?
    let weightTrend: String?
    let hasActiveMedications: Bool
    let behavioralNotesCount: Int

    init(profile: PuppyProfile, events: [PuppyEvent]) {
        let weightEvents = events.filter { $0.type == .gewicht }.sorted { $0.time > $1.time }

        if let latest = weightEvents.first, let weightStr = latest.note {
            let cleaned = weightStr.replacingOccurrences(of: "kg", with: "").trimmingCharacters(in: .whitespaces)
            self.currentWeightKg = Double(cleaned)
            self.daysSinceLastWeight = Calendar.current.dateComponents([.day], from: latest.time, to: Date()).day
        } else {
            self.currentWeightKg = nil
            self.daysSinceLastWeight = nil
        }

        if weightEvents.count >= 3 {
            let weights = weightEvents.prefix(3).compactMap { event -> Double? in
                guard let note = event.note else { return nil }
                let cleaned = note.replacingOccurrences(of: "kg", with: "").trimmingCharacters(in: .whitespaces)
                return Double(cleaned)
            }

            if weights.count >= 2 {
                let diff = weights[0] - weights[weights.count - 1]
                if diff > 0.2 {
                    self.weightTrend = "gaining"
                } else if diff < -0.2 {
                    self.weightTrend = "losing"
                } else {
                    self.weightTrend = "stable"
                }
            } else {
                self.weightTrend = nil
            }
        } else {
            self.weightTrend = nil
        }

        self.hasActiveMedications = !profile.medicationSchedule.medications.isEmpty

        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        self.behavioralNotesCount = events.filter {
            $0.type == .gedrag && $0.time >= sevenDaysAgo
        }.count
    }
}

// MARK: - User Sentiment Context

/// User's self-reported sentiment on how various areas are going.
struct UserSentimentContext: AIContextComponent {
    static let componentKey = "sentiment"
    static let estimatedTokens = 80

    let primaryFocus: String?
    let detectedPriorityFocus: String?
    let priorityReason: String?
    let strugglingAreas: [AreaRating]
    let rootCauseDependencies: [String]
    let goingWellAreas: [String]
    let mutedAreas: [String]
    let daysSinceLastCheckIn: Int?

    struct AreaRating: Codable, Sendable {
        let area: String
        let score: Int
        let daysSinceRated: Int
    }

    init(state: SentimentState) {
        self.primaryFocus = state.primaryFocus?.rawValue

        var struggling: [AreaRating] = []
        for category in state.strugglingCategories {
            if let checkIn = state.checkIns[category], checkIn.isFresh {
                struggling.append(AreaRating(
                    area: category.rawValue,
                    score: checkIn.score,
                    daysSinceRated: checkIn.ageInDays
                ))
            }
        }
        self.strugglingAreas = struggling

        var dependencies: [String] = []
        for category in state.strugglingCategories {
            for dep in category.rootCauseDependencies {
                if let depCheckIn = state.checkIns[dep], depCheckIn.isStruggling {
                    dependencies.append("\(category.rawValue) depends on \(dep.rawValue)")
                }
            }
        }
        self.rootCauseDependencies = dependencies

        if let (priority, reason) = SentimentTipProvider.identifyPrimaryFocus(
            strugglingCategories: state.strugglingCategories,
            checkIns: state.checkIns
        ) {
            self.detectedPriorityFocus = priority.rawValue
            self.priorityReason = reason
        } else {
            self.detectedPriorityFocus = nil
            self.priorityReason = nil
        }

        self.goingWellAreas = state.checkIns.values
            .filter { $0.isFresh && $0.isDoingWell && !$0.shouldMuteTips }
            .map { $0.category.rawValue }

        self.mutedAreas = state.mutedCategories.map { $0.rawValue }

        if let lastDate = state.lastCheckInDate {
            self.daysSinceLastCheckIn = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
        } else {
            self.daysSinceLastCheckIn = nil
        }
    }

    init() {
        self.primaryFocus = nil
        self.detectedPriorityFocus = nil
        self.priorityReason = nil
        self.strugglingAreas = []
        self.rootCauseDependencies = []
        self.goingWellAreas = []
        self.mutedAreas = []
        self.daysSinceLastCheckIn = nil
    }
}

// MARK: - Behavior Challenges Context

/// Context about behavior challenges and interventions.
struct BehaviorChallengesContext: AIContextComponent {
    static let componentKey = "behavior"
    static let estimatedTokens = 120

    let activeIssues: [BehaviorIssue]
    let incidentsThisWeek: Int
    let incidentsLastWeek: Int
    let overallTrend: String
    let activeInterventions: [InterventionSummary]
    let daysSinceLastIncident: Int?

    struct BehaviorIssue: Codable, Sendable {
        let category: String
        let incidentsThisWeek: Int
        let incidentsLastWeek: Int
        let trend: String
        let commonTriggers: [String]
    }

    struct InterventionSummary: Codable, Sendable {
        let name: String
        let category: String
        let practiceCountThisWeek: Int
        let daysSinceLastPractice: Int?
    }

    init(events: [PuppyEvent], interventions: [BehaviorIntervention]) {
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now

        let behaviorEvents = events.filter { $0.isBehaviorIncident }.thisMonth()
        let thisWeekEvents = behaviorEvents.filter { $0.time.isThisWeek }
        let lastWeekEvents = behaviorEvents.filter { $0.time.isLastWeek }

        self.incidentsThisWeek = thisWeekEvents.count
        self.incidentsLastWeek = lastWeekEvents.count

        if lastWeekEvents.isEmpty && !thisWeekEvents.isEmpty {
            self.overallTrend = "new"
        } else if thisWeekEvents.count < lastWeekEvents.count {
            self.overallTrend = "improving"
        } else if thisWeekEvents.count > lastWeekEvents.count {
            self.overallTrend = "worsening"
        } else {
            self.overallTrend = "stable"
        }

        let grouped = Dictionary(grouping: behaviorEvents) { $0.behaviorCategoryEnum }
        var issues: [BehaviorIssue] = []

        for (category, categoryEvents) in grouped {
            guard let cat = category else { continue }

            let thisWeek = categoryEvents.filter { $0.time.isThisWeek }.count
            let lastWeek = categoryEvents.filter { $0.time.isLastWeek }.count

            let trend: String
            if lastWeek == 0 && thisWeek > 0 {
                trend = "new"
            } else if thisWeek < lastWeek {
                trend = "improving"
            } else if thisWeek > lastWeek {
                trend = "worsening"
            } else {
                trend = "stable"
            }

            let triggers = categoryEvents.compactMap { $0.behaviorTrigger }
            let triggerCounts = Dictionary(grouping: triggers) { $0 }.mapValues { $0.count }
            let topTriggers = triggerCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }

            issues.append(BehaviorIssue(
                category: cat.rawValue,
                incidentsThisWeek: thisWeek,
                incidentsLastWeek: lastWeek,
                trend: trend,
                commonTriggers: topTriggers
            ))
        }

        self.activeIssues = issues.sorted { $0.incidentsThisWeek > $1.incidentsThisWeek }

        if let lastIncident = behaviorEvents.max(by: { $0.time < $1.time }) {
            self.daysSinceLastIncident = Date().daysSince(lastIncident.time)
        } else {
            self.daysSinceLastIncident = nil
        }

        self.activeInterventions = interventions.filter { $0.isActive }.map { intervention in
            InterventionSummary(
                name: intervention.name,
                category: intervention.category.rawValue,
                practiceCountThisWeek: intervention.practiceCountThisWeek,
                daysSinceLastPractice: intervention.daysSinceLastPractice
            )
        }
    }

    init() {
        self.activeIssues = []
        self.incidentsThisWeek = 0
        self.incidentsLastWeek = 0
        self.overallTrend = "stable"
        self.activeInterventions = []
        self.daysSinceLastIncident = nil
    }
}

// MARK: - Senior Wellness Context

/// Senior dog wellness assessment data for AI context.
struct SeniorWellnessContext: AIContextComponent {
    static let componentKey = "senior_wellness"
    static let estimatedTokens = 100

    let isSenior: Bool
    let latestMobilityScore: Int?
    let mobilityTrend: String?
    let latestCCDScore: Int?
    let ccdSeverity: String?
    let latestQoLScore: Int?
    let qolInterpretation: String?
    let activeConditions: [String]
    let medicationCount: Int
    let daysWithSymptoms: Int

    init(profile: PuppyProfile) {
        self.isSenior = profile.lifecyclePhase == .senior

        let wellnessStore = SeniorWellnessStore.shared

        // Mobility
        if let mobility = wellnessStore.latestMobility, mobility.isFresh {
            self.latestMobilityScore = mobility.score
        } else {
            self.latestMobilityScore = nil
        }
        self.mobilityTrend = wellnessStore.mobilityState.trend?.rawValue

        // Cognitive
        if let cognitive = wellnessStore.latestCognitive, cognitive.isCurrent {
            self.latestCCDScore = cognitive.totalScore
            self.ccdSeverity = cognitive.severity.rawValue
        } else {
            self.latestCCDScore = nil
            self.ccdSeverity = nil
        }

        // Quality of Life
        if let qol = wellnessStore.latestQoL, qol.isCurrent {
            self.latestQoLScore = qol.totalScore
            self.qolInterpretation = qol.interpretation.rawValue
        } else {
            self.latestQoLScore = nil
            self.qolInterpretation = nil
        }

        // Conditions and medications
        self.activeConditions = profile.healthConditions
            .filter { $0.status == .active }
            .map { $0.type.rawValue }

        self.medicationCount = profile.medicationSchedule.medications.count

        // Recent symptoms
        self.daysWithSymptoms = HealthSymptomStore.shared.recentSymptoms().count
    }

    init() {
        self.isSenior = false
        self.latestMobilityScore = nil
        self.mobilityTrend = nil
        self.latestCCDScore = nil
        self.ccdSeverity = nil
        self.latestQoLScore = nil
        self.qolInterpretation = nil
        self.activeConditions = []
        self.medicationCount = 0
        self.daysWithSymptoms = 0
    }
}
