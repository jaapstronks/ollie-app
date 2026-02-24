//
//  MasteredSkill.swift
//  OllieShared
//
//  Records when a training skill was mastered
//

import Foundation

/// Records when a training skill was mastered
public struct MasteredSkill: Codable, Identifiable, Sendable, Equatable {
    public var id: UUID
    public var skillId: String
    public var masteredAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        skillId: String,
        masteredAt: Date = Date(),
        modifiedAt: Date? = nil
    ) {
        self.id = id
        self.skillId = skillId
        self.masteredAt = masteredAt
        self.modifiedAt = modifiedAt ?? masteredAt
    }

    // MARK: - Coding Keys

    public enum CodingKeys: String, CodingKey {
        case id
        case skillId = "skill_id"
        case masteredAt = "mastered_at"
        case modifiedAt = "modified_at"
    }

    // MARK: - Custom Decoding (handle missing modifiedAt for migration)

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        skillId = try container.decode(String.self, forKey: .skillId)
        masteredAt = try container.decode(Date.self, forKey: .masteredAt)
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? masteredAt
    }

    // MARK: - Helpers

    /// Create an updated copy with new modifiedAt timestamp
    public func withUpdatedTimestamp() -> MasteredSkill {
        var updated = self
        updated.modifiedAt = Date()
        return updated
    }
}
