//
//  QualityOfLifeSheet.swift
//  Ollie-app
//
//  Sheet for quality of life (HHHHHMM) assessment
//  Part of Brief 05: Senior Wellness
//

import SwiftUI
import OtisShared

struct QualityOfLifeSheet: View {
    let onSave: (QualityOfLifeAssessment) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileStore: ProfileStore

    @State private var scores: [QoLCategory: Int] = [:]
    @State private var note: String = ""

    private var puppyName: String {
        profileStore.activeProfile?.name ?? "Your dog"
    }

    private var totalScore: Int {
        QoLCategory.allCases.reduce(0) { $0 + (scores[$1] ?? 5) }
    }

    private var interpretation: QoLInterpretation {
        let percentage = Double(totalScore) / 70.0
        switch percentage {
        case 0.8...: return .good
        case 0.5..<0.8: return .acceptable
        case 0.35..<0.5: return .compromised
        default: return .poor
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Instructions
                    Text(Strings.SeniorWellness.rateEachArea)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Category sliders
                    ForEach(QoLCategory.allCases, id: \.self) { category in
                        categorySection(category)
                    }

                    // Score summary
                    scoreSummary

                    // Note
                    noteSection
                }
                .padding()
            }
            .navigationTitle(Strings.SeniorWellness.qualityOfLife)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.SeniorWellness.save) {
                        saveAssessment()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            // Initialize with default scores
            for category in QoLCategory.allCases {
                scores[category] = 5
            }
        }
    }

    // MARK: - Category Section

    @ViewBuilder
    private func categorySection(_ category: QoLCategory) -> some View {
        let score = Binding(
            get: { scores[category] ?? 5 },
            set: { scores[category] = $0 }
        )

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.label)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(category.question)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(score.wrappedValue)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(colorForScore(score.wrappedValue))
                    .frame(width: 30)
            }

            // Slider
            HStack {
                Text(category.lowLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                Slider(value: .init(
                    get: { Double(score.wrappedValue) },
                    set: { score.wrappedValue = Int($0.rounded()) }
                ), in: 1...10, step: 1)
                .tint(colorForScore(score.wrappedValue))

                Text(category.highLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .trailing)
            }

            // Score buttons for precise selection
            HStack(spacing: 4) {
                ForEach(1...10, id: \.self) { value in
                    Button {
                        scores[category] = value
                    } label: {
                        Text("\(value)")
                            .font(.caption2)
                            .frame(width: 24, height: 24)
                            .background(score.wrappedValue == value ? colorForScore(value) : Color(.tertiarySystemBackground))
                            .foregroundStyle(score.wrappedValue == value ? .white : .primary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 1...3: return .red
        case 4...5: return .orange
        case 6...7: return .yellow
        case 8...10: return .green
        default: return .gray
        }
    }

    // MARK: - Score Summary

    @ViewBuilder
    private var scoreSummary: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: interpretation.icon)
                    .foregroundStyle(Color(interpretation.colorName))
                Text(Strings.SeniorWellness.qolScore(totalScore, maxScore: 70))
                    .font(.headline)
            }

            Text(interpretation.label)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color(interpretation.colorName))

            Text(interpretation.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(interpretation.colorName).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        let assessment = QualityOfLifeAssessment(
            hurt: scores[.hurt] ?? 5,
            hunger: scores[.hunger] ?? 5,
            hydration: scores[.hydration] ?? 5,
            hygiene: scores[.hygiene] ?? 5,
            happiness: scores[.happiness] ?? 5,
            mobility: scores[.mobility] ?? 5,
            moreDays: scores[.moreDays] ?? 5,
            note: note.isEmpty ? nil : note
        )
        onSave(assessment)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    QualityOfLifeSheet { assessment in
        print("Saved: \(assessment)")
    }
    .environmentObject(ProfileStore.shared)
}
