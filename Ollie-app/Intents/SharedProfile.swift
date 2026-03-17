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
    /// CloudKit record ID of the current user (for event attribution)
    let currentUserRecordID: String?

    /// Core logging is always free now - no time-gate
    var canLogEvents: Bool {
        true  // Always true in the new subscription model
    }

    /// Create from full PuppyProfile
    @MainActor
    init(from profile: PuppyProfile) {
        self.name = profile.name
        self.legacyPremiumUnlocked = profile.legacyPremiumUnlocked
        self.currentUserRecordID = UserIdentityStore.shared.currentUserRecordID
    }

    /// Direct initializer for decoding
    init(name: String, legacyPremiumUnlocked: Bool, currentUserRecordID: String? = nil) {
        self.name = name
        self.legacyPremiumUnlocked = legacyPremiumUnlocked
        self.currentUserRecordID = currentUserRecordID
    }

    // MARK: - Codable Migration

    private enum CodingKeys: String, CodingKey {
        case name
        case isPremiumUnlocked  // Legacy key for backwards compatibility
        case legacyPremiumUnlocked
        case freeDaysRemaining  // Legacy key (ignored)
        case currentUserMemberId  // Legacy key (UUID)
        case currentUserRecordID  // New key (CloudKit record ID string)
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

        // Try new CloudKit record ID field first, fall back to legacy UUID
        if let recordID = try container.decodeIfPresent(String.self, forKey: .currentUserRecordID) {
            currentUserRecordID = recordID
        } else if let legacyId = try container.decodeIfPresent(UUID.self, forKey: .currentUserMemberId) {
            currentUserRecordID = legacyId.uuidString  // Convert to string
        } else {
            currentUserRecordID = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(legacyPremiumUnlocked, forKey: .legacyPremiumUnlocked)
        try container.encodeIfPresent(currentUserRecordID, forKey: .currentUserRecordID)
    }
}
