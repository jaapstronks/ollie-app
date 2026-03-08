//
//  AIPottyAnalysisCard.swift
//  Ollie-app
//
//  Card displaying AI-powered potty training insights.
//

import SwiftUI
import OtisShared

/// Card displaying AI-powered potty training analysis.
struct AIPottyAnalysisCard: View {
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var eventStore: EventStore

    /// Optional pre-calculated stats to pass to AI
    var prediction: PottyPrediction?
    var gapStats: GapStats?

    @State private var analysis: PottyAnalysisResponse?
    @State private var isLoading = false
    @State private var error: String?

    @Environment(\.colorScheme) private var colorScheme

    /// Whether the card should be visible
    private var shouldShow: Bool {
        isLoading || analysis != nil
    }

    var body: some View {
        AIInsightCardContainer(
            title: Strings.AINudges.pottySuggestion,
            tint: .green,
            isLoading: isLoading,
            isVisible: shouldShow
        ) {
            if let analysis = analysis {
                analysisContent(analysis)
            }
        }
        .task {
            await loadAnalysis()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func analysisContent(_ analysis: PottyAnalysisResponse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Progress assessment
            Text(analysis.progressAssessment)
                .font(.subheadline)
                .foregroundStyle(.primary)

            // Key insight
            if let insight = analysis.keyInsight {
                Text(insight)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Suggestion
            if let suggestion = analysis.suggestion {
                AISuggestionRow(text: suggestion)
                    .padding(.top, 2)
            }

            // Risk factors
            if let risks = analysis.riskFactors, !risks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.AINudges.riskFactors + ":")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)

                    AIBulletList(
                        items: risks.map { formatRiskFactor($0) },
                        bulletColor: .orange
                    )
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Data Loading

    private func loadAnalysis() async {
        guard let profile = profileStore.profile else { return }

        // Check if AI is available
        guard AI.isAvailable(for: profile) else {
            return
        }

        // Check for cached result first
        if let cached = AI.cachedPottyAnalysis(profileId: profile.id) {
            self.analysis = cached
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Potty analysis needs 14 days of history for gap patterns and streaks
        let recentEvents = eventStore.getEvents(from: Date.daysAgo(14), to: Date())

        let result = await AI.requestPottyAnalysis(
            profile: profile,
            events: recentEvents,
            prediction: prediction,
            gapStats: gapStats
        )

        switch result {
        case .success(let response):
            self.analysis = response
            self.error = nil

        case .shadow(let response):
            // In shadow mode, still display for the developer
            self.analysis = response
            self.error = nil

        case .fallback(let reason):
            self.error = reason.description
        }
    }

    // MARK: - Helpers

    private func formatRiskFactor(_ risk: String) -> String {
        // Convert snake_case to readable format
        risk.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Preview

#if DEBUG
struct AIPottyAnalysisCard_Previews: PreviewProvider {
    static var previews: some View {
        AIPottyAnalysisCard()
            .environmentObject(ProfileStore())
            .environmentObject(EventStore())
            .padding()
    }
}
#endif
