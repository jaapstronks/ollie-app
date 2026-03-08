//
//  EnrichmentActivity.swift
//  OtisShared
//
//  Enrichment activity tracking for mental stimulation and engagement
//

import Foundation

// MARK: - Enrichment Type

/// Types of enrichment activities
public enum EnrichmentType: String, Codable, Sendable, CaseIterable {
    case puzzleToy
    case snuffleMat
    case hideAndSeek
    case nosework
    case trickTraining
    case foodDispenser
    case tugPlay
    case fetchPlay
    case socialPlay
    case newEnvironment
    case agility
    case swimming
    case chewSession
    case calmingActivity

    public var label: String {
        switch self {
        case .puzzleToy: return "Puzzle toy"
        case .snuffleMat: return "Snuffle mat"
        case .hideAndSeek: return "Hide and seek"
        case .nosework: return "Nose work"
        case .trickTraining: return "Trick training"
        case .foodDispenser: return "Food dispenser"
        case .tugPlay: return "Tug play"
        case .fetchPlay: return "Fetch"
        case .socialPlay: return "Social play"
        case .newEnvironment: return "New environment"
        case .agility: return "Agility"
        case .swimming: return "Swimming"
        case .chewSession: return "Chew session"
        case .calmingActivity: return "Calming activity"
        }
    }

    public var icon: String {
        switch self {
        case .puzzleToy: return "puzzlepiece.fill"
        case .snuffleMat: return "leaf.fill"
        case .hideAndSeek: return "eye.slash.fill"
        case .nosework: return "nose.fill"
        case .trickTraining: return "star.fill"
        case .foodDispenser: return "cylinder.fill"
        case .tugPlay: return "arrow.left.and.right"
        case .fetchPlay: return "circle.fill"
        case .socialPlay: return "person.2.fill"
        case .newEnvironment: return "map.fill"
        case .agility: return "figure.run"
        case .swimming: return "drop.fill"
        case .chewSession: return "circle.hexagongrid.fill"
        case .calmingActivity: return "heart.fill"
        }
    }

    /// Category for grouping
    public var category: EnrichmentCategory {
        switch self {
        case .puzzleToy, .snuffleMat, .hideAndSeek, .nosework, .foodDispenser:
            return .mental
        case .tugPlay, .fetchPlay, .agility, .swimming:
            return .physical
        case .socialPlay, .newEnvironment:
            return .social
        case .trickTraining:
            return .training
        case .chewSession, .calmingActivity:
            return .calming
        }
    }

    /// Brief description of the activity
    public var description: String {
        switch self {
        case .puzzleToy:
            return "Interactive toys that challenge problem-solving"
        case .snuffleMat:
            return "Hide treats in fabric for foraging"
        case .hideAndSeek:
            return "Hide treats or toys around the house"
        case .nosework:
            return "Scent tracking and detection games"
        case .trickTraining:
            return "Learning new tricks or behaviors"
        case .foodDispenser:
            return "Kong, lick mat, or slow feeder"
        case .tugPlay:
            return "Interactive tug games with rules"
        case .fetchPlay:
            return "Retrieving games with balls or toys"
        case .socialPlay:
            return "Play with other dogs or people"
        case .newEnvironment:
            return "Exploring new places or routes"
        case .agility:
            return "Obstacle courses and jumps"
        case .swimming:
            return "Water play and swimming"
        case .chewSession:
            return "Safe chewing with appropriate items"
        case .calmingActivity:
            return "Relaxation training or massage"
        }
    }

    /// Energy level required (1-5)
    public var energyLevel: Int {
        switch self {
        case .calmingActivity, .chewSession:
            return 1
        case .snuffleMat, .foodDispenser:
            return 2
        case .puzzleToy, .hideAndSeek, .nosework, .trickTraining:
            return 3
        case .socialPlay, .newEnvironment, .tugPlay:
            return 4
        case .fetchPlay, .agility, .swimming:
            return 5
        }
    }

    /// Whether this can be done indoors
    public var canDoIndoors: Bool {
        switch self {
        case .puzzleToy, .snuffleMat, .hideAndSeek, .nosework, .trickTraining,
             .foodDispenser, .tugPlay, .chewSession, .calmingActivity:
            return true
        case .fetchPlay, .socialPlay, .newEnvironment, .agility, .swimming:
            return false
        }
    }
}

// MARK: - Enrichment Category

/// Categories for grouping enrichment types
public enum EnrichmentCategory: String, Codable, Sendable, CaseIterable {
    case mental
    case physical
    case social
    case training
    case calming

    public var label: String {
        switch self {
        case .mental: return "Mental"
        case .physical: return "Physical"
        case .social: return "Social"
        case .training: return "Training"
        case .calming: return "Calming"
        }
    }

    public var icon: String {
        switch self {
        case .mental: return "brain.head.profile"
        case .physical: return "figure.run"
        case .social: return "person.2.fill"
        case .training: return "star.fill"
        case .calming: return "heart.fill"
        }
    }
}

// MARK: - Enrichment Activity

/// A completed enrichment activity
public struct EnrichmentActivity: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var type: EnrichmentType
    public var completedAt: Date
    public var durationMinutes: Int?
    public var note: String?
    public var createdAt: Date
    public var modifiedAt: Date

    /// Human-readable name for logging (conforms to StorableModel)
    public var displayName: String {
        type.label
    }

    public init(
        id: UUID = UUID(),
        type: EnrichmentType,
        completedAt: Date = Date(),
        durationMinutes: Int? = nil,
        note: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.completedAt = completedAt
        self.durationMinutes = durationMinutes
        self.note = note
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    // MARK: - Computed Properties

    /// Category of this activity
    public var category: EnrichmentCategory {
        type.category
    }

    /// Formatted completion date
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: completedAt)
    }

    /// Formatted duration
    public var formattedDuration: String? {
        guard let minutes = durationMinutes else { return nil }
        if minutes < 60 {
            return "\(minutes) min"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if remainingMinutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(remainingMinutes)m"
    }
}

// MARK: - Factory Methods

public extension EnrichmentActivity {

    /// Create an enrichment activity completed now
    static func now(type: EnrichmentType, durationMinutes: Int? = nil, note: String? = nil) -> EnrichmentActivity {
        EnrichmentActivity(type: type, durationMinutes: durationMinutes, note: note)
    }
}

// MARK: - Array Extensions

public extension Array where Element == EnrichmentActivity {

    /// Sort by completion date (newest first)
    func sortedByDate() -> [EnrichmentActivity] {
        sorted { $0.completedAt > $1.completedAt }
    }

    /// Filter to activities within the last N days
    func withinDays(_ days: Int) -> [EnrichmentActivity] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return filter { $0.completedAt >= cutoff }
    }

    /// Get activities from today
    var completedToday: [EnrichmentActivity] {
        filter { Calendar.current.isDateInToday($0.completedAt) }
    }

    /// Get activities from this week
    var thisWeek: [EnrichmentActivity] {
        withinDays(7)
    }

    /// Group by category
    var byCategory: [EnrichmentCategory: [EnrichmentActivity]] {
        Dictionary(grouping: self) { $0.category }
    }

    /// Group by type
    var byType: [EnrichmentType: [EnrichmentActivity]] {
        Dictionary(grouping: self) { $0.type }
    }

    /// Get types that haven't been done recently (for suggestions)
    func typesNotDoneRecently(days: Int = 7) -> [EnrichmentType] {
        let recentTypes = Set(withinDays(days).map(\.type))
        return EnrichmentType.allCases.filter { !recentTypes.contains($0) }
    }

    /// Get a random suggestion excluding recent activities
    func randomSuggestion(excludingDays: Int = 3) -> EnrichmentType? {
        let available = typesNotDoneRecently(days: excludingDays)
        return available.randomElement() ?? EnrichmentType.allCases.randomElement()
    }

    /// Total enrichment time this week
    var weeklyMinutes: Int {
        thisWeek.compactMap(\.durationMinutes).reduce(0, +)
    }

    /// Count of activities per category this week
    var weeklyCategoryCounts: [EnrichmentCategory: Int] {
        Dictionary(grouping: thisWeek) { $0.category }
            .mapValues { $0.count }
    }
}
