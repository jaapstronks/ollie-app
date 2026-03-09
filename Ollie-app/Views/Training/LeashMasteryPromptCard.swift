//
//  LeashMasteryPromptCard.swift
//  Ollie-app
//
//  Dismissible card prompting user to mark leash training as mastered
//  Shows when sentiment average has been high for an extended period

import SwiftUI

/// A dismissible card that prompts the user to mark leash training as mastered
struct LeashMasteryPromptCard: View {
    let weeksAtHighRating: Int
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
                Text(Strings.Leash.masteryPromptTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(Strings.Leash.weeksOfGreatRatings(weeksAtHighRating))
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
            .accessibilityLabel(Strings.Leash.markMastered)

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
        LeashMasteryPromptCard(
            weeksAtHighRating: 2,
            onMarkMastered: { print("Mark mastered") },
            onDismiss: { print("Dismiss") }
        )

        LeashMasteryPromptCard(
            weeksAtHighRating: 3,
            onMarkMastered: { print("Mark mastered") },
            onDismiss: { print("Dismiss") }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
