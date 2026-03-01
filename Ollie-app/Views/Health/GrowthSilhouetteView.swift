//
//  GrowthSilhouetteView.swift
//  Otis-app
//
//  Visual before/after dog silhouette showing growth
//

import SwiftUI
import OtisShared

/// Visual representation of puppy growth with scaled dog silhouettes
struct GrowthSilhouetteView: View {
    let firstWeight: Double
    let currentWeight: Double
    let weightUnit: WeightUnit
    let animated: Bool

    @State private var showAnimation = false

    // Scale calculation: small dog is base, large dog scales up based on ratio
    private var sizeRatio: CGFloat {
        guard firstWeight > 0 else { return 1.0 }
        let ratio = currentWeight / firstWeight
        // Cap the visual ratio to avoid extremely large icons
        return min(CGFloat(ratio), 3.0)
    }

    // Base size for the small (first weight) dog
    private let baseSize: CGFloat = 24

    var body: some View {
        HStack(spacing: 0) {
            // First weight (small dog)
            VStack(spacing: 6) {
                Image(systemName: "dog.fill")
                    .font(.system(size: baseSize))
                    .foregroundStyle(.secondary.opacity(0.5))

                Text(weightUnit.format(firstWeight))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 50)

            // Arrow/path between
            GrowthArrow()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)

            // Current weight (large dog)
            VStack(spacing: 6) {
                Image(systemName: "dog.fill")
                    .font(.system(size: showAnimation ? baseSize * sizeRatio : baseSize))
                    .foregroundStyle(Color.otisAccent)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showAnimation)

                Text(weightUnit.format(currentWeight))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .frame(minWidth: 60)
        }
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 0.1)) {
                    showAnimation = true
                }
            } else {
                showAnimation = true
            }
        }
    }
}

/// Arrow showing growth direction
private struct GrowthArrow: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let midY = geometry.size.height / 2
                let startX: CGFloat = 0
                let endX = geometry.size.width

                // Draw dashed line
                path.move(to: CGPoint(x: startX, y: midY))
                path.addLine(to: CGPoint(x: endX - 8, y: midY))

                // Draw arrow head
                path.move(to: CGPoint(x: endX - 12, y: midY - 4))
                path.addLine(to: CGPoint(x: endX, y: midY))
                path.addLine(to: CGPoint(x: endX - 12, y: midY + 4))
            }
            .stroke(
                Color.secondary.opacity(0.4),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 4])
            )
        }
        .frame(height: 24)
    }
}

// MARK: - Preview

#Preview("Growth 2x") {
    GrowthSilhouetteView(
        firstWeight: 4.0,
        currentWeight: 8.0,
        weightUnit: .kg,
        animated: true
    )
    .padding()
    .background(Color(.secondarySystemBackground))
}

#Preview("Growth 3x") {
    GrowthSilhouetteView(
        firstWeight: 3.0,
        currentWeight: 9.0,
        weightUnit: .kg,
        animated: true
    )
    .padding()
    .background(Color(.secondarySystemBackground))
}
