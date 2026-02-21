//
//  HealthMilestone.swift
//  Ollie-app
//
//  Health milestones for vaccinations, deworming, vet visits

import Foundation

/// A health milestone (vaccination, deworming, vet visit)
struct HealthMilestone: Identifiable, Codable {
    let id: UUID
    let date: Date
    let label: String
    let period: String?  // "Week 8", "6 months", etc.
    var isDone: Bool

    init(id: UUID = UUID(), date: Date, label: String, period: String?, isDone: Bool) {
        self.id = id
        self.date = date
        self.label = label
        self.period = period
        self.isDone = isDone
    }

    /// Status of this milestone relative to current date
    var status: MilestoneStatus {
        if isDone {
            return .done
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let milestoneDay = calendar.startOfDay(for: date)

        if milestoneDay < today {
            return .overdue
        } else if calendar.isDate(milestoneDay, equalTo: today, toGranularity: .weekOfYear) {
            return .nextUp
        } else {
            return .future
        }
    }

    enum MilestoneStatus {
        case done
        case nextUp
        case future
        case overdue
    }
}

/// Default milestones for a new puppy (based on Dutch vaccination schedule)
/// Users will be able to customize these later
enum DefaultMilestones {
    /// Create default milestones relative to a birth date
    static func create(birthDate: Date) -> [HealthMilestone] {
        let calendar = Calendar.current

        func dateAt(weeks: Int) -> Date {
            calendar.date(byAdding: .weekOfYear, value: weeks, to: birthDate) ?? birthDate
        }

        func dateAt(months: Int) -> Date {
            calendar.date(byAdding: .month, value: months, to: birthDate) ?? birthDate
        }

        return [
            HealthMilestone(
                date: dateAt(weeks: 6),
                label: Strings.Health.firstDewormingBreeder,
                period: Strings.Health.weekNumber(6),
                isDone: true
            ),
            HealthMilestone(
                date: dateAt(weeks: 8),
                label: Strings.Health.firstVaccination,
                period: Strings.Health.weekNumber(8),
                isDone: false
            ),
            HealthMilestone(
                date: dateAt(weeks: 9),
                label: Strings.Health.firstVetVisit,
                period: Strings.Health.weekNumber(9),
                isDone: false
            ),
            HealthMilestone(
                date: dateAt(weeks: 9),
                label: Strings.Health.firstDewormingHome,
                period: Strings.Health.weekNumber(9),
                isDone: false
            ),
            HealthMilestone(
                date: dateAt(weeks: 12),
                label: Strings.Health.secondVaccination,
                period: Strings.Health.weekNumber(12),
                isDone: false
            ),
            HealthMilestone(
                date: dateAt(weeks: 16),
                label: Strings.Health.thirdVaccination,
                period: Strings.Health.weekNumber(16),
                isDone: false
            ),
            HealthMilestone(
                date: dateAt(months: 6),
                label: Strings.Health.neuteredDiscussion,
                period: Strings.Health.monthNumber(6),
                isDone: false
            ),
            HealthMilestone(
                date: dateAt(months: 12),
                label: Strings.Health.yearlyVaccination,
                period: Strings.Health.monthNumber(12),
                isDone: false
            )
        ]
    }
}
