//
//  PreparationSection.swift
//  Otis-app
//
//  Checkable preparation items for equipment and concepts before training unlocks
//

import SwiftUI

/// Section showing preparation items that must be completed before training
struct PreparationSection: View {
    @ObservedObject var progressStore: TrainingProgressStore
    let preparationItems: [PreparationItem]

    @State private var expandedConceptId: String?
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

    // MARK: - Concept Row (with expandable explanation)

    @ViewBuilder
    private func conceptRow(for item: PreparationItem) -> some View {
        let isCompleted = progressStore.isPreparationItemCompleted(item.id)
        let isExpanded = expandedConceptId == item.id

        VStack(alignment: .leading, spacing: 8) {
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

                // Label (tappable for info)
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.8)) {
                        if expandedConceptId == item.id {
                            expandedConceptId = nil
                        } else {
                            expandedConceptId = item.id
                        }
                    }
                } label: {
                    HStack {
                        Text(item.name)
                            .font(.subheadline)
                            .foregroundStyle(isCompleted ? .secondary : .primary)
                            .strikethrough(isCompleted)

                        Spacer()

                        if item.explanation != nil {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Strings.Training.Preparation.conceptExpandAccessibility(name: item.name, isExpanded: isExpanded))
            }

            // Expanded explanation
            if isExpanded, let explanation = item.explanation {
                Text(explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 36)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
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
