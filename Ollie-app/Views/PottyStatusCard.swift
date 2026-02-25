//
//  PottyStatusCard.swift
//  Ollie-app
//
//  V3: Hero widget with smart predictions and urgency levels
//  Uses liquid glass design for iOS 26 aesthetic

import SwiftUI
import OllieShared

/// Prominent card showing potty status with smart predictions
/// Uses liquid glass design with semantic tinting based on urgency
struct PottyStatusCard: View {
    let prediction: PottyPrediction
    let puppyName: String
    let onLogPotty: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    init(prediction: PottyPrediction, puppyName: String, onLogPotty: (() -> Void)? = nil) {
        self.prediction = prediction
        self.puppyName = puppyName
        self.onLogPotty = onLogPotty
    }

    var body: some View {
        // Hide during night hours (23:00 - 06:00) or if no data
        if isNightTime {
            EmptyView()
        } else {
            cardContent
                .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        StatusCardHeader(
            iconName: prediction.urgency.iconName,
            iconColor: prediction.urgency.iconColor,
            tintColor: indicatorColor,
            title: PredictionCalculations.displayText(for: prediction, puppyName: puppyName),
            titleColor: prediction.urgency.textColor,
            subtitle: PredictionCalculations.subtitleText(for: prediction)
        ) {
            // Show action when urgency warrants it
            if let onLogPotty, shouldShowAction {
                Button(action: onLogPotty) {
                    Label(Strings.PottyStatus.logNow, systemImage: "drop.fill")
                }
                .buttonStyle(.glassPillCompact(tint: .custom(indicatorColor)))
            }
        }
        .statusCardPadding()
        .glassStatusCard(tintColor: indicatorColor, cornerRadius: LayoutConstants.cornerRadiusL)
        .shadow(color: shadowColor, radius: 10, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.PottyStatus.accessibility)
        .accessibilityValue(PredictionCalculations.displayText(for: prediction, puppyName: puppyName))
        .accessibilityHint(Strings.PottyStatus.predictionHint(name: puppyName))
    }

    private var shouldShowAction: Bool {
        prediction.urgency.isUrgent
    }

    // MARK: - Computed Properties

    private var indicatorColor: Color {
        prediction.urgency.iconColor
    }

    private var shadowColor: Color {
        let baseColor = prediction.urgency.iconColor
        let opacity = colorScheme == .dark ? 0.2 : 0.1
        return baseColor.opacity(prediction.urgency.isUrgent ? opacity * 1.25 : opacity)
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
