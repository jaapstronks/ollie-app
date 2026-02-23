//
//  OnboardingNameStep.swift
//  Ollie-app
//
//  Name input step for onboarding
//

import SwiftUI
import OllieShared

/// Name input step - first step of onboarding
struct OnboardingNameStep: View {
    @Binding var name: String
    @FocusState.Binding var isNameFieldFocused: Bool
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            Text(Strings.Onboarding.nameQuestion)
                .font(.title)
                .fontWeight(.bold)

            TextField(Strings.Onboarding.namePlaceholder, text: $name)
                .textFieldStyle(.roundedBorder)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .focused($isNameFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    isNameFieldFocused = false
                }
                .accessibilityLabel(Strings.Onboarding.namePlaceholder)
                .accessibilityHint(Strings.Onboarding.nameAccessibility)

            Spacer()

            OnboardingNextButton(enabled: !name.isEmpty, action: onNext)
        }
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(Strings.Common.next) {
                    if !name.isEmpty {
                        isNameFieldFocused = false
                        onNext()
                    } else {
                        isNameFieldFocused = false
                    }
                }
                .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Reusable Buttons

/// Next button used across onboarding steps
struct OnboardingNextButton: View {
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(Strings.Common.next)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(enabled ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .disabled(!enabled)
    }
}

/// Back button used across onboarding steps
struct OnboardingBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(Strings.Common.back)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .foregroundColor(.primary)
                .cornerRadius(12)
        }
    }
}
