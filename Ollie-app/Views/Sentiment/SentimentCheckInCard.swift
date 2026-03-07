//
//  SentimentCheckInCard.swift
//  Ollie-app
//
//  A card that asks the user to rate how a particular area is going.
//  Shows context about their logged activity, then asks for a 1-5 rating.
//

import SwiftUI

struct SentimentCheckInCard: View {
    let category: SentimentCategory
    let contextSummary: String
    let onSubmit: (Int) -> Void
    let onDismiss: () -> Void

    @State private var selectedRating: Int?

    private let ratingLabels = [
        (1, Strings.Sentiment.ratingStruggling),
        (2, Strings.Sentiment.ratingDifficult),
        (3, Strings.Sentiment.ratingOkay),
        (4, Strings.Sentiment.ratingGood),
        (5, Strings.Sentiment.ratingGreat)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .foregroundStyle(.purple)
                Text(Strings.Sentiment.checkInTitle)
                    .font(.headline)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
            }

            // Context summary
            if !contextSummary.isEmpty {
                Text(contextSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Question
            Text(category.questionText)
                .font(.body)
                .fontWeight(.medium)

            // Rating buttons
            HStack(spacing: 8) {
                ForEach(ratingLabels, id: \.0) { rating, label in
                    RatingButton(
                        rating: rating,
                        label: label,
                        isSelected: selectedRating == rating
                    ) {
                        selectedRating = rating
                    }
                }
            }

            // Submit button
            if let rating = selectedRating {
                Button {
                    onSubmit(rating)
                } label: {
                    Text(Strings.Sentiment.submit)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Rating Button

private struct RatingButton: View {
    let rating: Int
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(rating)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.purple.opacity(0.15) : Color(.tertiarySystemBackground))
            .foregroundStyle(isSelected ? .purple : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SentimentCheckInCard(
            category: .pottyTraining,
            contextSummary: "78% outdoor success this week, 2 accidents today.",
            onSubmit: { rating in
                print("Submitted rating: \(rating)")
            },
            onDismiss: {
                print("Dismissed")
            }
        )
        .padding()

        SentimentCheckInCard(
            category: .benchTraining,
            contextSummary: "",
            onSubmit: { _ in },
            onDismiss: {}
        )
        .padding()
    }
}
