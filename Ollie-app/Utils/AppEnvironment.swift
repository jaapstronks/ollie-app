//
//  AppEnvironment.swift
//  Otis-app
//
//  Detects app environment (production, TestFlight, debug)

import Foundation

/// Represents the current app environment
enum AppEnvironment {
    case production
    case testFlight
    case debug

    /// Detect the current environment
    static var current: AppEnvironment {
        #if DEBUG
        return .debug
        #else
        // TestFlight builds use sandbox receipt
        if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
            return .testFlight
        }
        return .production
        #endif
    }

    /// Whether the current environment is a beta build (debug or TestFlight)
    var isBeta: Bool {
        self != .production
    }

    /// Display name for the environment
    var displayName: String {
        switch self {
        case .production:
            return "Production"
        case .testFlight:
            return "TestFlight"
        case .debug:
            return "Debug"
        }
    }
}
