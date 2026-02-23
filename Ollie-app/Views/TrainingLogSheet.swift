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
    let onSave: (PuppyEvent) -> Void
    let onCancel: () -> Void

    @State private var selectedTime: Date = Date()
    @State private var duration: Int = 5
    @State private var result: String = ""
    @State private var note: String = ""

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Skill header
                    skillHeader

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

                        TextField(Strings.Training.notePlaceholder, text: $note, axis: .vertical)
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

    // MARK: - Skill Header

    @ViewBuilder
    private var skillHeader: some View {
        HStack(spacing: 12) {
            // Icon in circle
            ZStack {
                Circle()
                    .fill(Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: skill.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(Color.ollieAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(skill.category.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassStatusCard(tintColor: Color.ollieAccent)
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

#Preview {
    TrainingLogSheet(
        skill: previewSkillForTrainingLog,
        onSave: { _ in },
        onCancel: {}
    )
}
