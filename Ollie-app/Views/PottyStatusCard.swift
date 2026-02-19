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
        HStack(spacing: 14) {
            // Icon with glass circle background
            Image(systemName: PredictionCalculations.iconName(for: prediction.urgency))
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(PredictionCalculations.iconColor(for: prediction.urgency))
                .frame(width: 44, height: 44)
                .background(iconBackground)
                .clipShape(Circle())
                .overlay(iconOverlay)

            VStack(alignment: .leading, spacing: 3) {
                // Main status text
                Text(PredictionCalculations.displayText(for: prediction, puppyName: puppyName))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(textColor)

                // Subtitle with timing details
                if let subtitle = PredictionCalculations.subtitleText(for: prediction) {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Urgency indicator pill
            urgencyPill
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(glassOverlay)
        .shadow(color: shadowColor, radius: 10, y: 5)
    }

    // MARK: - Glass Components

    @ViewBuilder
    private var iconBackground: some View {
        ZStack {
            indicatorColor.opacity(colorScheme == .dark ? 0.2 : 0.15)

            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private var iconOverlay: some View {
        Circle()
            .strokeBorder(
                indicatorColor.opacity(0.3),
                lineWidth: 0.5
            )
    }

    @ViewBuilder
    private var urgencyPill: some View {
        Text(urgencyLabel)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(indicatorColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(indicatorColor.opacity(colorScheme == .dark ? 0.2 : 0.12))
            )
            .overlay(
                Capsule()
                    .strokeBorder(indicatorColor.opacity(0.2), lineWidth: 0.5)
            )
    }

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            // Base with urgency tint
            if colorScheme == .dark {
                Color.white.opacity(0.06)
            } else {
                Color.white.opacity(0.75)
            }

            // Urgency tint
            indicatorColor.opacity(colorScheme == .dark ? 0.08 : 0.05)

            // Top highlight
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .background(.thinMaterial)
    }

    @ViewBuilder
    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                        indicatorColor.opacity(colorScheme == .dark ? 0.1 : 0.08),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
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
            return "Net geweest"
        case .normal:
            return "Normaal"
        case .attention:
            return "Let op"
        case .soon:
            return "Bijna tijd"
        case .overdue:
            return "Nu!"
        case .postAccident:
            return "Ongelukje"
        case .unknown:
            return "Onbekend"
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
