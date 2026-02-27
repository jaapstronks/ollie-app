//
//  CombinedSleepPottyCard.swift
//  Ollie-app
//
//  Combined status card for when puppy is sleeping AND potty is urgent/overdue
//  Shows both pieces of info together with contextual message

import SwiftUI
import OllieShared

/// Combined card showing sleep + potty urgency together
/// Used when puppy is sleeping but potty is urgent/overdue
struct CombinedSleepPottyCard: View {
    let sleepingSince: Date
    let sleepDurationMin: Int
    let pottyUrgency: PottyUrgency
    let minutesOverdue: Int?
    let onWakeUp: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var sleepDurationText: String {
        if sleepDurationMin <= 1 {
            return Strings.CombinedStatus.justFellAsleep
        } else if sleepDurationMin <= 15 {
            return Strings.CombinedStatus.sleepingBriefly(duration: sleepDurationMin.formatAsDuration())
        }
        return Strings.CombinedStatus.sleepingFor(duration: sleepDurationMin.formatAsDuration())
    }

    var body: some View {
        VStack(spacing: 12) {
            // Sleep status header
            HStack(spacing: 14) {
                // Combined icon: moon with warning
                ZStack {
                    GlassIconCircle(tintColor: .ollieSleep, size: 44) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color.ollieSleep)
                    }

                    // Warning badge overlay
                    Circle()
                        .fill(.orange)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Image(systemName: "exclamationmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .offset(x: 16, y: -16)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(sleepDurationText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(Strings.SleepStatus.started(time: sleepingSince.timeString))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                GlassStatusPill(text: Strings.CombinedStatus.sleepingPottyLabel, tintColor: .ollieSleep)
            }

            // Divider
            Rectangle()
                .fill(.quaternary)
                .frame(height: 1)
                .padding(.horizontal, 4)

            // Potty warning section
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.CombinedStatus.whenWakesTakeOutside)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(pottySubtitle)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Spacer()
            }
            .padding(.leading, 6)

            // Wake up button
            Button(action: onWakeUp) {
                Label(Strings.CombinedStatus.wakeUp, systemImage: "sun.max.fill")
            }
            .buttonStyle(.glassPill(tint: .custom(.ollieSleep)))
        }
        .statusCardPadding()
        .glassStatusCard(tintColor: gradientColor, cornerRadius: LayoutConstants.cornerRadiusL)
        .shadow(color: shadowColor, radius: 10, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.CombinedStatus.combinedCardAccessibility)
        .accessibilityValue("\(sleepDurationText). \(pottySubtitle)")
    }

    // MARK: - Computed Properties

    private var pottySubtitle: String {
        if let overdue = minutesOverdue, overdue > 0 {
            return Strings.CombinedStatus.pottyOverdueWhileSleeping(minutes: overdue)
        }
        return Strings.CombinedStatus.pottyUrgentWhileSleeping
    }

    /// Gradient color combining sleep (purple) and warning (orange)
    private var gradientColor: Color {
        // Use purple as base with subtle orange influence
        .ollieSleep
    }

    private var shadowColor: Color {
        let opacity = colorScheme == .dark ? 0.2 : 0.1
        return Color.ollieSleep.opacity(opacity)
    }
}

// MARK: - Previews

#Preview("Potty Overdue While Sleeping") {
    VStack {
        CombinedSleepPottyCard(
            sleepingSince: Date().addingTimeInterval(-45 * 60),
            sleepDurationMin: 45,
            pottyUrgency: .overdue(minutesOverdue: 8),
            minutesOverdue: 8,
            onWakeUp: { print("Wake up tapped") }
        )
        Spacer()
    }
    .padding()
}

#Preview("Potty Soon While Sleeping") {
    VStack {
        CombinedSleepPottyCard(
            sleepingSince: Date().addingTimeInterval(-30 * 60),
            sleepDurationMin: 30,
            pottyUrgency: .soon(minutesRemaining: 5),
            minutesOverdue: nil,
            onWakeUp: { print("Wake up tapped") }
        )
        Spacer()
    }
    .padding()
}
