//
//  UserPreferences.swift
//  Ollie-app
//

import SwiftUI
import OllieShared

/// Appearance mode options
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return Strings.Settings.systemTheme
        case .light: return Strings.Settings.lightTheme
        case .dark: return Strings.Settings.darkTheme
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

/// Temperature unit options
enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius = "celsius"
    case fahrenheit = "fahrenheit"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .celsius: return Strings.Units.celsius
        case .fahrenheit: return Strings.Units.fahrenheit
        }
    }

    var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }

    /// Convert Celsius to this unit
    func convert(fromCelsius celsius: Double) -> Double {
        switch self {
        case .celsius: return celsius
        case .fahrenheit: return celsius * 9 / 5 + 32
        }
    }

    /// Format temperature with unit symbol
    func format(_ celsius: Double) -> String {
        let converted = convert(fromCelsius: celsius)
        return "\(Int(converted))°"
    }
}

/// Weight unit options
enum WeightUnit: String, CaseIterable, Identifiable {
    case kg = "kg"
    case lbs = "lbs"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .kg: return Strings.Units.kilograms
        case .lbs: return Strings.Units.pounds
        }
    }

    var symbol: String {
        switch self {
        case .kg: return "kg"
        case .lbs: return "lbs"
        }
    }

    /// Convert kg to this unit
    func convert(fromKg kg: Double) -> Double {
        switch self {
        case .kg: return kg
        case .lbs: return kg * 2.20462
        }
    }

    /// Convert from this unit to kg
    func toKg(_ value: Double) -> Double {
        switch self {
        case .kg: return value
        case .lbs: return value / 2.20462
        }
    }

    /// Format weight with unit symbol
    func format(_ kg: Double) -> String {
        let converted = convert(fromKg: kg)
        if self == .kg {
            if converted >= 10 {
                return String(format: "%.1f kg", converted)
            } else {
                return String(format: "%.2f kg", converted)
            }
        } else {
            if converted >= 22 {
                return String(format: "%.1f lbs", converted)
            } else {
                return String(format: "%.2f lbs", converted)
            }
        }
    }

    /// Format weight delta with unit symbol
    func formatDelta(_ deltaKg: Double) -> String {
        let converted = convert(fromKg: deltaKg)
        let sign = converted >= 0 ? "+" : ""
        return String(format: "%@%.2f %@", sign, converted, symbol)
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
        case temperatureUnit = "temperatureUnit"
        case weightUnit = "weightUnit"
        case celebrationStyle = "celebrationStyle"

        // Atmosphere settings
        case atmosphereTimeOfDay = "atmosphereTimeOfDay"
        case atmosphereWeather = "atmosphereWeather"
        case atmosphereState = "atmosphereState"
        case atmosphereSeasonal = "atmosphereSeasonal"
    }

    // MARK: - Defaults

    static let defaults: [String: Any] = [
        Key.lastSelectedTab.rawValue: 0,
        Key.hasCompletedOnboarding.rawValue: false,
        Key.showTimeSinceLastPlas.rawValue: true,
        Key.enableHaptics.rawValue: true,
        Key.appearanceMode.rawValue: AppearanceMode.system.rawValue,
        Key.temperatureUnit.rawValue: TemperatureUnit.celsius.rawValue,
        Key.weightUnit.rawValue: WeightUnit.kg.rawValue,
        Key.celebrationStyle.rawValue: CelebrationStyle.full.rawValue,

        // Atmosphere defaults (time/weather/state on by default, seasonal opt-in)
        Key.atmosphereTimeOfDay.rawValue: true,
        Key.atmosphereWeather.rawValue: true,
        Key.atmosphereState.rawValue: true,
        Key.atmosphereSeasonal.rawValue: false
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
