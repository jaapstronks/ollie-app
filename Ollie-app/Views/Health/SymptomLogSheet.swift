//
//  SymptomLogSheet.swift
//  Ollie-app
//
//  Sheet for logging health symptoms with detailed tracking
//  Follows the BehaviorLogSheet pattern
//  Part of Brief 04: Health Logging
//

import SwiftUI
import OtisShared

/// Sheet for logging health symptoms
struct SymptomLogSheet: View {
    let onSave: (HealthSymptomLog) -> Void
    let onCancel: () -> Void
    let preselectedConditionId: UUID?

    @State private var selectedSymptom: SymptomType?
    @State private var severity: Int = 3
    @State private var bodyLocation: BodyLocation?
    @State private var startTimeDescription: SymptomStartTime = .justNow
    @State private var duration: SymptomDuration = .ongoing
    @State private var selectedTriggers: Set<SymptomTrigger> = []
    @State private var customTrigger: String = ""
    @State private var note: String = ""

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var profileStore: ProfileStore

    init(
        preselectedConditionId: UUID? = nil,
        onSave: @escaping (HealthSymptomLog) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.preselectedConditionId = preselectedConditionId
        self.onSave = onSave
        self.onCancel = onCancel
    }

    private var canSave: Bool {
        selectedSymptom != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Symptom Selection
                    symptomSelectionSection

                    if selectedSymptom != nil {
                        // Severity
                        severitySection

                        // Body Location (optional)
                        bodyLocationSection

                        // When it started
                        startTimeSection

                        // Duration
                        durationSection

                        // Triggers
                        triggerSection

                        // Notes
                        notesSection

                        // Urgency warning if applicable
                        if let symptom = selectedSymptom, symptom.urgencyLevel == .emergency {
                            urgencyWarning
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(Strings.HealthLogging.logSymptom)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        onCancel()
                    }
                    .foregroundStyle(Color.otisAccent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.log) {
                        saveSymptom()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(canSave ? Color.otisAccent : Color.otisMuted)
                    .disabled(!canSave)
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var symptomSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.HealthLogging.whatDidYouNotice, icon: "stethoscope")

            // Group symptoms by category
            ForEach(relevantCategories, id: \.self) { category in
                VStack(alignment: .leading, spacing: 8) {
                    Text(category.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    FlowLayout(spacing: 8) {
                        ForEach(symptomsFor(category: category)) { symptom in
                            SymptomChip(
                                symptom: symptom,
                                isSelected: selectedSymptom == symptom
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedSymptom = symptom
                                }
                                HapticFeedback.selection()
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var severitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.HealthLogging.severity, icon: "chart.bar.fill")

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { level in
                    SeverityButton(
                        level: level,
                        isSelected: severity == level
                    ) {
                        withAnimation(.spring(response: 0.25)) {
                            severity = level
                        }
                        HapticFeedback.selection()
                    }
                }
            }

            // Severity labels
            HStack {
                Text(Strings.HealthLogging.severityMild)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Strings.HealthLogging.severityModerate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Strings.HealthLogging.severitySevere)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var bodyLocationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.HealthLogging.bodyLocation, icon: "figure.stand")

            Picker("", selection: $bodyLocation) {
                Text(Strings.HealthLogging.bodyUnspecified)
                    .tag(BodyLocation?.none)

                ForEach(BodyLocationGroup.allCases, id: \.self) { group in
                    Section(header: Text(group.label)) {
                        ForEach(group.locations, id: \.self) { location in
                            Text(location.label)
                                .tag(BodyLocation?.some(location))
                        }
                    }
                }
            }
            .pickerStyle(.menu)
            .tint(Color.otisAccent)
        }
    }

    @ViewBuilder
    private var startTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.HealthLogging.whenDidItStart, icon: "clock.fill")

            FlowLayout(spacing: 8) {
                ForEach(SymptomStartTime.allCases, id: \.self) { startTime in
                    SelectableChip(
                        text: startTime.label,
                        isSelected: startTimeDescription == startTime
                    ) {
                        withAnimation(.spring(response: 0.25)) {
                            startTimeDescription = startTime
                        }
                        HapticFeedback.selection()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.HealthLogging.duration, icon: "timer")

            FlowLayout(spacing: 8) {
                ForEach(SymptomDuration.allCases, id: \.self) { dur in
                    SelectableChip(
                        text: dur.label,
                        isSelected: duration == dur
                    ) {
                        withAnimation(.spring(response: 0.25)) {
                            duration = dur
                        }
                        HapticFeedback.selection()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var triggerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.HealthLogging.relatedTo, icon: "bolt.fill")

            FlowLayout(spacing: 8) {
                ForEach(SymptomTrigger.allCases, id: \.self) { trigger in
                    SelectableChip(
                        text: trigger.label,
                        isSelected: selectedTriggers.contains(trigger)
                    ) {
                        withAnimation(.spring(response: 0.25)) {
                            if selectedTriggers.contains(trigger) {
                                selectedTriggers.remove(trigger)
                            } else {
                                selectedTriggers.insert(trigger)
                            }
                        }
                        HapticFeedback.selection()
                    }
                }
            }

            TextField(Strings.HealthLogging.notesPlaceholder, text: $customTrigger)
                .textFieldStyle(.roundedBorder)
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.HealthLogging.notes, icon: "note.text")

            TextField(Strings.HealthLogging.notesPlaceholder, text: $note, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }

    @ViewBuilder
    private var urgencyWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.red)

            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.Symptoms.urgencyEmergency)
                    .font(.headline)
                    .foregroundStyle(.red)

                Text("This symptom may require immediate veterinary attention.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.otisAccent)

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private var relevantCategories: [SymptomCategory] {
        // Show common categories first, then condition-specific ones
        var categories: [SymptomCategory] = [.general, .mobility, .digestive]

        // Add condition-specific categories
        let conditions = profileStore.activeConditions
        for condition in conditions {
            let conditionSymptoms = condition.type.commonSymptoms
            for symptom in conditionSymptoms {
                if !categories.contains(symptom.category) {
                    categories.append(symptom.category)
                }
            }
        }

        return categories
    }

    private func symptomsFor(category: SymptomCategory) -> [SymptomType] {
        SymptomType.allCases
            .filter { $0.category == category }
            .sorted { $0.label < $1.label }
    }

    private func saveSymptom() {
        guard let symptom = selectedSymptom else { return }

        let log = HealthSymptomLog(
            symptomType: symptom,
            severity: severity,
            bodyLocation: bodyLocation,
            startTime: Date(),
            startTimeDescription: startTimeDescription,
            duration: duration,
            status: duration == .resolved ? .resolved : .active,
            triggers: Array(selectedTriggers),
            customTrigger: customTrigger.isEmpty ? nil : customTrigger,
            relatedConditionId: preselectedConditionId,
            note: note.isEmpty ? nil : note
        )

        onSave(log)
    }
}

// MARK: - Supporting Views

private struct SymptomChip: View {
    let symptom: SymptomType
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symptom.icon)
                    .font(.system(size: 12))

                Text(symptom.label)
                    .font(.subheadline)
            }
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.otisAccent : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.white))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SeverityButton: View {
    let level: Int
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text("\(level)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? severityColor : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.white))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isSelected ? Color.clear : Color.primary.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var severityColor: Color {
        switch level {
        case 1: return .green
        case 2: return .blue
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        default: return .gray
        }
    }
}

private struct SelectableChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.otisAccent : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.white))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : Color.primary.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SymptomLogSheet(
        onSave: { log in
            print("Saved: \(log.symptomType.label)")
        },
        onCancel: {}
    )
    .environmentObject(ProfileStore.shared)
}
