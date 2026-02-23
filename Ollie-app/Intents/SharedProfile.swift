//
//  SharedProfile.swift
//  Ollie-app
//
//  Minimal profile for App Intents - shared via App Group

import Foundation

/// Minimal profile struct shared with App Intents via App Group
/// Contains only what intents need to function
struct SharedProfile: Codable {
    let name: String
    let isPremiumUnlocked: Bool
    let freeDaysRemaining: Int

    /// Whether the user can log events (premium or still in free period)
    var canLogEvents: Bool {
        isPremiumUnlocked || freeDaysRemaining > 0
    }

    /// Create from full PuppyProfile
    init(from profile: PuppyProfile) {
        self.name = profile.name
        self.isPremiumUnlocked = profile.isPremiumUnlocked
        self.freeDaysRemaining = profile.freeDaysRemaining
    }

    /// Direct initializer for decoding
    init(name: String, isPremiumUnlocked: Bool, freeDaysRemaining: Int) {
        self.name = name
        self.isPremiumUnlocked = isPremiumUnlocked
        self.freeDaysRemaining = freeDaysRemaining
    }
}
