//
//  MobilityTrendCard.swift
//  Ollie-app
//
//  Card showing mobility assessment trends for senior dogs
//  Part of Brief 05: Senior Wellness
//

import SwiftUI
import OtisShared

struct MobilityTrendCard: View {
    @Environment(ProfileStore.self) private var profileStore
    @StateObject private var wellnessStore = SeniorWellnessStore.shared

    let onLogTap: () -> Void
    let onViewHistoryTap: () -> Void

    private var puppyName: String {
        profileStore.activeProfile?.name ?? "Your dog"
    }

    private var weekAssessments: [MobilityAssessment] {
        wellnessStore.mobilityAssessmentsThisWeek()
    }

    private var averageScore: Double? {
        guard !weekAssessments.isEmpty else { return nil }
        return Double(weekAssessments.reduce(0) { $0 + $1.score }) / Double(weekAssessments.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundStyle(.blue)
                Text(Strings.SeniorWellness.howIsMobility(name: puppyName))
                    .font(.headline)
                Spacer()
            }

            // Quick score buttons
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { score in
                    QuickScoreButton(
                        score: score,
                        isLatest: wellnessStore.latestMobility?.score == score && wellnessStore.latestMobility?.isToday == true,
                        action: {
                            wellnessStore.recordMobility(score: score)
                        }
                    )
                }
            }

            // Weekly summary
            if !weekAssessments.isEmpty {
                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.SeniorWellness.thisWeek)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let avg = averageScore {
                            Text(String(format: "Average: %.1f/5", avg))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }

                    Spacer()

                    // Mini trend indicators
                    HStack(spacing: 4) {
                        ForEach(weekAssessments.suffix(7).reversed()) { assessment in
                            Circle()
                                .fill(colorForScore(assessment.score))
                                .frame(width: 8, height: 8)
                        }
                    }

                    if let trend = wellnessStore.mobilityState.trend {
                        HStack(spacing: 4) {
                            Image(systemName: trend.icon)
                            Text(trend.label)
                        }
                        .font(.caption)
                        .foregroundStyle(Color(trend.colorName))
                    }
                }

                // Common observations this week
                let observations = commonObservationsThisWeek()
                if !observations.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(observations.prefix(3), id: \.self) { observation in
                            Label(observation.label, systemImage: observation.icon)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Actions
            HStack {
                Button(action: onLogTap) {
                    Label("Log Details", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                Spacer()

                Button(action: onViewHistoryTap) {
                    Text(Strings.SeniorWellness.viewHistory)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .mint
        case 5: return .green
        default: return .gray
        }
    }

    private func commonObservationsThisWeek() -> [MobilityObservation] {
        var counts: [MobilityObservation: Int] = [:]
        for assessment in weekAssessments {
            for observation in assessment.observations {
                counts[observation, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }.map(\.key)
    }
}

// MARK: - Quick Score Button

private struct QuickScoreButton: View {
    let score: Int
    let isLatest: Bool
    let action: () -> Void

    private var color: Color {
        switch score {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .mint
        case 5: return .green
        default: return .gray
        }
    }

    var body: some View {
        Button(action: action) {
            Text("\(score)")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isLatest ? color : Color(.tertiarySystemBackground))
                .foregroundStyle(isLatest ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    if isLatest {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color, lineWidth: 2)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Extension for isToday

private extension MobilityAssessment {
    var isToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }
}

// MARK: - Preview

#Preview {
    MobilityTrendCard(
        onLogTap: {},
        onViewHistoryTap: {}
    )
    .environment(ProfileStore.shared)
    .padding()
}
