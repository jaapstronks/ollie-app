//
//  MobilityAssessmentSheet.swift
//  Ollie-app
//
//  Sheet for logging mobility assessments for senior dogs
//  Part of Brief 05: Senior Wellness
//

import SwiftUI
import OtisShared

struct MobilityAssessmentSheet: View {
    let onSave: (MobilityAssessment) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileStore: ProfileStore

    @State private var selectedScore: Int = 3
    @State private var selectedObservations: Set<MobilityObservation> = []
    @State private var note: String = ""

    private var puppyName: String {
        profileStore.activeProfile?.name ?? "Your dog"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Score Selection
                    scoreSection

                    // Observations
                    observationsSection

                    // Note
                    noteSection
                }
                .padding()
            }
            .navigationTitle(Strings.SeniorWellness.mobilityAssessment)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.SeniorWellness.saveAssessment) {
                        saveAssessment()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Score Section

    @ViewBuilder
    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Strings.SeniorWellness.rateMobilityFor(name: puppyName))
                .font(.headline)

            // Score buttons
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { score in
                    ScoreButton(
                        score: score,
                        isSelected: selectedScore == score,
                        action: { selectedScore = score }
                    )
                }
            }

            // Score description
            if let level = MobilityScoreLevel(rawValue: selectedScore) {
                Text(level.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Observations Section

    @ViewBuilder
    private var observationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(Strings.SeniorWellness.observations)
                    .font(.headline)
                Text(Strings.SeniorWellness.observationsHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            FlowLayout(spacing: 8) {
                ForEach(MobilityObservation.allCases, id: \.self) { observation in
                    ObservationChip(
                        observation: observation,
                        isSelected: selectedObservations.contains(observation),
                        action: {
                            if selectedObservations.contains(observation) {
                                selectedObservations.remove(observation)
                            } else {
                                selectedObservations.insert(observation)
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Note Section

    @ViewBuilder
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.SeniorWellness.addNote)
                .font(.headline)

            TextField(Strings.SeniorWellness.optionalNotes, text: $note, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Actions

    private func saveAssessment() {
        let assessment = MobilityAssessment(
            score: selectedScore,
            observations: Array(selectedObservations),
            note: note.isEmpty ? nil : note
        )
        onSave(assessment)
        dismiss()
    }
}

// MARK: - Supporting Views

private struct ScoreButton: View {
    let score: Int
    let isSelected: Bool
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
                .font(.title2)
                .fontWeight(.bold)
                .frame(width: 48, height: 48)
                .background(isSelected ? color : Color(.tertiarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Circle())
                .overlay {
                    if isSelected {
                        Circle()
                            .stroke(color, lineWidth: 3)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

private struct ObservationChip: View {
    let observation: MobilityObservation
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: observation.icon)
                    .font(.caption)
                Text(observation.label)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.tertiarySystemBackground))
            .foregroundStyle(isSelected ? .blue : .primary)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    MobilityAssessmentSheet { assessment in
        print("Saved: \(assessment)")
    }
    .environmentObject(ProfileStore.shared)
}
