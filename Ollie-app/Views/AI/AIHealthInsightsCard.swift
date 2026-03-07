//
//  AIHealthInsightsCard.swift
//  Ollie-app
//
//  Card displaying AI-powered health and wellness insights.
//

import SwiftUI
import OtisShared

/// Card displaying AI-powered health and wellness insights.
struct AIHealthInsightsCard: View {
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var eventStore: EventStore

    @State private var insights: HealthInsightsResponse?
    @State private var isLoading = false
    @State private var error: String?

    @Environment(\.colorScheme) private var colorScheme

    /// Whether the card should be visible
    private var shouldShow: Bool {
        isLoading || insights != nil
    }

    var body: some View {
        AIInsightCardContainer(
            title: Strings.AINudges.healthInsight,
            tint: .blue,
            isLoading: isLoading,
            isVisible: shouldShow
        ) {
            if let insights = insights {
                insightsContent(insights)
            }
        }
        .task {
            await loadInsights()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func insightsContent(_ insights: HealthInsightsResponse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Wellness assessment
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text(insights.wellnessAssessment)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            // Insights list
            if !insights.insights.isEmpty {
                AIBulletList(items: insights.insights, bulletColor: .blue)
            }

            // Recommendations
            if let recommendations = insights.recommendations, !recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.AINudges.recommendations + ":")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)

                    ForEach(recommendations, id: \.self) { rec in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue.opacity(0.7))
                            Text(rec)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Data Loading

    private func loadInsights() async {
        guard let profile = profileStore.profile else { return }

        // Check if AI is available
        guard AI.isAvailable(for: profile) else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        let result = await AI.requestHealthInsights(
            profile: profile,
            events: eventStore.events
        )

        switch result {
        case .success(let response):
            self.insights = response
            self.error = nil

        case .shadow(let response):
            // In shadow mode, still display for the developer
            self.insights = response
            self.error = nil

        case .fallback(let reason):
            self.error = reason.description
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AIHealthInsightsCard_Previews: PreviewProvider {
    static var previews: some View {
        AIHealthInsightsCard()
            .environmentObject(ProfileStore())
            .environmentObject(EventStore())
            .padding()
    }
}
#endif
