//
//  OnboardingGenderStep.swift
//  Otis-app
//
//  Gender selection step for onboarding
//

import SwiftUI
import OtisShared

/// Gender selection step
struct OnboardingGenderStep: View {
    let puppyName: String
    @Binding var gender: PuppyProfile.Gender
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var hasAppeared = false

    /// Options to display - excludes unspecified since that's handled by skip
    private var displayOptions: [PuppyProfile.Gender] {
        [.male, .female]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 24)

            // Header
            VStack(spacing: 12) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.otisAccent)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.Onboarding.genderQuestion(name: puppyName))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.Onboarding.genderSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)
            }
            .padding(.bottom, 32)

            // Gender options
            VStack(spacing: 12) {
                ForEach(Array(displayOptions.enumerated()), id: \.element) { index, genderOption in
                    GenderOptionButton(
                        gender: genderOption,
                        isSelected: gender == genderOption,
                        onSelect: {
                            HapticFeedback.light()
                            gender = genderOption
                        }
                    )
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 15)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.08), value: hasAppeared)
                }

                // Skip option
                Button {
                    HapticFeedback.light()
                    gender = .unspecified
                    onNext()
                } label: {
                    Text(Strings.Onboarding.skipForNow)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
                .opacity(hasAppeared ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: hasAppeared)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Buttons
            HStack(spacing: 12) {
                OnboardingBackButton(action: onBack)
                OnboardingNextButton(enabled: gender != .unspecified, action: onNext)
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

// MARK: - Gender Option Button

private struct GenderOptionButton: View {
    let gender: PuppyProfile.Gender
    let isSelected: Bool
    let onSelect: () -> Void

    private var icon: String {
        switch gender {
        case .male: return "♂"
        case .female: return "♀"
        case .unspecified: return "?"
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Text(icon)
                    .font(.title)

                Text(gender.label)
                    .font(.body)
                    .fontWeight(.medium)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.otisAccent : Color(.tertiaryLabel))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.otisAccent.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.otisAccent.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    OnboardingGenderStep(
        puppyName: "Max",
        gender: .constant(.unspecified),
        onNext: {},
        onBack: {}
    )
}
