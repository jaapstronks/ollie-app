//
//  FirstRunWelcomeCard.swift
//  Otis-app
//
//  Welcome card shown after onboarding when user's puppy is already home
//  Asks a simple question to establish baseline state
//

import SwiftUI

/// Welcome card for first-time users after onboarding
/// Shows a friendly prompt to establish initial puppy state
struct FirstRunWelcomeCard: View {
    let puppyName: String
    let onSleeping: () -> Void
    let onAwake: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            // Welcome header
            VStack(spacing: 8) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                Text(Strings.FirstRun.welcomeTitle(name: puppyName))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(Strings.FirstRun.welcomeSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 4)

            // Question
            Text(Strings.FirstRun.sleepQuestion(name: puppyName))
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            // Answer buttons
            HStack(spacing: 12) {
                // Sleeping button
                Button {
                    onSleeping()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.zzz.fill")
                        Text(Strings.FirstRun.yesSleeping)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // Awake button
                Button {
                    onAwake()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sun.max.fill")
                        Text(Strings.FirstRun.noAwake)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.FirstRun.accessibilityLabel(name: puppyName))
    }

    private var cardBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(Color(.secondarySystemBackground))
        }
        return AnyShapeStyle(Color(.secondarySystemBackground))
    }
}

#Preview("First Run Welcome") {
    VStack {
        FirstRunWelcomeCard(
            puppyName: "Max",
            onSleeping: { print("Sleeping") },
            onAwake: { print("Awake") }
        )
        .padding()
    }
    .background(Color(.systemBackground))
}
