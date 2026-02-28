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

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 32)

            // Profile photo or icon
            Group {
                if let photo = profilePhoto {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.ollieAccent, lineWidth: 3))
                        .shadow(color: Color.ollieAccent.opacity(0.2), radius: 12, x: 0, y: 4)
                } else {
                    Circle()
                        .fill(Color.ollieAccent.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .overlay {
                            Image(systemName: "checkmark")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundStyle(Color.ollieAccent)
                        }
                }
            }
            .scaleEffect(hasAppeared ? 1.0 : 0.8)
            .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()
                .frame(height: 20)

            Text(Strings.Onboarding.readyToStart)
                .font(.title2)
                .fontWeight(.bold)
                .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()
                .frame(height: 24)

            // Profile summary card
            VStack(alignment: .leading, spacing: 0) {
                ConfirmProfileRow(label: Strings.Settings.name, value: name)
                if !breedToSave.isEmpty {
                    Divider().padding(.leading, 16)
                    ConfirmProfileRow(label: Strings.Settings.breed, value: breedToSave)
                }
                Divider().padding(.leading, 16)
                ConfirmProfileRow(label: Strings.Onboarding.born, value: formatOnboardingDate(birthDate))
                Divider().padding(.leading, 16)
                ConfirmProfileRow(label: Strings.Onboarding.cameHome, value: formatOnboardingDate(homeDate))
                Divider().padding(.leading, 16)
                ConfirmProfileRow(label: Strings.Settings.size, value: sizeCategory.label)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal, 24)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .offset(y: hasAppeared ? 0 : 15)

            Spacer()

            // Buttons
            HStack(spacing: 12) {
                OnboardingBackButton(action: onBack)

                Button(action: onSave) {
                    Text(Strings.Common.start)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.ollieAccent)
                        )
                        .foregroundStyle(.white)
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

// MARK: - Confirm Profile Row

private struct ConfirmProfileRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
