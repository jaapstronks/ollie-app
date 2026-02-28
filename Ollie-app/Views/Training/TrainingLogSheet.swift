//
//  TrainingLogSheet.swift
//  Ollie-app
//
//  Sheet for logging a training session
//

import SwiftUI
import OllieShared

/// Sheet for logging a training session for a specific skill
struct TrainingLogSheet: View {
    let skill: Skill
    let prefillData: TrainingSessionData?
    let onSave: (PuppyEvent) -> Void
    let onCancel: () -> Void

    @State private var selectedTime: Date
    @State private var duration: Int
    @State private var result: String = ""
    @State private var note: String = ""

    @Environment(\.colorScheme) private var colorScheme

    init(
        skill: Skill,
        prefillData: TrainingSessionData? = nil,
        onSave: @escaping (PuppyEvent) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.skill = skill
        self.prefillData = prefillData
        self.onSave = onSave
        self.onCancel = onCancel

        // Pre-fill from session data if available
        if let data = prefillData {
            _selectedTime = State(initialValue: data.startTime)
            _duration = State(initialValue: max(1, data.durationMinutes))
        } else {
            _selectedTime = State(initialValue: Date())
            _duration = State(initialValue: 5)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Skill header
                    SheetHeaderCard(
                        title: skill.name,
                        icon: .skill(skill),
                        subtitle: skill.category.label,
                        tintColor: .ollieAccent
                    )

                    // Session summary (if from training mode)
                    if let data = prefillData {
                        sessionSummaryCard(data)
                    }

                    // Time picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.QuickLogSheet.time)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        DatePicker(
                            "",
                            selection: $selectedTime,
                            in: ...Date(),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }

                    // Duration stepper
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.Training.duration)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("\(duration)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(minWidth: 40)

                            Text(Strings.Training.durationMinutes)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Stepper("", value: $duration, in: 1...30)
                                .labelsHidden()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                        )
                    }

                    // Result field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.Training.result)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        TextField(Strings.Training.resultPlaceholder, text: $result)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                            )
                    }

                    // Note field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.Training.note)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        TextField(notePlaceholder, text: $note, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(3...5)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                            )
                    }
                }
                .padding()
            }
            .navigationTitle(Strings.Training.logTrainingSession)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        saveSession()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Session Summary Card

    @ViewBuilder
    private func sessionSummaryCard(_ data: TrainingSessionData) -> some View {
        HStack(spacing: 16) {
            // Duration
            VStack(spacing: 4) {
                Text("\(data.durationMinutes)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(Strings.Common.minutes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // Clicks
            VStack(spacing: 4) {
                Text("\(data.clickCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(Strings.TrainingSession.clicks)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.ollieAccent.opacity(colorScheme == .dark ? 0.15 : 0.1))
        )
    }

    // MARK: - Helpers

    private var notePlaceholder: String {
        if let data = prefillData, data.clickCount > 0 {
            return "\(data.clickCount) clicks..."
        }
        return Strings.Training.notePlaceholder
    }

    // MARK: - Save

    private func saveSession() {
        let event = PuppyEvent(
            time: selectedTime,
            type: .training,
            note: note.isEmpty ? nil : note,
            exercise: skill.id,
            result: result.isEmpty ? nil : result,
            durationMin: duration
        )

        HapticFeedback.success()
        onSave(event)
    }
}

// MARK: - Preview

private let previewSkillForTrainingLog = Skill(
    id: "sit",
    icon: "arrow.down.to.line",
    category: .basicCommands,
    week: 2,
    priority: 1,
    requires: ["luring"]
)

#Preview("Without Prefill") {
    TrainingLogSheet(
        skill: previewSkillForTrainingLog,
        onSave: { _ in },
        onCancel: {}
    )
}

#Preview("With Prefill") {
    TrainingLogSheet(
        skill: previewSkillForTrainingLog,
        prefillData: TrainingSessionData(
            skill: previewSkillForTrainingLog,
            startTime: Date().addingTimeInterval(-180),
            endTime: Date(),
            clickCount: 12
        ),
        onSave: { _ in },
        onCancel: {}
    )
}
