//
//  Strings+Medications.swift
//  OtisShared
//
//  Medication tracking strings.
//

import Foundation

extension Strings {
    // MARK: - Medications
    public enum Medications {
        public static var title: String { String(localized: "Medications", bundle: Strings.bundle) }
        public static var addMedication: String { String(localized: "Add medication", bundle: Strings.bundle) }
        public static var editMedication: String { String(localized: "Edit medication", bundle: Strings.bundle) }
        public static var name: String { String(localized: "Name", bundle: Strings.bundle) }
        public static var instructions: String { String(localized: "Instructions", bundle: Strings.bundle) }
        public static var instructionsPlaceholder: String { String(localized: "Dosage, notes...", bundle: Strings.bundle) }
        public static var schedule: String { String(localized: "Schedule", bundle: Strings.bundle) }
        public static var daily: String { String(localized: "Daily", bundle: Strings.bundle) }
        public static var weekly: String { String(localized: "Weekly", bundle: Strings.bundle) }
        public static var times: String { String(localized: "Times", bundle: Strings.bundle) }
        public static var addTime: String { String(localized: "Add time", bundle: Strings.bundle) }
        public static var linkToMeal: String { String(localized: "Link to meal", bundle: Strings.bundle) }
        public static var startDate: String { String(localized: "Start date", bundle: Strings.bundle) }
        public static var endDate: String { String(localized: "End date", bundle: Strings.bundle) }
        public static var indefinitely: String { String(localized: "Indefinitely", bundle: Strings.bundle) }
        public static var untilDate: String { String(localized: "Until date", bundle: Strings.bundle) }
        public static var markAsDone: String { String(localized: "Slide to complete", bundle: Strings.bundle) }
        public static var overdue: String { String(localized: "Overdue", bundle: Strings.bundle) }
        public static var scheduled: String { String(localized: "scheduled", bundle: Strings.bundle) }
        public static var noMedications: String { String(localized: "No medications", bundle: Strings.bundle) }
        public static func noMedicationsHint(name: String) -> String {
            String(localized: "Tap to add \(name)'s medications", bundle: Strings.bundle)
        }
        /// Legacy static version
        public static var noMedicationsHint: String { String(localized: "Tap to add medications", bundle: Strings.bundle) }
        public static var active: String { String(localized: "Active", bundle: Strings.bundle) }
        public static var paused: String { String(localized: "Paused", bundle: Strings.bundle) }
        public static var icon: String { String(localized: "Icon", bundle: Strings.bundle) }
        public static var daysOfWeek: String { String(localized: "Days of week", bundle: Strings.bundle) }
        public static var duration: String { String(localized: "Duration", bundle: Strings.bundle) }
        public static var sunday: String { String(localized: "Sun", bundle: Strings.bundle) }
        public static var monday: String { String(localized: "Mon", bundle: Strings.bundle) }
        public static var tuesday: String { String(localized: "Tue", bundle: Strings.bundle) }
        public static var wednesday: String { String(localized: "Wed", bundle: Strings.bundle) }
        public static var thursday: String { String(localized: "Thu", bundle: Strings.bundle) }
        public static var friday: String { String(localized: "Fri", bundle: Strings.bundle) }
        public static var saturday: String { String(localized: "Sat", bundle: Strings.bundle) }
        public static func dayShort(_ index: Int) -> String {
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
        public static var deleteConfirmTitle: String { String(localized: "Delete medication?", bundle: Strings.bundle) }
        public static var deleteConfirmMessage: String { String(localized: "This will remove the medication from your schedule.", bundle: Strings.bundle) }
    }
}
