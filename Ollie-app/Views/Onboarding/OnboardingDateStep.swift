//
//  OnboardingDateStep.swift
//  Ollie-app
//
//  Birth date and home date steps for onboarding
//

import SwiftUI

/// Birth date selection step
struct OnboardingBirthStep: View {
    let puppyName: String
    @Binding var birthDate: Date
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "gift.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.ollieAccent)

            Text(Strings.Onboarding.birthDateQuestion(name: puppyName))
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            DatePicker(
                Strings.Onboarding.birthDate,
                selection: $birthDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal)
            .accessibilityLabel(Strings.Onboarding.birthDateAccessibility(name: puppyName))

            Spacer()

            HStack {
                OnboardingBackButton(action: onBack)
                OnboardingNextButton(enabled: true, action: onNext)
            }
        }
        .padding()
    }
}

/// Home date selection step
struct OnboardingHomeStep: View {
    let puppyName: String
    @Binding var homeDate: Date
    let minDate: Date  // birthDate
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "house.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.ollieAccent)

            Text(Strings.Onboarding.homeDateQuestion(name: puppyName))
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            DatePicker(
                Strings.Onboarding.homeDate,
                selection: $homeDate,
                in: minDate...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal)
            .accessibilityLabel(Strings.Onboarding.homeDateAccessibility(name: puppyName))

            Spacer()

            HStack {
                OnboardingBackButton(action: onBack)
                OnboardingNextButton(enabled: true, action: onNext)
            }
        }
        .padding()
    }
}
