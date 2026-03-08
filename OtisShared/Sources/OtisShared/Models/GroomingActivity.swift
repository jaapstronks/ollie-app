//
//  GroomingActivity.swift
//  OtisShared
//
//  Grooming schedule and activity tracking for dogs
//

import Foundation

// MARK: - Grooming Type

/// Types of grooming activities
public enum GroomingType: String, Codable, Sendable, CaseIterable {
    case brushing
    case bathing
    case nailTrim
    case earCleaning
    case teethBrushing
    case haircut
    case deShedding
    case pawCare
    case eyeCleaning
    case analGlands

    public var label: String {
        switch self {
        case .brushing: return String(localized: "Brushing", table: "Routines", bundle: Strings.bundle)
        case .bathing: return String(localized: "Bath", table: "Routines", bundle: Strings.bundle)
        case .nailTrim: return String(localized: "Nail trim", table: "Routines", bundle: Strings.bundle)
        case .earCleaning: return String(localized: "Ear cleaning", table: "Routines", bundle: Strings.bundle)
        case .teethBrushing: return String(localized: "Teeth brushing", table: "Routines", bundle: Strings.bundle)
        case .haircut: return String(localized: "Haircut", table: "Routines", bundle: Strings.bundle)
        case .deShedding: return String(localized: "De-shedding", table: "Routines", bundle: Strings.bundle)
        case .pawCare: return String(localized: "Paw care", table: "Routines", bundle: Strings.bundle)
        case .eyeCleaning: return String(localized: "Eye cleaning", table: "Routines", bundle: Strings.bundle)
        case .analGlands: return String(localized: "Anal glands", table: "Routines", bundle: Strings.bundle)
        }
    }

    public var icon: String {
        switch self {
        case .brushing: return "comb.fill"
        case .bathing: return "shower.fill"
        case .nailTrim: return "scissors"
        case .earCleaning: return "ear.fill"
        case .teethBrushing: return "mouth.fill"
        case .haircut: return "scissors"
        case .deShedding: return "wind"
        case .pawCare: return "pawprint.fill"
        case .eyeCleaning: return "eye.fill"
        case .analGlands: return "cross.circle.fill"
        }
    }

    /// Default recommended interval in days
    public var defaultIntervalDays: Int {
        switch self {
        case .brushing: return 3           // Every 3 days
        case .bathing: return 30           // Monthly
        case .nailTrim: return 21          // Every 3 weeks
        case .earCleaning: return 14       // Every 2 weeks
        case .teethBrushing: return 1      // Daily (ideally)
        case .haircut: return 60           // Every 2 months
        case .deShedding: return 7         // Weekly
        case .pawCare: return 14           // Every 2 weeks
        case .eyeCleaning: return 7        // Weekly
        case .analGlands: return 60        // Every 2 months (or as needed)
        }
    }

    /// Whether this is typically done at home vs professional groomer
    public var isTypicallyProfessional: Bool {
        switch self {
        case .haircut, .analGlands:
            return true
        default:
            return false
        }
    }

    /// Short description for the activity
    public var description: String {
        switch self {
        case .brushing:
            return String(localized: "Remove loose fur and prevent matting", table: "Routines", bundle: Strings.bundle)
        case .bathing:
            return String(localized: "Full bath with dog shampoo", table: "Routines", bundle: Strings.bundle)
        case .nailTrim:
            return String(localized: "Trim nails to prevent overgrowth", table: "Routines", bundle: Strings.bundle)
        case .earCleaning:
            return String(localized: "Clean ears to prevent infections", table: "Routines", bundle: Strings.bundle)
        case .teethBrushing:
            return String(localized: "Brush teeth for dental health", table: "Routines", bundle: Strings.bundle)
        case .haircut:
            return String(localized: "Professional coat trimming", table: "Routines", bundle: Strings.bundle)
        case .deShedding:
            return String(localized: "Remove undercoat and reduce shedding", table: "Routines", bundle: Strings.bundle)
        case .pawCare:
            return String(localized: "Check pads and trim fur between toes", table: "Routines", bundle: Strings.bundle)
        case .eyeCleaning:
            return String(localized: "Clean eye area and remove tear stains", table: "Routines", bundle: Strings.bundle)
        case .analGlands:
            return String(localized: "Express anal glands if needed", table: "Routines", bundle: Strings.bundle)
        }
    }
}

// MARK: - Grooming Activity

/// A grooming activity with scheduling
public struct GroomingActivity: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var type: GroomingType
    public var intervalDays: Int                   // Days between activities
    public var lastCompleted: Date?                // Last time this was done
    public var isEnabled: Bool                     // Whether to track this activity
    public var note: String?
    public var createdAt: Date
    public var modifiedAt: Date

    /// Human-readable name for logging (conforms to StorableModel)
    public var displayName: String {
        type.label
    }

    public init(
        id: UUID = UUID(),
        type: GroomingType,
        intervalDays: Int? = nil,
        lastCompleted: Date? = nil,
        isEnabled: Bool = true,
        note: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.intervalDays = intervalDays ?? type.defaultIntervalDays
        self.lastCompleted = lastCompleted
        self.isEnabled = isEnabled
        self.note = note
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    // MARK: - Computed Properties

    /// Next due date based on interval
    public var nextDue: Date? {
        guard let lastCompleted = lastCompleted else { return nil }
        return Calendar.current.date(byAdding: .day, value: intervalDays, to: lastCompleted)
    }

    /// Days until next due (negative if overdue)
    public var daysUntilDue: Int? {
        guard let nextDue = nextDue else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: nextDue).day
    }

    /// Whether this activity is due (within grace period of 2 days before)
    public var isDue: Bool {
        guard let days = daysUntilDue else {
            // Never completed, so it's due
            return true
        }
        return days <= 2
    }

    /// Whether this activity is overdue
    public var isOverdue: Bool {
        guard let days = daysUntilDue else { return false }
        return days < 0
    }

    /// Days since last completed
    public var daysSinceLastCompleted: Int? {
        guard let lastCompleted = lastCompleted else { return nil }
        return Calendar.current.dateComponents([.day], from: lastCompleted, to: Date()).day
    }

    /// Status label for display
    public var statusLabel: String {
        guard let days = daysUntilDue else {
            return String(localized: "Not yet done", table: "Routines", bundle: Strings.bundle)
        }

        if days < 0 {
            let absDays = abs(days)
            let suffix = absDays == 1 ? "" : "s"
            return String(localized: "\(absDays) day\(suffix) overdue", table: "Routines", bundle: Strings.bundle)
        } else if days == 0 {
            return String(localized: "Due today", table: "Routines", bundle: Strings.bundle)
        } else if days == 1 {
            return String(localized: "Due tomorrow", table: "Routines", bundle: Strings.bundle)
        } else if days <= 7 {
            return String(localized: "Due in \(days) days", table: "Routines", bundle: Strings.bundle)
        } else {
            let weeks = days / 7
            let suffix = weeks == 1 ? "" : "s"
            return String(localized: "Due in \(weeks) week\(suffix)", table: "Routines", bundle: Strings.bundle)
        }
    }

    /// Formatted last completed date
    public var formattedLastCompleted: String? {
        guard let lastCompleted = lastCompleted else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: lastCompleted)
    }

    // MARK: - Methods

    /// Mark as completed now
    public mutating func markCompleted(at date: Date = Date()) {
        lastCompleted = date
        modifiedAt = Date()
    }
}

// MARK: - Factory Methods

public extension GroomingActivity {

    /// Create default grooming activities for a dog
    static func defaultActivities() -> [GroomingActivity] {
        GroomingType.allCases.map { type in
            GroomingActivity(type: type, isEnabled: !type.isTypicallyProfessional)
        }
    }

    /// Create a quick grooming activity that was just completed
    static func justCompleted(type: GroomingType, note: String? = nil) -> GroomingActivity {
        GroomingActivity(type: type, lastCompleted: Date(), note: note)
    }
}

// MARK: - Array Extensions

public extension Array where Element == GroomingActivity {

    /// Get activities that are due or overdue
    var due: [GroomingActivity] {
        filter { $0.isEnabled && $0.isDue }
    }

    /// Get activities that are overdue
    var overdue: [GroomingActivity] {
        filter { $0.isEnabled && $0.isOverdue }
    }

    /// Sort by urgency (most overdue first)
    func sortedByUrgency() -> [GroomingActivity] {
        sorted { activity1, activity2 in
            let days1 = activity1.daysUntilDue ?? -1000
            let days2 = activity2.daysUntilDue ?? -1000
            return days1 < days2
        }
    }

    /// Get activity by type
    func activity(for type: GroomingType) -> GroomingActivity? {
        first { $0.type == type }
    }

    /// Filter to only enabled activities
    var enabled: [GroomingActivity] {
        filter(\.isEnabled)
    }

    /// Get activities grouped by status
    var groupedByStatus: (overdue: [GroomingActivity], due: [GroomingActivity], upcoming: [GroomingActivity]) {
        let overdue = filter { $0.isEnabled && $0.isOverdue }
        let due = filter { $0.isEnabled && $0.isDue && !$0.isOverdue }
        let upcoming = filter { $0.isEnabled && !$0.isDue }
        return (overdue, due, upcoming)
    }
}
