//
//  SharedProfile.swift
//  Ollie-app
//
//  Minimal profile for App Intents - shared via App Group

import Foundation
import OllieShared

/// Minimal profile struct shared with App Intents via App Group
/// Contains only what intents need to function
struct SharedProfile: Codable {
    let name: String
    let legacyPremiumUnlocked: Bool

    /// Core logging is always free now - no time-gate
    var canLogEvents: Bool {
        true  // Always true in the new subscription model
    }

    /// Create from full PuppyProfile
    init(from profile: PuppyProfile) {
        self.name = profile.name
        self.legacyPremiumUnlocked = profile.legacyPremiumUnlocked
    }

    /// Direct initializer for decoding
    init(name: String, legacyPremiumUnlocked: Bool) {
        self.name = name
        self.legacyPremiumUnlocked = legacyPremiumUnlocked
    }

    // MARK: - Codable Migration

    private enum CodingKeys: String, CodingKey {
        case name
        case isPremiumUnlocked  // Legacy key for backwards compatibility
        case legacyPremiumUnlocked
        case freeDaysRemaining  // Legacy key (ignored)
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
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(legacyPremiumUnlocked, forKey: .legacyPremiumUnlocked)
    }
}
