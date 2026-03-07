//
//  AIContextComponents.swift
//  Ollie-app
//
//  Modular context components for AI function calls.
//  Each component encapsulates a specific domain of puppy data
//  that can be selectively included in AI requests.
//

import Foundation
import OtisShared

// MARK: - Context Component Protocol

/// Protocol for modular context components that can be composed into AI requests.
/// Each component represents a specific domain of information.
protocol AIContextComponent: Codable, Sendable {
    /// Unique identifier for this component type
    static var componentKey: String { get }

    /// Approximate token cost for budget estimation
    static var estimatedTokens: Int { get }
}

// MARK: - Dog Identity Context

/// Core identity information about the dog (always included).
/// Uses pseudonymized name for privacy.
struct DogIdentityContext: AIContextComponent {
    static let componentKey = "dog_identity"
    static let estimatedTokens = 50

    /// Pseudonymized identifier (first letter + last letter of name)
    let pseudonym: String

    /// Age in weeks
    let ageWeeks: Int

    /// Age in months (for easier LLM interpretation)
    let ageMonths: Int

    /// Days since coming home (attachment/adjustment context)
    let daysHome: Int

    /// Size category affects exercise limits, feeding, etc.
    let sizeCategory: String

    /// Breed group for breed-specific considerations (nil if unknown)
    let breedGroup: String?

    /// Life stage for age-appropriate recommendations
    let lifeStage: String

    init(profile: PuppyProfile) {
        // Pseudonymize: first + last letter (e.g., "Luna" -> "La")
        let name = profile.name.trimmingCharacters(in: .whitespaces)
        let first = name.first.map(String.init) ?? "X"
        let last = name.last.map(String.init) ?? "X"
        self.pseudonym = "\(first)\(last)"

        self.ageWeeks = profile.ageInWeeks
        self.ageMonths = profile.ageInMonths
        self.daysHome = profile.daysHome
        self.sizeCategory = profile.sizeCategory.rawValue
        self.breedGroup = profile.breed // TODO: Map to breed group

        // Determine life stage
        if profile.ageInWeeks < 8 {
            self.lifeStage = "neonatal"
        } else if profile.ageInWeeks < 12 {
            self.lifeStage = "early_puppy"
        } else if profile.ageInWeeks < 24 {
            self.lifeStage = "puppy"
        } else if profile.ageInMonths < 12 {
            self.lifeStage = "adolescent"
        } else if profile.ageInMonths < 24 {
            self.lifeStage = "young_adult"
        } else {
            self.lifeStage = "adult"
        }
    }
}

// MARK: - Household Context

/// Information about household members involved in puppy care.
struct HouseholdContext: AIContextComponent {
    static let componentKey = "household"
    static let estimatedTokens = 30

    /// Number of household members involved
    let memberCount: Int

    /// Pseudonymized member roles (e.g., ["M1": "owner", "M2": "comanager"])
    let memberRoles: [String: String]

    init(profile: PuppyProfile) {
        let members = profile.householdMembers.members
        self.memberCount = members.count

        var roles: [String: String] = [:]
        for (index, member) in members.enumerated() {
            let key = "M\(index + 1)"
            // HouseholdMember doesn't have a role property - use isCurrentUser to differentiate
            roles[key] = member.isCurrentUser ? "primary" : "member"
        }
        self.memberRoles = roles
    }
}

// MARK: - Potty Patterns Context

/// Potty training progress and patterns.
struct PottyPatternsContext: AIContextComponent {
    static let componentKey = "potty_patterns"
    static let estimatedTokens = 120

    /// Minutes since last pee
    let minutesSinceLastPee: Int?

    /// Minutes since last poop
    let minutesSinceLastPoop: Int?

    /// Median gap between pees (last 7 days)
    let medianPeeGapMinutes: Int?

    /// Current outdoor streak count
    let outdoorStreakCount: Int

    /// Success rate (outdoor / total) last 24h
    let last24hSuccessRate: Double?

    /// Whether currently in an urgent window
    let isUrgent: Bool

    /// Predicted minutes until next potty need
    let predictedMinutesUntilNext: Int?

    /// Time of day patterns (e.g., "morning_heavy", "evening_light")
    let timeOfDayPattern: String?

    init(events: [PuppyEvent], prediction: PottyPrediction?, gapStats: GapStats?) {
        let now = Date()
        let pees = events.pee()
        let poops = events.poop()

        if let lastPee = pees.first {
            self.minutesSinceLastPee = Int(now.timeIntervalSince(lastPee.time) / 60)
        } else {
            self.minutesSinceLastPee = nil
        }

        if let lastPoop = poops.first {
            self.minutesSinceLastPoop = Int(now.timeIntervalSince(lastPoop.time) / 60)
        } else {
            self.minutesSinceLastPoop = nil
        }

        self.medianPeeGapMinutes = gapStats?.medianMinutes

        // Calculate outdoor streak
        var streak = 0
        for event in pees {
            if event.location == .buiten {
                streak += 1
            } else {
                break
            }
        }
        self.outdoorStreakCount = streak

        // 24h success rate
        let last24h = events.filter { now.timeIntervalSince($0.time) <= 24 * 3600 }
        let pottyEvents = last24h.filter { $0.type == .plassen || $0.type == .poepen }
        let outdoorCount = pottyEvents.filter { $0.location == .buiten }.count
        if !pottyEvents.isEmpty {
            self.last24hSuccessRate = Double(outdoorCount) / Double(pottyEvents.count)
        } else {
            self.last24hSuccessRate = nil
        }

        if let prediction = prediction {
            // Check urgency based on enum cases
            switch prediction.urgency {
            case .soon, .overdue, .postAccident:
                self.isUrgent = true
            default:
                self.isUrgent = false
            }
            // Calculate minutes until next from expectedGap and minutesSinceLast
            if let minutesSince = prediction.minutesSinceLast {
                self.predictedMinutesUntilNext = max(0, prediction.expectedGapMinutes - minutesSince)
            } else {
                self.predictedMinutesUntilNext = prediction.expectedGapMinutes
            }
        } else {
            self.isUrgent = false
            self.predictedMinutesUntilNext = nil
        }

        self.timeOfDayPattern = nil // TODO: Implement pattern detection
    }
}

// MARK: - Sleep Context

/// Current sleep state and patterns.
struct SleepContext: AIContextComponent {
    static let componentKey = "sleep"
    static let estimatedTokens = 60

    /// Whether currently sleeping
    let isSleeping: Bool

    /// Minutes asleep (if sleeping)
    let minutesAsleep: Int?

    /// Minutes awake (if awake)
    let minutesAwake: Int?

    /// Night sleep last night (hours)
    let lastNightSleepHours: Double?

    /// Number of naps today
    let napsToday: Int

    /// Total nap minutes today
    let napMinutesToday: Int

    init(events: [PuppyEvent], sleepState: SleepState) {
        self.isSleeping = sleepState.isSleeping

        // Extract duration from enum associated values
        switch sleepState {
        case .sleeping(_, let durationMin):
            self.minutesAsleep = durationMin
            self.minutesAwake = nil
        case .awake(_, let durationMin):
            self.minutesAsleep = nil
            self.minutesAwake = durationMin
        case .unknown:
            self.minutesAsleep = nil
            self.minutesAwake = nil
        }

        // Calculate night sleep from events
        // TODO: Pull from SleepCalculations
        self.lastNightSleepHours = nil

        // Count today's naps
        let today = Calendar.current.startOfDay(for: Date())
        let todayEvents = events.filter { $0.time >= today }
        let sleepEvents = todayEvents.filter { $0.type == .slapen }
        let wakeEvents = todayEvents.filter { $0.type == .ontwaken }

        self.napsToday = sleepEvents.count

        // Calculate nap duration (simplified)
        var totalNapMinutes = 0
        for sleepEvent in sleepEvents {
            if let wakeEvent = wakeEvents.first(where: { $0.time > sleepEvent.time }) {
                let duration = wakeEvent.time.timeIntervalSince(sleepEvent.time) / 60
                if duration < 180 { // Naps < 3 hours
                    totalNapMinutes += Int(duration)
                }
            }
        }
        self.napMinutesToday = totalNapMinutes
    }
}

// MARK: - Feeding Context

/// Meal and feeding patterns.
struct FeedingContext: AIContextComponent {
    static let componentKey = "feeding"
    static let estimatedTokens = 50

    /// Meals per day (from schedule)
    let scheduledMealsPerDay: Int

    /// Meals logged today
    let mealsLoggedToday: Int

    /// Minutes since last meal
    let minutesSinceLastMeal: Int?

    /// Water events in last 2 hours
    let waterEventsLast2h: Int

    init(profile: PuppyProfile, events: [PuppyEvent]) {
        self.scheduledMealsPerDay = profile.mealSchedule.mealsPerDay

        let today = Calendar.current.startOfDay(for: Date())
        let todayEvents = events.filter { $0.time >= today }
        self.mealsLoggedToday = todayEvents.meals().count

        if let lastMeal = events.meals().first {
            self.minutesSinceLastMeal = Int(Date().timeIntervalSince(lastMeal.time) / 60)
        } else {
            self.minutesSinceLastMeal = nil
        }

        let twoHoursAgo = Date().addingTimeInterval(-2 * 3600)
        self.waterEventsLast2h = events.filter { $0.type == .drinken && $0.time >= twoHoursAgo }.count
    }
}

// MARK: - Exercise Context

/// Exercise and activity patterns.
struct ExerciseContext: AIContextComponent {
    static let componentKey = "exercise"
    static let estimatedTokens = 60

    /// Maximum exercise minutes (age-appropriate)
    let maxExerciseMinutes: Int

    /// Exercise minutes logged today
    let exerciseMinutesToday: Int

    /// Number of walks today
    let walksToday: Int

    /// Minutes since last walk
    let minutesSinceLastWalk: Int?

    /// Yard/garden visits today
    let yardVisitsToday: Int

    init(profile: PuppyProfile, events: [PuppyEvent]) {
        self.maxExerciseMinutes = profile.maxExerciseMinutes

        let today = Calendar.current.startOfDay(for: Date())
        let todayEvents = events.filter { $0.time >= today }

        let walks = todayEvents.walks()
        self.walksToday = walks.count
        self.exerciseMinutesToday = walks.compactMap { $0.durationMin }.reduce(0, +)

        if let lastWalk = events.walks().first {
            self.minutesSinceLastWalk = Int(Date().timeIntervalSince(lastWalk.time) / 60)
        } else {
            self.minutesSinceLastWalk = nil
        }

        self.yardVisitsToday = todayEvents.filter { $0.type == .tuin }.count
    }
}

// MARK: - Training Progress Context

/// Skills training progress summary.
struct TrainingProgressContext: AIContextComponent {
    static let componentKey = "training"
    static let estimatedTokens = 200

    /// Total skills started
    let skillsStarted: Int

    /// Skills in active learning phases
    let skillsInLearning: Int

    /// Skills in maintenance
    let skillsInMaintenance: Int

    /// Skills needing remediation
    let skillsNeedingWork: Int

    /// Average confidence across started skills
    let averageConfidence: Double

    /// Training sessions in last 7 days
    let sessionsLast7Days: Int

    /// Average days between sessions (consistency metric)
    let averageSessionGapDays: Double?

    /// Recent regressions (last 14 days)
    let recentRegressionCount: Int

    /// Skills due for review
    let skillsDueForReview: Int

    /// Pace warning if any
    let paceWarning: String?

    /// Suggested next skill to focus on
    let suggestedNextSkill: String?

    init(summary: TrainingAISummary) {
        self.skillsStarted = summary.stats.totalSkillsStarted
        self.skillsInLearning = summary.stats.skillsInLearning
        self.skillsInMaintenance = summary.stats.skillsInMaintenance
        self.skillsNeedingWork = summary.stats.skillsNeedingWork
        self.averageConfidence = summary.stats.averageConfidence
        self.sessionsLast7Days = summary.stats.sessionsLast7Days
        self.averageSessionGapDays = summary.averageSessionGapDays
        self.recentRegressionCount = summary.recentRegressions.count
        self.skillsDueForReview = summary.skillsDueForReview.count
        self.paceWarning = summary.paceWarning?.type.rawValue
        self.suggestedNextSkill = summary.suggestedNextSkill
    }

    /// Lightweight initializer when full summary unavailable
    init() {
        self.skillsStarted = 0
        self.skillsInLearning = 0
        self.skillsInMaintenance = 0
        self.skillsNeedingWork = 0
        self.averageConfidence = 0
        self.sessionsLast7Days = 0
        self.averageSessionGapDays = nil
        self.recentRegressionCount = 0
        self.skillsDueForReview = 0
        self.paceWarning = nil
        self.suggestedNextSkill = nil
    }
}

// MARK: - Training Detail Context (for training-specific calls)

/// Detailed training context for skill-specific AI guidance.
/// Only included in training-focused function calls.
struct TrainingDetailContext: AIContextComponent {
    static let componentKey = "training_detail"
    static let estimatedTokens = 400

    /// Skills grouped by phase with full details
    let skillsByPhase: [String: [SkillDetail]]

    /// Recent training sessions (last 7 days)
    let recentSessions: [SessionDetail]

    /// Regression history for pattern detection
    let regressionHistory: [String: Int]

    /// Stale skills that need attention
    let staleSkills: [StaleSkillDetail]

    /// Contexts explored (generalization breadth)
    let contextsExploredCount: Int

    struct SkillDetail: Codable, Sendable {
        let skillId: String
        let confidence: Double
        let totalReps: Int
        let daysSinceLastPractice: Int?
        let maintenanceTier: Int?
        let proofingProgress: Double? // 0-1 combined 3D progress
    }

    struct SessionDetail: Codable, Sendable {
        let skillId: String
        let daysAgo: Int
        let successRate: Double
        let context: String?
    }

    struct StaleSkillDetail: Codable, Sendable {
        let skillId: String
        let daysSinceLastPractice: Int
        let phase: String
        let riskLevel: String
    }

    init(summary: TrainingAISummary) {
        var byPhase: [String: [SkillDetail]] = [:]
        for (phase, snapshots) in summary.skillsByPhase {
            byPhase[phase] = snapshots.map { snapshot in
                SkillDetail(
                    skillId: snapshot.skillId,
                    confidence: snapshot.confidenceScore,
                    totalReps: snapshot.totalReps,
                    daysSinceLastPractice: snapshot.daysSinceLastPractice,
                    maintenanceTier: snapshot.maintenanceTier,
                    proofingProgress: snapshot.proofingProgress?.overallProgress
                )
            }
        }
        self.skillsByPhase = byPhase

        let now = Date()
        self.recentSessions = summary.recentSessions.prefix(10).map { session in
            let daysAgo = Calendar.current.dateComponents([.day], from: session.timestamp, to: now).day ?? 0
            return SessionDetail(
                skillId: session.skillId,
                daysAgo: daysAgo,
                successRate: session.successRate,
                context: session.context
            )
        }

        self.regressionHistory = summary.regressionHistory

        self.staleSkills = summary.staleSkilIs.map { stale in
            StaleSkillDetail(
                skillId: stale.skillId,
                daysSinceLastPractice: stale.daysSinceLastPractice,
                phase: stale.phase,
                riskLevel: stale.riskLevel
            )
        }

        self.contextsExploredCount = summary.contextsExplored.count
    }
}

// MARK: - Socialization Context

/// Socialization progress and window status.
struct SocializationContext: AIContextComponent {
    static let componentKey = "socialization"
    static let estimatedTokens = 100

    /// Whether in critical socialization window (8-16 weeks)
    let inCriticalWindow: Bool

    /// Weeks remaining in critical window
    let weeksRemainingInWindow: Int?

    /// Overall socialization progress (0-1)
    let overallProgress: Double

    /// Exposures logged this week
    let exposuresThisWeek: Int

    /// Categories with low exposure
    let lowExposureCategories: [String]

    /// Categories completed
    let completedCategories: Int

    init(profile: PuppyProfile, socializationProgress: SocializationProgress?) {
        let ageWeeks = profile.ageInWeeks
        self.inCriticalWindow = ageWeeks >= 8 && ageWeeks <= 16

        if inCriticalWindow {
            self.weeksRemainingInWindow = max(0, 16 - ageWeeks)
        } else {
            self.weeksRemainingInWindow = nil
        }

        if let progress = socializationProgress {
            self.overallProgress = progress.overallProgress
            self.exposuresThisWeek = progress.exposuresThisWeek
            self.lowExposureCategories = progress.lowExposureCategories
            self.completedCategories = progress.completedCategories
        } else {
            self.overallProgress = 0
            self.exposuresThisWeek = 0
            self.lowExposureCategories = []
            self.completedCategories = 0
        }
    }
}

/// Lightweight progress info for socialization (computed externally)
struct SocializationProgress {
    let overallProgress: Double
    let exposuresThisWeek: Int
    let lowExposureCategories: [String]
    let completedCategories: Int
}

// MARK: - Recent Events Summary

/// Summary of recent logged events for pattern context.
struct RecentEventsSummary: AIContextComponent {
    static let componentKey = "recent_events"
    static let estimatedTokens = 80

    /// Total events in last 24 hours
    let eventsLast24h: Int

    /// Events by type (last 24h)
    let eventsByType: [String: Int]

    /// Hours since last logged event
    let hoursSinceLastEvent: Double?

    /// Logging consistency (events per day, last 7 days)
    let avgEventsPerDay: Double

    init(events: [PuppyEvent]) {
        let now = Date()
        let last24h = events.filter { now.timeIntervalSince($0.time) <= 24 * 3600 }
        self.eventsLast24h = last24h.count

        var byType: [String: Int] = [:]
        for event in last24h {
            byType[event.type.rawValue, default: 0] += 1
        }
        self.eventsByType = byType

        if let lastEvent = events.first {
            self.hoursSinceLastEvent = now.timeIntervalSince(lastEvent.time) / 3600
        } else {
            self.hoursSinceLastEvent = nil
        }

        // Calculate 7-day average
        let sevenDaysAgo = now.addingTimeInterval(-7 * 24 * 3600)
        let last7Days = events.filter { $0.time >= sevenDaysAgo }
        self.avgEventsPerDay = Double(last7Days.count) / 7.0
    }
}

// MARK: - Health Context

/// Health and wellness information.
struct HealthContext: AIContextComponent {
    static let componentKey = "health"
    static let estimatedTokens = 70

    /// Most recent weight (kg)
    let currentWeightKg: Double?

    /// Days since last weight log
    let daysSinceLastWeight: Int?

    /// Weight trend (gaining/stable/losing)
    let weightTrend: String?

    /// Any active medications
    let hasActiveMedications: Bool

    /// Behavioral notes in last 7 days
    let behavioralNotesCount: Int

    init(profile: PuppyProfile, events: [PuppyEvent]) {
        // Find weight events
        let weightEvents = events.filter { $0.type == .gewicht }.sorted { $0.time > $1.time }

        if let latest = weightEvents.first, let weightStr = latest.note {
            // Parse weight from note (format: "X.X kg" or just "X.X")
            let cleaned = weightStr.replacingOccurrences(of: "kg", with: "").trimmingCharacters(in: .whitespaces)
            self.currentWeightKg = Double(cleaned)

            let days = Calendar.current.dateComponents([.day], from: latest.time, to: Date()).day
            self.daysSinceLastWeight = days
        } else {
            self.currentWeightKg = nil
            self.daysSinceLastWeight = nil
        }

        // Determine trend from last 3 weights
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
/// This provides direct signals that complement event-based inference.
struct UserSentimentContext: AIContextComponent {
    static let componentKey = "sentiment"
    static let estimatedTokens = 80

    /// Primary focus area the user wants help with (if set)
    let primaryFocus: String?

    /// Detected priority focus based on root cause analysis
    let detectedPriorityFocus: String?

    /// Explanation for why this is the priority
    let priorityReason: String?

    /// Categories where user is struggling (score 1-3)
    let strugglingAreas: [AreaRating]

    /// Root cause dependencies detected (e.g., "nipping depends on sleeping")
    let rootCauseDependencies: [String]

    /// Categories going well (score 4-5) - tips should be minimal
    let goingWellAreas: [String]

    /// Categories where tips should be completely muted (score 5)
    let mutedAreas: [String]

    /// Days since last sentiment check-in
    let daysSinceLastCheckIn: Int?

    struct AreaRating: Codable, Sendable {
        let area: String
        let score: Int
        let daysSinceRated: Int
    }

    /// Initialize with explicit state (for use from non-MainActor context)
    init(state: SentimentState) {
        self.primaryFocus = state.primaryFocus?.rawValue

        // Build struggling areas with scores
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

        // Detect root cause dependencies
        var dependencies: [String] = []
        for category in state.strugglingCategories {
            for dep in category.rootCauseDependencies {
                if let depCheckIn = state.checkIns[dep], depCheckIn.isStruggling {
                    dependencies.append("\(category.rawValue) depends on \(dep.rawValue)")
                }
            }
        }
        self.rootCauseDependencies = dependencies

        // Detect priority focus using tip provider logic
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

        // Going well (4-5) but not muted
        self.goingWellAreas = state.checkIns.values
            .filter { $0.isFresh && $0.isDoingWell && !$0.shouldMuteTips }
            .map { $0.category.rawValue }

        // Muted (score 5)
        self.mutedAreas = state.mutedCategories.map { $0.rawValue }

        // Days since last check-in
        if let lastDate = state.lastCheckInDate {
            self.daysSinceLastCheckIn = Calendar.current.dateComponents(
                [.day], from: lastDate, to: Date()
            ).day
        } else {
            self.daysSinceLastCheckIn = nil
        }
    }

    /// Initialize with no sentiment data (fallback)
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
