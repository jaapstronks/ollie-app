//
//  UserPreferences.swift
//  Ollie-app
//

import SwiftUI

/// Appearance mode options
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "Systeem"
        case .light: return "Licht"
        case .dark: return "Donker"
        }
    }

    var icon: String {
        switch self {
        case .system: return "iphone"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// User preferences stored in UserDefaults via @AppStorage
enum UserPreferences {
    // MARK: - Keys

    enum Key: String {
        case lastSelectedTab = "lastSelectedTab"
        case hasCompletedOnboarding = "hasCompletedOnboarding"
        case showTimeSinceLastPlas = "showTimeSinceLastPlas"
        case enableHaptics = "enableHaptics"
        case lastViewedDate = "lastViewedDate"
        case appearanceMode = "appearanceMode"
    }

    // MARK: - Defaults

    static let defaults: [String: Any] = [
        Key.lastSelectedTab.rawValue: 0,
        Key.hasCompletedOnboarding.rawValue: false,
        Key.showTimeSinceLastPlas.rawValue: true,
        Key.enableHaptics.rawValue: true,
        Key.appearanceMode.rawValue: AppearanceMode.system.rawValue
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
