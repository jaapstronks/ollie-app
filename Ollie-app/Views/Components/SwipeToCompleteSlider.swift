//
//  SwipeToCompleteSlider.swift
//  Ollie-app
//
//  Swipe gesture slider that prevents accidental taps for completing actions
//

import SwiftUI
import OllieShared

/// A swipe-to-complete slider that requires deliberate gesture to trigger
struct SwipeToCompleteSlider: View {
    let label: String
    let icon: String
    let tintColor: Color
    let onComplete: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var isComplete = false
    @State private var showCheckmark = false
    @State private var checkmarkScale: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Threshold percentage of track width to trigger completion (reduced for faster feel)
    private let completionThreshold: CGFloat = 0.65

    /// Thumb size
    private let thumbSize: CGFloat = 44

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let maxOffset = trackWidth - thumbSize - 8

            ZStack(alignment: .leading) {
                // Track background
                trackBackground

                // Progress fill
                progressFill(maxOffset: maxOffset)

                // Label or checkmark
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
            complete()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var trackBackground: some View {
        ZStack {
            if colorScheme == .dark {
                Color.white.opacity(0.08)
            } else {
                Color.white.opacity(0.6)
            }

            tintColor.opacity(colorScheme == .dark ? 0.1 : 0.08)

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
                        tintColor.opacity(isComplete ? 0.5 : 0.3),
                        tintColor.opacity(isComplete ? 0.3 : 0.15)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: isComplete ? .infinity : max(0, dragOffset + thumbSize + 8))
            .frame(maxWidth: isComplete ? .infinity : nil)
            .opacity(progress > 0.1 || isComplete ? 1 : 0)
    }

    @ViewBuilder
    private func sliderLabel(trackWidth: CGFloat) -> some View {
        HStack(spacing: 8) {
            Spacer()

            if isComplete {
                // Animated checkmark
                Image(systemName: "checkmark")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(tintColor)
                    .scaleEffect(checkmarkScale)
            } else {
                Image(systemName: "chevron.right.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .opacity(dragOffset > 20 ? 0 : 1)

                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .opacity(dragOffset > 40 ? 0.5 : 1)
            }

            Spacer()
        }
        .padding(.leading, isComplete ? 0 : thumbSize + 12)
    }

    @ViewBuilder
    private func thumb(maxOffset: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            isComplete ? Color.ollieSuccess : tintColor,
                            (isComplete ? Color.ollieSuccess : tintColor).opacity(0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: (isComplete ? Color.ollieSuccess : tintColor).opacity(0.4), radius: isComplete ? 8 : 4, y: 2)

            Image(systemName: isComplete ? "checkmark" : icon)
                .font(.body.weight(.bold))
                .foregroundStyle(.white)
                .scaleEffect(isComplete ? 1.1 : 1)
        }
        .frame(width: thumbSize, height: thumbSize)
        .scaleEffect(isComplete ? 1.15 : 1)
        .offset(x: isComplete ? (maxOffset / 2) : (4 + dragOffset))
        .opacity(isComplete ? 0 : 1)
        .gesture(
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    guard !isComplete else { return }
                    let newOffset = max(0, min(value.translation.width, maxOffset))
                    dragOffset = newOffset

                    // Haptic feedback at key points
                    let progress = newOffset / maxOffset
                    if progress > 0.6 && progress < 0.65 {
                        HapticFeedback.light()
                    }
                }
                .onEnded { _ in
                    guard !isComplete else { return }
                    let progress = dragOffset / maxOffset
                    if progress >= completionThreshold {
                        complete()
                    } else {
                        // Quick snap back
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }

    // MARK: - Actions

    private func complete() {
        guard !isComplete else { return }

        // Immediate haptic
        HapticFeedback.success()

        // Quick completion animation
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            isComplete = true
            dragOffset = 0
        }

        // Checkmark pop animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.1)) {
            checkmarkScale = 1.2
        }

        withAnimation(.spring(response: 0.2, dampingFraction: 0.7).delay(0.25)) {
            checkmarkScale = 1.0
        }

        // Call completion quickly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
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
