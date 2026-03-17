//
//  BodyConditionScore.swift
//  OtisShared
//
//  Body condition scoring for dogs using the 9-point scale
//

import Foundation

// MARK: - BCS Category

/// Body condition score categories on the 9-point scale
public enum BCSCategory: Int, Codable, Sendable, CaseIterable {
    case emaciated = 1
    case veryThin = 2
    case thin = 3
    case underweight = 4
    case ideal = 5
    case slightlyOverweight = 6
    case overweight = 7
    case obese = 8
    case morbidlyObese = 9

    public init?(score: Int) {
        guard (1...9).contains(score) else { return nil }
        self.init(rawValue: score)
    }

    public var score: Int { rawValue }

    public var label: String {
        switch self {
        case .emaciated: return "Emaciated"
        case .veryThin: return "Very thin"
        case .thin: return "Thin"
        case .underweight: return "Underweight"
        case .ideal: return "Ideal"
        case .slightlyOverweight: return "Slightly overweight"
        case .overweight: return "Overweight"
        case .obese: return "Obese"
        case .morbidlyObese: return "Severely obese"
        }
    }

    public var shortLabel: String {
        switch self {
        case .emaciated: return "1"
        case .veryThin: return "2"
        case .thin: return "3"
        case .underweight: return "4"
        case .ideal: return "5"
        case .slightlyOverweight: return "6"
        case .overweight: return "7"
        case .obese: return "8"
        case .morbidlyObese: return "9"
        }
    }

    public var description: String {
        switch self {
        case .emaciated:
            return "Ribs, spine, and hip bones are highly visible. No body fat. Severe muscle wasting."
        case .veryThin:
            return "Ribs easily visible with no fat covering. Tops of spine visible. Pronounced waist."
        case .thin:
            return "Ribs easily felt with minimal fat covering. Waist easily visible from above."
        case .underweight:
            return "Ribs easily felt with slight fat covering. Waist visible from above. Slight abdominal tuck."
        case .ideal:
            return "Ribs felt without excess fat covering. Waist visible from above. Abdominal tuck present."
        case .slightlyOverweight:
            return "Ribs felt with slight excess fat covering. Waist visible from above but less defined."
        case .overweight:
            return "Ribs difficult to feel with moderate fat covering. Waist barely visible. No abdominal tuck."
        case .obese:
            return "Ribs very difficult to feel under heavy fat covering. No waist visible. Fat deposits present."
        case .morbidlyObese:
            return "Ribs not palpable. Obvious fat deposits over spine and tail base. No waist or tuck."
        }
    }

    public var icon: String {
        switch self {
        case .emaciated, .veryThin, .thin, .underweight:
            return "arrow.down.circle.fill"
        case .ideal:
            return "checkmark.circle.fill"
        case .slightlyOverweight, .overweight, .obese, .morbidlyObese:
            return "arrow.up.circle.fill"
        }
    }

    public var color: String {
        switch self {
        case .emaciated, .morbidlyObese:
            return "otisDanger"
        case .veryThin, .thin, .obese:
            return "otisWarning"
        case .underweight, .slightlyOverweight, .overweight:
            return "otisInfo"
        case .ideal:
            return "otisSuccess"
        }
    }

    /// Whether this score is within the healthy range (4-6)
    public var isHealthy: Bool {
        (4...6).contains(rawValue)
    }

    /// Recommendation based on the score
    public var recommendation: String {
        switch self {
        case .emaciated:
            return "Urgent: Consult your veterinarian immediately for a nutritional assessment."
        case .veryThin:
            return "Increase food intake and consult your vet to rule out underlying conditions."
        case .thin:
            return "Consider gradually increasing daily food portions."
        case .underweight:
            return "Slightly increase food or add healthy treats."
        case .ideal:
            return "Maintain current diet and exercise routine."
        case .slightlyOverweight:
            return "Slightly reduce treats or increase activity."
        case .overweight:
            return "Reduce daily food intake and increase exercise duration."
        case .obese:
            return "Consult your vet for a weight management plan."
        case .morbidlyObese:
            return "Urgent: Work with your veterinarian on a structured weight loss program."
        }
    }
}

// MARK: - Body Condition Score

/// A recorded body condition score assessment
public struct BodyConditionScore: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var score: Int                          // 1-9 scale
    public var note: String?
    public var createdAt: Date
    public var modifiedAt: Date

    /// Human-readable name for logging (conforms to StorableModel)
    public var displayName: String {
        "BCS \(score)/9"
    }

    public init(
        id: UUID = UUID(),
        score: Int,
        note: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.score = max(1, min(9, score))  // Clamp to 1-9
        self.note = note
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    // MARK: - Computed Properties

    /// The BCS category for this score
    public var category: BCSCategory {
        BCSCategory(score: score) ?? .ideal
    }

    /// Whether this is a healthy score
    public var isHealthy: Bool {
        category.isHealthy
    }

    /// Formatted date string
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }
}

// MARK: - Factory Methods

public extension BodyConditionScore {
    /// Create a BCS assessment with current timestamp
    static func now(score: Int, note: String? = nil) -> BodyConditionScore {
        BodyConditionScore(score: score, note: note)
    }
}

// MARK: - Array Extensions

public extension Array where Element == BodyConditionScore {
    /// Sort by date (newest first)
    func sortedByDate() -> [BodyConditionScore] {
        sorted { $0.createdAt > $1.createdAt }
    }

    /// Get the most recent assessment
    var latest: BodyConditionScore? {
        self.max(by: { $0.createdAt < $1.createdAt })
    }

    /// Get the oldest assessment
    var earliest: BodyConditionScore? {
        self.min(by: { $0.createdAt < $1.createdAt })
    }

    /// Calculate the trend (positive = gaining, negative = losing)
    var trend: Int? {
        guard count >= 2,
              let latest = latest,
              let previous = sorted(by: { $0.createdAt < $1.createdAt }).dropLast().last else {
            return nil
        }
        return latest.score - previous.score
    }

    /// Average score
    var averageScore: Double? {
        guard !isEmpty else { return nil }
        return Double(reduce(0) { $0 + $1.score }) / Double(count)
    }
}
