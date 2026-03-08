//
//  GroomingQuickLogSheet.swift
//  Otis-app
//
//  Quick logging sheet for grooming activities from Today tab
//  Allows marking activities complete without going to full settings
//

import SwiftUI
import OtisShared

/// Quick log sheet for grooming activities
struct GroomingQuickLogSheet: View {
    @EnvironmentObject var routineStore: RoutineStore
    @Environment(\.dismiss) private var dismiss

    let puppyName: String
    /// Optional: pre-select a specific activity type
    var preselectedType: GroomingType? = nil

    @State private var selectedType: GroomingType? = nil
    @State private var logDate: Date = Date()
    @State private var note: String = ""
    @State private var showingDatePicker = false
    @FocusState private var isNoteFocused: Bool

    /// Activities that are enabled in the user's grooming schedule
    private var enabledActivities: [GroomingActivity] {
        routineStore.groomingActivities.filter(\.isEnabled).sorted { a, b in
            // Sort by urgency (most overdue first)
            (a.daysUntilDue ?? -1000) < (b.daysUntilDue ?? -1000)
        }
    }

    /// All grooming types (for logging activities not yet tracked)
    private var allTypes: [GroomingType] {
        GroomingType.allCases.filter { type in
            // Exclude types already shown in enabled activities
            !enabledActivities.contains { $0.type == type }
        }
    }

    /// Whether the log button should be enabled
    private var canLog: Bool {
        selectedType != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Activity selection
                    activitySelectionSection

                    // Date picker
                    dateSection

                    // Note field
                    noteSection
                }
                .padding()
            }
            .navigationTitle(Strings.Grooming.logActivity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Grooming.log) {
                        logActivity()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canLog)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(Strings.Common.done) {
                        isNoteFocused = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if let preselected = preselectedType {
                selectedType = preselected
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Activity Selection

    @ViewBuilder
    private var activitySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Grooming.whatDidYouDo)
                .font(.headline)

            // Grid of activity buttons
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                // Show enabled activities first (with status)
                ForEach(enabledActivities) { activity in
                    GroomingTypeButton(
                        type: activity.type,
                        isSelected: selectedType == activity.type,
                        status: activity.statusLabel,
                        isOverdue: activity.isOverdue,
                        onSelect: {
                            HapticFeedback.light()
                            selectedType = activity.type
                        }
                    )
                }

                // Show other types
                ForEach(allTypes, id: \.rawValue) { type in
                    GroomingTypeButton(
                        type: type,
                        isSelected: selectedType == type,
                        status: nil,
                        isOverdue: false,
                        onSelect: {
                            HapticFeedback.light()
                            selectedType = type
                        }
                    )
                }
            }
        }
    }

    // MARK: - Date Section

    @ViewBuilder
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Grooming.when)
                .font(.headline)

            Button {
                showingDatePicker.toggle()
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)

                    Text(formattedDate)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            if showingDatePicker {
                DatePicker(
                    "",
                    selection: $logDate,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingDatePicker)
    }

    // MARK: - Note Section

    @ViewBuilder
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Grooming.notesOptional)
                .font(.headline)

            TextField(Strings.Grooming.notePlaceholder, text: $note, axis: .vertical)
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .focused($isNoteFocused)
                .lineLimit(3...6)
        }
    }

    // MARK: - Helpers

    private var formattedDate: String {
        if Calendar.current.isDateInToday(logDate) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: logDate))"
        } else if Calendar.current.isDateInYesterday(logDate) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Yesterday, \(formatter.string(from: logDate))"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: logDate)
        }
    }

    private func logActivity() {
        guard let type = selectedType else { return }

        HapticFeedback.success()

        // Mark the activity as completed
        let noteToSave = note.isEmpty ? nil : note
        routineStore.markGroomingCompleted(type: type, at: logDate, note: noteToSave)

        dismiss()
    }
}

// MARK: - Grooming Type Button

private struct GroomingTypeButton: View {
    let type: GroomingType
    let isSelected: Bool
    let status: String?
    let isOverdue: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : (isOverdue ? .orange : .primary))

                Text(type.label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let status = status {
                    Text(status)
                        .font(.system(size: 9))
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : (isOverdue ? .orange : .secondary))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.otisAccent : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isOverdue && !isSelected ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Preview

#Preview("Empty") {
    GroomingQuickLogSheet(puppyName: "Luna")
        .environmentObject(RoutineStore())
}

#Preview("With Activities") {
    let store = RoutineStore()
    // Note: In real use, the store would have activities populated

    return GroomingQuickLogSheet(puppyName: "Ollie")
        .environmentObject(store)
}
