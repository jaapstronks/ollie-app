//
//  OtisColors.swift
//  Otis-app
//
//  Brand colors and semantic color palette

import SwiftUI
import OtisShared

// MARK: - Color Usage Philosophy
//
// CATEGORY COLORS (What type of event/content):
// - Timeline events, filter chips, stats section headers
// - Sleep events → otisSleep (muted blue)
// - Food/meals → otisAccent (gold)
// - Walks/outdoor → otisSuccess (green)
// - Training → otisPurple (purple)
// - Health/medical → otisHealth (coral)
// - Milestones → otisRose (rose)
//
// OUTCOME COLORS (Success/failure):
// - Potty location: outdoor = otisSuccess, indoor = otisDanger
// - Completion states: completed = otisSuccess
//
// URGENCY COLORS (Attention level):
// - Status cards, reminders, alerts
// - Just happened/good → otisSuccess (green)
// - Normal/info → otisInfo (teal)
// - Attention needed → otisWarning (gold)
// - Urgent/overdue → otisDanger (red)

/// Otis brand color palette
extension Color {
    // MARK: - Brand Colors

    /// Warm gold — primary accent
    static let otisAccent = Color(hex: "E8A855")

    /// Light gold — backgrounds, badges
    /// Adjusted for WCAG 4.5:1 contrast ratio
    static let otisAccentLight = Color(hex: "D4A04A")

    /// Deep amber — pressed states
    /// Adjusted for WCAG 4.5:1 contrast ratio on dark backgrounds
    static let otisAccentDark = Color(hex: "A36B1D")

    // MARK: - Semantic Colors

    /// Green — buiten, positive outcomes, social interactions
    static let otisSuccess = Color(hex: "5BAA6E")

    /// Gold — caution, transitions (same as accent)
    static let otisWarning = Color(hex: "E8A855")

    /// Red — binnen, alerts, urgent
    static let otisDanger = Color(hex: "D4594E")

    /// Teal — stats, neutral data, foundations
    static let otisInfo = Color(hex: "5BA4B5")

    /// Muted blue — sleep, rest, crate
    static let otisSleep = Color(hex: "7B8CC2")

    /// Purple — training, mental activities, learning
    static let otisPurple = Color(hex: "9B7BC2")

    /// Rose — milestones, celebrations, care
    static let otisRose = Color(hex: "E87B9E")

    /// Gray — secondary text, neutral
    /// Adjusted for WCAG 4.5:1 contrast ratio
    static let otisMuted = Color(hex: "6B7280")

    // MARK: - Health/Medical Colors

    /// Coral — health events (weight, medication, vet)
    static let otisHealth = Color(hex: "E87B6B")

    /// Light coral — health event backgrounds
    static let otisHealthTint = Color(hex: "FDF0EE")

    // MARK: - Milestone Category Colors

    /// Health milestones — medical red
    static let otisHealthRed = Color(hex: "E85555")

    /// Health tint — light background
    static let otisHealthRedTint = Color(hex: "FDECEC")

    /// Developmental milestones — purple
    static let otisDevelopmental = Color(hex: "9B7BC2")

    /// Developmental tint — light background
    static let otisDevelopmentalTint = Color(hex: "F3EDF9")

    /// Administrative milestones — blue
    static let otisAdministrative = Color(hex: "5BA4B5")

    /// Administrative tint — light background
    static let otisAdministrativeTint = Color(hex: "EBF5F7")

    /// Custom milestones — orange
    static let otisCustomOrange = Color(hex: "E8A855")

    /// Custom tint — light background
    static let otisCustomOrangeTint = Color(hex: "FDF5E8")

    // MARK: - Background Colors

    /// Warm cream background (light mode)
    static let otisBackgroundLight = Color(hue: 38/360, saturation: 0.60, brightness: 0.97)

    /// Warm dark background (dark mode)
    static let otisBackgroundDark = Color(hue: 25/360, saturation: 0.20, brightness: 0.08)

    /// Card background (light mode)
    static let otisCardLight = Color(hue: 38/360, saturation: 0.50, brightness: 0.99)

    /// Card background (dark mode)
    static let otisCardDark = Color(hue: 25/360, saturation: 0.20, brightness: 0.11)

    /// Border color (light mode)
    static let otisBorderLight = Color(hue: 38/360, saturation: 0.30, brightness: 0.88)

    /// Border color (dark mode)
    static let otisBorderDark = Color(hue: 25/360, saturation: 0.15, brightness: 0.18)

    // MARK: - Hex Initializer

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Adaptive Opacity Helpers

extension Color {
    /// Returns a color with adaptive opacity based on color scheme
    /// Dark mode typically needs higher opacity for visibility
    /// - Parameters:
    ///   - dark: Opacity for dark mode (typically higher)
    ///   - light: Opacity for light mode (typically lower)
    ///   - colorScheme: The current color scheme
    func adaptiveOpacity(dark: Double, light: Double, colorScheme: ColorScheme) -> Color {
        self.opacity(colorScheme == .dark ? dark : light)
    }

    /// Common adaptive background opacity (0.15 dark, 0.08 light)
    func backgroundOpacity(colorScheme: ColorScheme) -> Color {
        adaptiveOpacity(dark: 0.15, light: 0.08, colorScheme: colorScheme)
    }

    /// Subtle adaptive background (0.08 dark, 0.05 light)
    func subtleBackgroundOpacity(colorScheme: ColorScheme) -> Color {
        adaptiveOpacity(dark: 0.08, light: 0.05, colorScheme: colorScheme)
    }

    /// Badge/chip adaptive opacity (0.2 dark, 0.1 light)
    func badgeOpacity(colorScheme: ColorScheme) -> Color {
        adaptiveOpacity(dark: 0.2, light: 0.1, colorScheme: colorScheme)
    }
}

// MARK: - SkillLearningPhase Colors & Labels

extension SkillLearningPhase {
    /// Color associated with this learning phase
    public var color: Color {
        switch self {
        case .notStarted: return .secondary
        case .luring: return .otisInfo
        case .addingCue: return .otisPurple
        case .proofing: return .otisAccent
        case .generalizing: return .otisSuccess.opacity(0.8)
        case .maintaining: return .otisSuccess
        case .needsWork: return .otisDanger
        }
    }

    /// Localized display label for the phase
    public var label: String {
        switch self {
        case .notStarted: return Strings.Training.statusNotStarted
        case .luring: return Strings.Training.phaseLuring
        case .addingCue: return Strings.Training.phaseAddingCue
        case .proofing: return Strings.Training.phaseProofing
        case .generalizing: return Strings.Training.phaseGeneralizing
        case .maintaining: return Strings.Training.statusMastered
        case .needsWork: return Strings.Training.refresherNeeded
        }
    }

    /// Short label for compact displays (e.g., phase timelines)
    public var shortLabel: String {
        switch self {
        case .luring: return "Lure"
        case .addingCue: return "Cue"
        case .proofing: return "Proof"
        case .generalizing: return "Gen."
        case .maintaining: return "Done"
        default: return ""
        }
    }
}
