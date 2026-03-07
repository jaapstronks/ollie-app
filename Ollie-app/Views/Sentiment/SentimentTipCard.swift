//
//  SentimentTipCard.swift
//  Ollie-app
//
//  Displays a rotating tip for an area where the user is struggling.
//  Links to detailed info sheets when available.
//

import SwiftUI

struct SentimentTipCard: View {
    let category: SentimentCategory
    let tip: SentimentTip
    let rootCauseMessage: String?
    let onInfoSheet: ((InfoSheetType) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with category
            HStack {
                Image(systemName: category.iconName)
                    .foregroundStyle(categoryColor)
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(categoryColor)
                Spacer()
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
            }

            // Root cause message if applicable
            if let rootCause = rootCauseMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(rootCause)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Tip content
            VStack(alignment: .leading, spacing: 6) {
                Text(tip.title)
                    .font(.headline)

                Text(tip.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Action button if available
            if let actionLabel = tip.actionLabel, let sheetType = tip.infoSheetType {
                Button {
                    onInfoSheet?(sheetType)
                } label: {
                    HStack {
                        Text(actionLabel)
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(categoryColor)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var categoryColor: Color {
        switch category {
        case .pottyTraining: return .green
        case .benchTraining: return .purple
        case .sleeping: return .indigo
        case .walks: return .blue
        case .skillsTraining: return .orange
        case .nipping: return .red
        case .chewing: return .pink
        case .barking: return .yellow
        case .separationAnxiety: return .teal
        default: return .gray
        }
    }
}

// MARK: - Sentiment Tips Container

/// Container that shows tips for all struggling areas.
struct SentimentTipsContainer: View {
    @ObservedObject var sentimentStore: SentimentStore
    let onInfoSheet: ((InfoSheetType) -> Void)?

    var body: some View {
        let strugglingCategories = sentimentStore.strugglingCategories

        if !strugglingCategories.isEmpty {
            // Identify primary focus
            let (primaryCategory, rootCauseMessage) = SentimentTipProvider.identifyPrimaryFocus(
                strugglingCategories: strugglingCategories,
                checkIns: sentimentStore.checkIns
            ) ?? (strugglingCategories.first!, nil)

            // Get tip for primary category
            if let tip = SentimentTipProvider.tipOfTheDay(for: primaryCategory) {
                SentimentTipCard(
                    category: primaryCategory,
                    tip: tip,
                    rootCauseMessage: rootCauseMessage,
                    onInfoSheet: onInfoSheet
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SentimentTipCard(
            category: .benchTraining,
            tip: SentimentTip(
                title: "The 1-minute rule",
                body: "Puppies will settle if you can wait through about 1 minute of whining. Sit nearby so they know you're there.",
                actionLabel: "Learn more",
                infoSheetType: .crateTraining
            ),
            rootCauseMessage: nil,
            onInfoSheet: nil
        )

        SentimentTipCard(
            category: .nipping,
            tip: SentimentTip(
                title: "Sleep prevents biting",
                body: "Most nipping happens when puppies are overtired. A well-rested pup bites much less.",
                actionLabel: nil,
                infoSheetType: nil
            ),
            rootCauseMessage: "Overtired puppies bite more. Getting enough sleep will reduce nipping.",
            onInfoSheet: nil
        )
    }
    .padding()
}
