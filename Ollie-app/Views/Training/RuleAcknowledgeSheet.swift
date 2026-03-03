//
//  RuleAcknowledgeSheet.swift
//  Otis-app
//
//  Modal for acknowledging new training rules
//

import SwiftUI

/// Modal sheet for acknowledging a training rule before proceeding
struct RuleAcknowledgeSheet: View {
    let rule: TrainingRule
    let onAcknowledge: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @AccessibilityFocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.orange)
            }
            .accessibilityHidden(true)

            // Title
            Text(rule.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .accessibilityFocused($isTitleFocused)
                .accessibilityAddTraits(.isHeader)

            // Description
            Text(rule.ruleDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            // Got it button
            Button {
                HapticFeedback.medium()
                onAcknowledge()
            } label: {
                Text(Strings.Training.Rules.gotIt)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
            .accessibilityHint(Strings.Training.Rules.acknowledgeHint)
        }
        .interactiveDismissDisabled()
        .onAppear {
            // Move VoiceOver focus to the title when sheet appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTitleFocused = true
            }
        }
    }
}

// MARK: - Rule Card (for reference view)

/// Card displaying a rule in the reference list
struct RuleCard: View {
    let rule: TrainingRule
    @State private var isExpanded = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticFeedback.light()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.body)
                        .foregroundStyle(.orange)

                    Text(rule.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Strings.Training.Rules.ruleCardAccessibility(title: rule.title, isExpanded: isExpanded))

            if isExpanded {
                Text(rule.ruleDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        )
    }
}

// MARK: - Preview

private let previewRule = TrainingRule(
    id: "neverClickWithoutReward",
    triggeredByStep: "clicker.understand"
)

#Preview("Acknowledge Sheet") {
    RuleAcknowledgeSheet(
        rule: previewRule,
        onAcknowledge: {}
    )
}

#Preview("Rule Card") {
    VStack(spacing: 12) {
        RuleCard(rule: previewRule)
        RuleCard(rule: TrainingRule(id: "wordMustMatchMoment", triggeredByStep: "sit.addCue"))
    }
    .padding()
}
