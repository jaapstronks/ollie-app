//
//  WidgetColorPalette.swift
//  OllieWidget
//
//  Color computation utilities for status dashboard widget
//

import SwiftUI
import WidgetKit

/// Color utilities for the status dashboard widget
enum WidgetColorPalette {

    // MARK: - Background Gradient

    static func backgroundGradient(
        isCurrentlySleeping: Bool,
        minutesSinceLastPlas: Int,
        colorScheme: ColorScheme
    ) -> LinearGradient {
        let isDark = colorScheme == .dark

        if isCurrentlySleeping {
            // Sleeping - soft indigo/purple
            if isDark {
                return LinearGradient(
                    colors: [Color(red: 0.15, green: 0.15, blue: 0.28), Color(red: 0.18, green: 0.16, blue: 0.32)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.94, green: 0.94, blue: 0.98), Color(red: 0.90, green: 0.90, blue: 0.96)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }

        // Awake - use potty urgency colors
        if minutesSinceLastPlas > 120 {
            if isDark {
                return LinearGradient(
                    colors: [Color(red: 0.35, green: 0.15, blue: 0.15), Color(red: 0.40, green: 0.18, blue: 0.16)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.98, green: 0.92, blue: 0.90), Color(red: 0.95, green: 0.85, blue: 0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else if minutesSinceLastPlas > 90 {
            if isDark {
                return LinearGradient(
                    colors: [Color(red: 0.35, green: 0.28, blue: 0.12), Color(red: 0.38, green: 0.30, blue: 0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 1.0, green: 0.96, blue: 0.88), Color(red: 1.0, green: 0.92, blue: 0.80)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else {
            if isDark {
                return LinearGradient(
                    colors: [Color(red: 0.12, green: 0.22, blue: 0.18), Color(red: 0.14, green: 0.25, blue: 0.20)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.92, green: 0.97, blue: 0.94), Color(red: 0.85, green: 0.94, blue: 0.88)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    // MARK: - Sleep Colors

    static func sleepIconBackground(colorScheme: ColorScheme) -> Color {
        let isDark = colorScheme == .dark
        return isDark
            ? Color(red: 0.35, green: 0.30, blue: 0.55).opacity(0.7)
            : Color(red: 0.80, green: 0.78, blue: 0.92).opacity(0.6)
    }

    static func sleepIconColor(colorScheme: ColorScheme) -> Color {
        let isDark = colorScheme == .dark
        return isDark
            ? Color(red: 0.70, green: 0.65, blue: 0.95)
            : Color(red: 0.45, green: 0.40, blue: 0.70)
    }

    // MARK: - Potty Colors

    static func pottyIconBackground(minutes: Int, colorScheme: ColorScheme) -> Color {
        let isDark = colorScheme == .dark

        if minutes > 120 {
            return isDark
                ? Color(red: 0.55, green: 0.25, blue: 0.22).opacity(0.7)
                : Color(red: 0.95, green: 0.75, blue: 0.70).opacity(0.6)
        } else if minutes > 90 {
            return isDark
                ? Color(red: 0.55, green: 0.45, blue: 0.20).opacity(0.7)
                : Color(red: 1.0, green: 0.88, blue: 0.65).opacity(0.6)
        } else {
            return isDark
                ? Color(red: 0.20, green: 0.45, blue: 0.35).opacity(0.7)
                : Color(red: 0.70, green: 0.88, blue: 0.78).opacity(0.6)
        }
    }

    static func pottyIconColor(minutes: Int, colorScheme: ColorScheme) -> Color {
        let isDark = colorScheme == .dark

        if minutes > 120 {
            return isDark
                ? Color(red: 1.0, green: 0.55, blue: 0.50)
                : Color(red: 0.85, green: 0.30, blue: 0.25)
        } else if minutes > 90 {
            return isDark
                ? Color(red: 1.0, green: 0.75, blue: 0.30)
                : Color(red: 0.90, green: 0.60, blue: 0.10)
        } else {
            return isDark
                ? Color(red: 0.45, green: 0.85, blue: 0.65)
                : Color(red: 0.25, green: 0.65, blue: 0.45)
        }
    }

    static func pottyUrgencyColor(minutes: Int, colorScheme: ColorScheme) -> Color {
        let isDark = colorScheme == .dark

        if minutes > 120 {
            return isDark ? Color(red: 1.0, green: 0.55, blue: 0.50) : .red
        } else {
            return isDark ? Color(red: 1.0, green: 0.75, blue: 0.30) : .orange
        }
    }

    // MARK: - Streak Colors

    static func streakIcon(streak: Int) -> String {
        if streak == 0 { return "xmark.circle.fill" }
        else if streak < 3 { return "star.fill" }
        else if streak < 10 { return "flame.fill" }
        else { return "trophy.fill" }
    }

    static func streakIconColor(streak: Int, colorScheme: ColorScheme) -> Color {
        let isDark = colorScheme == .dark

        if streak == 0 {
            return isDark ? Color(red: 0.90, green: 0.55, blue: 0.55) : Color(red: 0.70, green: 0.35, blue: 0.35)
        } else if streak < 3 {
            return isDark ? Color(red: 0.50, green: 0.85, blue: 0.65) : Color(red: 0.30, green: 0.60, blue: 0.45)
        } else if streak < 10 {
            return isDark ? Color(red: 1.0, green: 0.70, blue: 0.30) : Color(red: 0.90, green: 0.55, blue: 0.15)
        } else {
            return isDark ? Color(red: 1.0, green: 0.80, blue: 0.25) : Color(red: 0.85, green: 0.65, blue: 0.10)
        }
    }

    static func streakIconBackground(streak: Int, colorScheme: ColorScheme) -> Color {
        let isDark = colorScheme == .dark

        if streak == 0 {
            return isDark
                ? Color(red: 0.45, green: 0.25, blue: 0.25).opacity(0.7)
                : Color(red: 0.90, green: 0.80, blue: 0.80).opacity(0.6)
        } else if streak < 3 {
            return isDark
                ? Color(red: 0.20, green: 0.40, blue: 0.30).opacity(0.7)
                : Color(red: 0.75, green: 0.90, blue: 0.82).opacity(0.6)
        } else if streak < 10 {
            return isDark
                ? Color(red: 0.50, green: 0.40, blue: 0.18).opacity(0.7)
                : Color(red: 1.0, green: 0.88, blue: 0.70).opacity(0.6)
        } else {
            return isDark
                ? Color(red: 0.50, green: 0.45, blue: 0.15).opacity(0.7)
                : Color(red: 1.0, green: 0.92, blue: 0.60).opacity(0.6)
        }
    }

    // MARK: - Status Colors

    static func mealStatusColor(isOverdue: Bool) -> Color {
        if isOverdue {
            return .orange
        }
        return .secondary
    }

    static func walkStatusColor(isOverdue: Bool) -> Color {
        if isOverdue {
            return .orange
        }
        return .secondary
    }
}
