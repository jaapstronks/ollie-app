//
//  SkeletonModifier.swift
//  Otis-app
//
//  Shimmer loading effect for skeleton screens.
//  Uses a single shared animation phase for optimal performance.
//

import Combine
import QuartzCore
import SwiftUI

// MARK: - Shared Shimmer Phase

/// Shared animation phase for all skeleton shimmer effects.
/// Uses CADisplayLink for a controllable, cancellable animation.
@MainActor
private final class ShimmerPhaseProvider: ObservableObject {
    static let shared = ShimmerPhaseProvider()

    /// Current shimmer phase (0...1), cycles every 1.5 seconds
    @Published private(set) var phase: CGFloat = 0

    /// Number of active subscribers - animation only runs when > 0
    private var subscriberCount = 0
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    private let duration: CFTimeInterval = 1.5

    private init() {}

    func subscribe() {
        subscriberCount += 1
        if subscriberCount == 1 {
            startAnimation()
        }
    }

    func unsubscribe() {
        subscriberCount = max(0, subscriberCount - 1)
        if subscriberCount == 0 {
            stopAnimation()
        }
    }

    private func startAnimation() {
        guard displayLink == nil else { return }
        startTime = CACurrentMediaTime()

        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
        phase = 0
    }

    @objc private func tick() {
        let elapsed = CACurrentMediaTime() - startTime
        // Map to 0...1 range, cycling every `duration` seconds
        phase = CGFloat(elapsed.truncatingRemainder(dividingBy: duration) / duration)
    }
}

// MARK: - Skeleton View Modifier

/// Applies a shimmering skeleton loading effect to any view.
/// Uses a shared animation source for optimal performance.
struct SkeletonModifier: ViewModifier {
    let isLoading: Bool

    @StateObject private var phaseProvider = ShimmerPhaseProvider.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if isLoading {
            content
                .redacted(reason: .placeholder)
                .overlay(shimmerOverlay)
                .onAppear {
                    // PERFORMANCE: Check debug toggle to disable shimmer animation
                    if !reduceMotion && !PerformanceDebug.disableSkeletons {
                        phaseProvider.subscribe()
                    }
                }
                .onDisappear {
                    phaseProvider.unsubscribe()
                }
                .accessibilityLabel("Loading")
        } else {
            content
        }
    }

    @ViewBuilder
    private var shimmerOverlay: some View {
        if !reduceMotion {
            ShimmerOverlay(phase: phaseProvider.phase)
                .drawingGroup()
        }
    }
}

/// Efficient shimmer overlay using a single gradient pass
private struct ShimmerOverlay: View {
    let phase: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            // Offset ranges from -width to +width based on phase
            let offset = (phase * 3 - 1) * width

            LinearGradient(
                colors: shimmerColors,
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width)
            .offset(x: offset)
        }
        .clipped()
    }

    private var shimmerColors: [Color] {
        let opacity1 = colorScheme == .dark ? 0.15 : 0.4
        let opacity2 = colorScheme == .dark ? 0.25 : 0.6
        return [
            Color.clear,
            Color.white.opacity(opacity1),
            Color.white.opacity(opacity2),
            Color.white.opacity(opacity1),
            Color.clear
        ]
    }
}

extension View {
    /// Applies a shimmering skeleton loading effect when isLoading is true.
    /// Use this on container views wrapping skeleton shape components.
    func shimmer(isLoading: Bool) -> some View {
        modifier(SkeletonModifier(isLoading: isLoading))
    }

    /// Applies a skeleton loading effect when isLoading is true.
    /// Convenience method that calls shimmer(isLoading:).
    func skeleton(isLoading: Bool) -> some View {
        shimmer(isLoading: isLoading)
    }
}

// MARK: - Skeleton Shape Components

/// A skeleton placeholder for text lines
struct SkeletonText: View {
    let width: CGFloat?
    let height: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    init(width: CGFloat? = nil, height: CGFloat = 16) {
        self.width = width
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(skeletonColor)
            .frame(width: width, height: height)
    }

    private var skeletonColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.08)
    }
}

/// A skeleton placeholder for circular elements (avatars, icons)
struct SkeletonCircle: View {
    let size: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Circle()
            .fill(skeletonColor)
            .frame(width: size, height: size)
    }

    private var skeletonColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.08)
    }
}

/// A skeleton placeholder for rectangular elements (cards, images)
struct SkeletonRect: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    init(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = LayoutConstants.cornerRadiusM) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(skeletonColor)
            .frame(width: width, height: height)
    }

    private var skeletonColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.08)
    }
}

// MARK: - Pre-built Skeleton Components (No individual animation)

/// Skeleton for a timeline event row.
/// NOTE: Apply `.skeleton(isLoading: true)` at the container level, not here.
struct SkeletonEventRow: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonCircle(size: 40)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonText(width: 120, height: 14)
                SkeletonText(width: 80, height: 12)
            }

            Spacer()

            SkeletonText(width: 50, height: 12)
        }
        .padding(.horizontal, LayoutConstants.horizontalPadding)
        .padding(.vertical, 12)
    }
}

/// Skeleton for a status card.
/// NOTE: Apply `.skeleton(isLoading: true)` at the container level, not here.
struct SkeletonStatusCard: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonCircle(size: 44)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonText(width: 140, height: 16)
                SkeletonText(width: 100, height: 12)
            }

            Spacer()

            SkeletonRect(width: 60, height: 28, cornerRadius: 14)
        }
        .padding(LayoutConstants.statusCardHorizontalPadding)
        .glassBackground(.card)
    }
}

/// Skeleton for a gallery thumbnail.
/// NOTE: Apply `.skeleton(isLoading: true)` at the container level, not here.
struct SkeletonThumbnail: View {
    var body: some View {
        SkeletonRect(height: 100, cornerRadius: LayoutConstants.cornerRadiusS)
    }
}

/// Skeleton for a full timeline loading state.
/// This is a container - applies a SINGLE shimmer animation to all children.
struct SkeletonTimeline: View {
    var body: some View {
        VStack(spacing: 0) {
            // Status card skeleton
            SkeletonStatusCard()
                .padding(.horizontal)
                .padding(.bottom, 8)

            // Event rows skeleton
            ForEach(0..<5, id: \.self) { _ in
                SkeletonEventRow()
            }
        }
        .shimmer(isLoading: true) // Single animation for the entire container
    }
}

// MARK: - Preview

#Preview("Skeleton Components") {
    ScrollView {
        VStack(spacing: 24) {
            GroupBox("Skeleton Shapes") {
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonText(width: 200, height: 16)
                    SkeletonText(width: 150, height: 14)
                    SkeletonText(height: 12)

                    HStack {
                        SkeletonCircle(size: 44)
                        SkeletonCircle(size: 32)
                        SkeletonCircle(size: 24)
                    }

                    SkeletonRect(height: 80)
                }
            }
            .shimmer(isLoading: true)

            GroupBox("Event Row Skeleton") {
                SkeletonEventRow()
            }
            .shimmer(isLoading: true)

            GroupBox("Status Card Skeleton") {
                SkeletonStatusCard()
            }
            .shimmer(isLoading: true)

            GroupBox("Timeline Skeleton") {
                SkeletonTimeline()
            }
        }
        .padding()
    }
}

#Preview("Skeleton Loading State") {
    struct LoadingDemo: View {
        @State private var isLoading = true

        var body: some View {
            VStack(spacing: 20) {
                Toggle("Loading", isOn: $isLoading)
                    .padding()

                // Card with skeleton modifier
                VStack(alignment: .leading, spacing: 8) {
                    Text("Status Card")
                        .font(.headline)
                    Text("This is a description that shows when loaded")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .glassBackground(.card)
                .shimmer(isLoading: isLoading)
                .padding(.horizontal)

                Spacer()
            }
        }
    }

    return LoadingDemo()
}
