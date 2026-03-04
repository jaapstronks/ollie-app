//
//  FloatingClickerButton.swift
//  Otis-app
//
//  Compact floating clicker button for use anywhere in the app
//

import SwiftUI

/// Compact floating clicker button with sound and haptic feedback
struct FloatingClickerButton: View {
    @State private var isPressed = false
    @State private var clickCount = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let buttonSize: CGFloat = 60

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
                                Color.otisAccent.opacity(0.3),
                                Color.otisAccent.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: buttonSize + 12, height: buttonSize + 12)

                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.otisAccent,
                                Color.otisAccent.opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: buttonSize, height: buttonSize)
                    .shadow(
                        color: Color.otisAccent.opacity(0.4),
                        radius: isPressed ? 2 : 8,
                        y: isPressed ? 1 : 4
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
                    .frame(width: buttonSize - 12, height: buttonSize - 12)
                    .offset(y: -6)

                // Icon
                Image(systemName: "hand.tap.fill")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(FloatingClickerButtonStyle(isPressed: $isPressed))
        .accessibilityLabel(Strings.TrainingSession.clickerAccessibilityLabel)
        .accessibilityHint(Strings.TrainingSession.clickerAccessibilityHint)
        .onAppear {
            AudioService.shared.prepareClickSound()
        }
    }

    private func handleClick() {
        clickCount += 1

        // Play sound
        AudioService.shared.playClick()

        // Trigger haptic
        HapticFeedback.heavy()
    }
}

// MARK: - Floating Clicker Button Style

/// Custom button style that tracks press state without blocking gesture
private struct FloatingClickerButtonStyle: ButtonStyle {
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
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingClickerButton()
                    .padding(.trailing, 16)
                    .padding(.bottom, 100)
            }
        }
    }
}
