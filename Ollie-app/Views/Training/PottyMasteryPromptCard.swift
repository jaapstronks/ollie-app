//
//  PottyMasteryPromptCard.swift
//  Otis-app
//
//  Dismissible card prompting user to mark potty training as mastered
//  Shows when outdoor percentage has been at 100% for multiple consecutive days
//

import SwiftUI

/// A dismissible card that prompts the user to mark potty training as mastered
/// Shows below the potty training guide when criteria are met
struct PottyMasteryPromptCard: View {
    let consecutiveDays: Int
    let onMarkMastered: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Celebration icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.green)
            }
            .accessibilityHidden(true)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.Training.PottyTraining.masteryPromptTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(Strings.Training.PottyTraining.daysAtPerfect(consecutiveDays))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            // Mark mastered button
            Button {
                onMarkMastered()
            } label: {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Strings.Training.PottyTraining.markMastered)

            // Dismiss button
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Strings.Common.cancel)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.green.opacity(colorScheme == .dark ? 0.08 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        PottyMasteryPromptCard(
            consecutiveDays: 5,
            onMarkMastered: { print("Mark mastered") },
            onDismiss: { print("Dismiss") }
        )

        PottyMasteryPromptCard(
            consecutiveDays: 10,
            onMarkMastered: { print("Mark mastered") },
            onDismiss: { print("Dismiss") }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
