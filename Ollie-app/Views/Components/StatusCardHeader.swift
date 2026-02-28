//
//  StatusCardHeader.swift
//  Ollie-app
//
//  Shared header component for status cards
//

import SwiftUI
import OllieShared

/// Reusable header component for status cards (PottyStatusCard, SleepStatusCard, etc.)
/// Supports an optional trailing view (typically an action button) on the right side
struct StatusCardHeader<TrailingContent: View>: View {
    let iconName: String
    let iconColor: Color
    let tintColor: Color
    let title: String
    let titleColor: Color
    let subtitle: String?
    let iconSize: CGFloat
    let trailingContent: TrailingContent

    init(
        iconName: String,
        iconColor: Color,
        tintColor: Color,
        title: String,
        titleColor: Color = .primary,
        subtitle: String? = nil,
        iconSize: CGFloat = 44,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.iconName = iconName
        self.iconColor = iconColor
        self.tintColor = tintColor
        self.title = title
        self.titleColor = titleColor
        self.subtitle = subtitle
        self.iconSize = iconSize
        self.trailingContent = trailingContent()
    }

    var body: some View {
        HStack(spacing: 14) {
            GlassIconCircle(tintColor: tintColor, size: iconSize) {
                Image(systemName: iconName)
                    .font(.system(size: iconSize * 0.5, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(titleColor)
                    .lineLimit(2)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            trailingContent
        }
    }
}

// MARK: - Convenience initializer for empty trailing content

extension StatusCardHeader where TrailingContent == EmptyView {
    init(
        iconName: String,
        iconColor: Color,
        tintColor: Color,
        title: String,
        titleColor: Color = .primary,
        subtitle: String? = nil,
        iconSize: CGFloat = 44
    ) {
        self.init(
            iconName: iconName,
            iconColor: iconColor,
            tintColor: tintColor,
            title: title,
            titleColor: titleColor,
            subtitle: subtitle,
            iconSize: iconSize
        ) {
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview("StatusCardHeader") {
    VStack(spacing: 16) {
        // With action button
        StatusCardHeader(
            iconName: "drop.fill",
            iconColor: .green,
            tintColor: .green,
            title: "Potty status is good",
            subtitle: "Last: 30 min ago"
        ) {
            Button(action: {}) {
                Label("Log", systemImage: "plus")
            }
            .buttonStyle(GlassPillCompactButtonStyle(tint: .custom(.green)))
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)

        // With action button (sleeping state)
        StatusCardHeader(
            iconName: "moon.zzz.fill",
            iconColor: .purple,
            tintColor: .purple,
            title: "Sleeping for 45 min",
            subtitle: "Started at 14:30",
            iconSize: 40
        ) {
            Button(action: {}) {
                Label("Wake Up", systemImage: "sun.max.fill")
            }
            .buttonStyle(.glassPillCompact(tint: .custom(.purple)))
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)

        // Urgent with action
        StatusCardHeader(
            iconName: "exclamationmark.triangle.fill",
            iconColor: .orange,
            tintColor: .orange,
            title: "Time to go outside!",
            titleColor: .orange,
            subtitle: "90 min since last potty"
        ) {
            Button(action: {}) {
                Label("Log Now", systemImage: "drop.fill")
            }
            .buttonStyle(.glassPillCompact(tint: .custom(.orange)))
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)

        // No action (empty trailing)
        StatusCardHeader(
            iconName: "sun.max.fill",
            iconColor: .green,
            tintColor: .green,
            title: "Awake for 20 min",
            subtitle: "Woke at 14:30"
        )
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    .padding()
}
