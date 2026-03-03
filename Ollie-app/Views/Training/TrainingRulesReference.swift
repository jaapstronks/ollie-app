//
//  TrainingRulesReference.swift
//  Otis-app
//
//  Reference view for all learned training rules
//

import SwiftUI

/// View showing all acknowledged training rules for reference
struct TrainingRulesReference: View {
    @ObservedObject var progressStore: TrainingProgressStore
    let allRules: [TrainingRule]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var seenRules: [TrainingRule] {
        progressStore.getSeenRules(from: allRules)
    }

    var body: some View {
        NavigationStack {
            Group {
                if seenRules.isEmpty {
                    emptyState
                } else {
                    rulesList
                }
            }
            .navigationTitle(Strings.Training.Rules.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.close) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Rules List

    private var rulesList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(Strings.Training.Rules.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(seenRules) { rule in
                        RuleCard(rule: rule)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "lightbulb")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text(Strings.Training.Rules.noRulesYet)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }
}

// MARK: - Inline Rules Link

/// Button to open the rules reference sheet
struct TrainingRulesLink: View {
    let seenRulesCount: Int
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            HapticFeedback.light()
            onTap()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.body)
                    .foregroundStyle(.orange)

                Text(Strings.Training.Progression.viewRules)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()

                if seenRulesCount > 0 {
                    Text("\(seenRulesCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.orange)
                        )
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

private let previewRules = [
    TrainingRule(id: "neverClickWithoutReward", triggeredByStep: "clicker.understand"),
    TrainingRule(id: "wordMustMatchMoment", triggeredByStep: "sit.addCue"),
    TrainingRule(id: "clickEndsExercise", triggeredByStep: "down.buildDuration")
]

#Preview("Reference View") {
    TrainingRulesReference(
        progressStore: TrainingProgressStore(),
        allRules: previewRules
    )
}

#Preview("Rules Link") {
    VStack {
        TrainingRulesLink(seenRulesCount: 3, onTap: {})
        TrainingRulesLink(seenRulesCount: 0, onTap: {})
    }
    .padding()
}
