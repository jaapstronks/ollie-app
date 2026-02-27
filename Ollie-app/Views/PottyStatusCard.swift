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

    init(prediction: PottyPrediction, puppyName: String, onLogPotty: (() -> Void)? = nil) {
        self.prediction = prediction
        self.puppyName = puppyName
        self.onLogPotty = onLogPotty
    }

    var body: some View {
        StatusCardHeader(
            iconName: prediction.urgency.iconName,
            iconColor: prediction.urgency.iconColor,
            tintColor: indicatorColor,
            title: displayText,
            titleColor: prediction.urgency.textColor,
            subtitle: PredictionCalculations.subtitleText(for: prediction)
        ) {
            if let onLogPotty, shouldShowAction {
                Button(action: onLogPotty) {
                    Label(Strings.PottyStatus.logNow, systemImage: "drop.fill")
                }
                .buttonStyle(.glassPillCompact(tint: .custom(indicatorColor)))
            }
        }
        .statusCardContainer(
            tint: indicatorColor,
            cornerRadius: LayoutConstants.cornerRadiusL,
            isVisible: !Constants.isNightTimeNow(),
            showShadow: true,
            isUrgent: prediction.urgency.isUrgent,
            accessibilityLabel: Strings.PottyStatus.accessibility,
            accessibilityValue: displayText,
            accessibilityHint: Strings.PottyStatus.predictionHint(name: puppyName)
        )
        .padding(.vertical, 6)
    }

    // MARK: - Computed Properties

    private var displayText: String {
        PredictionCalculations.displayText(for: prediction, puppyName: puppyName)
    }

    private var shouldShowAction: Bool {
        prediction.urgency.isUrgent
    }

    private var indicatorColor: Color {
        prediction.urgency.iconColor
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
