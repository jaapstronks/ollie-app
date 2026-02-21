//
//  PendingMedication.swift
//  Ollie-app
//
//  Represents a medication dose that is pending completion
//

import Foundation

/// A medication dose that needs to be taken
struct PendingMedication: Identifiable {
    let id: UUID
    let medication: Medication
    let time: MedicationTime
    let scheduledDate: Date
    let isOverdue: Bool

    init(
        medication: Medication,
        time: MedicationTime,
        scheduledDate: Date,
        isOverdue: Bool
    ) {
        // Use a composite ID from medication and time for uniqueness
        self.id = UUID(uuidString: "\(medication.id.uuidString.prefix(8))-\(time.id.uuidString.prefix(8))-\(scheduledDate.timeIntervalSince1970)".padding(toLength: 36, withPad: "0", startingAt: 0)) ?? UUID()
        self.medication = medication
        self.time = time
        self.scheduledDate = scheduledDate
        self.isOverdue = isOverdue
    }
}
