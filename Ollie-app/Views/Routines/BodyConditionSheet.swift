//
//  BodyConditionSheet.swift
//  Otis-app
//
//  9-point body condition score selector
//

import SwiftUI
import OtisShared

/// Sheet for recording body condition score
struct BodyConditionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RoutineStore.self) private var routineStore

    @State private var selectedScore: Int = 5
    @State private var note: String = ""
    @State private var showHistory = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Score selector
                    scoreSelector

                    // Selected score details
                    scoreDetails

                    // Note
                    noteSection

                    // History toggle
                    if !routineStore.bodyConditionScores.isEmpty {
                        historySection
                    }
                }
                .padding()
            }
            .navigationTitle(Strings.BodyCondition.score)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        routineStore.addBodyConditionScore(selectedScore, note: note.isEmpty ? nil : note)
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Score Selector

    @ViewBuilder
    private var scoreSelector: some View {
        VStack(spacing: 12) {
            Text(Strings.BodyCondition.ninePointScale)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Score grid
            HStack(spacing: 8) {
                ForEach(1...9, id: \.self) { score in
                    let category = BCSCategory(score: score) ?? .ideal

                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedScore = score
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(score)")
                                .font(.title2.bold())
                                .foregroundStyle(selectedScore == score ? .white : Color(category.color))

                            Circle()
                                .fill(selectedScore == score ? Color(category.color) : Color(category.color).opacity(0.2))
                                .frame(width: 8, height: 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedScore == score ? Color(category.color) : Color(.tertiarySystemGroupedBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Scale labels
            HStack {
                Text("Underweight")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Ideal")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Spacer()
                Text("Overweight")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Score Details

    @ViewBuilder
    private var scoreDetails: some View {
        let category = BCSCategory(score: selectedScore) ?? .ideal

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(Color(category.color))

                VStack(alignment: .leading) {
                    Text(category.label)
                        .font(.headline)
                    Text("Score \(selectedScore)/9")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if category.isHealthy {
                    Label("Healthy", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Text(category.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            // Recommendation
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)

                Text(category.recommendation)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Note Section

    @ViewBuilder
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Common.note)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("Add any observations...", text: $note, axis: .vertical)
                .lineLimit(3...6)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - History Section

    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    showHistory.toggle()
                }
            } label: {
                HStack {
                    Text(Strings.BodyCondition.history)
                        .font(.headline)

                    Spacer()

                    Image(systemName: showHistory ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if showHistory {
                ForEach(routineStore.bodyConditionScores.prefix(10)) { score in
                    HStack {
                        Text("\(score.score)/9")
                            .font(.headline)
                            .foregroundStyle(Color(score.category.color))
                            .frame(width: 44)

                        VStack(alignment: .leading) {
                            Text(score.category.label)
                                .font(.subheadline)
                            Text(score.formattedDate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if let note = score.note, !note.isEmpty {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BodyConditionSheet()
        .environment(RoutineStore())
}
