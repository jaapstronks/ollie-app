//
//  AITrainingGuidanceCard.swift
//  Ollie-app
//
//  Example card showing AI-powered training guidance.
//  Demonstrates usage of the new modular AI system.
//

import SwiftUI
import OtisShared

/// Card displaying AI-powered training suggestions.
struct AITrainingGuidanceCard: View {
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var eventStore: EventStore
    @EnvironmentObject var skillProgressStore: SkillProgressStore
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var guidance: TrainingGuidanceResponse?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView

            if isLoading {
                loadingView
            } else if let guidance = guidance {
                guidanceContent(guidance)
            } else if let error = error {
                errorView(error)
            } else {
                placeholderView
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            await loadGuidance()
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(.purple)
            Text("Training Suggestion")
                .font(.headline)
            Spacer()
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
    }

    @ViewBuilder
    private func guidanceContent(_ guidance: TrainingGuidanceResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Suggested skill
            if let skillId = guidance.suggestedSkill {
                HStack {
                    Image(systemName: "target")
                        .foregroundStyle(.blue)
                    Text("Focus on: **\(skillDisplayName(skillId))**")
                }
            }

            // Rationale
            if let rationale = guidance.skillRationale {
                Text(rationale)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Session advice
            if let advice = guidance.sessionAdvice {
                Text(advice)
                    .font(.callout)
                    .padding(.top, 4)
            }

            // Pace warning
            if let paceWarning = guidance.paceGuidance {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(paceWarning)
                        .font(.caption)
                }
                .padding(.top, 4)
            }

            // Warm-up suggestions
            if let warmup = guidance.warmupSkills, !warmup.isEmpty {
                HStack {
                    Text("Warm up with:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(warmup, id: \.self) { skillId in
                        Text(skillDisplayName(skillId))
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func errorView(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.red)
            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var placeholderView: some View {
        Text("AI training suggestions will appear here")
            .font(.subheadline)
            .foregroundStyle(.secondary)
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
            // In shadow mode, we can still display for debugging
            #if DEBUG
            self.guidance = response
            #endif
            self.error = nil

        case .fallback(let reason):
            self.error = reason.description
        }
    }

    // MARK: - Helpers

    private func skillDisplayName(_ skillId: String) -> String {
        // Convert skill ID to display name
        // e.g., "sit" -> "Sit", "down_stay" -> "Down Stay"
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
            .environmentObject(SubscriptionManager.shared)
            .padding()
    }
}
#endif
