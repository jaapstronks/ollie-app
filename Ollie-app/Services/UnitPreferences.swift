//
//  UnitPreferences.swift
//  Ollie-app
//
//  Observable object for unit preferences (weight, temperature).
//  Use as @EnvironmentObject instead of repeating @AppStorage patterns.
//

import SwiftUI
import Combine

/// Centralized unit preferences accessible via environment.
/// Replaces repeated @AppStorage patterns for weightUnit and temperatureUnit.
@Observable
@MainActor
final class UnitPreferences {

    // MARK: - Shared Instance

    static let shared = UnitPreferences()

    // MARK: - Observable Properties

    var weightUnit: WeightUnit {
        didSet {
            UserDefaults.standard.set(weightUnit.rawValue, forKey: UserPreferences.Key.weightUnit.rawValue)
        }
    }

    var temperatureUnit: TemperatureUnit {
        didSet {
            UserDefaults.standard.set(temperatureUnit.rawValue, forKey: UserPreferences.Key.temperatureUnit.rawValue)
        }
    }

    // MARK: - Initialization

    private init() {
        let weightRaw = UserDefaults.standard.string(forKey: UserPreferences.Key.weightUnit.rawValue) ?? WeightUnit.kg.rawValue
        self.weightUnit = WeightUnit(rawValue: weightRaw) ?? .kg

        let tempRaw = UserDefaults.standard.string(forKey: UserPreferences.Key.temperatureUnit.rawValue) ?? TemperatureUnit.celsius.rawValue
        self.temperatureUnit = TemperatureUnit(rawValue: tempRaw) ?? .celsius
    }

    // MARK: - Convenience Methods

    /// Format a weight value in kg using the user's preferred unit
    func formatWeight(_ kg: Double) -> String {
        weightUnit.format(kg)
    }

    /// Format a weight delta in kg using the user's preferred unit
    func formatWeightDelta(_ deltaKg: Double) -> String {
        weightUnit.formatDelta(deltaKg)
    }

    /// Convert a weight from the user's preferred unit to kg
    func toKg(_ value: Double) -> Double {
        weightUnit.toKg(value)
    }

    /// Convert a weight from kg to the user's preferred unit
    func fromKg(_ kg: Double) -> Double {
        weightUnit.convert(fromKg: kg)
    }

    /// Format a temperature in Celsius using the user's preferred unit
    func formatTemperature(_ celsius: Double) -> String {
        temperatureUnit.format(celsius)
    }

    /// Convert a temperature from Celsius to the user's preferred unit
    func convertTemperature(fromCelsius celsius: Double) -> Double {
        temperatureUnit.convert(fromCelsius: celsius)
    }
}
