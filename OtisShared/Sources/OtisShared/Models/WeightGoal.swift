//
//  WeightGoal.swift
//  OtisShared
//
//  Weight goal tracking for adult dogs - target weight management
//

import Foundation

// MARK: - Weight Goal Direction

/// Direction of weight goal
public enum WeightGoalDirection: String, Codable, Sendable, CaseIterable {
    case lose
    case maintain
    case gain

    public var label: String {
        switch self {
        case .lose: return "Lose weight"
        case .maintain: return "Maintain weight"
        case .gain: return "Gain weight"
        }
    }

    public var icon: String {
        switch self {
        case .lose: return "arrow.down.circle.fill"
        case .maintain: return "equal.circle.fill"
        case .gain: return "arrow.up.circle.fill"
        }
    }

    public var color: String {
        switch self {
        case .lose: return "otisWarning"
        case .maintain: return "otisSuccess"
        case .gain: return "otisAccent"
        }
    }
}

// MARK: - Weight Goal

/// A weight management goal for a dog
public struct WeightGoal: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var targetWeightKg: Double
    public var startWeightKg: Double
    public var startDate: Date
    public var targetDate: Date?                   // Optional target date
    public var isActive: Bool
    public var note: String?
    public var createdAt: Date
    public var modifiedAt: Date

    /// Human-readable name for logging (conforms to StorableModel)
    public var displayName: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        let target = formatter.string(from: NSNumber(value: targetWeightKg)) ?? "\(targetWeightKg)"
        return "\(target) kg goal"
    }

    public init(
        id: UUID = UUID(),
        targetWeightKg: Double,
        startWeightKg: Double,
        startDate: Date = Date(),
        targetDate: Date? = nil,
        isActive: Bool = true,
        note: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.targetWeightKg = targetWeightKg
        self.startWeightKg = startWeightKg
        self.startDate = startDate
        self.targetDate = targetDate
        self.isActive = isActive
        self.note = note
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    // MARK: - Computed Properties

    /// The direction of the weight goal
    public var direction: WeightGoalDirection {
        if abs(targetWeightKg - startWeightKg) < 0.1 {
            return .maintain
        }
        return targetWeightKg < startWeightKg ? .lose : .gain
    }

    /// Total weight change needed (positive for gain, negative for loss)
    public var totalChangeNeeded: Double {
        targetWeightKg - startWeightKg
    }

    /// Absolute weight difference
    public var absoluteChangeNeeded: Double {
        abs(totalChangeNeeded)
    }

    /// Days since goal started
    public var daysSinceStart: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    }

    /// Days remaining until target date (nil if no target date)
    public var daysRemaining: Int? {
        guard let targetDate = targetDate else { return nil }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0)
    }

    /// Whether the target date has passed
    public var isOverdue: Bool {
        guard let targetDate = targetDate else { return false }
        return Date() > targetDate
    }

    // MARK: - Progress Calculation

    /// Calculate progress percentage based on current weight
    /// - Parameter currentWeightKg: The current weight
    /// - Returns: Progress percentage (0-100+, can exceed 100 if goal surpassed)
    public func progressPercentage(currentWeightKg: Double) -> Double {
        guard absoluteChangeNeeded > 0 else { return 100.0 }

        let currentChange = abs(currentWeightKg - startWeightKg)

        // Check if moving in right direction
        let isCorrectDirection: Bool
        switch direction {
        case .lose:
            isCorrectDirection = currentWeightKg <= startWeightKg
        case .gain:
            isCorrectDirection = currentWeightKg >= startWeightKg
        case .maintain:
            return currentWeightKg == startWeightKg ? 100.0 : max(0, 100.0 - (currentChange / absoluteChangeNeeded * 100.0))
        }

        if !isCorrectDirection {
            return 0.0
        }

        return min(100.0, (currentChange / absoluteChangeNeeded) * 100.0)
    }

    /// Weight remaining to reach goal (positive if not yet reached)
    /// - Parameter currentWeightKg: The current weight
    /// - Returns: Weight remaining (positive means not yet achieved)
    public func weightRemaining(currentWeightKg: Double) -> Double {
        switch direction {
        case .lose:
            return max(0, currentWeightKg - targetWeightKg)
        case .gain:
            return max(0, targetWeightKg - currentWeightKg)
        case .maintain:
            return abs(currentWeightKg - targetWeightKg)
        }
    }

    /// Whether the goal has been achieved
    /// - Parameter currentWeightKg: The current weight
    /// - Returns: True if goal achieved (within 0.1 kg tolerance)
    public func isAchieved(currentWeightKg: Double) -> Bool {
        switch direction {
        case .lose:
            return currentWeightKg <= targetWeightKg
        case .gain:
            return currentWeightKg >= targetWeightKg
        case .maintain:
            return abs(currentWeightKg - targetWeightKg) < 0.1
        }
    }

    /// Weekly weight change rate needed to reach goal on time
    /// - Returns: kg per week (positive for gain, negative for loss), nil if no target date
    public func weeklyRateNeeded(currentWeightKg: Double) -> Double? {
        guard let weeksRemaining = daysRemaining.map({ Double($0) / 7.0 }),
              weeksRemaining > 0 else { return nil }

        let remaining = targetWeightKg - currentWeightKg
        return remaining / weeksRemaining
    }
}

// MARK: - Factory Methods

public extension WeightGoal {

    /// Create a weight loss goal
    static func loseWeight(from currentKg: Double, to targetKg: Double, by targetDate: Date? = nil) -> WeightGoal {
        WeightGoal(
            targetWeightKg: min(currentKg, targetKg),
            startWeightKg: currentKg,
            targetDate: targetDate
        )
    }

    /// Create a weight gain goal
    static func gainWeight(from currentKg: Double, to targetKg: Double, by targetDate: Date? = nil) -> WeightGoal {
        WeightGoal(
            targetWeightKg: max(currentKg, targetKg),
            startWeightKg: currentKg,
            targetDate: targetDate
        )
    }

    /// Create a weight maintenance goal
    static func maintain(at weightKg: Double) -> WeightGoal {
        WeightGoal(
            targetWeightKg: weightKg,
            startWeightKg: weightKg
        )
    }
}

// MARK: - Array Extensions

public extension Array where Element == WeightGoal {
    /// Get the currently active goal
    var active: WeightGoal? {
        first { $0.isActive }
    }

    /// Sort by start date (newest first)
    func sortedByStartDate() -> [WeightGoal] {
        sorted { $0.startDate > $1.startDate }
    }
}
