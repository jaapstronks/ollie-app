//
//  MedicationCompletion.swift
//  Ollie-app
//
//  Track daily medication completions
//

import Foundation

/// Records when a medication dose was taken
struct MedicationCompletion: Codable, Identifiable {
    var id: UUID
    var medicationId: UUID
    var timeId: UUID
    var date: Date                       // Calendar date (start of day)
    var completedAt: Date                // Actual completion timestamp

    init(
        id: UUID = UUID(),
        medicationId: UUID,
        timeId: UUID,
        date: Date,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.medicationId = medicationId
        self.timeId = timeId
        // Normalize to start of day
        self.date = Calendar.current.startOfDay(for: date)
        self.completedAt = completedAt
    }
}
