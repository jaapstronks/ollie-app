//
//  WeightMeasurement.swift
//  OllieShared
//
//  Domain model for weight measurements - separated from daily events
//  for better alignment with the actual rhythm of weight tracking (monthly/vet visits)
//

import Foundation

/// A weight measurement for a dog
public struct WeightMeasurement: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var date: Date              // When measurement was taken
    public var weightKg: Double        // Always stored in kg
    public var note: String?
    public var createdAt: Date
    public var modifiedAt: Date

    /// Human-readable name for logging (conforms to StorableModel)
    public var displayName: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(String(format: "%.2f", weightKg)) kg on \(formatter.string(from: date))"
    }

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        weightKg: Double,
        note: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.note = note
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// Calculate the puppy's age in weeks at the time of this measurement
    public func ageWeeks(birthDate: Date) -> Int {
        let calendar = Calendar.current
        let weeks = calendar.dateComponents([.weekOfYear], from: birthDate, to: date).weekOfYear ?? 0
        return max(0, weeks)
    }

    /// Calculate the puppy's age in days at the time of this measurement
    public func ageDays(birthDate: Date) -> Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: birthDate, to: date).day ?? 0
        return max(0, days)
    }
}

// MARK: - Factory Methods

public extension WeightMeasurement {
    /// Create a weight measurement with current timestamp
    static func now(weightKg: Double, note: String? = nil) -> WeightMeasurement {
        WeightMeasurement(
            date: Date(),
            weightKg: weightKg,
            note: note
        )
    }
}

// MARK: - Array Extensions

public extension Array where Element == WeightMeasurement {
    /// Sort measurements by date (oldest first)
    func sortedByDate() -> [WeightMeasurement] {
        sorted { $0.date < $1.date }
    }

    /// Sort measurements by date (newest first)
    func sortedByDateDescending() -> [WeightMeasurement] {
        sorted { $0.date > $1.date }
    }

    /// Get the most recent measurement
    var latest: WeightMeasurement? {
        self.max { $0.date < $1.date }
    }

    /// Get the oldest measurement
    var earliest: WeightMeasurement? {
        self.min { $0.date < $1.date }
    }
}
