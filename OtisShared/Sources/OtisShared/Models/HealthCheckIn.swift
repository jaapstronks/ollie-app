//
//  HealthCheckIn.swift
//  OtisShared
//
//  Health check-in model for periodic Likert-scale health assessments
//  Part of Brief 04: Health Logging
//

import Foundation

// MARK: - Health Check-In Category

/// Categories for health check-ins (condition-dependent)
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
        case .mobility: return Strings.HealthLogging.checkInMobility
        case .energy: return Strings.HealthLogging.checkInEnergy
        case .appetite: return Strings.HealthLogging.checkInAppetite
        case .breathing: return Strings.HealthLogging.checkInBreathing
        case .comfort: return Strings.HealthLogging.checkInComfort
        case .cognition: return Strings.HealthLogging.checkInCognition
        case .skin: return Strings.HealthLogging.checkInSkin
        case .digestion: return Strings.HealthLogging.checkInDigestion
        case .vision: return Strings.HealthLogging.checkInVision
        case .hearing: return Strings.HealthLogging.checkInHearing
        case .overall: return Strings.HealthLogging.checkInOverall
        }
    }

    public var icon: String {
        switch self {
        case .mobility: return "figure.walk"
        case .energy: return "bolt.fill"
        case .appetite: return "fork.knife"
        case .breathing: return "lungs.fill"
        case .comfort: return "heart.fill"
        case .cognition: return "brain.head.profile"
        case .skin: return "hand.raised.fill"
        case .digestion: return "stomach"
        case .vision: return "eye.fill"
        case .hearing: return "ear.fill"
        case .overall: return "pawprint.fill"
        }
    }

    /// Generate the question text for this category
    public func question(for name: String) -> String {
        switch self {
        case .mobility:
            return Strings.HealthLogging.questionMobility(name: name)
        case .energy:
            return Strings.HealthLogging.questionEnergy(name: name)
        case .appetite:
            return Strings.HealthLogging.questionAppetite(name: name)
        case .breathing:
            return Strings.HealthLogging.questionBreathing(name: name)
        case .comfort:
            return Strings.HealthLogging.questionComfort(name: name)
        case .cognition:
            return Strings.HealthLogging.questionCognition(name: name)
        case .skin:
            return Strings.HealthLogging.questionSkin(name: name)
        case .digestion:
            return Strings.HealthLogging.questionDigestion(name: name)
        case .vision:
            return Strings.HealthLogging.questionVision(name: name)
        case .hearing:
            return Strings.HealthLogging.questionHearing(name: name)
        case .overall:
            return Strings.HealthLogging.questionOverall(name: name)
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
        case .vision:
            return [.cataracts, .glaucoma, .progressiveRetinalAtrophy]
        case .hearing:
            return []  // Age-related, no specific conditions
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

// MARK: - Health Check-In

/// A user's periodic health rating
public struct HealthCheckIn: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var category: HealthCheckInCategory
    public var score: Int  // 1-5
    public var relatedConditionId: UUID?  // Optional link to specific condition
    public var note: String?
    public var contextSummary: String?  // What we showed them about recent symptoms
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        category: HealthCheckInCategory,
        score: Int,
        relatedConditionId: UUID? = nil,
        note: String? = nil,
        contextSummary: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.score = max(1, min(5, score))
        self.relatedConditionId = relatedConditionId
        self.note = note
        self.contextSummary = contextSummary
        self.createdAt = createdAt
    }

    /// Whether this rating indicates struggling (1-2)
    public var isStruggling: Bool { score <= 2 }

    /// Whether this rating indicates okay (3)
    public var isOkay: Bool { score == 3 }

    /// Whether this rating indicates doing well (4-5)
    public var isDoingWell: Bool { score >= 4 }

    /// Score description
    public var scoreDescription: String {
        switch score {
        case 1: return Strings.HealthLogging.ratingPoor
        case 2: return Strings.HealthLogging.ratingNotGreat
        case 3: return Strings.HealthLogging.ratingOkay
        case 4: return Strings.HealthLogging.ratingGood
        case 5: return Strings.HealthLogging.ratingGreat
        default: return Strings.HealthLogging.ratingOkay
        }
    }

    /// Age of this check-in in days
    public var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }

    /// Whether this check-in is still fresh enough to use (within 7 days)
    public var isFresh: Bool {
        ageInDays <= 7
    }
}

// MARK: - Health State

/// Aggregated health state for AI context
public struct HealthState: Codable, Sendable {
    public let checkIns: [HealthCheckInCategory: HealthCheckIn]
    public let lastCheckInDate: Date?
    public let recentSymptomCount: Int
    public let activeConditionCount: Int

    public init(
        checkIns: [HealthCheckInCategory: HealthCheckIn],
        lastCheckInDate: Date? = nil,
        recentSymptomCount: Int = 0,
        activeConditionCount: Int = 0
    ) {
        self.checkIns = checkIns
        self.lastCheckInDate = lastCheckInDate
        self.recentSymptomCount = recentSymptomCount
        self.activeConditionCount = activeConditionCount
    }

    /// Categories where the dog is struggling (score 1-2, fresh)
    public var strugglingCategories: [HealthCheckInCategory] {
        checkIns.values
            .filter { $0.isFresh && $0.isStruggling }
            .sorted { $0.score < $1.score }  // Most struggling first
            .map { $0.category }
    }

    /// Get the latest score for a category, if fresh
    public func score(for category: HealthCheckInCategory) -> Int? {
        guard let checkIn = checkIns[category], checkIn.isFresh else { return nil }
        return checkIn.score
    }

    /// Average health score across all fresh check-ins
    public var averageScore: Double? {
        let freshCheckIns = checkIns.values.filter { $0.isFresh }
        guard !freshCheckIns.isEmpty else { return nil }
        let total = freshCheckIns.reduce(0) { $0 + $1.score }
        return Double(total) / Double(freshCheckIns.count)
    }
}
