//
//  SharedProfile.swift
//  Otis-app
//
//  Minimal profile for App Intents - shared via App Group

import Foundation
import OtisShared

/// Minimal profile struct shared with App Intents via App Group
/// Contains only what intents need to function
struct SharedProfile: Codable {
    let name: String
    let legacyPremiumUnlocked: Bool
    /// ID of the current user's household member (for event attribution)
    let currentUserMemberId: UUID?

    /// Core logging is always free now - no time-gate
    var canLogEvents: Bool {
        true  // Always true in the new subscription model
    }

    /// Create from full PuppyProfile
    init(from profile: PuppyProfile) {
        self.name = profile.name
        self.legacyPremiumUnlocked = profile.legacyPremiumUnlocked
        self.currentUserMemberId = profile.householdMembers.currentUser()?.id
    }

    /// Direct initializer for decoding
    init(name: String, legacyPremiumUnlocked: Bool, currentUserMemberId: UUID? = nil) {
        self.name = name
        self.legacyPremiumUnlocked = legacyPremiumUnlocked
        self.currentUserMemberId = currentUserMemberId
    }

    // MARK: - Codable Migration

    private enum CodingKeys: String, CodingKey {
        case name
        case isPremiumUnlocked  // Legacy key for backwards compatibility
        case legacyPremiumUnlocked
        case freeDaysRemaining  // Legacy key (ignored)
        case currentUserMemberId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)

        // Try new field first, fall back to old
        if let legacy = try container.decodeIfPresent(Bool.self, forKey: .legacyPremiumUnlocked) {
            legacyPremiumUnlocked = legacy
        } else if let old = try container.decodeIfPresent(Bool.self, forKey: .isPremiumUnlocked) {
            legacyPremiumUnlocked = old
        } else {
            legacyPremiumUnlocked = false
        }

        currentUserMemberId = try container.decodeIfPresent(UUID.self, forKey: .currentUserMemberId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(legacyPremiumUnlocked, forKey: .legacyPremiumUnlocked)
        try container.encodeIfPresent(currentUserMemberId, forKey: .currentUserMemberId)
    }
}
