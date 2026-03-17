//
//  TheoryProgress.swift
//  Ollie-app
//
//  Tracks local-only theory reading progress per skill.
//  This is not synced to CloudKit - it's per-human, not per-dog.
//

import Foundation

/// Tracks which theory pages have been read for a skill
struct TheoryProgress: Codable, Equatable {
    var skillId: String
    var pagesRead: Set<Int>  // 0-indexed page indices
    var isComplete: Bool
    var completedAt: Date?
    var skipped: Bool  // True if user chose "I already know this"

    init(
        skillId: String,
        pagesRead: Set<Int> = [],
        isComplete: Bool = false,
        completedAt: Date? = nil,
        skipped: Bool = false
    ) {
        self.skillId = skillId
        self.pagesRead = pagesRead
        self.isComplete = isComplete
        self.completedAt = completedAt
        self.skipped = skipped
    }

    /// Calculate completion based on pages read
    mutating func updateCompletion(totalPages: Int) {
        if pagesRead.count >= totalPages && !isComplete {
            isComplete = true
            completedAt = Date()
        }
    }
}
