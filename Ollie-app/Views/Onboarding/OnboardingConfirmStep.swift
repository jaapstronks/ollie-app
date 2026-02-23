//
//  OnboardingConfirmStep.swift
//  Ollie-app
//
//  Confirmation/summary step for onboarding
//

import SwiftUI

/// Summary and confirmation step - final step of onboarding
struct OnboardingConfirmStep: View {
    let name: String
    let breedToSave: String
    let birthDate: Date
    let homeDate: Date
    let sizeCategory: PuppyProfile.SizeCategory
    let onSave: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.ollieAccent)

            Text(Strings.Onboarding.readyToStart)
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                ProfileRow(label: Strings.Settings.name, value: name)
                if !breedToSave.isEmpty {
                    ProfileRow(label: Strings.Settings.breed, value: breedToSave)
                }
                ProfileRow(label: Strings.Onboarding.born, value: formatOnboardingDate(birthDate))
                ProfileRow(label: Strings.Onboarding.cameHome, value: formatOnboardingDate(homeDate))
                ProfileRow(label: Strings.Settings.size, value: sizeCategory.label)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()

            HStack {
                OnboardingBackButton(action: onBack)

                Button(action: onSave) {
                    Text(Strings.Common.start)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }
}
