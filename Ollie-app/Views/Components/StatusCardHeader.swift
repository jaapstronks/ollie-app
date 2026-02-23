//
//  StatusCardHeader.swift
//  Ollie-app
//
//  Shared header component for status cards
//

import SwiftUI
import OllieShared

/// Reusable header component for status cards (PottyStatusCard, SleepStatusCard, etc.)
struct StatusCardHeader: View {
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

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            GlassStatusPill(text: statusLabel, tintColor: tintColor)
        }
    }
}

// MARK: - Preview

#Preview("StatusCardHeader") {
    VStack(spacing: 16) {
        StatusCardHeader(
            iconName: "drop.fill",
            iconColor: .green,
            tintColor: .green,
            title: "Potty status is good",
            subtitle: "Last: 30 min ago",
            statusLabel: "OK"
        )
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)

        StatusCardHeader(
            iconName: "moon.zzz.fill",
            iconColor: .purple,
            tintColor: .purple,
            title: "Sleeping for 45 min",
            subtitle: "Started at 14:30",
            statusLabel: "Sleeping",
            iconSize: 40
        )
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)

        StatusCardHeader(
            iconName: "exclamationmark.triangle.fill",
            iconColor: .orange,
            tintColor: .orange,
            title: "Time to go outside!",
            titleColor: .orange,
            subtitle: "90 min since last potty",
            statusLabel: "Soon"
        )
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    .padding()
}
