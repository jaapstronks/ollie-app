//
//  PostWakePottyCard.swift
//  Otis-app
//
//  Card shown after puppy wakes up when potty was urgent/overdue while sleeping
//  Prompts user to take puppy outside for potty

import SwiftUI
import OtisShared

/// Post-wake prompt card for potty
/// Shows after puppy wakes when potty was urgent while sleeping
struct PostWakePottyCard: View {
    let wokeAt: Date
    let minutesSinceWake: Int
    let pottyWasOverdueBy: Int?
    /// Subject pronoun for the dog (he/she/they)
    let subjectPronoun: String
    let onLogPotty: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Title text using proper pronouns
    private var titleText: String {
        Strings.CombinedStatus.awakeTimePotty(subject: subjectPronoun)
    }

    var body: some View {
        StatusCardHeader(
            iconName: "sun.max.fill",
            iconColor: .otisWarning,
            tintColor: .otisWarning,
            title: titleText,
            titleColor: .primary,
            subtitle: subtitleText
        ) {
            // Log potty button
            Button(action: onLogPotty) {
                Label(Strings.CombinedStatus.logPotty, systemImage: "drop.fill")
            }
            .buttonStyle(.glassPillCompact(tint: .custom(.otisWarning)))
        }
        .statusCardPadding()
        .glassStatusCard(tintColor: .otisWarning, cornerRadius: LayoutConstants.cornerRadiusL)
        .shadow(color: shadowColor, radius: 10, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.CombinedStatus.postWakeCardAccessibility)
        .accessibilityValue("\(titleText). \(subtitleText)")
    }

    // MARK: - Computed Properties

    /// Whether this was overnight sleep (morning time)
    /// In the morning, show "puppies need to go first thing" rather than specific overdue time
    private var isMorningFirstPotty: Bool {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        // Morning window: 5 AM - 11 AM
        return currentHour >= 5 && currentHour < 11
    }

    private var subtitleText: String {
        // For morning first potty, don't show specific overdue time
        if isMorningFirstPotty {
            return Strings.CombinedStatus.pottyFirstThingAfterWaking
        }

        // For daytime naps, show rounded overdue bucket
        if let overdue = pottyWasOverdueBy, overdue > 0 {
            if let bucket = PredictionCalculations.roundedOverdueBucket(overdue) {
                return Strings.CombinedStatus.pottyWasOverdueRounded(bucket: bucket)
            }
            // Below threshold, just say post-nap potty recommended
            return Strings.CombinedStatus.postNapPottyRecommended
        }
        return Strings.CombinedStatus.postNapPottyRecommended
    }

    private var shadowColor: Color {
        let opacity = colorScheme == .dark ? 0.2 : 0.1
        return Color.otisWarning.opacity(opacity)
    }
}

// MARK: - Previews

#Preview("Potty Was Overdue") {
    VStack {
        PostWakePottyCard(
            wokeAt: Date().addingTimeInterval(-2 * 60),
            minutesSinceWake: 2,
            pottyWasOverdueBy: 8,
            subjectPronoun: "she",
            onLogPotty: { print("Log potty tapped") }
        )
        Spacer()
    }
    .padding()
}

#Preview("General Post-Wake") {
    VStack {
        PostWakePottyCard(
            wokeAt: Date().addingTimeInterval(-3 * 60),
            minutesSinceWake: 3,
            pottyWasOverdueBy: nil,
            subjectPronoun: "he",
            onLogPotty: { print("Log potty tapped") }
        )
        Spacer()
    }
    .padding()
}
