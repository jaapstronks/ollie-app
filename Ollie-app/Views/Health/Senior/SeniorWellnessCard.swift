//
//  SeniorWellnessCard.swift
//  Ollie-app
//
//  Card for displaying senior wellness status in timeline/dashboard
//  Part of Brief 05: Senior Wellness
//

import SwiftUI
import OtisShared

struct SeniorWellnessCard: View {
    @Environment(ProfileStore.self) private var profileStore
    @State private var wellnessStore = SeniorWellnessStore.shared

    let onMobilityTap: () -> Void
    let onCognitiveTap: () -> Void
    let onQoLTap: () -> Void
    let onRRRTap: () -> Void

    private var puppyName: String {
        profileStore.activeProfile?.name ?? "Your dog"
    }

    private var activeConditions: [HealthCondition] {
        profileStore.activeProfile?.healthConditions.filter { $0.status == .active } ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "heart.circle.fill")
                    .foregroundStyle(.pink)
                Text("\(puppyName)'s Wellness")
                    .font(.headline)
                Spacer()
            }

            // Quick status grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Mobility
                QuickStatusTile(
                    title: "Mobility",
                    icon: "figure.walk",
                    value: wellnessStore.latestMobility.map { "\($0.score)/5" },
                    status: wellnessStore.latestMobility?.scoreDescription,
                    statusColor: wellnessStore.latestMobility.map { mobilityColor(for: $0.score) },
                    action: onMobilityTap
                )

                // Energy/Appetite (from check-ins if available)
                if let qol = wellnessStore.latestQoL, qol.isCurrent {
                    QuickStatusTile(
                        title: "Quality",
                        icon: "heart.fill",
                        value: "\(qol.totalScore)/70",
                        status: qol.interpretation.label,
                        statusColor: Color(qol.interpretation.colorName),
                        action: onQoLTap
                    )
                } else {
                    QuickStatusTile(
                        title: "Quality",
                        icon: "heart.fill",
                        value: nil,
                        status: "Not assessed",
                        statusColor: nil,
                        action: onQoLTap
                    )
                }
            }

            // Breathing rate (if heart condition)
            if wellnessStore.shouldShowRRRTracking(activeConditions: activeConditions) {
                Divider()

                HStack {
                    Image(systemName: "lungs.fill")
                        .foregroundStyle(.blue)

                    if let rrr = wellnessStore.latestRRR {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Breathing: \(rrr.formattedBPM)")
                                .font(.subheadline)
                            Text(rrr.status.label)
                                .font(.caption)
                                .foregroundStyle(Color(rrr.status.colorName))
                        }
                    } else {
                        Text("No breathing readings yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(action: onRRRTap) {
                        CapsuleBadge("Log", color: .blue, style: .tinted)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Cognitive check reminder (monthly)
            if wellnessStore.cognitiveAssessmentDue {
                Divider()

                Button(action: onCognitiveTap) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(.purple)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cognitive Check-In")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if let last = wellnessStore.latestCognitive {
                                Text("Last: \(last.createdAt, style: .relative)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Recommended monthly for seniors")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func mobilityColor(for score: Int) -> Color {
        switch score {
        case 1...2: return .red
        case 3: return .orange
        case 4...5: return .green
        default: return .gray
        }
    }
}

// MARK: - Quick Status Tile

private struct QuickStatusTile: View {
    let title: String
    let icon: String
    let value: String?
    let status: String?
    let statusColor: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(.blue)
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let value = value {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                } else {
                    Text("--")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                if let status = status {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(statusColor ?? .secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SeniorWellnessCard(
        onMobilityTap: {},
        onCognitiveTap: {},
        onQoLTap: {},
        onRRRTap: {}
    )
    .environment(ProfileStore.shared)
    .padding()
}
