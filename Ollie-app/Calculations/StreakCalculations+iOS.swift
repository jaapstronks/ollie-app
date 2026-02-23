//
//  StreakCalculations+iOS.swift
//  Ollie-app
//
//  iOS-only extensions for StreakCalculations that use SwiftUI.Color

import OllieShared
import SwiftUI

// MARK: - iOS-Only Color Extensions

extension StreakCalculations {
    /// Returns appropriate icon color based on streak count
    static func iconColor(for streak: Int) -> Color {
        switch streak {
        case 0: return .ollieMuted
        case 1...3: return .ollieInfo
        case 4...7: return .ollieSuccess
        case 8...14: return .ollieAccent
        default: return .ollieAccent
        }
    }
}
