//
//  ClickerButton.swift
//  Ollie-app
//
//  Reusable clicker button component for training sessions
//

import SwiftUI

/// Large clicker button with sound and haptic feedback
struct ClickerButton: View {
    @Binding var clickCount: Int
    let soundEnabled: Bool
    let vibrationEnabled: Bool

    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let buttonSize: CGFloat = 160

    var body: some View {
        Button {
            handleClick()
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.ollieAccent.opacity(0.3),
                                Color.ollieAccent.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: buttonSize + 24, height: buttonSize + 24)

                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.ollieAccent,
                                Color.ollieAccent.opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: buttonSize, height: buttonSize)
                    .shadow(
                        color: Color.ollieAccent.opacity(0.4),
                        radius: isPressed ? 4 : 12,
                        y: isPressed ? 2 : 6
                    )

                // Inner highlight
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: buttonSize - 20, height: buttonSize - 20)
                    .offset(y: -10)

                // Label
                VStack(spacing: 4) {
                    Text(Strings.TrainingSession.click)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Image(systemName: "hand.tap.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(ClickerButtonStyle(isPressed: $isPressed))
        .accessibilityLabel(Strings.TrainingSession.clickerAccessibilityLabel)
        .accessibilityHint(Strings.TrainingSession.clickerAccessibilityHint)
    }

    private func handleClick() {
        clickCount += 1

        // Play sound if enabled
        if soundEnabled {
            AudioService.shared.playClick()
        }

        // Trigger haptic if enabled
        if vibrationEnabled {
            HapticFeedback.heavy()
        }
    }
}

// MARK: - Clicker Button Style

/// Custom button style that tracks press state without blocking gesture
private struct ClickerButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var clicks = 0

        var body: some View {
            VStack(spacing: 32) {
                Text("\(clicks)")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .accessibilityLabel(Strings.TrainingSession.clickCount(clicks))

                Text(Strings.TrainingSession.clicks)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                ClickerButton(
                    clickCount: $clicks,
                    soundEnabled: true,
                    vibrationEnabled: true
                )
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
