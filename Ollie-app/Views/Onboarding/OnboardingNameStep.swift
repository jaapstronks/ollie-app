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

    @State private var hasAppeared = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: geometry.size.height * 0.12)

                    // Icon with subtle animation
                    Image(systemName: "pawprint.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.ollieAccent)
                        .scaleEffect(hasAppeared ? 1.0 : 0.8)
                        .opacity(hasAppeared ? 1.0 : 0.0)

                    Spacer()
                        .frame(height: 24)

                    // Title
                    Text(Strings.Onboarding.nameQuestion)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .offset(y: hasAppeared ? 0 : 10)

                    Spacer()
                        .frame(height: 8)

                    // Subtitle
                    Text(Strings.Onboarding.nameSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .offset(y: hasAppeared ? 0 : 10)

                    Spacer()
                        .frame(height: 32)

                    // Custom styled text field
                    OnboardingTextField(
                        placeholder: Strings.Onboarding.namePlaceholder,
                        text: $name,
                        isFocused: $isNameFieldFocused
                    )
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 15)

                    Spacer()
                        .frame(minHeight: 40)

                    // Next button
                    OnboardingNextButton(enabled: !name.isEmpty, action: onNext)
                        .opacity(hasAppeared ? 1.0 : 0.0)

                    Spacer()
                        .frame(height: 16)
                }
                .frame(minHeight: geometry.size.height)
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            // Auto-focus the text field after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isNameFieldFocused = true
            }
            // Animate content in
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
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

// MARK: - Custom Text Field

/// Styled text field for onboarding screens
struct OnboardingTextField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.title2)
            .fontWeight(.medium)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isFocused ? Color.ollieAccent : Color.clear,
                        lineWidth: 2
                    )
            )
            .focused($isFocused)
            .submitLabel(.done)
            .onSubmit {
                isFocused = false
            }
            .accessibilityLabel(placeholder)
            .accessibilityHint(Strings.Onboarding.nameAccessibility)
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
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(enabled ? Color.ollieAccent : Color.ollieAccent.opacity(0.35))
                )
                .foregroundStyle(.white)
        }
        .disabled(!enabled)
        .animation(.easeInOut(duration: 0.2), value: enabled)
    }
}

/// Back button used across onboarding steps
struct OnboardingBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(Strings.Common.back)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.ollieAccent.opacity(0.12))
                )
                .foregroundStyle(Color.ollieAccent)
        }
    }
}
