//
//  OnboardingCoatTypeStep.swift
//  Otis-app
//
//  Coat type selection step for onboarding (after breed selection)
//  Sets up coat-appropriate grooming schedule defaults
//

import SwiftUI
import OtisShared

/// Coat type selection step for onboarding
struct OnboardingCoatTypeStep: View {
    let puppyName: String
    let suggestedCoatType: CoatType?
    @Binding var selectedCoatType: CoatType?
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "comb.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.otisAccent)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.Onboarding.coatTypeQuestion(name: puppyName))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.Onboarding.coatTypeSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .opacity(hasAppeared ? 1.0 : 0.0)
            }
            .padding(.top, 8)
            .padding(.bottom, 20)

            // Coat type list
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(Array(CoatType.allCases.enumerated()), id: \.element.id) { index, coatType in
                        CoatTypeSelectionButton(
                            coatType: coatType,
                            isSelected: selectedCoatType == coatType,
                            isSuggested: suggestedCoatType == coatType,
                            onSelect: {
                                HapticFeedback.light()
                                selectedCoatType = coatType
                            }
                        )
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .offset(y: hasAppeared ? 0 : 15)
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.03), value: hasAppeared)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            // Buttons
            HStack(spacing: 12) {
                OnboardingBackButton(action: onBack)
                OnboardingNextButton(enabled: selectedCoatType != nil, action: onNext)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .opacity(hasAppeared ? 1.0 : 0.0)

            Button {
                selectedCoatType = nil
                onNext()
            } label: {
                Text(Strings.Onboarding.skipForNow)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 16)
            .opacity(hasAppeared ? 1.0 : 0.0)
        }
        .onAppear {
            // Pre-select suggested coat type if available
            if selectedCoatType == nil, let suggested = suggestedCoatType {
                selectedCoatType = suggested
            }
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Coat Type Selection Button

private struct CoatTypeSelectionButton: View {
    let coatType: CoatType
    let isSelected: Bool
    let isSuggested: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: coatType.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.otisAccent : .secondary)
                    .frame(width: 32)

                // Labels
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(coatType.label)
                            .font(.body)
                            .fontWeight(.medium)

                        if isSuggested {
                            Text(Strings.Grooming.suggested)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.otisAccent)
                                .clipShape(Capsule())
                        }
                    }

                    Text(coatType.examples)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.otisAccent : Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
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

// MARK: - Preview

#Preview {
    OnboardingCoatTypeStep(
        puppyName: "Luna",
        suggestedCoatType: .double,
        selectedCoatType: .constant(nil),
        onNext: {},
        onBack: {}
    )
}

#Preview("With Selection") {
    OnboardingCoatTypeStep(
        puppyName: "Ollie",
        suggestedCoatType: .curly,
        selectedCoatType: .constant(.curly),
        onNext: {},
        onBack: {}
    )
}
