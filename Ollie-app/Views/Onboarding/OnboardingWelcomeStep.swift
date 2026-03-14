//
//  OnboardingWelcomeStep.swift
//  Otis-app
//
//  Welcome step for onboarding - shows tagline and value prop
//

import SwiftUI
import OtisShared

/// Welcome step - first step of onboarding with two clear choices
struct OnboardingWelcomeStep: View {
    let onNext: () -> Void
    var onJoinExisting: (() -> Void)? = nil

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo and tagline
            VStack(spacing: 16) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.otisAccent)
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
            }

            Spacer()

            // Two choice buttons
            VStack(spacing: 16) {
                // Primary: Add my dog
                Button(action: onNext) {
                    WelcomeChoiceButton(
                        icon: "plus.circle.fill",
                        title: Strings.Onboarding.addMyDog,
                        subtitle: Strings.Onboarding.addMyDogSubtitle,
                        isPrimary: true
                    )
                }
                .buttonStyle(.plain)
                .opacity(hasAppeared ? 1.0 : 0.0)
                .offset(y: hasAppeared ? 0 : 20)

                // Secondary: Join shared dog
                if let onJoinExisting {
                    Button(action: onJoinExisting) {
                        WelcomeChoiceButton(
                            icon: "person.2.fill",
                            title: Strings.Onboarding.joinSharedDog,
                            subtitle: Strings.Onboarding.joinSharedDogSubtitle,
                            isPrimary: false
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 20)
                }
            }

            Spacer()
                .frame(height: 60)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                hasAppeared = true
            }
        }
    }
}

/// Big choice button for welcome screen
private struct WelcomeChoiceButton: View {
    let icon: String
    let title: String
    let subtitle: String
    var isPrimary: Bool = true

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(isPrimary ? .white : Color.otisAccent)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(isPrimary ? .white : .primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(isPrimary ? .white.opacity(0.8) : .secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(isPrimary ? .white.opacity(0.7) : .secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(isPrimary ? Color.otisAccent : Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

#Preview {
    OnboardingWelcomeStep(
        onNext: { print("Next tapped") },
        onJoinExisting: { print("Join existing tapped") }
    )
}
