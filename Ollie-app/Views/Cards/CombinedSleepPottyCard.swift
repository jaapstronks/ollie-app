//
//  CombinedSleepPottyCard.swift
//  Otis-app
//
//  Combined status card for when puppy is sleeping AND potty is urgent/overdue
//  Shows both pieces of info together with contextual message

import SwiftUI
import OtisShared

/// Combined card showing sleep + potty urgency together
/// Used when puppy is sleeping but potty is urgent/overdue
struct CombinedSleepPottyCard: View {
    let sleepingSince: Date
    let sleepDurationMin: Int
    let pottyUrgency: PottyUrgency
    let minutesOverdue: Int?
    let pendingActionable: ActionableItem?
    /// Subject pronoun for the dog (he/she/they)
    let subjectPronoun: String
    /// Object pronoun for the dog (him/her/them)
    let objectPronoun: String
    let onWakeUp: () -> Void

    init(
        sleepingSince: Date,
        sleepDurationMin: Int,
        pottyUrgency: PottyUrgency,
        minutesOverdue: Int?,
        pendingActionable: ActionableItem? = nil,
        subjectPronoun: String = "they",
        objectPronoun: String = "them",
        onWakeUp: @escaping () -> Void
    ) {
        self.sleepingSince = sleepingSince
        self.sleepDurationMin = sleepDurationMin
        self.pottyUrgency = pottyUrgency
        self.minutesOverdue = minutesOverdue
        self.pendingActionable = pendingActionable
        self.subjectPronoun = subjectPronoun
        self.objectPronoun = objectPronoun
        self.onWakeUp = onWakeUp
    }

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
                    GlassIconCircle(tintColor: .otisSleep, size: 44) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color.otisSleep)
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
                    Text(Strings.CombinedStatus.whenWakesTakeOutside(subject: subjectPronoun, object: objectPronoun))
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

            // Pending meal/walk section (if applicable)
            if let actionable = pendingActionable {
                HStack(spacing: 12) {
                    Image(systemName: actionable.item.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pendingActionableText(actionable))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text(pendingActionableSubtitle(actionable))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.leading, 6)
            }

            // Wake up button
            Button(action: onWakeUp) {
                Label(Strings.CombinedStatus.wakeUp, systemImage: "sun.max.fill")
            }
            .buttonStyle(.glassPill(tint: .custom(.otisSleep)))
        }
        .statusCardPadding()
        .glassStatusCard(tintColor: gradientColor, cornerRadius: LayoutConstants.cornerRadiusL)
        .shadow(color: shadowColor, radius: 10, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.CombinedStatus.combinedCardAccessibility)
        .accessibilityValue("\(sleepDurationText). \(pottySubtitle)")
    }

    // MARK: - Computed Properties

    /// Whether this is overnight sleep (morning time + sleep started before morning)
    /// In the morning, puppies need to go potty first thing - don't show overdue minutes
    private var isOvernightSleep: Bool {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())

        // Morning window: 5 AM - 11 AM
        guard currentHour >= 5 && currentHour < 11 else { return false }

        // Sleep started before this morning (last night)
        let sleepStartHour = calendar.component(.hour, from: sleepingSince)
        let sleepStartedToday = calendar.isDateInToday(sleepingSince)

        // Overnight if: started yesterday, OR started today before 5 AM (late night)
        return !sleepStartedToday || sleepStartHour < 5
    }

    private var pottySubtitle: String {
        // For overnight sleep in the morning, don't show specific overdue time
        // Puppies need to go first thing after waking - that's the rule
        if isOvernightSleep {
            return Strings.CombinedStatus.pottyFirstThingMorning
        }

        // For daytime naps, show rounded overdue bucket
        if let overdue = minutesOverdue, overdue > 0 {
            if let bucket = PredictionCalculations.roundedOverdueBucket(overdue) {
                return Strings.CombinedStatus.pottyOverdueWhileSleepingRounded(bucket: bucket)
            }
            // Below threshold, just say "potty needed soon"
            return Strings.CombinedStatus.pottyUrgentWhileSleeping
        }
        return Strings.CombinedStatus.pottyUrgentWhileSleeping
    }

    /// Gradient color combining sleep (purple) and warning (orange)
    private var gradientColor: Color {
        // Use purple as base with subtle orange influence
        .otisSleep
    }

    private var shadowColor: Color {
        let opacity = colorScheme == .dark ? 0.2 : 0.1
        return Color.otisSleep.opacity(opacity)
    }

    // MARK: - Pending Actionable Helpers

    /// Main text for pending meal/walk
    private func pendingActionableText(_ actionable: ActionableItem) -> String {
        switch actionable.item.itemType {
        case .walk:
            return Strings.CombinedStatus.alsoTimeForWalk
        case .meal:
            return Strings.CombinedStatus.alsoTimeForMeal
        }
    }

    /// Subtitle showing specific meal/walk name and time
    private func pendingActionableSubtitle(_ actionable: ActionableItem) -> String {
        let label = actionable.item.localizedLabel
        let time = actionable.item.timeString
        return "\(label) \(Strings.Common.atTime) \(time)"
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
