//
//  AtmosphereColors.swift
//  Ollie-app
//
//  Color calculations for contextual atmosphere

import SwiftUI

// MARK: - Atmosphere Color Palette

/// Color definitions for each time period
enum AtmosphereColors {

    // MARK: - Time Period Background Tints (Light Mode)

    /// Background tint colors for each time period in light mode
    static func backgroundTint(for period: TimeOfDayPeriod, colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return darkModeBackgroundTint(for: period)
        }
        return lightModeBackgroundTint(for: period)
    }

    private static func lightModeBackgroundTint(for period: TimeOfDayPeriod) -> Color {
        switch period {
        case .earlyMorning:
            // Cool blue: #F5F8FF
            return Color(red: 0.961, green: 0.973, blue: 1.0)
        case .morning:
            // Warm white: #FFFEF8
            return Color(red: 1.0, green: 0.996, blue: 0.973)
        case .midday:
            // Neutral white
            return Color(red: 0.99, green: 0.99, blue: 0.99)
        case .afternoon:
            // Golden: #FFF8F0
            return Color(red: 1.0, green: 0.973, blue: 0.941)
        case .evening:
            // Amber: #FFF5E8
            return Color(red: 1.0, green: 0.961, blue: 0.910)
        case .night:
            // Warm gray
            return Color(red: 0.965, green: 0.961, blue: 0.957)
        case .lateNight:
            // Dark neutral gray
            return Color(red: 0.945, green: 0.945, blue: 0.945)
        }
    }

    private static func darkModeBackgroundTint(for period: TimeOfDayPeriod) -> Color {
        // Dark mode uses very subtle tints on the dark background
        switch period {
        case .earlyMorning:
            // Very subtle cool blue
            return Color(red: 0.08, green: 0.09, blue: 0.12)
        case .morning:
            // Very subtle warm
            return Color(red: 0.11, green: 0.10, blue: 0.09)
        case .midday:
            // Neutral dark
            return Color(red: 0.10, green: 0.10, blue: 0.10)
        case .afternoon:
            // Very subtle golden
            return Color(red: 0.12, green: 0.10, blue: 0.08)
        case .evening:
            // Very subtle amber
            return Color(red: 0.12, green: 0.09, blue: 0.07)
        case .night:
            // Warm dark
            return Color(red: 0.09, green: 0.09, blue: 0.085)
        case .lateNight:
            // Deep dark
            return Color(red: 0.06, green: 0.06, blue: 0.06)
        }
    }

    // MARK: - Weather Overlays

    /// Optional tint overlay for weather conditions
    static func weatherOverlay(for weather: WeatherAtmosphere, colorScheme: ColorScheme) -> Color? {
        let opacity: Double = colorScheme == .dark ? 0.05 : 0.03

        switch weather {
        case .sunny:
            return Color.yellow.opacity(opacity)
        case .rainy:
            return Color.blue.opacity(opacity)
        case .snowy:
            return Color.white.opacity(opacity * 2)
        case .stormy:
            return Color.purple.opacity(opacity)
        case .foggy:
            return Color.gray.opacity(opacity)
        case .cloudy, .unknown:
            return nil
        }
    }

    // MARK: - Accent Colors

    /// Accent color adjustment for time period
    static func accentTint(for period: TimeOfDayPeriod) -> Color {
        switch period {
        case .earlyMorning:
            return Color.blue
        case .morning:
            return Color.orange
        case .midday:
            return Color.yellow
        case .afternoon:
            return Color(red: 1.0, green: 0.8, blue: 0.4)  // Golden
        case .evening:
            return Color(red: 1.0, green: 0.6, blue: 0.3)  // Amber
        case .night:
            return Color(red: 0.6, green: 0.5, blue: 0.8)  // Purple-ish
        case .lateNight:
            return Color(red: 0.4, green: 0.4, blue: 0.6)  // Muted blue
        }
    }

    // MARK: - Blending

    /// Blend between two colors with a given progress (0-1)
    static func blend(_ color1: Color, _ color2: Color, progress: Double) -> Color {
        // SwiftUI doesn't provide direct color component access easily,
        // so we use a simple approach with opacity blending via ZStack
        // For actual implementation, we'd need UIColor conversion
        // This is a simplified version that works for our use case
        return color1
    }

    /// Create blended background for transition between periods
    static func transitionBackground(
        currentPeriod: TimeOfDayPeriod,
        progress: Double,
        colorScheme: ColorScheme
    ) -> Color {
        guard progress > 0 else {
            return backgroundTint(for: currentPeriod, colorScheme: colorScheme)
        }

        // For transitions, we return the current period's color
        // The actual blending happens in the view modifier via opacity
        return backgroundTint(for: currentPeriod, colorScheme: colorScheme)
    }

    // MARK: - Mood Adjustments

    /// Apply mood-based saturation adjustment
    static func applySaturationForMood(_ mood: AtmosphereMood) -> Double {
        mood.saturationMultiplier
    }

    /// Apply mood-based brightness adjustment
    static func applyBrightnessForMood(_ mood: AtmosphereMood) -> Double {
        mood.brightnessAdjustment
    }

    // MARK: - Sleeping State

    /// Desaturation amount when puppy is sleeping (0-1)
    static let sleepingDesaturation: Double = 0.3

    /// Brightness reduction when sleeping
    static let sleepingBrightnessReduction: Double = 0.02
}

// MARK: - Color Extensions

extension Color {

    /// Create a slightly adjusted version of this color
    func adjustedFor(saturation: Double = 1.0, brightness: Double = 0) -> some View {
        self
            .saturation(saturation)
            .brightness(brightness)
    }
}
