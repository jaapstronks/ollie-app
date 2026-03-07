//
//  SentimentCheckIn.swift
//  Ollie-app
//
//  User sentiment ratings for key puppy care areas.
//  These direct signals complement (or replace) event-based inference.
//

import Foundation

// MARK: - Sentiment Category

/// Areas where we collect user sentiment ratings.
enum SentimentCategory: String, Codable, CaseIterable, Identifiable {
    // Core categories (always relevant)
    case pottyTraining = "potty_training"
    case benchTraining = "bench_training"
    case sleeping = "sleeping"
    case walks = "walks"
    case skillsTraining = "skills_training"

    // Behavior categories (age-dependent)
    case nipping = "nipping"
    case leashBehavior = "leash_behavior"
    case jumping = "jumping"
    case resourceGuarding = "resource_guarding"
    case chewing = "chewing"
    case barking = "barking"

    // Situational categories
    case separationAnxiety = "separation_anxiety"
    case carTravel = "car_travel"
    case handlingTolerance = "handling_tolerance"

    var id: String { rawValue }

    /// Display name for the category.
    var displayName: String {
        switch self {
        case .pottyTraining: return Strings.Sentiment.categoryPotty
        case .benchTraining: return Strings.Sentiment.categoryBench
        case .sleeping: return Strings.Sentiment.categorySleeping
        case .walks: return Strings.Sentiment.categoryWalks
        case .skillsTraining: return Strings.Sentiment.categorySkills
        case .nipping: return Strings.Sentiment.categoryNipping
        case .leashBehavior: return Strings.Sentiment.categoryLeash
        case .jumping: return Strings.Sentiment.categoryJumping
        case .resourceGuarding: return Strings.Sentiment.categoryResourceGuarding
        case .chewing: return Strings.Sentiment.categoryChewing
        case .barking: return Strings.Sentiment.categoryBarking
        case .separationAnxiety: return Strings.Sentiment.categorySeparation
        case .carTravel: return Strings.Sentiment.categoryCar
        case .handlingTolerance: return Strings.Sentiment.categoryHandling
        }
    }

    /// The question to ask for this category.
    var questionText: String {
        switch self {
        case .pottyTraining: return Strings.Sentiment.questionPotty
        case .benchTraining: return Strings.Sentiment.questionBench
        case .sleeping: return Strings.Sentiment.questionSleeping
        case .walks: return Strings.Sentiment.questionWalks
        case .skillsTraining: return Strings.Sentiment.questionSkills
        case .nipping: return Strings.Sentiment.questionNipping
        case .leashBehavior: return Strings.Sentiment.questionLeash
        case .jumping: return Strings.Sentiment.questionJumping
        case .resourceGuarding: return Strings.Sentiment.questionResourceGuarding
        case .chewing: return Strings.Sentiment.questionChewing
        case .barking: return Strings.Sentiment.questionBarking
        case .separationAnxiety: return Strings.Sentiment.questionSeparation
        case .carTravel: return Strings.Sentiment.questionCar
        case .handlingTolerance: return Strings.Sentiment.questionHandling
        }
    }

    /// SF Symbol icon for this category.
    var iconName: String {
        switch self {
        case .pottyTraining: return "drop.fill"
        case .benchTraining: return "house.lodge.fill"
        case .sleeping: return "moon.zzz.fill"
        case .walks: return "figure.walk"
        case .skillsTraining: return "star.fill"
        case .nipping: return "mouth.fill"
        case .leashBehavior: return "link"
        case .jumping: return "arrow.up.circle.fill"
        case .resourceGuarding: return "shield.fill"
        case .chewing: return "mouth"
        case .barking: return "speaker.wave.3.fill"
        case .separationAnxiety: return "person.fill.xmark"
        case .carTravel: return "car.fill"
        case .handlingTolerance: return "hand.raised.fill"
        }
    }

    /// Core categories that apply to all puppies.
    static var coreCategories: [SentimentCategory] {
        [.pottyTraining, .benchTraining, .sleeping, .walks, .skillsTraining]
    }

    /// Age-specific categories that become relevant at certain ages.
    static func ageRelevantCategories(ageWeeks: Int) -> [SentimentCategory] {
        var categories: [SentimentCategory] = []

        // Nipping peaks around 8-16 weeks
        if ageWeeks >= 8 && ageWeeks <= 20 {
            categories.append(.nipping)
        }

        // Leash behavior relevant once walks start (after vaccinations, ~12 weeks)
        if ageWeeks >= 10 {
            categories.append(.leashBehavior)
        }

        // Jumping becomes an issue as pup gets bigger
        if ageWeeks >= 12 {
            categories.append(.jumping)
        }

        // Chewing peaks during teething (12-24 weeks)
        if ageWeeks >= 12 && ageWeeks <= 28 {
            categories.append(.chewing)
        }

        // Separation anxiety can emerge once pup settles in
        if ageWeeks >= 12 {
            categories.append(.separationAnxiety)
        }

        // Barking increases with adolescence
        if ageWeeks >= 16 {
            categories.append(.barking)
        }

        // Resource guarding can emerge around adolescence
        if ageWeeks >= 16 {
            categories.append(.resourceGuarding)
        }

        // Handling tolerance critical in socialization window, still relevant later
        if ageWeeks <= 20 {
            categories.append(.handlingTolerance)
        }

        // Car travel is situational - always somewhat relevant
        categories.append(.carTravel)

        return categories
    }

    /// Categories that this category depends on (root causes).
    /// If struggling with this category, check these first.
    var rootCauseDependencies: [SentimentCategory] {
        switch self {
        case .pottyTraining:
            return [.benchTraining]  // Crate enables potty training
        case .nipping:
            return [.sleeping, .benchTraining]  // Overtired pups nip, crate provides timeout
        case .skillsTraining:
            return []  // Food motivation is separate (not a sentiment category)
        case .jumping:
            return [.skillsTraining]  // Need "sit" and impulse control
        case .leashBehavior:
            return [.skillsTraining, .walks]  // Need engagement skills
        case .separationAnxiety:
            return [.benchTraining]  // Crate builds alone-time tolerance
        case .chewing:
            return [.benchTraining, .sleeping]  // Bored/tired pups chew more
        case .barking:
            return [.sleeping, .skillsTraining]  // Overtired or under-stimulated
        default:
            return []
        }
    }

    /// Whether this category has a dedicated deep-dive info sheet.
    var hasInfoSheet: Bool {
        switch self {
        case .pottyTraining, .benchTraining, .sleeping, .nipping, .skillsTraining:
            return true
        default:
            return false
        }
    }
}

// MARK: - Sentiment Check-In

/// A user's rating of how a particular area is going.
struct SentimentCheckIn: Codable, Identifiable {
    let id: UUID
    let category: SentimentCategory
    let score: Int  // 1-5 scale
    let date: Date
    let contextSummary: String?  // What we showed them about their logged activity

    init(category: SentimentCategory, score: Int, contextSummary: String? = nil) {
        self.id = UUID()
        self.category = category
        self.score = max(1, min(5, score))
        self.date = Date()
        self.contextSummary = contextSummary
    }

    /// Whether this rating indicates the user is struggling (1-3).
    var isStruggling: Bool {
        score <= 3
    }

    /// Whether this rating indicates things are going well (4-5).
    var isDoingWell: Bool {
        score >= 4
    }

    /// Whether this rating indicates no tips needed (5).
    var shouldMuteTips: Bool {
        score == 5
    }

    /// Age of this check-in in days.
    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    }

    /// Whether this check-in is still fresh enough to use.
    var isFresh: Bool {
        ageInDays <= 7  // Ratings expire after a week
    }
}

// MARK: - Sentiment State

/// Aggregated sentiment state for AI context.
struct SentimentState: Codable {
    let checkIns: [SentimentCategory: SentimentCheckIn]
    let primaryFocus: SentimentCategory?
    let lastCheckInDate: Date?

    /// Categories where the user is struggling (score 1-3).
    var strugglingCategories: [SentimentCategory] {
        checkIns.values
            .filter { $0.isFresh && $0.isStruggling }
            .sorted { $0.score < $1.score }  // Most struggling first
            .map { $0.category }
    }

    /// Categories where tips should be muted (score 5, fresh).
    var mutedCategories: [SentimentCategory] {
        checkIns.values
            .filter { $0.isFresh && $0.shouldMuteTips }
            .map { $0.category }
    }

    /// Get the latest score for a category, if fresh.
    func score(for category: SentimentCategory) -> Int? {
        guard let checkIn = checkIns[category], checkIn.isFresh else { return nil }
        return checkIn.score
    }
}
