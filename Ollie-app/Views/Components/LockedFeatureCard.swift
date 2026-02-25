//
//  LockedFeatureCard.swift
//  Ollie-app
//
//  Placeholder card shown for premium-only features

import SwiftUI

/// Card shown in place of locked premium features
struct LockedFeatureCard: View {
    let title: String
    let description: String
    let icon: String
    let onUnlock: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onUnlock) {
            VStack(spacing: 16) {
                // Lock icon with feature icon
                ZStack {
                    Circle()
                        .fill(Color.ollieAccent.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(Color.ollieAccent)
                }

                // Title
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                // Description
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Unlock button
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.caption)

                    Text(Strings.OlliePlus.unlockWithPlus)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.ollieAccent))
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.ollieAccent.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
        }
        .buttonStyle(.plain)
    }
}

/// Compact locked card for inline use (e.g., in lists)
struct LockedFeatureRow: View {
    let title: String
    let icon: String
    let onUnlock: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onUnlock) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(Color.ollieAccent)
                    .frame(width: 28)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)

                    Text(Strings.OlliePlus.plusBadge)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.ollieAccent))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.02))
            )
        }
        .buttonStyle(.plain)
    }
}

/// Premium-locked skill card for training view (subscription upsell)
struct PremiumLockedSkillCard: View {
    let skillName: String
    let category: String
    let onUnlock: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onUnlock) {
            HStack(spacing: 12) {
                // Skill icon placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "lock.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Skill info
                VStack(alignment: .leading, spacing: 4) {
                    Text(skillName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Text(category)
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.7))
                }

                Spacer()

                // Ollie+ badge
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.caption2.weight(.bold))

                    Text(Strings.OlliePlus.plusBadge)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.ollieAccent))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Locked Feature Card") {
    VStack(spacing: 20) {
        LockedFeatureCard(
            title: "Pattern Analysis",
            description: "Discover behavioral patterns and trends with AI-powered insights",
            icon: "waveform.path.ecg",
            onUnlock: {}
        )

        LockedFeatureRow(
            title: "Sleep Insights",
            icon: "moon.stars.fill",
            onUnlock: {}
        )

        PremiumLockedSkillCard(
            skillName: "Advanced Recall",
            category: "Obedience",
            onUnlock: {}
        )
    }
    .padding()
}
