//
//  PostWakePottyCard.swift
//  Ollie-app
//
//  Card shown after puppy wakes up when potty was urgent/overdue while sleeping
//  Prompts user to take puppy outside for potty

import SwiftUI
import OllieShared

/// Post-wake prompt card for potty
/// Shows after puppy wakes when potty was urgent while sleeping
struct PostWakePottyCard: View {
    let wokeAt: Date
    let minutesSinceWake: Int
    let pottyWasOverdueBy: Int?
    let onLogPotty: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        StatusCardHeader(
            iconName: "sun.max.fill",
            iconColor: .ollieWarning,
            tintColor: .ollieWarning,
            title: Strings.CombinedStatus.awakeTimePotty,
            titleColor: .primary,
            subtitle: subtitleText
        ) {
            // Log potty button
            Button(action: onLogPotty) {
                Label(Strings.CombinedStatus.logPotty, systemImage: "drop.fill")
            }
            .buttonStyle(.glassPillCompact(tint: .custom(.ollieWarning)))
        }
        .statusCardPadding()
        .glassStatusCard(tintColor: .ollieWarning, cornerRadius: LayoutConstants.cornerRadiusL)
        .shadow(color: shadowColor, radius: 10, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.CombinedStatus.postWakeCardAccessibility)
        .accessibilityValue("\(Strings.CombinedStatus.awakeTimePotty). \(subtitleText)")
    }

    // MARK: - Computed Properties

    private var subtitleText: String {
        if let overdue = pottyWasOverdueBy, overdue > 0 {
            return Strings.CombinedStatus.pottyWasOverdue(minutes: overdue)
        }
        return Strings.CombinedStatus.postNapPottyRecommended
    }

    private var shadowColor: Color {
        let opacity = colorScheme == .dark ? 0.2 : 0.1
        return Color.ollieWarning.opacity(opacity)
    }
}

// MARK: - Previews

#Preview("Potty Was Overdue") {
    VStack {
        PostWakePottyCard(
            wokeAt: Date().addingTimeInterval(-2 * 60),
            minutesSinceWake: 2,
            pottyWasOverdueBy: 8,
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
            onLogPotty: { print("Log potty tapped") }
        )
        Spacer()
    }
    .padding()
}
