//
//  GrowthProgressArc.swift
//  Otis-app
//
//  Semi-circular progress arc showing journey to adult weight
//

import SwiftUI
import OtisShared

/// Progress arc showing journey from start weight to adult weight
struct GrowthProgressArc: View {
    let startWeight: Double
    let currentWeight: Double
    let estimatedAdultWeight: Double
    let weightUnit: WeightUnit
    let animated: Bool

    @State private var animatedProgress: Double = 0

    private var progress: Double {
        guard estimatedAdultWeight > startWeight else { return 1.0 }
        let range = estimatedAdultWeight - startWeight
        let current = currentWeight - startWeight
        return min(1.0, max(0.0, current / range))
    }

    var body: some View {
        VStack(spacing: 8) {
            // Arc visualization
            ZStack {
                // Background arc
                ArcShape(progress: 1.0)
                    .stroke(
                        Color.secondary.opacity(0.15),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )

                // Progress arc
                ArcShape(progress: animatedProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.otisAccent.opacity(0.6), .otisAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )

                // Current position indicator
                Circle()
                    .fill(Color.otisAccent)
                    .frame(width: 12, height: 12)
                    .shadow(color: .otisAccent.opacity(0.3), radius: 4)
                    .offset(x: indicatorOffset.x, y: indicatorOffset.y)
            }
            .frame(height: 60)

            // Labels
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Growth.startWeight)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(weightUnit.format(startWeight))
                        .font(.caption)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(Strings.Growth.currentWeight)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(weightUnit.format(currentWeight))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.otisAccent)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(Strings.Growth.adultWeight)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(weightUnit.format(estimatedAdultWeight))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                    animatedProgress = progress
                }
            } else {
                animatedProgress = progress
            }
        }
    }

    // Calculate indicator position on the arc
    private var indicatorOffset: CGPoint {
        // Arc goes from left to right (180 degrees)
        let angle = Double.pi * (1 - animatedProgress)
        let radius: CGFloat = 50 // Match arc radius
        let x = cos(angle) * radius
        let y = -sin(angle) * radius + 30 // Offset for arc center
        return CGPoint(x: x, y: y)
    }
}

/// Custom arc shape for the progress indicator
private struct ArcShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY - 10)
        let radius = min(rect.width / 2, rect.height) - 10

        // Start from left, go to right (180 degrees)
        let startAngle = Angle(degrees: 180)
        let endAngle = Angle(degrees: 180 - (180 * progress))

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        return path
    }
}

// MARK: - Preview

#Preview("50% Progress") {
    GrowthProgressArc(
        startWeight: 4.0,
        currentWeight: 14.0,
        estimatedAdultWeight: 27.0,
        weightUnit: .kg,
        animated: true
    )
    .padding()
    .background(Color(.secondarySystemBackground))
}

#Preview("75% Progress") {
    GrowthProgressArc(
        startWeight: 4.0,
        currentWeight: 21.0,
        estimatedAdultWeight: 27.0,
        weightUnit: .kg,
        animated: true
    )
    .padding()
    .background(Color(.secondarySystemBackground))
}
