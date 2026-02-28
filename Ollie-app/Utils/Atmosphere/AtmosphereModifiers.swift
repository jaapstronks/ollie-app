//
//  AtmosphereModifiers.swift
//  Ollie-app
//
//  View modifiers for applying contextual atmosphere

import SwiftUI

// MARK: - Atmosphere Background Modifier

/// Applies subtle atmospheric background tint based on current context
struct AtmosphereBackgroundModifier: ViewModifier {
    @EnvironmentObject private var atmosphere: AtmosphereProvider
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var intensity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .background(backgroundView)
    }

    @ViewBuilder
    private var backgroundView: some View {
        if atmosphere.isDisabled {
            Color(.systemBackground)
        } else {
            ZStack {
                // Base time-of-day background
                if atmosphere.shouldApplyTimeEffects {
                    AtmosphereColors.backgroundTint(
                        for: atmosphere.currentPeriod,
                        colorScheme: colorScheme
                    )
                    .opacity(intensity)

                    // Transition overlay to next period
                    if atmosphere.transitionProgress > 0 {
                        AtmosphereColors.backgroundTint(
                            for: atmosphere.currentPeriod.next,
                            colorScheme: colorScheme
                        )
                        .opacity(atmosphere.transitionProgress * intensity)
                    }
                } else {
                    Color(.systemBackground)
                }

                // Weather overlay
                if atmosphere.shouldApplyWeatherEffects,
                   let weatherColor = AtmosphereColors.weatherOverlay(
                       for: atmosphere.weatherAtmosphere,
                       colorScheme: colorScheme
                   ) {
                    weatherColor.opacity(intensity)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 3.0), value: atmosphere.currentPeriod)
            .animation(reduceMotion ? nil : .easeInOut(duration: 2.0), value: atmosphere.weatherAtmosphere)
            .saturation(sleepingSaturation)
            .brightness(sleepingBrightness)
            .animation(reduceMotion ? nil : .easeInOut(duration: 5.0), value: atmosphere.puppyState)
        }
    }

    private var sleepingSaturation: Double {
        guard atmosphere.shouldApplyStateEffects && atmosphere.puppyState == .sleeping else {
            return 1.0
        }
        return 1.0 - AtmosphereColors.sleepingDesaturation
    }

    private var sleepingBrightness: Double {
        guard atmosphere.shouldApplyStateEffects && atmosphere.puppyState == .sleeping else {
            return 0
        }
        return -AtmosphereColors.sleepingBrightnessReduction
    }
}

// MARK: - Atmosphere Tint Modifier

/// Applies atmospheric accent tint to foreground elements
struct AtmosphereTintModifier: ViewModifier {
    @EnvironmentObject private var atmosphere: AtmosphereProvider
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .tint(accentColor)
            .animation(reduceMotion ? nil : .easeInOut(duration: 3.0), value: atmosphere.currentPeriod)
    }

    private var accentColor: Color {
        guard atmosphere.shouldApplyTimeEffects else {
            return .accentColor
        }
        return AtmosphereColors.accentTint(for: atmosphere.currentPeriod)
    }
}

// MARK: - Atmosphere Nav Bar Modifier

/// Applies atmosphere styling specifically to navigation bar areas
struct AtmosphereNavBarModifier: ViewModifier {
    @EnvironmentObject private var atmosphere: AtmosphereProvider
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .background(navBarBackground)
    }

    @ViewBuilder
    private var navBarBackground: some View {
        if atmosphere.isDisabled {
            Color(.systemBackground)
        } else if atmosphere.shouldApplyTimeEffects {
            AtmosphereColors.backgroundTint(
                for: atmosphere.currentPeriod,
                colorScheme: colorScheme
            )
            .animation(reduceMotion ? nil : .easeInOut(duration: 3.0), value: atmosphere.currentPeriod)
            .saturation(atmosphere.shouldApplyStateEffects && atmosphere.puppyState == .sleeping ? 0.7 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 5.0), value: atmosphere.puppyState)
        } else {
            Color(.systemBackground)
        }
    }
}

// MARK: - View Extensions

extension View {

    /// Apply atmospheric background tint based on time, weather, and puppy state
    func atmosphereBackground(intensity: Double = 1.0) -> some View {
        self.modifier(AtmosphereBackgroundModifier(intensity: intensity))
    }

    /// Apply atmospheric accent tint
    func atmosphereTint() -> some View {
        self.modifier(AtmosphereTintModifier())
    }

    /// Apply atmosphere styling to navigation bar
    func atmosphereNavBar() -> some View {
        self.modifier(AtmosphereNavBarModifier())
    }

    /// Conditionally apply atmosphere if available in environment
    func withAtmosphereIfAvailable() -> some View {
        // This modifier applies subtle atmosphere effects when the provider is available
        self.modifier(SafeAtmosphereModifier())
    }
}

// MARK: - Safe Atmosphere Modifier

/// Safely applies atmosphere effects only when provider is available
private struct SafeAtmosphereModifier: ViewModifier {
    @Environment(\.atmosphereEnabled) private var atmosphereEnabled

    func body(content: Content) -> some View {
        if atmosphereEnabled {
            content.atmosphereBackground()
        } else {
            content
        }
    }
}

// MARK: - Environment Key

private struct AtmosphereEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var atmosphereEnabled: Bool {
        get { self[AtmosphereEnabledKey.self] }
        set { self[AtmosphereEnabledKey.self] = newValue }
    }
}
