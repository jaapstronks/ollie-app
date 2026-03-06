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
    let isMastered: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(
        icon: String,
        title: String,
        subtitle: String,
        statValue: String? = nil,
        tintColor: Color,
        isMastered: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.statValue = statValue
        self.tintColor = tintColor
        self.isMastered = isMastered
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon with checkmark overlay when mastered
                ZStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(isMastered ? .secondary : tintColor)
                        .frame(width: 32)

                    if isMastered {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.green)
                            .background(Circle().fill(colorScheme == .dark ? Color.black : Color.white).padding(1))
                            .offset(x: 10, y: 10)
                    }
                }
                .accessibilityHidden(true)

                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isMastered ? .secondary : .primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Mastered badge or stat badge
                if isMastered {
                    Text(Strings.Training.CrateTraining.mastered)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(colorScheme == .dark ? 0.2 : 0.12))
                        )
                } else if let statValue = statValue {
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
        .glassStatusCard(tintColor: isMastered ? Color.green.opacity(0.1) : tintColor.opacity(0.15))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(isMastered ? Strings.Training.CrateTraining.mastered : subtitle)")
        .accessibilityHint(isMastered ? "" : (statValue.map { "Current: \($0)" } ?? ""))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview("Training Guides") {
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

        // Mastered state
        TrainingGuideEntryCard(
            icon: "house.fill",
            title: Strings.Training.Guides.crateTitle,
            subtitle: Strings.Training.Guides.crateSubtitle,
            statValue: nil,
            tintColor: .indigo,
            isMastered: true
        ) {
            print("Crate guide tapped (mastered)")
        }
    }
    .padding()
}
