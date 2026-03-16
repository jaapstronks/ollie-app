//
//  ProgressRing.swift
//  Otis-app
//
//  Reusable circular progress indicator component
//

import SwiftUI

/// A circular progress ring with optional center text
///
/// Usage:
/// ```swift
/// ProgressRing(progress: 0.75, total: 10, completed: 7)
/// ProgressRing(fraction: 0.5, size: .large, tint: .purple)
/// ```
struct ProgressRing: View {
    /// Progress as a fraction (0.0 to 1.0)
    let fraction: CGFloat

    /// Size preset for the ring
    let size: Size

    /// Tint color for the progress arc
    let tint: Color

    /// Line width of the ring
    let lineWidth: CGFloat

    /// Optional center text (e.g., "5/10")
    let centerText: String?

    /// Font size for center text (auto-calculated if nil)
    let textSize: CGFloat?

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Size Presets

    enum Size {
        case compact    // 44pt - for inline use
        case standard   // 48pt - default
        case large      // 60pt - for prominent display

        var dimension: CGFloat {
            switch self {
            case .compact: return 44
            case .standard: return 48
            case .large: return 60
            }
        }

        var defaultTextSize: CGFloat {
            switch self {
            case .compact: return 9
            case .standard: return 10
            case .large: return 12
            }
        }

        var defaultLineWidth: CGFloat {
            switch self {
            case .compact: return 4
            case .standard: return 4
            case .large: return 5
            }
        }
    }

    // MARK: - Initializers

    /// Initialize with a fraction value
    init(
        fraction: CGFloat,
        size: Size = .standard,
        tint: Color = .otisAccent,
        lineWidth: CGFloat? = nil,
        centerText: String? = nil,
        textSize: CGFloat? = nil
    ) {
        self.fraction = min(max(fraction, 0), 1)
        self.size = size
        self.tint = tint
        self.lineWidth = lineWidth ?? size.defaultLineWidth
        self.centerText = centerText
        self.textSize = textSize
    }

    /// Initialize with completed/total counts
    init(
        completed: Int,
        total: Int,
        size: Size = .standard,
        tint: Color = .otisAccent,
        lineWidth: CGFloat? = nil,
        showText: Bool = true,
        textSize: CGFloat? = nil
    ) {
        let fraction = total > 0 ? CGFloat(completed) / CGFloat(total) : 0
        self.fraction = min(max(fraction, 0), 1)
        self.size = size
        self.tint = tint
        self.lineWidth = lineWidth ?? size.defaultLineWidth
        self.centerText = showText ? "\(completed)/\(total)" : nil
        self.textSize = textSize
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Center text
            if let text = centerText {
                Text(text)
                    .font(.system(size: textSize ?? size.defaultTextSize, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size.dimension, height: size.dimension)
    }
}

// MARK: - Preview

#Preview("Progress Ring Sizes") {
    VStack(spacing: 24) {
        HStack(spacing: 24) {
            VStack {
                ProgressRing(completed: 5, total: 10, size: .compact)
                Text("Compact").font(.caption)
            }

            VStack {
                ProgressRing(completed: 7, total: 10, size: .standard)
                Text("Standard").font(.caption)
            }

            VStack {
                ProgressRing(completed: 9, total: 10, size: .large)
                Text("Large").font(.caption)
            }
        }

        HStack(spacing: 24) {
            ProgressRing(completed: 3, total: 10, size: .compact, tint: .purple)
            ProgressRing(completed: 5, total: 10, size: .compact, tint: .orange)
            ProgressRing(completed: 8, total: 10, size: .compact, tint: .green)
        }

        // Without text
        HStack(spacing: 24) {
            ProgressRing(fraction: 0.25, size: .standard, tint: .red)
            ProgressRing(fraction: 0.5, size: .standard, tint: .blue)
            ProgressRing(fraction: 0.75, size: .standard, tint: .green)
        }
    }
    .padding()
}
