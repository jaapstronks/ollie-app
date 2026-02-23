//
//  OnboardingWelcomeStep.swift
//  Ollie-app
//
//  Welcome step for onboarding - shows tagline and value prop
//

import SwiftUI

/// Welcome step - first step of onboarding with brand messaging
struct OnboardingWelcomeStep: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo and tagline
            VStack(spacing: 16) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.accentColor)

                Text(Strings.App.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(Strings.App.tagline)
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                Text(Strings.Onboarding.welcomeSubtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            Spacer()

            // Two personas
            VStack(spacing: 16) {
                PersonaCard(
                    icon: "book.fill",
                    title: Strings.Onboarding.preparingTitle,
                    subtitle: Strings.Onboarding.preparingSubtitle
                )

                PersonaCard(
                    icon: "exclamationmark.bubble.fill",
                    title: Strings.Onboarding.alreadyInTitle,
                    subtitle: Strings.Onboarding.alreadyInSubtitle
                )
            }
            .padding(.horizontal)

            Spacer()

            // Get started button
            Button(action: onNext) {
                Text(Strings.Onboarding.getStarted)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

/// Card showing a persona scenario
private struct PersonaCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.ollieAccent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingWelcomeStep {
        print("Next tapped")
    }
}
