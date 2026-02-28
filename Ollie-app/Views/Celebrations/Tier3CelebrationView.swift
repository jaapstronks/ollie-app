//
//  Tier3CelebrationView.swift
//  Ollie-app
//
//  Tier 3 celebration: Full-screen with multi-burst confetti sequence
//  Used for major achievements like potty trained, all vaccinations complete

import SwiftUI
import OllieShared

/// Tier 3 full-screen celebration for major achievements
struct Tier3CelebrationView: View {
    let achievement: Achievement
    let puppyName: String
    let onTakePhoto: () -> Void
    let onAddFromLibrary: () -> Void
    let onSkip: () -> Void

    @State private var phase: CelebrationPhase = .buildup
    @State private var confettiBurst1 = false
    @State private var confettiBurst2 = false
    @State private var confettiBurst3 = false
    @State private var contentVisible = false
    @State private var buttonsVisible = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum CelebrationPhase {
        case buildup
        case reveal
        case celebration
        case interactive
    }

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            // Content
            VStack(spacing: 32) {
                Spacer()

                // Achievement badge with animation
                achievementBadge
                    .scaleEffect(phase == .reveal || phase == .celebration || phase == .interactive ? 1 : 0.3)
                    .opacity(phase == .buildup ? 0 : 1)

                // Achievement text
                VStack(spacing: 12) {
                    Text(achievement.localizedLabel)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text(achievement.celebrationMessage)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 20)

                Spacer()

                // Camera prompt
                if phase == .interactive {
                    VStack(spacing: 16) {
                        Text(Strings.Celebrations.captureThisMoment)
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        // Action buttons
                        VStack(spacing: 12) {
                            Button {
                                onTakePhoto()
                            } label: {
                                Label(Strings.Common.takePhoto, systemImage: "camera.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                            .buttonStyle(.glassPrimary(tint: .accent))

                            Button {
                                onAddFromLibrary()
                            } label: {
                                Label(Strings.Celebrations.addFromLibrary, systemImage: "photo.on.rectangle")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.glassSecondary)

                            Button {
                                onSkip()
                            } label: {
                                Text(Strings.Celebrations.maybeLater)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 24)
                    }
                    .opacity(buttonsVisible ? 1 : 0)
                    .offset(y: buttonsVisible ? 0 : 30)
                }

                Spacer()
                    .frame(height: 60)
            }
            .padding(.horizontal, 24)

            // Multi-burst confetti
            CelebrationView(style: .milestone, isActive: $confettiBurst1)
            CelebrationView(style: .streak, isActive: $confettiBurst2)
            CelebrationView(style: .milestone, isActive: $confettiBurst3)
        }
        .ignoresSafeArea()
        .onAppear {
            startCelebrationSequence()
        }
    }

    // MARK: - Components

    @ViewBuilder
    private var backgroundGradient: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    categoryColor.opacity(0.3),
                    Color(UIColor.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Radial glow behind badge
            RadialGradient(
                colors: [
                    categoryColor.opacity(0.4),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            .offset(y: -100)

            // Subtle pattern overlay (reduced motion respects this)
            if !reduceMotion {
                ShimmeringOverlay()
                    .opacity(0.3)
            }
        }
    }

    @ViewBuilder
    private var achievementBadge: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(categoryColor.opacity(0.1 - Double(index) * 0.03), lineWidth: 2)
                    .frame(width: 180 + CGFloat(index) * 40, height: 180 + CGFloat(index) * 40)
                    .scaleEffect(phase == .celebration || phase == .interactive ? 1 : 0.8)
                    .opacity(phase == .celebration || phase == .interactive ? 1 : 0)
            }

            // Main badge
            ZStack {
                // Background glow
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)

                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                categoryColor,
                                categoryColor.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: categoryColor.opacity(0.5), radius: 20)

                // Icon
                Image(systemName: achievement.category.icon)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.white)

                // Value badge
                if let value = achievement.value {
                    Text("\(value)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.3))
                        )
                        .offset(x: 55, y: -55)
                }
            }
        }
    }

    // MARK: - Animation Sequence

    private func startCelebrationSequence() {
        // Respect reduced motion
        if reduceMotion {
            phase = .interactive
            contentVisible = true
            buttonsVisible = true
            HapticFeedback.success()
            return
        }

        // Phase 1: Buildup (0.5s)
        withAnimation(.easeIn(duration: 0.5)) {
            phase = .reveal
        }

        // Phase 2: Reveal with first confetti (0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                phase = .celebration
            }
            confettiBurst1 = true
            HapticFeedback.success()
        }

        // Phase 3: Second confetti burst (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            confettiBurst2 = true
            HapticFeedback.light()
        }

        // Phase 4: Third confetti burst (2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            confettiBurst3 = true
        }

        // Phase 5: Show content (1.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.4)) {
                contentVisible = true
            }
        }

        // Phase 6: Show buttons (3.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.4)) {
                phase = .interactive
                buttonsVisible = true
            }
        }
    }

    // MARK: - Styling

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
}

// MARK: - Shimmering Overlay

private struct ShimmeringOverlay: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.1),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Tier 3 - Potty Trained") {
    Tier3CelebrationView(
        achievement: Achievement(
            id: "potty.streak.14",
            category: .pottyStreak,
            tier: .major,
            labelKey: "achievement.pottyStreak.14",
            value: 14
        ),
        puppyName: "Ollie",
        onTakePhoto: { print("Take photo") },
        onAddFromLibrary: { print("Add from library") },
        onSkip: { print("Skip") }
    )
}

#Preview("Tier 3 - First Birthday") {
    Tier3CelebrationView(
        achievement: Achievement.monthlyBirthday(months: 12),
        puppyName: "Ollie",
        onTakePhoto: { print("Take photo") },
        onAddFromLibrary: { print("Add from library") },
        onSkip: { print("Skip") }
    )
}
