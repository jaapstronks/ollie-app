//
//  InterventionLogSheet.swift
//  Otis-app
//
//  Sheet for adding or editing behavior interventions
//

import SwiftUI
import OtisShared

/// Sheet for adding a new behavior intervention
struct InterventionLogSheet: View {
    let category: BehaviorCategory
    var onSave: (BehaviorIntervention) -> Void
    var onCancel: () -> Void

    @State private var selectedTemplate: InterventionTemplate?
    @State private var customName: String = ""
    @State private var notes: String = ""
    @State private var showCustomInput = false

    @Environment(\.colorScheme) private var colorScheme

    private var suggestedTemplates: [InterventionTemplate] {
        InterventionTemplate.suggested(for: category)
    }

    private var otherTemplates: [InterventionTemplate] {
        InterventionTemplate.allCases.filter {
            $0 != .custom && !suggestedTemplates.contains($0)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection

                    // Suggested interventions for this category
                    suggestedSection

                    // Other interventions
                    otherSection

                    // Custom intervention
                    customSection

                    // Notes
                    notesSection
                }
                .padding()
            }
            .navigationTitle(OtisShared.Strings.BehaviorSupport.addIntervention)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        saveIntervention()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundStyle(.orange)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.orange.opacity(colorScheme == .dark ? 0.2 : 0.1))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(OtisShared.Strings.BehaviorSupport.selectIntervention)
                    .font(.headline)
                Text(category.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Suggested Section

    @ViewBuilder
    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(OtisShared.Strings.BehaviorSupport.suggestedInterventions)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ForEach(suggestedTemplates) { template in
                templateRow(template, isSuggested: true)
            }
        }
    }

    // MARK: - Other Section

    @ViewBuilder
    private var otherSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(OtisShared.Strings.BehaviorSupport.allInterventions)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ForEach(otherTemplates) { template in
                templateRow(template, isSuggested: false)
            }
        }
    }

    // MARK: - Template Row

    @ViewBuilder
    private func templateRow(_ template: InterventionTemplate, isSuggested: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedTemplate == template {
                    selectedTemplate = nil
                } else {
                    selectedTemplate = template
                    showCustomInput = false
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: selectedTemplate == template ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selectedTemplate == template ? .orange : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(template.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selectedTemplate == template ?
                          Color.orange.opacity(colorScheme == .dark ? 0.15 : 0.08) :
                          Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(selectedTemplate == template ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Custom Section

    @ViewBuilder
    private var customSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCustomInput.toggle()
                    if showCustomInput {
                        selectedTemplate = nil
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: showCustomInput ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(showCustomInput ? .orange : .secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(OtisShared.Strings.BehaviorSupport.interventionCustom)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text(OtisShared.Strings.BehaviorSupport.interventionCustomDesc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(showCustomInput ?
                              Color.orange.opacity(colorScheme == .dark ? 0.15 : 0.08) :
                              Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(showCustomInput ? Color.orange : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)

            if showCustomInput {
                TextField(OtisShared.Strings.BehaviorSupport.interventionPlaceholder, text: $customName)
                    .textFieldStyle(.roundedBorder)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Notes Section

    @ViewBuilder
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(OtisShared.Strings.BehaviorSupport.notesOptional)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            TextField(OtisShared.Strings.BehaviorSupport.interventionNotes, text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }

    // MARK: - Helpers

    private var canSave: Bool {
        selectedTemplate != nil || (!customName.isEmpty && showCustomInput)
    }

    private func saveIntervention() {
        let intervention: BehaviorIntervention

        if let template = selectedTemplate {
            intervention = template.toIntervention(
                for: category,
                notes: notes.isEmpty ? nil : notes
            )
        } else if showCustomInput && !customName.isEmpty {
            intervention = BehaviorIntervention(
                name: customName,
                category: category,
                notes: notes.isEmpty ? nil : notes
            )
        } else {
            return
        }

        onSave(intervention)
    }
}

// MARK: - Preview

#Preview {
    InterventionLogSheet(
        category: .reactivity,
        onSave: { _ in },
        onCancel: { }
    )
}
