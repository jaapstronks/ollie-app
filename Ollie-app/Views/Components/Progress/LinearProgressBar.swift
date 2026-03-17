//
//  LinearProgressBar.swift
//  Otis-app
//
//  Reusable linear progress bar component.
//  Consolidates duplicated GeometryReader + ZStack progress bar patterns.
//

import SwiftUI

/// A horizontal progress bar with customizable appearance
///
/// Usage:
/// ```swift
/// LinearProgressBar(progress: 0.75, tint: .green)
/// LinearProgressBar(current: 5, total: 10, tint: .blue, height: 8)
/// ```
struct LinearProgressBar: View {
    /// Progress as a fraction (0.0 to 1.0)
    let progress: CGFloat

    /// The fill color for the progress portion
    let tint: Color

    /// Height of the progress bar
    let height: CGFloat

    /// Corner radius (defaults to half of height for pill shape)
    let cornerRadius: CGFloat?

    /// Background opacity (for the unfilled portion)
    let backgroundOpacity: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initializers

    /// Initialize with a progress fraction
    init(
        progress: CGFloat,
        tint: Color = .otisAccent,
        height: CGFloat = 6,
        cornerRadius: CGFloat? = nil,
        backgroundOpacity: CGFloat = 0.2
    ) {
        self.progress = min(max(progress, 0), 1)
        self.tint = tint
        self.height = height
        self.cornerRadius = cornerRadius
        self.backgroundOpacity = backgroundOpacity
    }

    /// Initialize with current/total counts
    init(
        current: Int,
        total: Int,
        tint: Color = .otisAccent,
        height: CGFloat = 6,
        cornerRadius: CGFloat? = nil,
        backgroundOpacity: CGFloat = 0.2
    ) {
        let fraction = total > 0 ? CGFloat(current) / CGFloat(total) : 0
        self.progress = min(max(fraction, 0), 1)
        self.tint = tint
        self.height = height
        self.cornerRadius = cornerRadius
        self.backgroundOpacity = backgroundOpacity
    }

    // MARK: - Body

    private var resolvedCornerRadius: CGFloat {
        cornerRadius ?? (height / 2)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: resolvedCornerRadius)
                    .fill(Color.secondary.opacity(backgroundOpacity))
                    .frame(height: height)

                // Progress fill
                RoundedRectangle(cornerRadius: resolvedCornerRadius)
                    .fill(tint)
                    .frame(width: geometry.size.width * progress, height: height)
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

// MARK: - Gradient Variant

/// Linear progress bar with gradient fill
struct GradientProgressBar: View {
    let progress: CGFloat
    let gradient: LinearGradient
    let height: CGFloat
    let cornerRadius: CGFloat?
    let backgroundOpacity: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    init(
        progress: CGFloat,
        colors: [Color],
        height: CGFloat = 6,
        cornerRadius: CGFloat? = nil,
        backgroundOpacity: CGFloat = 0.2
    ) {
        self.progress = min(max(progress, 0), 1)
        self.gradient = LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
        self.height = height
        self.cornerRadius = cornerRadius
        self.backgroundOpacity = backgroundOpacity
    }

    private var resolvedCornerRadius: CGFloat {
        cornerRadius ?? (height / 2)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: resolvedCornerRadius)
                    .fill(Color.secondary.opacity(backgroundOpacity))
                    .frame(height: height)

                RoundedRectangle(cornerRadius: resolvedCornerRadius)
                    .fill(gradient)
                    .frame(width: geometry.size.width * progress, height: height)
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

// MARK: - Preview

#Preview("Linear Progress Bars") {
    VStack(spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Basic Progress Bars").font(.headline)
            LinearProgressBar(progress: 0.25, tint: .red)
            LinearProgressBar(progress: 0.5, tint: .orange)
            LinearProgressBar(progress: 0.75, tint: .green)
            LinearProgressBar(progress: 1.0, tint: .blue)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Different Heights").font(.headline)
            LinearProgressBar(progress: 0.6, tint: .purple, height: 4)
            LinearProgressBar(progress: 0.6, tint: .purple, height: 8)
            LinearProgressBar(progress: 0.6, tint: .purple, height: 12)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("With Counts").font(.headline)
            HStack {
                LinearProgressBar(current: 3, total: 10, tint: .otisAccent)
                Text("3/10")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Gradient").font(.headline)
            GradientProgressBar(
                progress: 0.7,
                colors: [.purple, .pink]
            )
        }
    }
    .padding()
}
