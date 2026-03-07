//
//  AITrainingGuidanceCard.swift
//  Ollie-app
//
//  Card displaying AI-powered training suggestions.
//

import SwiftUI
import OtisShared

/// Card displaying AI-powered training suggestions.
struct AITrainingGuidanceCard: View {
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var eventStore: EventStore
    @EnvironmentObject var skillProgressStore: SkillProgressStore

    @State private var guidance: TrainingGuidanceResponse?
    @State private var isLoading = false
    @State private var error: String?

    @Environment(\.colorScheme) private var colorScheme

    /// Whether the card should be visible
    private var shouldShow: Bool {
        isLoading || guidance != nil
    }

    var body: some View {
        AIInsightCardContainer(
            title: Strings.AINudges.trainingSuggestion,
            tint: .purple,
            isLoading: isLoading,
            isVisible: shouldShow
        ) {
            if let guidance = guidance {
                guidanceContent(guidance)
            }
        }
        .task {
            await loadGuidance()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func guidanceContent(_ guidance: TrainingGuidanceResponse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Encouragement message (celebration/motivational)
            if let encouragement = guidance.encouragementMessage {
                Text(encouragement)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            // Suggested skill with rationale
            if let skillId = guidance.suggestedSkill {
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.caption)
                        .foregroundStyle(.purple)
                    Text("\(Strings.AINudges.focusOn): **\(skillDisplayName(skillId))**")
                        .font(.subheadline)
                }

                if let rationale = guidance.skillRationale {
                    Text(rationale)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Session advice
            if let advice = guidance.sessionAdvice {
                Text(advice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }

            // Pace warning
            if let paceWarning = guidance.paceGuidance {
                AIWarningRow(text: paceWarning)
                    .padding(.top, 2)
            }

            // Warm-up suggestions
            if let warmup = guidance.warmupSkills, !warmup.isEmpty {
                HStack(spacing: 6) {
                    Text(Strings.AINudges.warmUpWith + ":")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    ForEach(warmup, id: \.self) { skillId in
                        Text(skillDisplayName(skillId))
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.purple.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadGuidance() async {
        guard let profile = profileStore.profile else { return }

        // Check if AI is available
        guard AI.isAvailable(for: profile) else {
            return
        }

        // Check for cached result first
        if let cached = AI.cachedTrainingGuidance(profileId: profile.id) {
            self.guidance = cached
            return
        }

        isLoading = true
        defer { isLoading = false }

        let result = await AI.requestTrainingGuidance(
            profile: profile,
            events: eventStore.events
        )

        switch result {
        case .success(let response):
            self.guidance = response
            self.error = nil

        case .shadow(let response):
            // In shadow mode, still display for the developer
            self.guidance = response
            self.error = nil

        case .fallback(let reason):
            self.error = reason.description
        }
    }

    // MARK: - Helpers

    private func skillDisplayName(_ skillId: String) -> String {
        // Convert skill ID to display name
        skillId
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

// MARK: - Preview

#if DEBUG
struct AITrainingGuidanceCard_Previews: PreviewProvider {
    static var previews: some View {
        AITrainingGuidanceCard()
            .environmentObject(ProfileStore())
            .environmentObject(EventStore())
            .environmentObject(SkillProgressStore())
            .padding()
    }
}
#endif
