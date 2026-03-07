//
//  CognitiveAssessmentSheet.swift
//  Ollie-app
//
//  Sheet for cognitive dysfunction (CCD) screening using DISHAA framework
//  Part of Brief 05: Senior Wellness
//

import SwiftUI
import OtisShared

struct CognitiveAssessmentSheet: View {
    let onSave: (CognitiveAssessment) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileStore: ProfileStore

    @State private var selectedSymptoms: Set<CCDSymptom> = []
    @State private var note: String = ""
    @State private var showingGuidance = false

    private var puppyName: String {
        profileStore.activeProfile?.name ?? "Your dog"
    }

    private var currentScore: Int {
        selectedSymptoms.count
    }

    private var currentSeverity: CCDSeverity {
        switch currentScore {
        case 0: return .none
        case 1...3: return .mild
        case 4...8: return .moderate
        default: return .severe
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Prompt
                    Text(Strings.SeniorWellness.cognitivePrompt(name: puppyName))
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Categories with symptoms
                    ForEach(CCDCategory.allCases, id: \.self) { category in
                        categorySection(category)
                    }

                    // Score summary
                    scoreSummary

                    // Note
                    noteSection
                }
                .padding()
            }
            .navigationTitle(Strings.SeniorWellness.cognitiveAssessment)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.SeniorWellness.saveAndGetGuidance) {
                        showingGuidance = true
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingGuidance) {
                GuidanceSheet(
                    severity: currentSeverity,
                    score: currentScore,
                    onDismiss: {
                        saveAssessment()
                    }
                )
            }
        }
    }

    // MARK: - Category Section

    @ViewBuilder
    private func categorySection(_ category: CCDCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .foregroundStyle(.blue)
                Text(category.label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            VStack(spacing: 8) {
                ForEach(category.symptoms, id: \.self) { symptom in
                    SymptomRow(
                        symptom: symptom,
                        isSelected: selectedSymptoms.contains(symptom),
                        action: {
                            if selectedSymptoms.contains(symptom) {
                                selectedSymptoms.remove(symptom)
                            } else {
                                selectedSymptoms.insert(symptom)
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Score Summary

    @ViewBuilder
    private var scoreSummary: some View {
        VStack(spacing: 8) {
            HStack {
                Text(Strings.SeniorWellness.ccdScore(currentScore, maxScore: CognitiveAssessment.maxScore))
                    .font(.headline)
                Text("•")
                    .foregroundStyle(.secondary)
                Text(currentSeverity.label)
                    .font(.headline)
                    .foregroundStyle(Color(currentSeverity.colorName))
            }

            if currentScore > 0 {
                Text(currentSeverity.guidance)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(currentSeverity.colorName).opacity(0.1))
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
        let assessment = CognitiveAssessment(
            symptoms: selectedSymptoms,
            note: note.isEmpty ? nil : note
        )
        onSave(assessment)
        dismiss()
    }
}

// MARK: - Supporting Views

private struct SymptomRow: View {
    let symptom: CCDSymptom
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelected ? .blue : .secondary)

                Text(symptom.label)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct GuidanceSheet: View {
    let severity: CCDSeverity
    let score: Int
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: severity == .none ? "checkmark.circle.fill" : "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(Color(severity.colorName))

            // Title
            Text(severity.label)
                .font(.title2)
                .fontWeight(.bold)

            // Score
            Text(Strings.SeniorWellness.ccdScore(score, maxScore: CognitiveAssessment.maxScore))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Guidance
            Text(severity.guidance)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Done button
            Button {
                dismiss()
                onDismiss()
            } label: {
                Text(Strings.Common.done)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 40)
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    CognitiveAssessmentSheet { assessment in
        print("Saved: \(assessment)")
    }
    .environmentObject(ProfileStore.shared)
}
