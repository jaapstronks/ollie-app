import Foundation

// MARK: - VetVisitTip

/// Represents a contextual tip to discuss with the vet during an upcoming visit.
/// Tips are generated based on breed, age, conditions, and recent symptoms.
public struct VetVisitTip: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let category: TipCategory
    public let title: String
    public let description: String
    public let source: TipSource
    public let priority: TipPriority
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        category: TipCategory,
        title: String,
        description: String,
        source: TipSource,
        priority: TipPriority,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.description = description
        self.source = source
        self.priority = priority
        self.createdAt = createdAt
    }

    // MARK: - TipCategory

    public enum TipCategory: String, CaseIterable, Sendable, Equatable {
        case breedRisk
        case ageRelated
        case conditionRelated
        case recentSymptom
        case preventive

        public var icon: String {
            switch self {
            case .breedRisk: return "pawprint.fill"
            case .ageRelated: return "birthday.cake"
            case .conditionRelated: return "heart.text.square.fill"
            case .recentSymptom: return "waveform.path.ecg"
            case .preventive: return "shield.checkered"
            }
        }

        public var sortOrder: Int {
            switch self {
            case .recentSymptom: return 0
            case .conditionRelated: return 1
            case .breedRisk: return 2
            case .ageRelated: return 3
            case .preventive: return 4
            }
        }
    }

    // MARK: - TipSource

    public enum TipSource: Sendable, Equatable {
        case breed(String)
        case age(months: Int)
        case condition(HealthConditionType)
        case symptom(SymptomType, count: Int)
        case preventive(String)

        public var description: String {
            switch self {
            case .breed(let breed):
                return "Based on \(breed) breed profile"
            case .age(let months):
                let years = months / 12
                let remainingMonths = months % 12
                if years > 0 && remainingMonths > 0 {
                    return "Based on age (\(years)y \(remainingMonths)m)"
                } else if years > 0 {
                    return "Based on age (\(years) years)"
                } else {
                    return "Based on age (\(months) months)"
                }
            case .condition(let condition):
                return "Related to \(condition.rawValue.replacingOccurrences(of: "_", with: " "))"
            case .symptom(_, let count):
                return "Logged \(count) time\(count == 1 ? "" : "s") recently"
            case .preventive(let reason):
                return reason
            }
        }
    }

    // MARK: - TipPriority

    public enum TipPriority: Int, Comparable, Sendable, Equatable {
        case low = 1
        case medium = 2
        case high = 3

        public static func < (lhs: TipPriority, rhs: TipPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        public var colorName: String {
            switch self {
            case .low: return "otisInfo"
            case .medium: return "otisWarning"
            case .high: return "otisDestructive"
            }
        }
    }
}

// MARK: - Tip Grouping

extension Array where Element == VetVisitTip {

    /// Groups tips by category, sorted by priority within each group
    public func groupedByCategory() -> [(category: VetVisitTip.TipCategory, tips: [VetVisitTip])] {
        let grouped = Dictionary(grouping: self) { $0.category }
        return grouped
            .map { (category: $0.key, tips: $0.value.sorted { $0.priority > $1.priority }) }
            .sorted { $0.category.sortOrder < $1.category.sortOrder }
    }

    /// Returns tips sorted by priority (highest first)
    public func sortedByPriority() -> [VetVisitTip] {
        sorted { $0.priority > $1.priority }
    }

    /// Returns only high priority tips
    public var highPriority: [VetVisitTip] {
        filter { $0.priority == .high }
    }
}
