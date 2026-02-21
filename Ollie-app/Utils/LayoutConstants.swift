//
//  LayoutConstants.swift
//  Ollie-app
//
//  Centralized layout constants to ensure consistency across views.
//  Avoids magic numbers like .padding(.horizontal, 16) scattered throughout.

import SwiftUI

// MARK: - Layout Constants

enum LayoutConstants {

    // MARK: - Spacing

    /// Extra small spacing (4pt)
    static let spacingXS: CGFloat = 4

    /// Small spacing (8pt)
    static let spacingS: CGFloat = 8

    /// Medium spacing (12pt)
    static let spacingM: CGFloat = 12

    /// Standard spacing (16pt)
    static let spacing: CGFloat = 16

    /// Large spacing (20pt)
    static let spacingL: CGFloat = 20

    /// Extra large spacing (24pt)
    static let spacingXL: CGFloat = 24

    /// Double spacing (32pt)
    static let spacing2XL: CGFloat = 32

    // MARK: - Padding

    /// Standard horizontal padding for cards and containers
    static let horizontalPadding: CGFloat = 16

    /// Standard vertical padding
    static let verticalPadding: CGFloat = 14

    /// Card internal padding
    static let cardPadding: CGFloat = 14

    /// Section padding (used between major UI sections)
    static let sectionPadding: CGFloat = 20

    /// Edge insets for scrollable content
    static let contentInsets = EdgeInsets(
        top: 16,
        leading: 16,
        bottom: 16,
        trailing: 16
    )

    // MARK: - Corner Radii

    /// Small corner radius (8pt) - buttons, small elements
    static let cornerRadiusS: CGFloat = 8

    /// Medium corner radius (12pt) - cards, containers
    static let cornerRadiusM: CGFloat = 12

    /// Standard corner radius (16pt) - primary cards
    static let cornerRadius: CGFloat = 16

    /// Large corner radius (18pt) - hero cards
    static let cornerRadiusL: CGFloat = 18

    /// Extra large corner radius (24pt) - sheets, modals
    static let cornerRadiusXL: CGFloat = 24

    // MARK: - Icon Sizes

    /// Small icon size (16pt)
    static let iconSizeS: CGFloat = 16

    /// Medium icon size (20pt)
    static let iconSizeM: CGFloat = 20

    /// Standard icon size (24pt)
    static let iconSize: CGFloat = 24

    /// Large icon size (32pt)
    static let iconSizeL: CGFloat = 32

    /// Extra large icon size (44pt) - FAB, hero icons
    static let iconSizeXL: CGFloat = 44

    // MARK: - Touch Targets

    /// Minimum touch target size (44pt - Apple HIG)
    static let minTouchTarget: CGFloat = 44

    /// Large touch target (56pt)
    static let largeTouchTarget: CGFloat = 56

    // MARK: - Heights

    /// Standard row height
    static let rowHeight: CGFloat = 44

    /// Card minimum height
    static let cardMinHeight: CGFloat = 60

    /// Quick log bar height
    static let quickLogBarHeight: CGFloat = 60

    /// FAB button size
    static let fabSize: CGFloat = 56

    /// Tab bar approximate height
    static let tabBarHeight: CGFloat = 49

    /// Navigation bar approximate height
    static let navBarHeight: CGFloat = 44

    // MARK: - Sheet Detents

    /// Small sheet detent fraction
    static let sheetDetentSmall: CGFloat = 0.25

    /// Medium sheet detent fraction
    static let sheetDetentMedium: CGFloat = 0.5

    /// Large sheet detent fraction
    static let sheetDetentLarge: CGFloat = 0.75

    // MARK: - Progress/Charts

    /// Progress bar height
    static let progressBarHeight: CGFloat = 8

    /// Small progress bar height
    static let progressBarHeightS: CGFloat = 4

    /// Chart height
    static let chartHeight: CGFloat = 200

    // MARK: - Animation

    /// Standard animation duration
    static let animationDuration: Double = 0.25

    /// Quick animation duration
    static let animationQuick: Double = 0.15

    /// Slow animation duration
    static let animationSlow: Double = 0.4
}

// MARK: - Color Convenience (Urgency Mapping)

enum StatusColors {
    /// Get color for urgency level
    static func forUrgency(_ level: UrgencyLevel) -> Color {
        switch level {
        case .low:
            return .ollieSuccess
        case .normal:
            return .primary
        case .medium:
            return .ollieAccent
        case .high:
            return .ollieWarning
        case .critical:
            return .ollieDanger
        case .unknown:
            return .secondary
        }
    }
}

/// Generic urgency levels for status cards
enum UrgencyLevel {
    case low
    case normal
    case medium
    case high
    case critical
    case unknown
}
