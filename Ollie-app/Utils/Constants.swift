//
//  Constants.swift
//  Ollie-app
//

import Foundation

enum Constants {
    // Puppy dates
    static let birthDate = DateComponents(calendar: .current, year: 2025, month: 12, day: 20).date!
    static let startDate = DateComponents(calendar: .current, year: 2026, month: 2, day: 14).date!

    // Schedule
    static let bedtimeHour = 22
    static let minNapDurationForPottyTrigger = 15 // minutes

    // Emoji map for event types
    static let eventEmoji: [EventType: String] = [
        .eten: "🍽️",
        .drinken: "💧",
        .plassen: "🚽",
        .poepen: "💩",
        .slapen: "😴",
        .ontwaken: "☀️",
        .uitlaten: "🚶",
        .tuin: "🌳",
        .training: "🎓",
        .bench: "🏠",
        .sociaal: "🐕",
        .milestone: "⭐",
        .gedrag: "📝",
        .gewicht: "⚖️"
    ]

    // Dutch labels for event types
    static let eventLabels: [EventType: String] = [
        .eten: "Eten",
        .drinken: "Drinken",
        .plassen: "Plassen",
        .poepen: "Poepen",
        .slapen: "Slapen",
        .ontwaken: "Wakker",
        .uitlaten: "Uitlaten",
        .tuin: "Tuin",
        .training: "Training",
        .bench: "Bench",
        .sociaal: "Sociaal",
        .milestone: "Mijlpaal",
        .gedrag: "Gedrag",
        .gewicht: "Gewicht"
    ]

    // Quick log event types (most common, shown in bottom bar)
    static let quickLogTypes: [EventType] = [
        .plassen,
        .poepen,
        .eten,
        .slapen,
        .ontwaken,
        .uitlaten
    ]
}
