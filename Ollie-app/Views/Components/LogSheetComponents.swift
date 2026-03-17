//
//  LogSheetComponents.swift
//  Otis-app
//
//  Shared UI components for quick log sheets

import SwiftUI
import OtisShared

// MARK: - Note Field

/// Shared note field component for log sheets
struct LogSheetNoteField: View {
    @Binding var note: String
    var label: String = Strings.QuickLogSheet.noteOptional
    var placeholder: String = Strings.QuickLogSheet.notePlaceholder
    var accessibilityIdentifier: String = "LOG_NOTE_FIELD"

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $note)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(Strings.LogEvent.note)
                .accessibilityHint(Strings.QuickLogSheet.noteAccessibilityHint)
                .accessibilityIdentifier(accessibilityIdentifier)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Action Buttons

/// Shared action buttons component for log sheets (cancel + save)
struct LogSheetActionButtons: View {
    let canSave: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var saveLabel: String = Strings.Common.log
    var cancelAccessibilityIdentifier: String = "LOG_CANCEL_BUTTON"
    var saveAccessibilityIdentifier: String = "LOG_SAVE_BUTTON"

    var body: some View {
        HStack(spacing: 16) {
            Button(Strings.Common.cancel) {
                onCancel()
            }
            .foregroundStyle(.secondary)
            .accessibilityIdentifier(cancelAccessibilityIdentifier)

            Button {
                HapticFeedback.success()
                onSave()
            } label: {
                HStack {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                    Text(saveLabel)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canSave ? Color.accentColor : Color.gray)
                .cornerRadius(LayoutConstants.cornerRadiusM)
            }
            .disabled(!canSave)
            .accessibilityIdentifier(saveAccessibilityIdentifier)
        }
    }
}

// MARK: - Previews

#Preview("Note Field") {
    LogSheetNoteField(note: .constant(""))
        .padding()
}

#Preview("Action Buttons - Enabled") {
    LogSheetActionButtons(
        canSave: true,
        onCancel: {},
        onSave: {}
    )
    .padding()
}

#Preview("Action Buttons - Disabled") {
    LogSheetActionButtons(
        canSave: false,
        onCancel: {},
        onSave: {}
    )
    .padding()
}
