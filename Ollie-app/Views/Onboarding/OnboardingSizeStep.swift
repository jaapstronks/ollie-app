//
//  OnboardingSizeStep.swift
//  Ollie-app
//
//  Size category selection step for onboarding
//

import SwiftUI

/// Size category selection step (shown only for custom breeds)
struct OnboardingSizeStep: View {
    let puppyName: String
    @Binding var sizeCategory: PuppyProfile.SizeCategory
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "ruler.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.ollieAccent)

            Text(Strings.Onboarding.sizeQuestion(name: puppyName))
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(PuppyProfile.SizeCategory.allCases) { size in
                    SizeCategoryButton(
                        size: size,
                        isSelected: sizeCategory == size,
                        onSelect: { sizeCategory = size }
                    )
                }
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                OnboardingBackButton(action: onBack)
                OnboardingNextButton(enabled: true, action: onNext)
            }
        }
        .padding()
    }
}

// MARK: - Size Category Button

private struct SizeCategoryButton: View {
    let size: PuppyProfile.SizeCategory
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading) {
                    Text(size.label)
                        .font(.headline)
                    Text(size.examples)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}
