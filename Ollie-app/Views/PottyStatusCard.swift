//
//  PottyStatusCard.swift
//  Ollie-app
//
//  V3: Hero widget with smart predictions and urgency levels

import SwiftUI

/// Prominent card showing potty status with smart predictions
struct PottyStatusCard: View {
    let prediction: PottyPrediction
    let puppyName: String

    var body: some View {
        // Hide during night hours (23:00 - 06:00) or if no data
        if isNightTime {
            EmptyView()
        } else {
            cardContent
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        HStack {
            // Emoji indicator
            Text(PredictionCalculations.emoji(for: prediction.urgency))
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 2) {
                // Main status text
                Text(PredictionCalculations.displayText(for: prediction, puppyName: puppyName))
                    .font(.headline)
                    .foregroundColor(textColor)

                // Subtitle with timing details
                if let subtitle = PredictionCalculations.subtitleText(for: prediction) {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Color indicator dot
            Circle()
                .fill(indicatorColor)
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
    }

    // MARK: - Computed Properties

    private var indicatorColor: Color {
        switch prediction.urgency {
        case .justWent:
            return .green
        case .normal:
            return .green
        case .attention:
            return .orange
        case .soon:
            return .orange
        case .overdue, .postAccident:
            return .red
        case .unknown:
            return .gray
        }
    }

    private var textColor: Color {
        switch prediction.urgency {
        case .justWent, .normal:
            return .primary
        case .attention:
            return .orange
        case .soon:
            return .orange
        case .overdue, .postAccident:
            return .red
        case .unknown:
            return .secondary
        }
    }

    private var backgroundColor: Color {
        switch prediction.urgency {
        case .justWent:
            return Color.green.opacity(0.15)
        case .normal:
            return Color.green.opacity(0.1)
        case .attention:
            return Color.orange.opacity(0.1)
        case .soon:
            return Color.orange.opacity(0.15)
        case .overdue, .postAccident:
            return Color.red.opacity(0.1)
        case .unknown:
            return Color(.secondarySystemBackground)
        }
    }

    private var isNightTime: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 23 || hour < 6
    }
}

// MARK: - Previews

#Preview("Just Went") {
    VStack {
        PottyStatusCard(
            prediction: PottyPrediction(
                urgency: .justWent,
                trigger: .none,
                expectedGapMinutes: 90,
                minutesSinceLast: 5,
                lastWasIndoor: false
            ),
            puppyName: "Ollie"
        )
        Spacer()
    }
    .padding()
}

#Preview("Normal") {
    VStack {
        PottyStatusCard(
            prediction: PottyPrediction(
                urgency: .normal(minutesRemaining: 45),
                trigger: .none,
                expectedGapMinutes: 90,
                minutesSinceLast: 45,
                lastWasIndoor: false
            ),
            puppyName: "Ollie"
        )
        Spacer()
    }
    .padding()
}

#Preview("Post-Meal Trigger") {
    VStack {
        PottyStatusCard(
            prediction: PottyPrediction(
                urgency: .attention(minutesRemaining: 15),
                trigger: .postMeal(minutesAgo: 20),
                expectedGapMinutes: 67,
                minutesSinceLast: 52,
                lastWasIndoor: false
            ),
            puppyName: "Ollie"
        )
        Spacer()
    }
    .padding()
}

#Preview("Soon") {
    VStack {
        PottyStatusCard(
            prediction: PottyPrediction(
                urgency: .soon(minutesRemaining: 5),
                trigger: .none,
                expectedGapMinutes: 90,
                minutesSinceLast: 85,
                lastWasIndoor: false
            ),
            puppyName: "Ollie"
        )
        Spacer()
    }
    .padding()
}

#Preview("Overdue") {
    VStack {
        PottyStatusCard(
            prediction: PottyPrediction(
                urgency: .overdue(minutesOverdue: 15),
                trigger: .none,
                expectedGapMinutes: 90,
                minutesSinceLast: 105,
                lastWasIndoor: false
            ),
            puppyName: "Ollie"
        )
        Spacer()
    }
    .padding()
}

#Preview("Post-Accident") {
    VStack {
        PottyStatusCard(
            prediction: PottyPrediction(
                urgency: .postAccident,
                trigger: .none,
                expectedGapMinutes: 0,
                minutesSinceLast: 5,
                lastWasIndoor: true
            ),
            puppyName: "Ollie"
        )
        Spacer()
    }
    .padding()
}

#Preview("Unknown") {
    VStack {
        PottyStatusCard(
            prediction: PottyPrediction(
                urgency: .unknown,
                trigger: .none,
                expectedGapMinutes: 90,
                minutesSinceLast: nil,
                lastWasIndoor: false
            ),
            puppyName: "Ollie"
        )
        Spacer()
    }
    .padding()
}
