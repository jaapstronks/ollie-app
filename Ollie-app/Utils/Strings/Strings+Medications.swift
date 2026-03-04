//
//  Strings+Medications.swift
//  Otis-app
//
//  Medications strings
//

import Foundation

private let table = "Medications"

extension Strings {

    // MARK: - Medications
    enum Medications {
        static let title = String(localized: "Medications", table: table)
        static let addMedication = String(localized: "Add medication", table: table)
        static let editMedication = String(localized: "Edit medication", table: table)
        static let name = String(localized: "Name", table: table)
        static let instructions = String(localized: "Instructions", table: table)
        static let instructionsPlaceholder = String(localized: "Dosage, notes...", table: table)
        static let schedule = String(localized: "Schedule", table: table)
        static let daily = String(localized: "Daily", table: table)
        static let weekly = String(localized: "Weekly", table: table)
        static let times = String(localized: "Times", table: table)
        static let addTime = String(localized: "Add time", table: table)
        static let linkToMeal = String(localized: "Link to meal", table: table)
        static let startDate = String(localized: "Start date", table: table)
        static let endDate = String(localized: "End date", table: table)
        static let indefinitely = String(localized: "Indefinitely", table: table)
        static let untilDate = String(localized: "Until date", table: table)
        static let markAsDone = String(localized: "Slide to complete", table: table)
        static let overdue = String(localized: "Overdue", table: table)
        static let scheduled = String(localized: "scheduled", table: table)
        static let noMedications = String(localized: "No medications", table: table)
        static let noMedicationsHint = String(localized: "Tap to add your puppy's medications", table: table)
        static let active = String(localized: "Active", table: table)
        static let paused = String(localized: "Paused", table: table)
        static let icon = String(localized: "Icon", table: table)
        static let daysOfWeek = String(localized: "Days of week", table: table)
        static let duration = String(localized: "Duration", table: table)

        // Day names (short)
        static let sunday = String(localized: "Sun", table: table)
        static let monday = String(localized: "Mon", table: table)
        static let tuesday = String(localized: "Tue", table: table)
        static let wednesday = String(localized: "Wed", table: table)
        static let thursday = String(localized: "Thu", table: table)
        static let friday = String(localized: "Fri", table: table)
        static let saturday = String(localized: "Sat", table: table)

        static func dayShort(_ index: Int) -> String {
            switch index {
            case 0: return sunday
            case 1: return monday
            case 2: return tuesday
            case 3: return wednesday
            case 4: return thursday
            case 5: return friday
            case 6: return saturday
            default: return ""
            }
        }

        // Delete confirmation
        static let deleteConfirmTitle = String(localized: "Delete medication?", table: table)
        static let deleteConfirmMessage = String(localized: "This will remove the medication from your schedule.", table: table)
    }
}
