//
//  AIRecommendationCard.swift
//  Otis-app
//
//  Card displaying AI logging recommendations with action buttons.
//

import SwiftUI

struct AIRecommendationCard: View {
    let recommendation: AILoggingCategoryRecommendation
    let onKeepCurrent: () -> Void
    let onReduceReminders: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.AINudges.recommendationTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(Strings.AINudges.recommendationBody(category: localizedCategoryName(recommendation.category)))
                .font(.subheadline)
                .foregroundStyle(.primary)

            HStack(spacing: 10) {
                Button(Strings.AINudges.keepCurrent, action: onKeepCurrent)
                    .buttonStyle(.glassPillCompact(tint: .custom(.otisMuted)))

                Button(Strings.AINudges.reduceReminders, action: onReduceReminders)
                    .buttonStyle(.glassPillCompact(tint: .custom(.otisAccent)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground).opacity(0.6))
        .cornerRadius(LayoutConstants.cornerRadiusM)
    }

    private func localizedCategoryName(_ category: AILoggingCategory) -> String {
        switch category {
        case .potty: return Strings.AINudges.categoryPotty
        case .walk: return Strings.AINudges.categoryWalk
        case .meal: return Strings.AINudges.categoryMeal
        case .training: return Strings.AINudges.categoryTraining
        case .socialization: return Strings.AINudges.categorySocialization
        }
    }
}
