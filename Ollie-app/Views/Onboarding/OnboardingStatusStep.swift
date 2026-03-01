//
//  OnboardingStatusStep.swift
//  Otis-app
//
//  Step to determine if the puppy is already home or expected
//

import SwiftUI

/// Status selection step - is the puppy already home or expected?
struct OnboardingStatusStep: View {
    let puppyName: String
    @Binding var isExpecting: Bool
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.otisAccent)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.Onboarding.statusQuestion(name: puppyName))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)

            // Options
            VStack(spacing: 16) {
                StatusOptionButton(
                    title: Strings.Onboarding.statusAlreadyHome(name: puppyName),
                    icon: "checkmark.circle.fill",
                    isSelected: !isExpecting,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpecting = false
                        }
                    }
                )
                .opacity(hasAppeared ? 1.0 : 0.0)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.5).delay(0.1), value: hasAppeared)

                StatusOptionButton(
                    title: Strings.Onboarding.statusExpecting(name: puppyName),
                    icon: "clock.fill",
                    isSelected: isExpecting,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpecting = true
                        }
                    }
                )
                .opacity(hasAppeared ? 1.0 : 0.0)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.5).delay(0.2), value: hasAppeared)
            }
            .padding(.horizontal, 24)

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

/// Button for status options
private struct StatusOptionButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.white : Color.otisAccent)

                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? Color.white : Color.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.otisAccent : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.otisAccent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    OnboardingStatusStep(
        puppyName: "Luna",
        isExpecting: .constant(false),
        onNext: {},
        onBack: {}
    )
}
