//
//  PendingMedication.swift
//  OllieShared
//
//  Represents a medication dose that is pending completion

import Foundation

/// A medication dose that needs to be taken
public struct PendingMedication: Identifiable, Sendable {
    public let id: UUID
    public let medication: Medication
    public let time: MedicationTime
    public let scheduledDate: Date
    public let isOverdue: Bool

    public init(
        medication: Medication,
        time: MedicationTime,
        scheduledDate: Date,
        isOverdue: Bool
    ) {
        self.id = UUID(uuidString: "\(medication.id.uuidString.prefix(8))-\(time.id.uuidString.prefix(8))-\(scheduledDate.timeIntervalSince1970)".padding(toLength: 36, withPad: "0", startingAt: 0)) ?? UUID()
        self.medication = medication
        self.time = time
        self.scheduledDate = scheduledDate
        self.isOverdue = isOverdue
    }
}
