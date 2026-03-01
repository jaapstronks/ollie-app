//
//  StatusCardConfigurable.swift
//  Otis-app
//
//  Protocol for configuring status cards with consistent styling.
//  Provides a standardized interface for status card properties.

import SwiftUI

// MARK: - Status Card Configuration Protocol

/// Protocol for types that can configure a status card
/// Provides a standardized interface for icon, title, subtitle, colors, and visibility
protocol StatusCardConfigurable {
    /// SF Symbol name for the status icon
    var statusIconName: String { get }

    /// Color for the status icon
    var statusIconColor: Color { get }

    /// Tint color for the card background
    var statusTintColor: Color { get }

    /// Main title text
    var statusTitle: String { get }

    /// Color for the title text
    var statusTitleColor: Color { get }

    /// Optional subtitle text
    var statusSubtitle: String? { get }

    /// Whether the card should be visible
    var isStatusVisible: Bool { get }

    /// Whether the status is urgent (triggers attention styling)
    var isStatusUrgent: Bool { get }

    /// Accessibility label for the card
    var statusAccessibilityLabel: String { get }

    /// Accessibility value for the card
    var statusAccessibilityValue: String { get }

    /// Accessibility hint for the card
    var statusAccessibilityHint: String? { get }
}

// MARK: - Default Implementations

extension StatusCardConfigurable {
    /// Default: title color matches icon color
    var statusTitleColor: Color { statusIconColor }

    /// Default: not urgent
    var isStatusUrgent: Bool { false }

    /// Default: accessibility value is the title
    var statusAccessibilityValue: String { statusTitle }

    /// Default: no hint
    var statusAccessibilityHint: String? { nil }
}

// MARK: - Configurable Status Card View

/// A status card that uses a configuration protocol
/// Can be used as an alternative to building custom status cards
struct ConfigurableStatusCard<Config: StatusCardConfigurable, Action: View>: View {
    let config: Config
    @ViewBuilder let action: () -> Action

    var body: some View {
        StatusCardHeader(
            iconName: config.statusIconName,
            iconColor: config.statusIconColor,
            tintColor: config.statusTintColor,
            title: config.statusTitle,
            titleColor: config.statusTitleColor,
            subtitle: config.statusSubtitle
        ) {
            action()
        }
        .statusCardContainer(
            tint: config.statusTintColor,
            isVisible: config.isStatusVisible,
            isUrgent: config.isStatusUrgent,
            accessibilityLabel: config.statusAccessibilityLabel,
            accessibilityValue: config.statusAccessibilityValue,
            accessibilityHint: config.statusAccessibilityHint
        )
    }
}

// MARK: - Convenience Initializer

extension ConfigurableStatusCard where Action == EmptyView {
    /// Initialize without an action button
    init(config: Config) {
        self.config = config
        self.action = { EmptyView() }
    }
}
