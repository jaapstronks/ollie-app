//
//  HealthCheckInCard.swift
//  Ollie-app
//
//  A card that asks the user to rate a health category.
//  Shows context about recent symptoms, then asks for a 1-5 rating.
//  Follows the SentimentCheckInCard pattern.
//  Part of Brief 04: Health Logging
//

import SwiftUI
import OtisShared

struct HealthCheckInCard: View {
    let category: HealthCheckInCategory
    let puppyName: String
    let contextSummary: String
    let onSubmit: (Int) -> Void
    let onDismiss: () -> Void

    @State private var selectedRating: Int?

    private let ratingLabels = [
        (1, Strings.HealthLogging.ratingPoor),
        (2, Strings.HealthLogging.ratingNotGreat),
        (3, Strings.HealthLogging.ratingOkay),
        (4, Strings.HealthLogging.ratingGood),
        (5, Strings.HealthLogging.ratingGreat)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(.teal)
                Text(Strings.HealthLogging.healthCheckIn)
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
            Text(category.question(for: puppyName))
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
                        withAnimation(.spring(response: 0.25)) {
                            selectedRating = rating
                        }
                        HapticFeedback.selection()
                    }
                }
            }

            // Submit button
            if let rating = selectedRating {
                Button {
                    onSubmit(rating)
                } label: {
                    Text(Strings.HealthLogging.submit)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.teal)
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
            .background(isSelected ? Color.teal.opacity(0.15) : Color(.tertiarySystemBackground))
            .foregroundStyle(isSelected ? .teal : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.teal : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        HealthCheckInCard(
            category: .mobility,
            puppyName: "Luna",
            contextSummary: "Luna was rated \"okay\" 4 days ago. 2 related symptom(s) logged this week.",
            onSubmit: { rating in
                print("Submitted rating: \(rating)")
            },
            onDismiss: {
                print("Dismissed")
            }
        )
        .padding()

        HealthCheckInCard(
            category: .energy,
            puppyName: "Max",
            contextSummary: "",
            onSubmit: { _ in },
            onDismiss: {}
        )
        .padding()
    }
}
