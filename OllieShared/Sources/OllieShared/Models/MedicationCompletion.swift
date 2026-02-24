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
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        medicationId: UUID,
        timeId: UUID,
        date: Date,
        completedAt: Date = Date(),
        modifiedAt: Date? = nil
    ) {
        self.id = id
        self.medicationId = medicationId
        self.timeId = timeId
        self.date = Calendar.current.startOfDay(for: date)
        self.completedAt = completedAt
        self.modifiedAt = modifiedAt ?? completedAt
    }

    // MARK: - Coding Keys

    public enum CodingKeys: String, CodingKey {
        case id
        case medicationId = "medication_id"
        case timeId = "time_id"
        case date
        case completedAt = "completed_at"
        case modifiedAt = "modified_at"
    }

    // MARK: - Custom Decoding (handle missing modifiedAt for migration)

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        medicationId = try container.decode(UUID.self, forKey: .medicationId)
        timeId = try container.decode(UUID.self, forKey: .timeId)
        date = try container.decode(Date.self, forKey: .date)
        completedAt = try container.decode(Date.self, forKey: .completedAt)
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? completedAt
    }
}
