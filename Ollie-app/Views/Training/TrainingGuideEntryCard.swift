//
//  TrainingGuideEntryCard.swift
//  Otis-app
//
//  Compact entry card for training guides (~60pt height)
//  Tappable to open detailed guide sheets
//

import SwiftUI

/// Compact entry card for training guides
/// Design: Icon + title + subtitle + stat badge + chevron (~60pt height)
struct TrainingGuideEntryCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let statValue: String?
    let tintColor: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(
        icon: String,
        title: String,
        subtitle: String,
        statValue: String? = nil,
        tintColor: Color,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.statValue = statValue
        self.tintColor = tintColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(tintColor)
                    .frame(width: 32)
                    .accessibilityHidden(true)

                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Stat badge (if available)
                if let statValue = statValue {
                    Text(statValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(tintColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(tintColor.opacity(colorScheme == .dark ? 0.2 : 0.12))
                        )
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassStatusCard(tintColor: tintColor.opacity(0.15))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityHint(statValue.map { "Current: \($0)" } ?? "")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview("Potty Training") {
    VStack(spacing: 12) {
        TrainingGuideEntryCard(
            icon: "target",
            title: Strings.Training.Guides.pottyTitle,
            subtitle: Strings.Training.Guides.pottySubtitle,
            statValue: "85%",
            tintColor: .otisSuccess
        ) {
            print("Potty guide tapped")
        }

        TrainingGuideEntryCard(
            icon: "house.fill",
            title: Strings.Training.Guides.crateTitle,
            subtitle: Strings.Training.Guides.crateSubtitle,
            statValue: "42%",
            tintColor: .indigo
        ) {
            print("Crate guide tapped")
        }

        // Without stat
        TrainingGuideEntryCard(
            icon: "target",
            title: Strings.Training.Guides.pottyTitle,
            subtitle: Strings.Training.Guides.pottySubtitle,
            statValue: nil,
            tintColor: .otisSuccess
        ) {
            print("Potty guide tapped")
        }
    }
    .padding()
}
