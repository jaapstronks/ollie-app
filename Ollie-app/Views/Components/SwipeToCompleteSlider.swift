//
//  SwipeToCompleteSlider.swift
//  Ollie-app
//
//  Swipe gesture slider that prevents accidental taps for completing actions
//

import SwiftUI

/// A swipe-to-complete slider that requires deliberate gesture to trigger
struct SwipeToCompleteSlider: View {
    let label: String
    let icon: String
    let tintColor: Color
    let onComplete: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var isComplete = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Threshold percentage of track width to trigger completion
    private let completionThreshold: CGFloat = 0.75

    /// Thumb size
    private let thumbSize: CGFloat = 44

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let maxOffset = trackWidth - thumbSize - 8 // 8 = padding on both sides

            ZStack(alignment: .leading) {
                // Track background
                trackBackground

                // Progress fill
                progressFill(maxOffset: maxOffset)

                // Label
                sliderLabel(trackWidth: trackWidth)

                // Draggable thumb
                thumb(maxOffset: maxOffset)
            }
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .frame(height: 52)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityHint(Strings.Common.doubleTapHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            // VoiceOver double-tap alternative
            complete()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var trackBackground: some View {
        ZStack {
            // Base glass layer
            if colorScheme == .dark {
                Color.white.opacity(0.08)
            } else {
                Color.white.opacity(0.6)
            }

            // Tint overlay
            tintColor.opacity(colorScheme == .dark ? 0.1 : 0.08)

            // Top highlight
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .background(.thinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                            Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
    }

    @ViewBuilder
    private func progressFill(maxOffset: CGFloat) -> some View {
        let progress = min(1, dragOffset / maxOffset)

        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        tintColor.opacity(0.3),
                        tintColor.opacity(0.15)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: max(0, dragOffset + thumbSize + 8))
            .opacity(progress > 0.1 ? 1 : 0)
    }

    @ViewBuilder
    private func sliderLabel(trackWidth: CGFloat) -> some View {
        HStack(spacing: 8) {
            Spacer()

            if !isComplete {
                Image(systemName: "chevron.right.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .opacity(dragOffset > 20 ? 0 : 1)

                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .opacity(dragOffset > 40 ? 0.5 : 1)
            } else {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tintColor)
            }

            Spacer()
        }
        .padding(.leading, thumbSize + 12)
    }

    @ViewBuilder
    private func thumb(maxOffset: CGFloat) -> some View {
        ZStack {
            // Thumb background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            tintColor,
                            tintColor.opacity(0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: tintColor.opacity(0.3), radius: 4, y: 2)

            // Icon
            Image(systemName: isComplete ? "checkmark" : icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(width: thumbSize, height: thumbSize)
        .offset(x: 4 + dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let newOffset = max(0, min(value.translation.width, maxOffset))
                    dragOffset = newOffset

                    // Selection haptic during drag
                    if Int(newOffset) % 30 == 0 {
                        HapticFeedback.selection()
                    }
                }
                .onEnded { value in
                    let progress = dragOffset / maxOffset
                    if progress >= completionThreshold {
                        complete()
                    } else {
                        // Spring back
                        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }

    // MARK: - Actions

    private func complete() {
        guard !isComplete else { return }

        HapticFeedback.success()
        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
            isComplete = true
            dragOffset = 0
        }

        // Call completion after brief delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onComplete()
        }
    }
}

// MARK: - Strings Extension

extension Strings.Common {
    static let doubleTapHint = String(localized: "Double-tap to complete")
}

// MARK: - Preview

#Preview("SwipeToCompleteSlider") {
    VStack(spacing: 20) {
        SwipeToCompleteSlider(
            label: "Slide to complete",
            icon: "pills.fill",
            tintColor: .ollieAccent,
            onComplete: { print("Completed!") }
        )

        SwipeToCompleteSlider(
            label: "Mark as done",
            icon: "checkmark",
            tintColor: .ollieSuccess,
            onComplete: { print("Done!") }
        )
    }
    .padding()
}
