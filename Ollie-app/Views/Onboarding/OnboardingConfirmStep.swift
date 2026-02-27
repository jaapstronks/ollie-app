//
//  OnboardingConfirmStep.swift
//  Ollie-app
//
//  Confirmation/summary step for onboarding
//

import SwiftUI
import UIKit
import OllieShared

/// Summary and confirmation step - final step of onboarding
struct OnboardingConfirmStep: View {
    let name: String
    let breedToSave: String
    let birthDate: Date
    let homeDate: Date
    let sizeCategory: PuppyProfile.SizeCategory
    let profilePhoto: UIImage?
    let onSave: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Profile photo or icon
            if let photo = profilePhoto {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.ollieAccent, lineWidth: 3))
            } else {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.ollieAccent)
            }

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
            .cornerRadius(LayoutConstants.cornerRadiusM)
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
                        .cornerRadius(LayoutConstants.cornerRadiusM)
                }
            }
        }
        .padding()
    }
}
