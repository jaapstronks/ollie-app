//
//  Strings+Health.swift
//  Otis-app
//
//  Health and weight tracking strings
//

import Foundation

private let table = "Health"
private let milestonesTable = "Milestones"

extension Strings {

    // MARK: - Health View
    enum Health {
        static let title = String(localized: "Health", table: table)
        static let weight = String(localized: "Weight", table: table)
        static let noWeightData = String(localized: "No weight data yet", table: table)
        static let logFirstWeight = String(localized: "Log your first weight measurement", table: table)
        static let logWeight = String(localized: "Log weight", table: table)
        static let measurementDate = String(localized: "Date", table: table, comment: "Label for weight measurement date picker")
        static let currentWeight = String(localized: "Current weight", table: table)
        static let growthCurve = String(localized: "Growth curve", table: table)
        static let referenceRange = String(localized: "Reference range", table: table)

        // Weight status
        static let weightOnTrack = String(localized: "On track", table: table)
        static let weightAboveReference = String(localized: "Above reference", table: table)
        static let weightBelowReference = String(localized: "Below reference", table: table)

        // Weight delta
        static func sinceLast(_ delta: String) -> String {
            String(localized: "\(delta) since last", table: table)
        }
        static func sincePrevious(_ delta: String, date: String) -> String {
            String(localized: "\(delta) since \(date)", table: table)
        }

        // Accessibility
        static func currentWeightAccessibility(_ weight: String) -> String {
            String(localized: "Current weight: \(weight)", table: table)
        }
        static func weightIncreased(_ delta: String) -> String {
            String(localized: "Gained \(delta)", table: table)
        }
        static func weightDecreased(_ delta: String) -> String {
            String(localized: "Lost \(delta)", table: table)
        }

        // Chart
        static let weeks = String(localized: "Weeks", table: table)
        static let kg = String(localized: "kg", table: table)
        static let lbs = String(localized: "lbs", table: table)
        static let yourPuppy = String(localized: "Your puppy", table: table)
        static let reference = String(localized: "Reference", table: table)

        // Week/month labels
        static func weekNumber(_ week: Int) -> String {
            String(localized: "Week \(week)", table: table)
        }
        static func monthNumber(_ month: Int) -> String {
            String(localized: "\(month) months", table: table)
        }
        static func monthsOld(_ months: Int) -> String {
            if months == 1 {
                return String(localized: "1 month old", table: table)
            } else {
                return String(localized: "\(months) months old", table: table)
            }
        }

        // Weight log sheet
        static let weightKg = String(localized: "Weight (kg)", table: table)
        static let weightLbs = String(localized: "Weight (lbs)", table: table)
        static let enterWeight = String(localized: "Enter weight", table: table)
        static let weightPlaceholder = String(localized: "e.g. 8.5", table: table)
        static let weightPlaceholderLbs = String(localized: "e.g. 18.7", table: table)

        // Health view misc
        static let done = String(localized: "Done", table: table)
        static let today = String(localized: "Today", table: table)
        static let future = String(localized: "Upcoming", table: table)

        // Medical Timeline
        static let medicalTimeline = String(localized: "Medical Timeline", table: table)
        static let birth = String(localized: "Birth", table: table)
        static let noMedicalHistory = String(localized: "No medical history yet", table: table)
        static let noMedicalHistoryHint = String(localized: "Health milestones and vet appointments will appear here", table: table)
        static func ageAtEvent(weeks: Int) -> String {
            if weeks == 0 {
                return String(localized: "Birth", table: table)
            } else if weeks < 4 {
                return String(localized: "Week \(weeks)", table: table)
            } else if weeks < 52 {
                let months = weeks / 4
                return String(localized: "\(months) months", table: table)
            } else {
                let years = weeks / 52
                return String(localized: "\(years) year(s)", table: table)
            }
        }
        static func currentAge(weeks: Int) -> String {
            if weeks < 52 {
                return String(localized: "Currently \(weeks) weeks old", table: table)
            } else {
                let years = weeks / 52
                let remainingWeeks = weeks % 52
                if remainingWeeks == 0 {
                    return String(localized: "Currently \(years) year(s) old", table: table)
                } else {
                    return String(localized: "Currently \(years) year(s) and \(remainingWeeks) weeks old", table: table)
                }
            }
        }

        // MARK: - Milestone strings (referencing Milestones table)
        // These are kept here for backward compatibility with existing views
        static let milestones = String(localized: "Milestones", table: milestonesTable)
        static let nextUp = String(localized: "Next up", table: milestonesTable)
        static let overdue = String(localized: "Overdue", table: milestonesTable)
        static let medicalMilestones = String(localized: "Medical Milestones", table: milestonesTable)
        static let noMedicalMilestones = String(localized: "No medical milestones yet", table: milestonesTable)

        // Milestone sections
        static let upcomingMilestones = String(localized: "Coming Up", table: milestonesTable)
        static let completedMilestones = String(localized: "Completed", table: milestonesTable)
        static let addMilestone = String(localized: "Add Milestone", table: milestonesTable)
        static let completeMilestone = String(localized: "Mark Complete", table: milestonesTable)
        static let uncompleteMilestone = String(localized: "Mark Incomplete", table: milestonesTable)

        // Milestone completion sheet
        static let completeTitle = String(localized: "Complete Milestone", table: milestonesTable)
        static let completionDate = String(localized: "Completion date", table: milestonesTable)
        static let addNotes = String(localized: "Add notes", table: milestonesTable)
        static let notesPlaceholder = String(localized: "Optional notes about this milestone...", table: milestonesTable)
        static let vetClinic = String(localized: "Vet clinic", table: milestonesTable)
        static let vetClinicPlaceholder = String(localized: "Clinic name (optional)", table: milestonesTable)
        static let addToCalendar = String(localized: "Add to Calendar", table: milestonesTable)
        static let removeFromCalendar = String(localized: "Remove from Calendar", table: milestonesTable)
        static let addPhoto = String(localized: "Add Photo", table: milestonesTable)

        // Default milestones (vaccination schedule)
        static let firstDewormingBreeder = String(localized: "First deworming (breeder)", table: milestonesTable)
        static let firstVaccination = String(localized: "First vaccination (DHP + Lepto)", table: milestonesTable)
        static let firstVetVisit = String(localized: "First vet visit", table: milestonesTable)
        static let firstDewormingHome = String(localized: "First deworming (home)", table: milestonesTable)
        static let secondVaccination = String(localized: "Second vaccination (DHP + Lepto + Rabies)", table: milestonesTable)
        static let thirdVaccination = String(localized: "Third vaccination (cocktail)", table: milestonesTable)
        static let neuteredDiscussion = String(localized: "Spay/neuter discussion with vet", table: milestonesTable)
        static let yearlyVaccination = String(localized: "Yearly vaccination", table: milestonesTable)

        // Milestone labels (localized versions of labelKeys)
        static let milestoneFirstDewormingBreeder = String(localized: "First deworming (breeder)", table: milestonesTable)
        static let milestoneFirstVaccination = String(localized: "First vaccination (DHP + Lepto)", table: milestonesTable)
        static let milestoneFirstVaccinationDetail = String(localized: "Core vaccination at 8 weeks", table: milestonesTable)
        static let milestoneFirstVetVisit = String(localized: "First vet visit", table: milestonesTable)
        static let milestoneFirstDewormingHome = String(localized: "First deworming (home)", table: milestonesTable)
        static let milestoneSecondVaccination = String(localized: "Second vaccination (DHP + Lepto + Rabies)", table: milestonesTable)
        static let milestoneSecondVaccinationDetail = String(localized: "Booster vaccination at 12 weeks", table: milestonesTable)
        static let milestoneThirdVaccination = String(localized: "Third vaccination (cocktail)", table: milestonesTable)
        static let milestoneThirdVaccinationDetail = String(localized: "Final puppy vaccination at 16 weeks", table: milestonesTable)
        static let milestoneNeuteredDiscussion = String(localized: "Spay/neuter discussion with vet", table: milestonesTable)
        static let milestoneYearlyVaccination = String(localized: "Yearly vaccination", table: milestonesTable)

        // Developmental milestones
        static let milestoneSocializationStart = String(localized: "Socialization window begins", table: milestonesTable)
        static let milestoneSocializationStartDetail = String(localized: "Critical period for positive experiences starts now", table: milestonesTable)
        static let milestoneSocializationPeak = String(localized: "Peak socialization period", table: milestonesTable)
        static let milestoneSocializationPeakDetail = String(localized: "Most receptive time for new experiences", table: milestonesTable)
        static let milestoneSocializationEnd = String(localized: "Socialization window closing", table: milestonesTable)
        static let milestoneSocializationEndDetail = String(localized: "Window is narrowing - focus on remaining exposures", table: milestonesTable)
        static let milestoneFearPeriod1 = String(localized: "First fear period", table: milestonesTable)
        static let milestoneFearPeriod1Detail = String(localized: "Be extra gentle with new experiences", table: milestonesTable)
        static let milestoneFearPeriod2 = String(localized: "Second fear period", table: milestonesTable)
        static let milestoneFearPeriod2Detail = String(localized: "Temporary increase in fearfulness - stay patient", table: milestonesTable)

        // Administrative milestones
        static let milestoneMicrochipRegistration = String(localized: "Microchip registration", table: milestonesTable)
        static let milestoneInsuranceSetup = String(localized: "Pet insurance setup", table: milestonesTable)
        static let milestoneInsuranceSetupDetail = String(localized: "Consider health insurance coverage", table: milestonesTable)
        static let milestoneDogLicense = String(localized: "Dog license", table: milestonesTable)
        static let milestoneDogLicenseDetail = String(localized: "Register with your municipality if required", table: milestonesTable)

        // Custom milestone (Otis+)
        static let customMilestoneTitle = String(localized: "Title", table: milestonesTable)
        static let customMilestoneDate = String(localized: "Date", table: milestonesTable)
        static let customMilestoneCategory = String(localized: "Category", table: milestonesTable)
        static let customMilestoneReminder = String(localized: "Reminder", table: milestonesTable)
        static let customMilestoneReminderDays = String(localized: "days before", table: milestonesTable)

        // Milestone timing
        static let photoAdded = String(localized: "Photo added", table: milestonesTable)
        static let addPhotoButton = String(localized: "Add photo", table: milestonesTable)
        static let reminderNextOccurrence = String(localized: "Add reminder for next occurrence", table: milestonesTable)
        static let optionalNotes = String(localized: "Optional notes about this milestone", table: milestonesTable)
        static let calendarHelpText = String(localized: "Add this milestone to your default calendar with a reminder", table: milestonesTable)

        static func inDays(_ days: Int) -> String {
            String(localized: "in \(days)d", table: milestonesTable)
        }

        static func daysOverdue(_ days: Int) -> String {
            String(localized: "\(days)d overdue", table: milestonesTable)
        }

        static func daysAgo(_ days: Int) -> String {
            String(localized: "\(days)d ago", table: milestonesTable)
        }
    }

    // MARK: - This Week Card
    enum ThisWeek {
        static let title = String(localized: "This Week", table: table)
        static let upcoming = String(localized: "Upcoming", table: table)
        static let socializationActive = String(localized: "Socialization active", table: table)
        static let windowEnded = String(localized: "Window ended", table: table)
        static let exposures = String(localized: "exposures", table: table)
        static let categories = String(localized: "categories", table: table)
        static let focusOn = String(localized: "Focus on:", table: table)
    }
}
