//
//  OnboardingWelcomeStep.swift
//  Ollie-app
//
//  Welcome step for onboarding - shows tagline and value prop
//

import SwiftUI
import OllieShared

/// Welcome step - first step of onboarding with brand messaging
struct OnboardingWelcomeStep: View {
    let onNext: () -> Void

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)

            // Logo and tagline
            VStack(spacing: 12) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.ollieAccent)
                    .scaleEffect(hasAppeared ? 1.0 : 0.7)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.App.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.App.tagline)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 8)

                Text(Strings.Onboarding.welcomeSubtitle)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 8)
            }

            Spacer()
                .frame(height: 40)

            // Two personas
            VStack(spacing: 12) {
                PersonaCard(
                    icon: "book.fill",
                    title: Strings.Onboarding.preparingTitle,
                    subtitle: Strings.Onboarding.preparingSubtitle
                )
                .opacity(hasAppeared ? 1.0 : 0.0)
                .offset(y: hasAppeared ? 0 : 20)

                PersonaCard(
                    icon: "exclamationmark.bubble.fill",
                    title: Strings.Onboarding.alreadyInTitle,
                    subtitle: Strings.Onboarding.alreadyInSubtitle
                )
                .opacity(hasAppeared ? 1.0 : 0.0)
                .offset(y: hasAppeared ? 0 : 20)
            }

            Spacer()

            // Get started button
            Button(action: onNext) {
                Text(Strings.Onboarding.getStarted)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.ollieAccent)
                    .foregroundStyle(.white)
                    .cornerRadius(14)
            }
            .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()
                .frame(height: 8)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                hasAppeared = true
            }
        }
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
        .cornerRadius(LayoutConstants.cornerRadiusM)
    }
}

#Preview {
    OnboardingWelcomeStep {
        print("Next tapped")
    }
}
