//
//  TrainingLogSheet.swift
//  Otis-app
//
//  Sheet for logging a training session with rep tracking and context
//

import SwiftUI
import OtisShared

/// Sheet for logging a training session for a specific skill
struct TrainingLogSheet: View {
    let skill: Skill
    let prefillData: TrainingSessionData?
    let onSave: (PuppyEvent) -> Void
    let onCancel: () -> Void

    /// Optional callback to record session in SkillProgressStore
    var onRecordProgress: ((String, Int, Int, String?) -> Void)?

    @State private var selectedTime: Date
    @State private var duration: Int
    @State private var result: String = ""
    @State private var note: String = ""

    // Rep tracking
    @State private var successReps: Int = 0
    @State private var failedReps: Int = 0

    // Training context
    @State private var selectedContext: StandardTrainingContext = .home

    @Environment(\.colorScheme) private var colorScheme

    init(
        skill: Skill,
        prefillData: TrainingSessionData? = nil,
        onSave: @escaping (PuppyEvent) -> Void,
        onCancel: @escaping () -> Void,
        onRecordProgress: ((String, Int, Int, String?) -> Void)? = nil
    ) {
        self.skill = skill
        self.prefillData = prefillData
        self.onSave = onSave
        self.onCancel = onCancel
        self.onRecordProgress = onRecordProgress

        // Pre-fill from session data if available
        if let data = prefillData {
            _selectedTime = State(initialValue: data.startTime)
            _duration = State(initialValue: max(1, data.durationMinutes))
            // Use click count as initial success reps for clicker-based training
            _successReps = State(initialValue: data.clickCount)
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
                        tintColor: .otisAccent
                    )

                    // Session summary (if from training mode)
                    if let data = prefillData {
                        sessionSummaryCard(data)
                    }

                    // Rep counter section
                    repCounterSection

                    // Context picker section
                    contextPickerSection

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
                .fill(Color.otisAccent.opacity(colorScheme == .dark ? 0.15 : 0.1))
        )
    }

    // MARK: - Rep Counter Section

    @ViewBuilder
    private var repCounterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Training.howDidItGo)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                // Success reps
                repCounter(
                    label: Strings.Training.successfulReps,
                    value: $successReps,
                    color: .otisSuccess,
                    icon: "checkmark.circle.fill"
                )

                // Failed reps
                repCounter(
                    label: Strings.Training.failedReps,
                    value: $failedReps,
                    color: .otisWarning,
                    icon: "xmark.circle.fill"
                )
            }

            // Success rate indicator (if any reps logged)
            if successReps + failedReps > 0 {
                let successRate = Double(successReps) / Double(successReps + failedReps)
                let rateColor: Color = successRate >= 0.8 ? .otisSuccess : (successRate >= 0.5 ? .orange : .otisWarning)
                HStack {
                    Text(Strings.Training.confidencePercent(Int(successRate * 100)))
                        .font(.caption)
                        .foregroundStyle(rateColor)
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private func repCounter(
        label: String,
        value: Binding<Int>,
        color: Color,
        icon: String
    ) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    if value.wrappedValue > 0 {
                        value.wrappedValue -= 1
                        HapticFeedback.light()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(value.wrappedValue > 0 ? color : .secondary.opacity(0.3))
                }
                .disabled(value.wrappedValue == 0)

                Text("\(value.wrappedValue)")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(minWidth: 36)
                    .monospacedDigit()

                Button {
                    value.wrappedValue += 1
                    HapticFeedback.light()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(color)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(colorScheme == .dark ? 0.1 : 0.05))
        )
    }

    // MARK: - Context Picker Section

    @ViewBuilder
    private var contextPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Training.whereDidYouTrain)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(StandardTrainingContext.allCases, id: \.rawValue) { context in
                        contextButton(context)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func contextButton(_ context: StandardTrainingContext) -> some View {
        let isSelected = selectedContext == context

        Button {
            selectedContext = context
            HapticFeedback.selection()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: context.icon)
                    .font(.system(size: 14))
                Text(contextLabel(for: context))
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected
                          ? Color.otisAccent
                          : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    /// Get localized label for training context
    private func contextLabel(for context: StandardTrainingContext) -> String {
        switch context {
        case .home: return Strings.Training.contextHome
        case .garden: return Strings.Training.contextGarden
        case .quietStreet: return Strings.Training.contextQuietStreet
        case .busyStreet: return Strings.Training.contextBusyStreet
        case .park: return Strings.Training.contextPark
        case .indoorPublic: return Strings.Training.contextIndoorPublic
        case .carRide: return Strings.Training.contextCarRide
        case .other: return Strings.Training.contextOther
        }
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
        // Build note with context info if reps are logged
        var fullNote = note
        if successReps + failedReps > 0 && note.isEmpty {
            let successRate = Double(successReps) / Double(successReps + failedReps)
            fullNote = "\(Int(successRate * 100))% success (\(successReps)/\(successReps + failedReps))"
        }

        let event = PuppyEvent(
            time: selectedTime,
            type: .training,
            note: fullNote.nilIfBlank,
            exercise: skill.id,
            result: result.nilIfBlank,
            durationMin: duration,
            successReps: successReps > 0 ? successReps : nil,
            failedReps: failedReps > 0 ? failedReps : nil,
            trainingContext: selectedContext.rawValue
        )

        // Record progress if callback is provided and reps were logged
        if let onRecordProgress = onRecordProgress, successReps + failedReps > 0 {
            onRecordProgress(skill.id, successReps, failedReps, selectedContext.rawValue)
        }

        HapticFeedback.success()
        onSave(event)
    }
}

// MARK: - Preview

private let previewSkillForTrainingLog = Skill(
    id: "sit",
    icon: "arrow.down.to.line",
    category: .basicCommands,
    sortOrder: 7,
    requires: ["luring"],
    method: .classical,
    durationMinutes: 3,
    sessionsPerDay: 3,
    steps: nil,
    phases: nil
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
