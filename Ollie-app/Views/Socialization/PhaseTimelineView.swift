//
//  PhaseTimelineView.swift
//  Otis-app
//
//  Visual timeline showing socialization phases

import SwiftUI
import OtisShared

/// Visual timeline showing the socialization journey phases
struct PhaseTimelineView: View {
    let currentPhase: SocializationPhase

    @Environment(\.colorScheme) private var colorScheme

    private let phases: [SocializationPhase] = [
        .settlingIn,
        .firstSteps,
        .buildingConfidence,
        .peakWindow,
        .maintenance
    ]

    var body: some View {
        VStack(spacing: 8) {
            // Timeline dots and lines
            HStack(spacing: 0) {
                ForEach(Array(phases.enumerated()), id: \.element.rawValue) { index, phase in
                    if index > 0 {
                        // Connector line
                        Rectangle()
                            .fill(phase.sortOrder <= currentPhase.sortOrder ? Color.otisAccent : Color.secondary.opacity(0.3))
                            .frame(height: 2)
                    }

                    // Phase dot
                    phaseDot(for: phase)
                }
            }
            .padding(.horizontal, 8)

            // Phase labels
            HStack(spacing: 0) {
                ForEach(phases, id: \.rawValue) { phase in
                    Text(shortPhaseName(for: phase))
                        .font(.system(size: 9, weight: phase == currentPhase ? .semibold : .regular))
                        .foregroundStyle(phase == currentPhase ? Color.otisAccent : .secondary)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Socialization.journeyTimelineLabel)
        .accessibilityValue(Strings.Socialization.phaseAccessibility(name: phaseName(for: currentPhase), isCurrent: true))
    }

    @ViewBuilder
    private func phaseDot(for phase: SocializationPhase) -> some View {
        let isCurrent = phase == currentPhase
        let isCompleted = phase.sortOrder < currentPhase.sortOrder
        let size: CGFloat = isCurrent ? 24 : 16

        ZStack {
            Circle()
                .fill(dotColor(for: phase))
                .frame(width: size, height: size)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
            } else if isCurrent {
                Image(systemName: phase.icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentPhase)
    }

    private func dotColor(for phase: SocializationPhase) -> Color {
        if phase.sortOrder < currentPhase.sortOrder {
            return .otisSuccess
        } else if phase == currentPhase {
            return .otisAccent
        }
        return Color.secondary.opacity(0.3)
    }

    private func shortPhaseName(for phase: SocializationPhase) -> String {
        switch phase {
        case .settlingIn: return "Settle"
        case .firstSteps: return "First"
        case .buildingConfidence: return "Build"
        case .peakWindow: return "Peak"
        case .maintenance: return "Maint"
        }
    }

    private func phaseName(for phase: SocializationPhase) -> String {
        switch phase {
        case .settlingIn: return Strings.Socialization.phaseSettlingIn
        case .firstSteps: return Strings.Socialization.phaseFirstSteps
        case .buildingConfidence: return Strings.Socialization.phaseBuildingConfidence
        case .peakWindow: return Strings.Socialization.phasePeakWindow
        case .maintenance: return Strings.Socialization.phaseMaintenance
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        PhaseTimelineView(currentPhase: .settlingIn)
        PhaseTimelineView(currentPhase: .firstSteps)
        PhaseTimelineView(currentPhase: .buildingConfidence)
        PhaseTimelineView(currentPhase: .peakWindow)
        PhaseTimelineView(currentPhase: .maintenance)
    }
    .padding()
}
