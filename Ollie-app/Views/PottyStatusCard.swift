//
//  PottyStatusCard.swift
//  Ollie-app
//
//  V3: Hero widget with smart predictions and urgency levels
//  Uses liquid glass design for iOS 26 aesthetic

import SwiftUI

/// Prominent card showing potty status with smart predictions
/// Uses liquid glass design with semantic tinting based on urgency
struct PottyStatusCard: View {
    let prediction: PottyPrediction
    let puppyName: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // Hide during night hours (23:00 - 06:00) or if no data
        if isNightTime {
            EmptyView()
        } else {
            cardContent
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        StatusCardHeader(
            iconName: PredictionCalculations.iconName(for: prediction.urgency),
            iconColor: PredictionCalculations.iconColor(for: prediction.urgency),
            tintColor: indicatorColor,
            title: PredictionCalculations.displayText(for: prediction, puppyName: puppyName),
            titleColor: textColor,
            subtitle: PredictionCalculations.subtitleText(for: prediction),
            statusLabel: urgencyLabel
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassStatusCard(tintColor: indicatorColor, cornerRadius: 18)
        .shadow(color: shadowColor, radius: 10, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.PottyStatus.accessibility)
        .accessibilityValue("\(PredictionCalculations.displayText(for: prediction, puppyName: puppyName)). \(urgencyLabel)")
        .accessibilityHint(Strings.PottyStatus.predictionHint(name: puppyName))
    }

    // MARK: - Computed Properties

    private var indicatorColor: Color {
        PredictionCalculations.iconColor(for: prediction.urgency)
    }

    private var textColor: Color {
        switch prediction.urgency {
        case .justWent, .normal:
            return .primary
        case .attention:
            return Color.ollieAccent
        case .soon:
            return Color.ollieWarning
        case .overdue, .postAccident:
            return Color.ollieDanger
        case .unknown:
            return .secondary
        }
    }

    private var urgencyLabel: String {
        switch prediction.urgency {
        case .justWent:
            return Strings.PottyStatus.justWent
        case .normal:
            return Strings.PottyStatus.normal
        case .attention:
            return Strings.PottyStatus.attention
        case .soon:
            return Strings.PottyStatus.soonTime
        case .overdue:
            return Strings.PottyStatus.now
        case .postAccident:
            return Strings.PottyStatus.accident
        case .unknown:
            return Strings.PottyStatus.unknown
        }
    }

    private var shadowColor: Color {
        switch prediction.urgency {
        case .justWent, .normal:
            return Color.ollieSuccess.opacity(colorScheme == .dark ? 0.2 : 0.1)
        case .attention:
            return Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.1)
        case .soon:
            return Color.ollieWarning.opacity(colorScheme == .dark ? 0.25 : 0.12)
        case .overdue, .postAccident:
            return Color.ollieDanger.opacity(colorScheme == .dark ? 0.25 : 0.12)
        case .unknown:
            return Color.black.opacity(colorScheme == .dark ? 0.2 : 0.06)
        }
    }

    private var isNightTime: Bool {
        Constants.isNightTimeNow()
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
