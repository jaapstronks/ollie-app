//
//  Tier2CelebrationCard.swift
//  Ollie-app
//
//  Tier 2 celebration: Card slide-up with gentle confetti
//  Used for notable achievements like first vaccination, streak records

import SwiftUI
import OllieShared

/// Tier 2 celebration card that slides up from the bottom
struct Tier2CelebrationCard: View {
    let achievement: Achievement
    let puppyName: String
    let onAddPhoto: () -> Void
    let onShare: () -> Void
    let onDismiss: () -> Void

    @State private var showConfetti = false
    @State private var cardAppeared = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                // Header with achievement icon
                achievementHeader

                // Achievement badge/illustration
                achievementBadge

                // Achievement text
                VStack(spacing: 8) {
                    Text(achievement.localizedLabel)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    if let description = achievement.localizedDescription {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(achievement.celebrationMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                // Photo prompt
                photoPrompt

                // Action buttons
                actionButtons
            }
            .padding(24)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(cardOverlay)
            .shadow(color: categoryColor.opacity(0.3), radius: 20, y: 10)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .offset(y: cardAppeared ? 0 : 300)
            .opacity(cardAppeared ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black.opacity(cardAppeared ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }
        )
        .overlay {
            // Confetti overlay - full frame so particles burst from center
            CelebrationView(style: .milestone, isActive: $showConfetti)
                .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                cardAppeared = true
            }
            // Trigger confetti after card appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
            // Haptic feedback
            HapticFeedback.success()
        }
    }

    // MARK: - Components

    @ViewBuilder
    private var achievementHeader: some View {
        HStack {
            Spacer()
            Button {
                dismissWithAnimation()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private var achievementBadge: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(categoryColor.opacity(0.15))
                .frame(width: 120, height: 120)

            // Inner circle
            Circle()
                .fill(categoryColor.gradient)
                .frame(width: 88, height: 88)

            // Icon
            Image(systemName: achievement.category.icon)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.white)

            // Value badge (for streaks, counts)
            if let value = achievement.value {
                Text("\(value)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                    )
                    .offset(x: 36, y: -36)
            }
        }
    }

    @ViewBuilder
    private var photoPrompt: some View {
        HStack(spacing: 8) {
            Image(systemName: "camera.fill")
                .font(.subheadline)
            Text(Strings.Celebrations.addPhotoPrompt(puppyName: puppyName))
                .font(.subheadline)
        }
        .foregroundStyle(.secondary)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Add Photo button
            Button {
                onAddPhoto()
            } label: {
                Label(Strings.Common.addPhoto, systemImage: "camera.fill")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.glassPill(tint: .custom(categoryColor)))

            // Share button
            Button {
                onShare()
            } label: {
                Label(Strings.Common.share, systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.glassSecondary)
        }

        // Done button
        Button {
            dismissWithAnimation()
        } label: {
            Text(Strings.Common.done)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.glassPrimary(tint: .accent))
    }

    // MARK: - Styling

    @ViewBuilder
    private var cardBackground: some View {
        ZStack {
            // Base
            if colorScheme == .dark {
                Color.black.opacity(0.8)
            } else {
                Color.white.opacity(0.95)
            }

            // Category tint
            categoryColor.opacity(colorScheme == .dark ? 0.08 : 0.05)

            // Top gradient
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var cardOverlay: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.2 : 0.5),
                        categoryColor.opacity(colorScheme == .dark ? 0.1 : 0.2),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }

    private var categoryColor: Color {
        switch achievement.category {
        case .pottyStreak: return .ollieAccent
        case .training: return .olliePurple
        case .socialization: return .ollieAccent
        case .health: return .ollieSuccess
        case .lifestyle: return .olliePurple
        case .timeBased: return .ollieRose
        }
    }

    // MARK: - Actions

    private func dismissWithAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            cardAppeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview("Tier 2 - Health Achievement") {
    Tier2CelebrationCard(
        achievement: Achievement(
            id: "test.health",
            category: .health,
            tier: .notable,
            labelKey: "achievement.health.firstVaccination",
            value: nil
        ),
        puppyName: "Ollie",
        onAddPhoto: { print("Add photo") },
        onShare: { print("Share") },
        onDismiss: { print("Dismiss") }
    )
}

#Preview("Tier 2 - Streak Record") {
    Tier2CelebrationCard(
        achievement: Achievement.pottyStreak(days: 7, isRecord: true),
        puppyName: "Ollie",
        onAddPhoto: { print("Add photo") },
        onShare: { print("Share") },
        onDismiss: { print("Dismiss") }
    )
}
