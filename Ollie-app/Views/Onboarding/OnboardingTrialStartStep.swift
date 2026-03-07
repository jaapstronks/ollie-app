//
//  OnboardingTrialStartStep.swift
//  Otis-app
//
//  Onboarding step that prompts user to start the 14-day free trial

import SwiftUI

/// Onboarding step that invites users to start the 14-day free trial
struct OnboardingTrialStartStep: View {
    let puppyName: String
    let onStartTrial: () -> Void
    let onSkip: () -> Void

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero icon
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(Color.otisAccent)
                .symbolRenderingMode(.hierarchical)
                .scaleEffect(hasAppeared ? 1.0 : 0.8)
                .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()
                .frame(height: 20)

            Text(Strings.Trial.heroTitle)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()
                .frame(height: 8)

            Text(Strings.Trial.heroSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()
                .frame(height: 28)

            // Benefits list
            VStack(alignment: .leading, spacing: 14) {
                TrialBenefitRow(icon: "wand.and.stars", text: Strings.Trial.benefit1)
                TrialBenefitRow(icon: "graduationcap.fill", text: Strings.Trial.benefit2)
                TrialBenefitRow(icon: "chart.xyaxis.line", text: Strings.Trial.benefit3)
                TrialBenefitRow(icon: "creditcard.fill", text: Strings.Trial.benefit4)
            }
            .padding(.horizontal, 32)
            .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button {
                    HapticFeedback.success()
                    onStartTrial()
                } label: {
                    Text(Strings.Trial.startTrialButton)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.otisAccent)
                        )
                        .foregroundStyle(.white)
                }

                Button {
                    onSkip()
                } label: {
                    Text(Strings.Trial.skipTrialLink)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .opacity(hasAppeared ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
    }
}

/// Row showing a trial benefit with icon
private struct TrialBenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.otisAccent)
                .frame(width: 28)

            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    OnboardingTrialStartStep(
        puppyName: "Luna",
        onStartTrial: {},
        onSkip: {}
    )
}
