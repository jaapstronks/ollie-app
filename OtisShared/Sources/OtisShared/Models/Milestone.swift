//
//  Milestone.swift
//  OtisShared
//
//  Comprehensive milestone model for health, developmental, administrative, and custom milestones.
//  Supporting types are in separate files:
//  - MilestoneEnums.swift - MilestoneCategory, MilestoneStatus
//  - DefaultMilestones.swift - Factory for creating default milestones
//  - MilestoneLabelResolver.swift - Localized string resolution
//

import Foundation

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
    public var completionNotes: String?      // Otis+ feature
    public var completionPhotoID: UUID?      // Otis+ feature

    // Premium features
    public var vetClinicName: String?        // Otis+ feature (deprecated, use linkedContactID)
    public var linkedContactID: UUID?        // Otis+ feature: linked vet contact
    public var calendarEventID: String?      // Otis+ feature
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
        linkedContactID: UUID? = nil,
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
        self.linkedContactID = linkedContactID
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
        let table = "Milestones"
        if let weeks = targetAgeWeeks {
            return String(localized: "Week \(weeks)", table: table, bundle: Strings.bundle)
        }
        if let months = targetAgeMonths {
            return String(localized: "\(months) months", table: table, bundle: Strings.bundle)
        }
        if let days = targetAgeDays {
            let weeks = days / 7
            return String(localized: "Week \(weeks)", table: table, bundle: Strings.bundle)
        }
        return nil
    }

    /// Enhanced period label showing both age week AND approximate calendar date
    /// Example: "Age week 12 · ~March 15"
    public func periodLabelWithDate(birthDate: Date) -> String? {
        guard let targetDate = targetDate(birthDate: birthDate) else { return nil }
        let table = "Milestones"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"

        let approximateDate = "~\(dateFormatter.string(from: targetDate))"

        if let weeks = targetAgeWeeks {
            return String(localized: "Age week \(weeks) · \(approximateDate)", table: table, bundle: Strings.bundle)
        }
        if let months = targetAgeMonths {
            return String(localized: "\(months) months · \(approximateDate)", table: table, bundle: Strings.bundle)
        }
        if let days = targetAgeDays {
            let weeks = days / 7
            return String(localized: "Age week \(weeks) · \(approximateDate)", table: table, bundle: Strings.bundle)
        }

        // For fixed date milestones, just show the date
        return dateFormatter.string(from: targetDate)
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

// MARK: - Health Milestones Generator

extension Milestone {

    /// Generate health milestones for a profile, skipping milestones the dog has already passed
    public static func healthMilestones(for profile: PuppyProfile) -> [Milestone] {
        var milestones: [Milestone] = []
        var sortOrder = 100  // Start after default milestones

        let currentAgeMonths = profile.ageInMonths

        // Dental baseline at 24 months (2 years)
        if currentAgeMonths < 24 {
            milestones.append(Milestone(
                category: .health,
                labelKey: "milestone.dentalBaseline",
                detailKey: "milestone.dentalBaseline.detail",
                targetAgeMonths: 24,
                icon: "mouth.fill",
                sortOrder: sortOrder
            ))
            sortOrder += 1
        }

        // Annual wellness exams (from year 2 onwards)
        for year in 2...15 {
            let months = year * 12
            if currentAgeMonths < months {
                milestones.append(Milestone(
                    category: .health,
                    labelKey: "milestone.annualWellness",
                    detailKey: "milestone.annualWellness.detail",
                    targetAgeMonths: months,
                    icon: "heart.text.square.fill",
                    sortOrder: sortOrder
                ))
                sortOrder += 1
                break  // Only add the next upcoming one
            }
        }

        // Senior wellness screening (age varies by size)
        let seniorStartMonths = profile.seniorAgeMonths
        if currentAgeMonths < seniorStartMonths {
            milestones.append(Milestone(
                category: .health,
                labelKey: "milestone.seniorScreening",
                detailKey: "milestone.seniorScreening.detail",
                targetAgeMonths: seniorStartMonths,
                icon: "stethoscope",
                sortOrder: sortOrder
            ))
            sortOrder += 1
        }

        // Semi-annual checkups for seniors (every 6 months after senior threshold)
        if currentAgeMonths >= seniorStartMonths {
            let nextCheckupMonths = ((currentAgeMonths - seniorStartMonths) / 6 + 1) * 6 + seniorStartMonths
            milestones.append(Milestone(
                category: .health,
                labelKey: "milestone.semiAnnualSenior",
                detailKey: "milestone.semiAnnualSenior.detail",
                targetAgeMonths: nextCheckupMonths,
                isRecurring: true,
                recurrenceMonths: 6,
                icon: "heart.fill",
                sortOrder: sortOrder
            ))
            sortOrder += 1
        }

        // Breed-specific screenings
        milestones.append(contentsOf: breedScreeningMilestones(for: profile, startingSortOrder: sortOrder))

        return milestones
    }

    /// Generate breed-specific screening milestones
    private static func breedScreeningMilestones(for profile: PuppyProfile, startingSortOrder: Int) -> [Milestone] {
        var milestones: [Milestone] = []
        var sortOrder = startingSortOrder

        let currentAgeMonths = profile.ageInMonths
        let dueScreenings = profile.dueScreenings

        // Add milestones for each due screening
        for screening in dueScreenings {
            guard let screeningAge = screening.screeningRecommendedAgeMonths,
                  currentAgeMonths < screeningAge else {
                continue
            }

            let (labelKey, detailKey, icon) = screeningMilestoneInfo(for: screening.conditionType)

            milestones.append(Milestone(
                category: .health,
                labelKey: labelKey,
                detailKey: detailKey,
                targetAgeMonths: screeningAge,
                icon: icon,
                sortOrder: sortOrder
            ))
            sortOrder += 1
        }

        // Add size-based screenings for large/extra-large dogs
        if profile.sizeCategory == .large || profile.sizeCategory == .extraLarge {
            // Hip screening at 24 months for large breeds
            if currentAgeMonths < 24 && !dueScreenings.contains(where: { $0.conditionType == .hipDysplasia }) {
                milestones.append(Milestone(
                    category: .health,
                    labelKey: "milestone.hipScreening",
                    detailKey: "milestone.hipScreening.detail",
                    targetAgeMonths: 24,
                    icon: "figure.walk",
                    sortOrder: sortOrder
                ))
                sortOrder += 1
            }
        }

        return milestones
    }

    /// Map condition type to milestone label, detail, and icon
    private static func screeningMilestoneInfo(for conditionType: HealthConditionType) -> (labelKey: String, detailKey: String, icon: String) {
        switch conditionType {
        case .hipDysplasia:
            return ("milestone.hipScreening", "milestone.hipScreening.detail", "figure.walk")
        case .elbowDysplasia:
            return ("milestone.elbowScreening", "milestone.elbowScreening.detail", "figure.walk")
        case .heartMurmur, .dilatedCardiomyopathy, .mitralValveDisease:
            return ("milestone.heartScreening", "milestone.heartScreening.detail", "heart.fill")
        case .cataracts, .glaucoma, .progressiveRetinalAtrophy:
            return ("milestone.eyeScreening", "milestone.eyeScreening.detail", "eye.fill")
        default:
            return (conditionType.label, "", conditionType.icon)
        }
    }
}
