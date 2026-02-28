//
//  OnboardingDateStep.swift
//  Ollie-app
//
//  Birth date and home date steps for onboarding
//

import SwiftUI
import OllieShared

/// Birth date selection step
struct OnboardingBirthStep: View {
    let puppyName: String
    @Binding var birthDate: Date
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.ollieAccent)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.Onboarding.birthDateQuestion(name: puppyName))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)
            }
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Date picker
            DatePicker(
                Strings.Onboarding.birthDate,
                selection: $birthDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(Color.ollieAccent)
            .padding(.horizontal, 8)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .accessibilityLabel(Strings.Onboarding.birthDateAccessibility(name: puppyName))

            Spacer()

            // Buttons
            HStack(spacing: 12) {
                OnboardingBackButton(action: onBack)
                OnboardingNextButton(enabled: true, action: onNext)
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

/// Home date selection step
struct OnboardingHomeStep: View {
    let puppyName: String
    @Binding var homeDate: Date
    let minDate: Date  // birthDate
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.ollieAccent)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.Onboarding.homeDateQuestion(name: puppyName))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)
            }
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Date picker
            DatePicker(
                Strings.Onboarding.homeDate,
                selection: $homeDate,
                in: minDate...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(Color.ollieAccent)
            .padding(.horizontal, 8)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .accessibilityLabel(Strings.Onboarding.homeDateAccessibility(name: puppyName))

            Spacer()

            // Buttons
            HStack(spacing: 12) {
                OnboardingBackButton(action: onBack)
                OnboardingNextButton(enabled: true, action: onNext)
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
