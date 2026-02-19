//
//  Constants.swift
//  Ollie-app
//

import Foundation

/// App-wide constants (non-profile-specific)
enum Constants {
    /// Data directory name within app documents
    static let dataDirectoryName = "data"

    /// Profile file name
    static let profileFileName = "profile.json"

    /// Quick-log event types shown in the bottom bar
    static let quickLogTypes: [EventType] = [
        .plassen,
        .poepen,
        .eten,
        .slapen,
        .ontwaken,
        .uitlaten
    ]

    /// GitHub repo for data import
    static let gitHubOwner = "jaapstronks"
    static let gitHubRepo = "Ollie"
    static let gitHubDataPath = "data"
}
