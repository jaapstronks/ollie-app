//
//  AISocializationGuidanceCard.swift
//  Ollie-app
//
//  Card displaying AI-powered socialization guidance.
//

import SwiftUI
import OtisShared

/// Card displaying AI-powered socialization guidance.
struct AISocializationGuidanceCard: View {
    @Environment(ProfileStore.self) var profileStore
    @Environment(EventStore.self) var eventStore

    @State private var guidance: SocializationGuidanceResponse?
    @State private var isLoading = false
    @State private var error: String?

    @Environment(\.colorScheme) private var colorScheme

    /// Whether the card should be visible
    private var shouldShow: Bool {
        isLoading || guidance != nil
    }

    var body: some View {
        AIInsightCardContainer(
            title: Strings.AINudges.socializationSuggestion,
            tint: .pink,
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
    private func guidanceContent(_ guidance: SocializationGuidanceResponse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Assessment
            Text(guidance.assessment)
                .font(.subheadline)
                .foregroundStyle(.primary)

            // Window urgency (if applicable)
            if let urgency = guidance.windowUrgency {
                AIWarningRow(text: urgency)
            }

            // Priority category
            if let priority = guidance.priorityCategory {
                AICategoryBadge(
                    label: Strings.AINudges.priorityCategory,
                    value: formatCategory(priority),
                    badgeColor: .pink
                )
            }

            // Exposure suggestion
            if let suggestion = guidance.exposureSuggestion {
                AISuggestionRow(text: suggestion)
                    .padding(.top, 2)
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
        if let cached = AI.cachedSocializationGuidance(profileId: profile.id) {
            self.guidance = cached
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Socialization guidance needs 14 days of history for exposure frequency
        // PERFORMANCE: Use async version to avoid blocking main thread
        let recentEvents = await eventStore.getEventsAsync(from: Date.daysAgo(14), to: Date())

        let result = await AI.requestSocializationGuidance(
            profile: profile,
            events: recentEvents
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

    private func formatCategory(_ category: String) -> String {
        // Handle Dutch category names and convert to readable format
        switch category.lowercased() {
        case "mensen": return "People"
        case "dieren": return "Animals"
        case "omgevingen": return "Environments"
        case "geluiden": return "Sounds"
        case "objecten": return "Objects"
        case "oppervlakken": return "Surfaces"
        case "handling": return "Handling"
        default: return category.capitalized
        }
    }
}

// MARK: - Preview

#Preview {
    AISocializationGuidanceCard()
        .environment(ProfileStore())
        .environment(EventStore())
        .padding()
}
