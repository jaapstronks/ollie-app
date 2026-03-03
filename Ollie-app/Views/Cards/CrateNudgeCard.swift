//
//  CrateNudgeCard.swift
//  Otis-app
//
//  Contextual nudge card for crate naps on Today view
//  Shows when: awake, naps logged today, none in crate, has used crate before
//

import SwiftUI

/// Contextual nudge to encourage crate naps
struct CrateNudgeCard: View {
    let puppyName: String
    let onStartCrateNap: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "house.fill")
                        .font(.body)
                        .foregroundStyle(.indigo)
                }
                .accessibilityHidden(true)

                // Message
                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.Training.Guides.crateNudgeTitle(name: puppyName))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(Strings.Training.Guides.crateNudgeSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            // Action buttons
            HStack(spacing: 10) {
                // Dismiss button
                Button {
                    onDismiss()
                } label: {
                    Text(Strings.Training.Guides.notNow)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.secondary.opacity(colorScheme == .dark ? 0.15 : 0.1))
                        )
                }

                // Start crate nap button
                Button {
                    onStartCrateNap()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.caption)
                        Text(Strings.Training.Guides.startCrateNap)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.indigo)
                    )
                }
            }
        }
        .padding(14)
        .glassStatusCard(tintColor: .indigo.opacity(0.15))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Training.Guides.crateNudgeTitle(name: puppyName))
        .accessibilityHint(Strings.Training.Guides.crateNudgeSubtitle)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        CrateNudgeCard(
            puppyName: "Max",
            onStartCrateNap: { print("Start crate nap") },
            onDismiss: { print("Dismissed") }
        )
    }
    .padding()
}
