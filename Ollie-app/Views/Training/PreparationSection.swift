//
//  PreparationSection.swift
//  Otis-app
//
//  Checkable preparation items for equipment and concepts before training unlocks
//

import SwiftUI

/// Concept type for identifying which sheet to show
enum ConceptType: Identifiable {
    case operant
    case classical
    case timing

    var id: String {
        switch self {
        case .operant: return "operant"
        case .classical: return "classical"
        case .timing: return "timing"
        }
    }
}

/// Section showing preparation items that must be completed before training
struct PreparationSection: View {
    @ObservedObject var progressStore: TrainingProgressStore
    let preparationItems: [PreparationItem]

    @State private var sheetToShow: ConceptType?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var equipmentItems: [PreparationItem] {
        preparationItems.filter { $0.type == .equipment }
    }

    private var conceptItems: [PreparationItem] {
        preparationItems.filter { $0.type == .concept }
    }

    private var completedCount: Int {
        preparationItems.filter { progressStore.isPreparationItemCompleted($0.id) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "checklist")
                    .font(.title2)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Training.Preparation.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(Strings.Training.Preparation.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Progress badge
                Text(Strings.Training.Preparation.itemsCompleted(completedCount, total: preparationItems.count))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                    )
            }

            // Equipment section
            if !equipmentItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.Training.Preparation.equipmentTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)

                    ForEach(equipmentItems) { item in
                        checkableRow(for: item)
                    }
                }
            }

            // Concepts section
            if !conceptItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.Training.Preparation.conceptsTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)

                    ForEach(conceptItems) { item in
                        conceptRow(for: item)
                    }
                }
            }
        }
        .padding()
        .glassStatusCard(tintColor: .orange.opacity(0.3))
    }

    // MARK: - Checkable Row

    @ViewBuilder
    private func checkableRow(for item: PreparationItem) -> some View {
        let isCompleted = progressStore.isPreparationItemCompleted(item.id)

        Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                progressStore.togglePreparationItem(item.id)
            }
            HapticFeedback.light()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? Color.otisSuccess : .secondary)

                Text(item.name)
                    .font(.subheadline)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Strings.Training.Preparation.itemToggleAccessibility(name: item.name, isCompleted: isCompleted))
    }

    // MARK: - Concept Row (with sheet presentation)

    @ViewBuilder
    private func conceptRow(for item: PreparationItem) -> some View {
        let isCompleted = progressStore.isPreparationItemCompleted(item.id)

        HStack(spacing: 12) {
            // Checkbox
            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                    progressStore.togglePreparationItem(item.id)
                }
                HapticFeedback.light()
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? Color.otisSuccess : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Strings.Training.Preparation.itemToggleAccessibility(name: item.name, isCompleted: isCompleted))

            // Label
            Text(item.name)
                .font(.subheadline)
                .foregroundStyle(isCompleted ? .secondary : .primary)
                .strikethrough(isCompleted)

            Spacer()

            // Learn more button (opens sheet)
            if item.explanation != nil {
                Button {
                    HapticFeedback.light()
                    sheetToShow = conceptType(for: item.id)
                } label: {
                    HStack(spacing: 4) {
                        Text(Strings.Training.Preparation.learnMore)
                            .font(.caption)
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.otisAccent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private func conceptType(for itemId: String) -> ConceptType? {
        switch itemId {
        case "understandOperant": return .operant
        case "understandClassical": return .classical
        case "understandTiming": return .timing
        default: return nil
        }
    }

    private func handleConceptAcknowledge() {
        // Mark the concept as completed when user acknowledges
        if let concept = sheetToShow {
            switch concept {
            case .operant:
                if !progressStore.isPreparationItemCompleted("understandOperant") {
                    progressStore.togglePreparationItem("understandOperant")
                }
            case .classical:
                if !progressStore.isPreparationItemCompleted("understandClassical") {
                    progressStore.togglePreparationItem("understandClassical")
                }
            case .timing:
                if !progressStore.isPreparationItemCompleted("understandTiming") {
                    progressStore.togglePreparationItem("understandTiming")
                }
            }
        }
    }
}

// MARK: - Sheet Extension

extension PreparationSection {
    @ViewBuilder
    func withConceptSheets() -> some View {
        self
            .sheet(item: $sheetToShow) { conceptType in
                switch conceptType {
                case .operant:
                    OperantConditioningSheet(
                        onAcknowledge: handleConceptAcknowledge,
                        onDismiss: { sheetToShow = nil }
                    )
                    .presentationDetents([.large])
                case .classical:
                    ClassicalConditioningSheet(
                        onAcknowledge: handleConceptAcknowledge,
                        onDismiss: { sheetToShow = nil }
                    )
                    .presentationDetents([.large])
                case .timing:
                    ClickTimingSheet(
                        onAcknowledge: handleConceptAcknowledge,
                        onDismiss: { sheetToShow = nil }
                    )
                    .presentationDetents([.large])
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        PreparationSection(
            progressStore: TrainingProgressStore(),
            preparationItems: [
                PreparationItem(id: "clicker", type: .equipment),
                PreparationItem(id: "treats", type: .equipment),
                PreparationItem(id: "quietSpace", type: .equipment),
                PreparationItem(id: "understandOperant", type: .concept),
                PreparationItem(id: "understandClassical", type: .concept),
                PreparationItem(id: "understandTiming", type: .concept)
            ]
        )
        .padding()
    }
}
