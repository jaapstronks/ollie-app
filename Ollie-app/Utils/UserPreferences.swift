//
//  UserPreferences.swift
//  Ollie-app
//

import SwiftUI

/// User preferences stored in UserDefaults via @AppStorage
enum UserPreferences {
    // MARK: - Keys

    enum Key: String {
        case lastSelectedTab = "lastSelectedTab"
        case hasCompletedOnboarding = "hasCompletedOnboarding"
        case showTimeSinceLastPlas = "showTimeSinceLastPlas"
        case enableHaptics = "enableHaptics"
        case lastViewedDate = "lastViewedDate"
    }

    // MARK: - Defaults

    static let defaults: [String: Any] = [
        Key.lastSelectedTab.rawValue: 0,
        Key.hasCompletedOnboarding.rawValue: false,
        Key.showTimeSinceLastPlas.rawValue: true,
        Key.enableHaptics.rawValue: true
    ]

    /// Register default values on app launch
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: defaults)
    }
}

// MARK: - Property Wrapper Extensions

extension View {
    /// Convenience for reading/writing last selected tab
    func rememberTab(_ selection: Binding<Int>) -> some View {
        self.onChange(of: selection.wrappedValue) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: UserPreferences.Key.lastSelectedTab.rawValue)
        }
        .onAppear {
            let saved = UserDefaults.standard.integer(forKey: UserPreferences.Key.lastSelectedTab.rawValue)
            selection.wrappedValue = saved
        }
    }
}
