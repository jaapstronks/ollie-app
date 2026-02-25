//
//  StatusCard.swift
//  Ollie-app
//
//  Generic status card wrapper for consistent styling across
//  PottyStatusCard, SleepStatusCard, PoopStatusCard, etc.
//

import SwiftUI

// MARK: - Status Card Data

/// Configuration for the status card header
struct StatusCardHeaderData {
    let iconName: String
    let iconColor: Color
    let tintColor: Color
    let title: String
    let titleColor: Color
    let subtitle: String?
    let statusLabel: String
    let iconSize: CGFloat

    init(
        iconName: String,
        iconColor: Color,
        tintColor: Color,
        title: String,
        titleColor: Color = .primary,
        subtitle: String? = nil,
        statusLabel: String,
        iconSize: CGFloat = 44
    ) {
        self.iconName = iconName
        self.iconColor = iconColor
        self.tintColor = tintColor
        self.title = title
        self.titleColor = titleColor
        self.subtitle = subtitle
        self.statusLabel = statusLabel
        self.iconSize = iconSize
    }
}

/// Configuration for the status card action button
struct StatusCardAction {
    let label: String
    let systemImage: String
    let action: () -> Void

    init(label: String, systemImage: String, action: @escaping () -> Void) {
        self.label = label
        self.systemImage = systemImage
        self.action = action
    }
}

// MARK: - Status Card

/// Generic status card wrapper providing consistent styling
/// Use this to create status cards with a header, optional content, and optional action
struct StatusCard<Content: View>: View {
    let header: StatusCardHeaderData
    let action: StatusCardAction?
    let showAction: Bool
    let tintColor: Color
    let cornerRadius: CGFloat
    let accessibilityLabel: String
    let accessibilityValue: String
    let accessibilityHint: String?
    @ViewBuilder let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    init(
        header: StatusCardHeaderData,
        action: StatusCardAction? = nil,
        showAction: Bool = true,
        tintColor: Color,
        cornerRadius: CGFloat = LayoutConstants.cornerRadius,
        accessibilityLabel: String,
        accessibilityValue: String,
        accessibilityHint: String? = nil,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.header = header
        self.action = action
        self.showAction = showAction
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityValue = accessibilityValue
        self.accessibilityHint = accessibilityHint
        self.content = content
    }

    var body: some View {
        VStack(spacing: LayoutConstants.spacingM) {
            StatusCardHeader(
                iconName: header.iconName,
                iconColor: header.iconColor,
                tintColor: header.tintColor,
                title: header.title,
                titleColor: header.titleColor,
                subtitle: header.subtitle,
                iconSize: header.iconSize
            ) { EmptyView() }

            content()

            if let action, showAction {
                Button(action: action.action) {
                    Label(action.label, systemImage: action.systemImage)
                }
                .buttonStyle(.glassPill(tint: .custom(tintColor)))
            }
        }
        .statusCardPadding()
        .glassStatusCard(tintColor: tintColor, cornerRadius: cornerRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint ?? "")
    }
}

// MARK: - Convenience Initializer without Content

extension StatusCard where Content == EmptyView {
    init(
        header: StatusCardHeaderData,
        action: StatusCardAction? = nil,
        showAction: Bool = true,
        tintColor: Color,
        cornerRadius: CGFloat = LayoutConstants.cornerRadius,
        accessibilityLabel: String,
        accessibilityValue: String,
        accessibilityHint: String? = nil
    ) {
        self.header = header
        self.action = action
        self.showAction = showAction
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityValue = accessibilityValue
        self.accessibilityHint = accessibilityHint
        self.content = { EmptyView() }
    }
}

// MARK: - Preview

#Preview("StatusCard - Basic") {
    VStack(spacing: 16) {
        StatusCard(
            header: StatusCardHeaderData(
                iconName: "drop.fill",
                iconColor: .green,
                tintColor: .green,
                title: "Potty status is good",
                subtitle: "Last: 30 min ago",
                statusLabel: "OK"
            ),
            action: StatusCardAction(
                label: "Log Now",
                systemImage: "drop.fill",
                action: {}
            ),
            tintColor: .green,
            accessibilityLabel: "Potty Status",
            accessibilityValue: "Potty status is good. OK"
        )

        StatusCard(
            header: StatusCardHeaderData(
                iconName: "moon.zzz.fill",
                iconColor: .purple,
                tintColor: .purple,
                title: "Sleeping for 45 min",
                subtitle: "Started at 14:30",
                statusLabel: "Sleeping",
                iconSize: 40
            ),
            action: StatusCardAction(
                label: "Wake Up",
                systemImage: "sun.max.fill",
                action: {}
            ),
            tintColor: .purple,
            accessibilityLabel: "Sleep Status",
            accessibilityValue: "Sleeping for 45 min"
        )

        Spacer()
    }
    .padding()
}

#Preview("StatusCard - No Action") {
    VStack(spacing: 16) {
        StatusCard(
            header: StatusCardHeaderData(
                iconName: "leaf.fill",
                iconColor: .green,
                tintColor: .green,
                title: "2 poops today (2-3 expected)",
                subtitle: "Last: 2 hours ago",
                statusLabel: "Good"
            ),
            tintColor: .green,
            accessibilityLabel: "Poop Status",
            accessibilityValue: "2 poops today"
        )

        Spacer()
    }
    .padding()
}

#Preview("StatusCard - With Content") {
    VStack(spacing: 16) {
        StatusCard(
            header: StatusCardHeaderData(
                iconName: "exclamationmark.triangle.fill",
                iconColor: .orange,
                tintColor: .orange,
                title: "Time to go outside!",
                titleColor: .orange,
                subtitle: "90 min since last potty",
                statusLabel: "Soon"
            ),
            action: StatusCardAction(
                label: "Log Potty",
                systemImage: "drop.fill",
                action: {}
            ),
            tintColor: .orange,
            cornerRadius: LayoutConstants.cornerRadiusL,
            accessibilityLabel: "Potty Status",
            accessibilityValue: "Time to go outside"
        ) {
            // Custom content example
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Post-meal trigger detected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        Spacer()
    }
    .padding()
}
