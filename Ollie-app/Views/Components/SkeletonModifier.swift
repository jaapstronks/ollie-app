//
//  SkeletonModifier.swift
//  Ollie-app
//
//  Shimmer loading effect for skeleton screens.
//  Creates a polished loading state that feels faster than spinners.
//

import SwiftUI

// MARK: - Skeleton View Modifier

/// Applies a shimmering skeleton loading effect to any view
struct SkeletonModifier: ViewModifier {
    let isLoading: Bool

    @State private var shimmerOffset: CGFloat = -1
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if isLoading {
            content
                .redacted(reason: .placeholder)
                .overlay(
                    GeometryReader { geometry in
                        if !reduceMotion {
                            shimmerGradient
                                .frame(width: geometry.size.width * 2)
                                .offset(x: shimmerOffset * geometry.size.width * 2)
                        }
                    }
                    .clipped()
                )
                .onAppear {
                    startShimmerAnimation()
                }
                .accessibilityLabel("Loading")
        } else {
            content
        }
    }

    private var shimmerGradient: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                Color.white.opacity(colorScheme == .dark ? 0.25 : 0.6),
                Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func startShimmerAnimation() {
        guard !reduceMotion else { return }

        shimmerOffset = -1
        withAnimation(
            .linear(duration: 1.5)
            .repeatForever(autoreverses: false)
        ) {
            shimmerOffset = 1
        }
    }
}

extension View {
    /// Applies a skeleton loading effect when isLoading is true
    func skeleton(isLoading: Bool) -> some View {
        modifier(SkeletonModifier(isLoading: isLoading))
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

// MARK: - Pre-built Skeleton Components

/// Skeleton for a timeline event row
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

/// Skeleton for a status card
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

/// Skeleton for a gallery thumbnail
struct SkeletonThumbnail: View {
    var body: some View {
        SkeletonRect(height: 100, cornerRadius: LayoutConstants.cornerRadiusS)
    }
}

/// Skeleton for a full timeline loading state
struct SkeletonTimeline: View {
    @State private var shimmerOffset: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .skeleton(isLoading: true)
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

            GroupBox("Event Row Skeleton") {
                SkeletonEventRow()
            }

            GroupBox("Status Card Skeleton") {
                SkeletonStatusCard()
            }

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
                .skeleton(isLoading: isLoading)
                .padding(.horizontal)

                Spacer()
            }
        }
    }

    return LoadingDemo()
}
