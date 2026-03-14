//
//  BehaviorLogSheet.swift
//  Otis-app
//
//  Sheet for logging behavior incidents with detailed tracking
//

import SwiftUI
import OtisShared

/// Sheet for logging behavior incidents
struct BehaviorLogSheet: View {
    let onSave: (BehaviorCategory, String?, BehaviorIntensity?, BehaviorOutcome?, BehaviorContext?, Date, String?) -> Void
    let onCancel: () -> Void

    @State private var selectedCategory: BehaviorCategory?
    @State private var selectedTrigger: String?
    @State private var customTrigger: String = ""
    @State private var selectedIntensity: BehaviorIntensity?
    @State private var selectedOutcome: BehaviorOutcome?
    @State private var selectedContext: BehaviorContext?
    @State private var eventTime: Date = Date()
    @State private var note: String = ""

    @Environment(\.colorScheme) private var colorScheme

    private var canSave: Bool {
        selectedCategory != nil
    }

    private var effectiveTrigger: String? {
        if let trigger = selectedTrigger {
            return trigger
        }
        return customTrigger.isEmpty ? nil : customTrigger
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Category Selection
                    categorySection

                    if selectedCategory != nil {
                        // Trigger Selection
                        triggerSection

                        // Intensity Selection
                        intensitySection

                        // Context Selection
                        contextSection

                        // Outcome Selection
                        outcomeSection

                        // Time Adjustment
                        timeSection

                        // Notes
                        notesSection
                    }
                }
                .padding()
            }
            .navigationTitle(OtisShared.Strings.Behavior.title)
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
                        guard let category = selectedCategory else { return }
                        onSave(
                            category,
                            effectiveTrigger,
                            selectedIntensity,
                            selectedOutcome,
                            selectedContext,
                            eventTime,
                            note.isEmpty ? nil : note
                        )
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
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(OtisShared.Strings.Behavior.whatHappened, icon: "exclamationmark.triangle.fill")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(BehaviorCategory.allCases) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                            selectedTrigger = nil
                            customTrigger = ""
                        }
                        HapticFeedback.selection()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var triggerSection: some View {
        if let category = selectedCategory {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(OtisShared.Strings.Behavior.trigger, icon: "bolt.fill")

                FlowLayout(spacing: 8) {
                    ForEach(category.commonTriggers, id: \.self) { trigger in
                        TriggerChip(
                            text: trigger,
                            isSelected: selectedTrigger == trigger
                        ) {
                            withAnimation(.spring(response: 0.25)) {
                                selectedTrigger = selectedTrigger == trigger ? nil : trigger
                                if selectedTrigger != nil {
                                    customTrigger = ""
                                }
                            }
                            HapticFeedback.selection()
                        }
                    }
                }

                TextField(OtisShared.Strings.Behavior.triggerPlaceholder, text: $customTrigger)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: customTrigger) { _, newValue in
                        if !newValue.isEmpty {
                            selectedTrigger = nil
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(OtisShared.Strings.Behavior.howIntense, icon: "chart.bar.fill")

            HStack(spacing: 8) {
                ForEach(BehaviorIntensity.allCases) { intensity in
                    IntensityButton(
                        intensity: intensity,
                        isSelected: selectedIntensity == intensity
                    ) {
                        withAnimation(.spring(response: 0.25)) {
                            selectedIntensity = selectedIntensity == intensity ? nil : intensity
                        }
                        HapticFeedback.selection()
                    }
                }
            }

            if let intensity = selectedIntensity {
                Text(intensity.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(OtisShared.Strings.Behavior.whereDidItHappen, icon: "location.fill")

            FlowLayout(spacing: 8) {
                ForEach(BehaviorContext.allCases) { context in
                    ContextChip(
                        context: context,
                        isSelected: selectedContext == context
                    ) {
                        withAnimation(.spring(response: 0.25)) {
                            selectedContext = selectedContext == context ? nil : context
                        }
                        HapticFeedback.selection()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var outcomeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(OtisShared.Strings.Behavior.whatHappenedAfter, icon: "arrow.right.circle.fill")

            FlowLayout(spacing: 8) {
                ForEach(BehaviorOutcome.allCases) { outcome in
                    OutcomeChip(
                        outcome: outcome,
                        isSelected: selectedOutcome == outcome
                    ) {
                        withAnimation(.spring(response: 0.25)) {
                            selectedOutcome = selectedOutcome == outcome ? nil : outcome
                        }
                        HapticFeedback.selection()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.Meals.time, icon: "clock.fill")

            DatePicker(
                "",
                selection: $eventTime,
                in: ...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(OtisShared.Strings.Behavior.notes, icon: "note.text")

            TextField(OtisShared.Strings.Behavior.notesPlaceholder, text: $note, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
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
}

// MARK: - Supporting Views

private struct CategoryButton: View {
    let category: BehaviorCategory
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: category.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : Color.otisAccent)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.label)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? .white : .primary)

                    Text(category.description)
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.otisAccent : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct TriggerChip: View {
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

private struct IntensityButton: View {
    let intensity: BehaviorIntensity
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(intensity.rawValue)")
                    .font(.headline)
                    .fontWeight(.bold)

                Text(intensity.label)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? intensityColor : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var intensityColor: Color {
        switch intensity {
        case .mild: return .green
        case .low: return .blue
        case .moderate: return .orange
        case .high: return .red
        case .severe: return .purple
        }
    }
}

private struct ContextChip: View {
    let context: BehaviorContext
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: context.icon)
                    .font(.system(size: 12))

                Text(context.label)
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

private struct OutcomeChip: View {
    let outcome: BehaviorOutcome
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(outcome.label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? outcomeColor : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.white))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : Color.primary.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var outcomeColor: Color {
        switch outcome {
        case .redirected, .selfResolved: return .green
        case .managed: return .orange
        case .escalated, .removed: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    BehaviorLogSheet(
        onSave: { category, trigger, intensity, outcome, context, time, note in
            print("Saved: \(category.label)")
        },
        onCancel: {}
    )
}
