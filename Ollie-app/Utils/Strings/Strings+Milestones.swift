//
//  Strings+Milestones.swift
//  Otis-app
//
//  Milestones strings
//

import Foundation

private let table = "Milestones"

extension Strings {

    // MARK: - Milestones
    enum Milestones {
        static let title = String(localized: "Milestones", table: table)
        static let done = String(localized: "Completed", table: table)
        static let nextUp = String(localized: "Next up", table: table)
        static let overdue = String(localized: "Overdue", table: table)
        static let medicalMilestones = String(localized: "Medical Milestones", table: table)
        static let noMedicalMilestones = String(localized: "No medical milestones yet", table: table)

        // Milestone sections
        static let upcomingMilestones = String(localized: "Coming Up", table: table)
        static let completedMilestones = String(localized: "Completed", table: table)
        static let addMilestone = String(localized: "Add Milestone", table: table)
        static let completeMilestone = String(localized: "Mark Complete", table: table)
        static let uncompleteMilestone = String(localized: "Mark Incomplete", table: table)

        // Milestone completion sheet
        static let completeTitle = String(localized: "Complete Milestone", table: table)
        static let completionDate = String(localized: "Completion date", table: table)
        static let addNotes = String(localized: "Add notes", table: table)
        static let notesPlaceholder = String(localized: "Optional notes about this milestone...", table: table)
        static let vetClinic = String(localized: "Vet clinic", table: table)
        static let vetClinicPlaceholder = String(localized: "Clinic name (optional)", table: table)
        static let addToCalendar = String(localized: "Add to Calendar", table: table)
        static let removeFromCalendar = String(localized: "Remove from Calendar", table: table)
        static let addPhoto = String(localized: "Add Photo", table: table)

        // Default milestones (vaccination schedule)
        static let firstDewormingBreeder = String(localized: "First deworming (breeder)", table: table)
        static let firstVaccination = String(localized: "First vaccination (DHP + Lepto)", table: table)
        static let firstVaccinationDetail = String(localized: "Core vaccination at 8 weeks", table: table)
        static let firstVetVisit = String(localized: "First vet visit", table: table)
        static let firstDewormingHome = String(localized: "First deworming (home)", table: table)
        static let secondVaccination = String(localized: "Second vaccination (DHP + Lepto + Rabies)", table: table)
        static let secondVaccinationDetail = String(localized: "Booster vaccination at 12 weeks", table: table)
        static let thirdVaccination = String(localized: "Third vaccination (cocktail)", table: table)
        static let thirdVaccinationDetail = String(localized: "Final puppy vaccination at 16 weeks", table: table)
        static let neuteredDiscussion = String(localized: "Spay/neuter discussion with vet", table: table)
        static let yearlyVaccination = String(localized: "Yearly vaccination", table: table)

        // Developmental milestones
        static let socializationStart = String(localized: "Socialization window begins", table: table)
        static let socializationStartDetail = String(localized: "Critical period for positive experiences starts now", table: table)
        static let socializationPeak = String(localized: "Peak socialization period", table: table)
        static let socializationPeakDetail = String(localized: "Most receptive time for new experiences", table: table)
        static let socializationEnd = String(localized: "Socialization window closing", table: table)
        static let socializationEndDetail = String(localized: "Window is narrowing - focus on remaining exposures", table: table)
        static let fearPeriod1 = String(localized: "First fear period", table: table)
        static let fearPeriod1Detail = String(localized: "Be extra gentle with new experiences", table: table)
        static let fearPeriod2 = String(localized: "Second fear period", table: table)
        static let fearPeriod2Detail = String(localized: "Temporary increase in fearfulness - stay patient", table: table)

        // Administrative milestones
        static let microchipRegistration = String(localized: "Microchip registration", table: table)
        static let insuranceSetup = String(localized: "Pet insurance setup", table: table)
        static let insuranceSetupDetail = String(localized: "Consider health insurance coverage", table: table)
        static let dogLicense = String(localized: "Dog license", table: table)
        static let dogLicenseDetail = String(localized: "Register with your municipality if required", table: table)

        // Custom milestone (Otis+)
        static let customMilestoneTitle = String(localized: "Title", table: table)
        static let customMilestoneDate = String(localized: "Date", table: table)
        static let customMilestoneCategory = String(localized: "Category", table: table)
        static let customMilestoneReminder = String(localized: "Reminder", table: table)
        static let customMilestoneReminderDays = String(localized: "days before", table: table)

        // Milestone timing
        static let photoAdded = String(localized: "Photo added", table: table)
        static let addPhotoButton = String(localized: "Add photo", table: table)
        static let reminderNextOccurrence = String(localized: "Add reminder for next occurrence", table: table)
        static let optionalNotes = String(localized: "Optional notes about this milestone", table: table)
        static let calendarHelpText = String(localized: "Add this milestone to your default calendar with a reminder", table: table)
        static let comingUp = String(localized: "Coming up", table: table)

        static func inDays(_ days: Int) -> String {
            String(localized: "in \(days)d", table: table)
        }

        static func daysOverdue(_ days: Int) -> String {
            String(localized: "\(days)d overdue", table: table)
        }

        static func daysAgo(_ days: Int) -> String {
            String(localized: "\(days)d ago", table: table)
        }
    }
}
