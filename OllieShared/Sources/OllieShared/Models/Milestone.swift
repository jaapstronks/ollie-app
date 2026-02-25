//
//  Milestone.swift
//  OllieShared
//
//  Comprehensive milestone model for health, developmental, administrative, and custom milestones

import Foundation

// MARK: - Milestone Category

/// Categories for organizing milestones
public enum MilestoneCategory: String, Codable, CaseIterable, Sendable {
    case health          // Vaccinations, deworming, vet visits
    case developmental   // Socialization window, training milestones
    case administrative  // Registration, insurance, microchip
    case custom          // User-created milestones (Ollie+)

    /// SF Symbol icon for the category
    public var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .developmental: return "brain.head.profile"
        case .administrative: return "doc.text.fill"
        case .custom: return "star.fill"
        }
    }

    /// Localized display name
    public var displayName: String {
        switch self {
        case .health: return String(localized: "Health")
        case .developmental: return String(localized: "Development")
        case .administrative: return String(localized: "Administrative")
        case .custom: return String(localized: "Custom")
        }
    }
}

// MARK: - Milestone Status

/// Status of a milestone relative to current date
public enum MilestoneStatus: String, Codable, Sendable {
    case upcoming   // Future milestone
    case nextUp     // Coming up within the current or next week
    case overdue    // Past due date, not completed
    case completed  // Marked as done

    /// SF Symbol icon for the status
    public var icon: String {
        switch self {
        case .upcoming: return "circle"
        case .nextUp: return "arrow.right.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Milestone

/// A milestone event in the puppy's life (health, developmental, or custom)
public struct Milestone: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var category: MilestoneCategory
    public var labelKey: String
    public var detailKey: String?

    // Age-based targeting (mutually exclusive with fixedDate)
    public var targetAgeWeeks: Int?
    public var targetAgeDays: Int?
    public var targetAgeMonths: Int?

    // Fixed date targeting (for custom milestones)
    public var fixedDate: Date?

    // Recurrence
    public var isRecurring: Bool
    public var recurrenceMonths: Int?

    // Completion state
    public var isCompleted: Bool
    public var completedDate: Date?
    public var completionNotes: String?      // Ollie+ feature
    public var completionPhotoID: UUID?      // Ollie+ feature

    // Premium features
    public var vetClinicName: String?        // Ollie+ feature
    public var calendarEventID: String?      // Ollie+ feature
    public var reminderDaysBefore: Int

    // Display properties
    public var icon: String
    public var isActionable: Bool
    public var isUserDismissable: Bool
    public var sortOrder: Int
    public var isCustom: Bool

    // Timestamps
    public var createdAt: Date
    public var modifiedAt: Date

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        category: MilestoneCategory,
        labelKey: String,
        detailKey: String? = nil,
        targetAgeWeeks: Int? = nil,
        targetAgeDays: Int? = nil,
        targetAgeMonths: Int? = nil,
        fixedDate: Date? = nil,
        isRecurring: Bool = false,
        recurrenceMonths: Int? = nil,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        completionNotes: String? = nil,
        completionPhotoID: UUID? = nil,
        vetClinicName: String? = nil,
        calendarEventID: String? = nil,
        reminderDaysBefore: Int = 3,
        icon: String = "heart.fill",
        isActionable: Bool = true,
        isUserDismissable: Bool = false,
        sortOrder: Int = 0,
        isCustom: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.labelKey = labelKey
        self.detailKey = detailKey
        self.targetAgeWeeks = targetAgeWeeks
        self.targetAgeDays = targetAgeDays
        self.targetAgeMonths = targetAgeMonths
        self.fixedDate = fixedDate
        self.isRecurring = isRecurring
        self.recurrenceMonths = recurrenceMonths
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.completionNotes = completionNotes
        self.completionPhotoID = completionPhotoID
        self.vetClinicName = vetClinicName
        self.calendarEventID = calendarEventID
        self.reminderDaysBefore = reminderDaysBefore
        self.icon = icon
        self.isActionable = isActionable
        self.isUserDismissable = isUserDismissable
        self.sortOrder = sortOrder
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    // MARK: - Target Date Calculation

    /// Calculate the target date for this milestone based on the puppy's birth date
    public func targetDate(birthDate: Date) -> Date? {
        // Fixed date takes precedence
        if let fixedDate = fixedDate {
            return fixedDate
        }

        let calendar = Calendar.current

        // Days-based targeting (most precise)
        if let days = targetAgeDays {
            return calendar.date(byAdding: .day, value: days, to: birthDate)
        }

        // Weeks-based targeting
        if let weeks = targetAgeWeeks {
            return calendar.date(byAdding: .weekOfYear, value: weeks, to: birthDate)
        }

        // Months-based targeting
        if let months = targetAgeMonths {
            return calendar.date(byAdding: .month, value: months, to: birthDate)
        }

        return nil
    }

    /// Calculate the status of this milestone
    public func status(birthDate: Date, now: Date = Date()) -> MilestoneStatus {
        if isCompleted {
            return .completed
        }

        guard let target = targetDate(birthDate: birthDate) else {
            return .upcoming
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let targetDay = calendar.startOfDay(for: target)

        // Past due date
        if targetDay < today {
            return .overdue
        }

        // Within the next 7 days
        if let nextWeek = calendar.date(byAdding: .day, value: 7, to: today),
           targetDay <= nextWeek {
            return .nextUp
        }

        return .upcoming
    }

    /// Period label (e.g., "Week 8" or "6 months")
    public func periodLabel(birthDate: Date) -> String? {
        if let weeks = targetAgeWeeks {
            return String(localized: "Week \(weeks)")
        }
        if let months = targetAgeMonths {
            return String(localized: "\(months) months")
        }
        if let days = targetAgeDays {
            let weeks = days / 7
            return String(localized: "Week \(weeks)")
        }
        return nil
    }

    /// Formatted target date string
    public func formattedTargetDate(birthDate: Date) -> String? {
        guard let date = targetDate(birthDate: birthDate) else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Days until this milestone (negative if overdue)
    public func daysUntil(birthDate: Date, from: Date = Date()) -> Int? {
        guard let target = targetDate(birthDate: birthDate) else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: from), to: calendar.startOfDay(for: target)).day
    }
}

// MARK: - Default Milestones

/// Factory for creating default milestones based on puppy's birth date
public enum DefaultMilestones {

    /// Create default milestones for a new puppy
    public static func create() -> [Milestone] {
        var milestones: [Milestone] = []
        var sortOrder = 0

        // Health milestones - Dutch vaccination schedule
        milestones.append(Milestone(
            category: .health,
            labelKey: "milestone.firstDewormingBreeder",
            targetAgeWeeks: 6,
            isCompleted: true,  // Usually done by breeder
            icon: "pills.fill",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .health,
            labelKey: "milestone.firstVaccination",
            detailKey: "milestone.firstVaccination.detail",
            targetAgeWeeks: 8,
            icon: "syringe.fill",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .health,
            labelKey: "milestone.firstVetVisit",
            targetAgeWeeks: 9,
            icon: "cross.case.fill",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .health,
            labelKey: "milestone.firstDewormingHome",
            targetAgeWeeks: 9,
            icon: "pills.fill",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .health,
            labelKey: "milestone.secondVaccination",
            detailKey: "milestone.secondVaccination.detail",
            targetAgeWeeks: 12,
            icon: "syringe.fill",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .health,
            labelKey: "milestone.thirdVaccination",
            detailKey: "milestone.thirdVaccination.detail",
            targetAgeWeeks: 16,
            icon: "syringe.fill",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .health,
            labelKey: "milestone.neuteredDiscussion",
            targetAgeMonths: 6,
            icon: "stethoscope",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .health,
            labelKey: "milestone.yearlyVaccination",
            targetAgeMonths: 12,
            isRecurring: true,
            recurrenceMonths: 12,
            icon: "syringe.fill",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        // Developmental milestones
        milestones.append(Milestone(
            category: .developmental,
            labelKey: "milestone.socializationStart",
            detailKey: "milestone.socializationStart.detail",
            targetAgeWeeks: 8,
            icon: "person.3.fill",
            isActionable: false,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .developmental,
            labelKey: "milestone.socializationPeak",
            detailKey: "milestone.socializationPeak.detail",
            targetAgeWeeks: 12,
            icon: "sparkles",
            isActionable: false,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .developmental,
            labelKey: "milestone.socializationEnd",
            detailKey: "milestone.socializationEnd.detail",
            targetAgeWeeks: 16,
            icon: "clock.badge.checkmark.fill",
            isActionable: false,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .developmental,
            labelKey: "milestone.fearPeriod1",
            detailKey: "milestone.fearPeriod1.detail",
            targetAgeWeeks: 8,
            icon: "exclamationmark.triangle.fill",
            isActionable: false,
            isUserDismissable: true,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .developmental,
            labelKey: "milestone.fearPeriod2",
            detailKey: "milestone.fearPeriod2.detail",
            targetAgeMonths: 6,
            icon: "exclamationmark.triangle.fill",
            isActionable: false,
            isUserDismissable: true,
            sortOrder: sortOrder
        ))
        sortOrder += 1

        // Administrative milestones
        milestones.append(Milestone(
            category: .administrative,
            labelKey: "milestone.microchipRegistration",
            targetAgeWeeks: 8,
            icon: "wave.3.right.circle.fill",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .administrative,
            labelKey: "milestone.insuranceSetup",
            detailKey: "milestone.insuranceSetup.detail",
            targetAgeWeeks: 8,
            icon: "shield.checkered",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        milestones.append(Milestone(
            category: .administrative,
            labelKey: "milestone.dogLicense",
            detailKey: "milestone.dogLicense.detail",
            targetAgeWeeks: 12,
            icon: "doc.badge.plus",
            sortOrder: sortOrder
        ))
        sortOrder += 1

        return milestones
    }
}

// MARK: - Hashable

extension Milestone {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Milestone, rhs: Milestone) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Label Resolution

extension Milestone {

    /// Resolve the label key to a localized string
    public var localizedLabel: String {
        MilestoneLabelResolver.resolve(labelKey)
    }

    /// Resolve the detail key to a localized string (if present)
    public var localizedDetail: String? {
        guard let key = detailKey else { return nil }
        return MilestoneLabelResolver.resolve(key)
    }
}

/// Resolves milestone label keys to localized strings
public enum MilestoneLabelResolver {

    /// Resolve a label key to its localized string
    public static func resolve(_ key: String) -> String {
        switch key {
        // Health milestones
        case "milestone.firstDewormingBreeder":
            return String(localized: "First deworming (breeder)")
        case "milestone.firstVaccination":
            return String(localized: "First vaccination (DHP + Lepto)")
        case "milestone.firstVaccination.detail":
            return String(localized: "Core vaccination at 8 weeks")
        case "milestone.firstVetVisit":
            return String(localized: "First vet visit")
        case "milestone.firstDewormingHome":
            return String(localized: "First deworming (home)")
        case "milestone.secondVaccination":
            return String(localized: "Second vaccination (DHP + Lepto + Rabies)")
        case "milestone.secondVaccination.detail":
            return String(localized: "Booster vaccination at 12 weeks")
        case "milestone.thirdVaccination":
            return String(localized: "Third vaccination (cocktail)")
        case "milestone.thirdVaccination.detail":
            return String(localized: "Final puppy vaccination at 16 weeks")
        case "milestone.neuteredDiscussion":
            return String(localized: "Spay/neuter discussion with vet")
        case "milestone.yearlyVaccination":
            return String(localized: "Yearly vaccination")

        // Developmental milestones
        case "milestone.socializationStart":
            return String(localized: "Socialization window begins")
        case "milestone.socializationStart.detail":
            return String(localized: "Critical period for positive experiences starts now")
        case "milestone.socializationPeak":
            return String(localized: "Peak socialization period")
        case "milestone.socializationPeak.detail":
            return String(localized: "Most receptive time for new experiences")
        case "milestone.socializationEnd":
            return String(localized: "Socialization window closing")
        case "milestone.socializationEnd.detail":
            return String(localized: "Window is narrowing - focus on remaining exposures")
        case "milestone.fearPeriod1":
            return String(localized: "First fear period")
        case "milestone.fearPeriod1.detail":
            return String(localized: "Be extra gentle with new experiences")
        case "milestone.fearPeriod2":
            return String(localized: "Second fear period")
        case "milestone.fearPeriod2.detail":
            return String(localized: "Temporary increase in fearfulness - stay patient")

        // Administrative milestones
        case "milestone.microchipRegistration":
            return String(localized: "Microchip registration")
        case "milestone.insuranceSetup":
            return String(localized: "Pet insurance setup")
        case "milestone.insuranceSetup.detail":
            return String(localized: "Consider health insurance coverage")
        case "milestone.dogLicense":
            return String(localized: "Dog license")
        case "milestone.dogLicense.detail":
            return String(localized: "Register with your municipality if required")

        default:
            // For custom milestones, the key is the user-entered title
            return key
        }
    }
}
