//
//  OnboardingBreedStep.swift
//  Ollie-app
//
//  Breed selection step for onboarding
//

import SwiftUI
import OllieShared

/// Breed selection step
struct OnboardingBreedStep: View {
    let puppyName: String
    @Binding var selectedBreed: DogBreed?
    @Binding var customBreed: String
    @Binding var isCustomBreed: Bool
    @Binding var sizeCategory: PuppyProfile.SizeCategory
    @FocusState.Binding var isCustomBreedFieldFocused: Bool
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "dog.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.ollieAccent)

            Text(Strings.Onboarding.breedQuestion(name: puppyName))
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 10) {
                    // Predefined breeds
                    ForEach(DogBreed.breeds) { breed in
                        BreedSelectionButton(
                            breed: breed,
                            isSelected: selectedBreed?.name == breed.name && !isCustomBreed,
                            onSelect: {
                                HapticFeedback.light()
                                selectedBreed = breed
                                isCustomBreed = false
                                sizeCategory = breed.size
                                customBreed = ""
                            }
                        )
                    }

                    // "Other" option
                    OtherBreedButton(
                        isSelected: isCustomBreed,
                        onSelect: {
                            HapticFeedback.light()
                            isCustomBreed = true
                            selectedBreed = nil
                            isCustomBreedFieldFocused = true
                        }
                    )

                    // Custom breed text field (shown when "Other" selected)
                    if isCustomBreed {
                        TextField(Strings.Onboarding.breedOptional, text: $customBreed)
                            .textFieldStyle(.roundedBorder)
                            .focused($isCustomBreedFieldFocused)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
            }

            HStack {
                OnboardingBackButton(action: onBack)
                OnboardingNextButton(enabled: selectedBreed != nil || isCustomBreed, action: onNext)
            }
        }
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(Strings.Common.done) {
                    isCustomBreedFieldFocused = false
                }
                .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Breed Selection Button

private struct BreedSelectionButton: View {
    let breed: DogBreed
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(breed.name)
                        .font(.headline)
                    Text(breed.weightRange)
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
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected
                          ? Color.accentColor.opacity(0.1)
                          : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Other Breed Button

private struct OtherBreedButton: View {
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Onboarding.otherBreed)
                        .font(.headline)
                    Text(Strings.Onboarding.enterCustom)
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
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected
                          ? Color.accentColor.opacity(0.1)
                          : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}
