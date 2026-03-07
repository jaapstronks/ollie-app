//
//  SentimentOnboardingSheet.swift
//  Ollie-app
//
//  Initial onboarding flow that asks about all core categories at once.
//  Shown on first launch or when user has no sentiment data.
//

import SwiftUI
import OtisShared

struct SentimentOnboardingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var sentimentStore: SentimentStore

    let profile: PuppyProfile
    let events: [PuppyEvent]

    @State private var ratings: [SentimentCategory: Int] = [:]
    @State private var currentIndex = 0
    @State private var showThankYou = false

    private let categories = SentimentCategory.coreCategories

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showThankYou {
                    thankYouView
                } else {
                    questionFlow
                }
            }
            .navigationTitle(showThankYou ? "" : Strings.Sentiment.onboardingTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !showThankYou {
                        Button(Strings.Sentiment.skipForNow) {
                            dismiss()
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Question Flow

    @ViewBuilder
    private var questionFlow: some View {
        // Progress indicator
        ProgressView(value: Double(currentIndex + 1), total: Double(categories.count))
            .tint(.purple)
            .padding(.horizontal)

        Spacer()

        // Current question
        if currentIndex < categories.count {
            let category = categories[currentIndex]
            let context = SentimentContextBuilder.buildContext(
                for: category,
                events: events,
                profile: profile
            )

            QuestionView(
                category: category,
                contextSummary: context,
                selectedRating: ratings[category],
                onSelect: { rating in
                    ratings[category] = rating
                }
            )
            .padding()
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(category)
        }

        Spacer()

        // Navigation buttons
        HStack(spacing: 16) {
            if currentIndex > 0 {
                Button {
                    withAnimation {
                        currentIndex -= 1
                    }
                } label: {
                    Text(Strings.Common.back)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
            }

            Button {
                if currentIndex < categories.count - 1 {
                    withAnimation {
                        currentIndex += 1
                    }
                } else {
                    submitAll()
                }
            } label: {
                Text(currentIndex < categories.count - 1 ? Strings.Common.next : Strings.Common.done)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(ratings[categories[currentIndex]] == nil)
        }
        .padding()
    }

    // MARK: - Thank You View

    @ViewBuilder
    private var thankYouView: some View {
        Spacer()

        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text(Strings.Sentiment.thankYouTitle)
                .font(.title2)
                .fontWeight(.semibold)

            Text(Strings.Sentiment.thankYouSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }

        Spacer()

        Button {
            dismiss()
        } label: {
            Text(Strings.Common.done)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.purple)
        .padding()
    }

    // MARK: - Submit

    private func submitAll() {
        for (category, rating) in ratings {
            let context = SentimentContextBuilder.buildContext(
                for: category,
                events: events,
                profile: profile
            )
            sentimentStore.recordCheckIn(
                category: category,
                score: rating,
                contextSummary: context
            )
        }
        withAnimation {
            showThankYou = true
        }
    }
}

// MARK: - Question View

private struct QuestionView: View {
    let category: SentimentCategory
    let contextSummary: String
    let selectedRating: Int?
    let onSelect: (Int) -> Void

    /// Localized rating options with score and label
    private var ratingOptions: [(Int, String)] {
        [
            (1, Strings.Sentiment.ratingStruggling),
            (2, Strings.Sentiment.ratingDifficult),
            (3, Strings.Sentiment.ratingOkay),
            (4, Strings.Sentiment.ratingGood),
            (5, Strings.Sentiment.ratingGreat)
        ]
    }

    /// Optional hint text for categories that need explanation
    private var categoryHint: String? {
        switch category {
        case .skillsTraining:
            return Strings.Sentiment.skillsTrainingHint
        default:
            return nil
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Category icon
            Image(systemName: iconName(for: category))
                .font(.system(size: 48))
                .foregroundStyle(.purple)

            // Context (from logged data)
            if !contextSummary.isEmpty && contextSummary != Strings.Sentiment.noDataYet {
                Text(contextSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Question
            VStack(spacing: 8) {
                Text(category.questionText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                // Category hint (e.g., explaining skills training)
                if let hint = categoryHint {
                    Text(hint)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            // Rating options
            HStack(spacing: 12) {
                ForEach(ratingOptions, id: \.0) { rating, label in
                    RatingOptionButton(
                        rating: rating,
                        label: label,
                        isSelected: selectedRating == rating
                    ) {
                        onSelect(rating)
                    }
                }
            }
        }
    }

    private func iconName(for category: SentimentCategory) -> String {
        switch category {
        case .pottyTraining: return "drop.fill"
        case .benchTraining: return "house.lodge.fill"
        case .sleeping: return "moon.zzz.fill"
        case .walks: return "figure.walk"
        case .skillsTraining: return "star.fill"
        case .nipping: return "mouth.fill"
        case .leashBehavior: return "link"
        case .jumping: return "arrow.up.circle.fill"
        case .resourceGuarding: return "shield.fill"
        case .chewing: return "scissors"
        case .barking: return "speaker.wave.3.fill"
        case .separationAnxiety: return "person.and.arrow.left.and.arrow.right"
        case .carTravel: return "car.fill"
        case .handlingTolerance: return "hand.raised.fill"
        }
    }
}

// MARK: - Rating Option Button

private struct RatingOptionButton: View {
    let rating: Int
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text("\(rating)")
                    .font(.title)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.purple.opacity(0.15) : Color(.tertiarySystemBackground))
            .foregroundStyle(isSelected ? .purple : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    // Preview requires a real SentimentStore and profile which are MainActor-isolated
    Text("Preview requires app context")
        .foregroundStyle(.secondary)
}
