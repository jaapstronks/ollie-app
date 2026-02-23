//
//  MedicationCompletion.swift
//  OllieShared
//
//  Track daily medication completions

import Foundation

/// Records when a medication dose was taken
public struct MedicationCompletion: Codable, Identifiable, Sendable {
    public var id: UUID
    public var medicationId: UUID
    public var timeId: UUID
    public var date: Date
    public var completedAt: Date

    public init(
        id: UUID = UUID(),
        medicationId: UUID,
        timeId: UUID,
        date: Date,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.medicationId = medicationId
        self.timeId = timeId
        self.date = Calendar.current.startOfDay(for: date)
        self.completedAt = completedAt
    }
}
