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

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "dog.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.ollieAccent)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.Onboarding.breedQuestion(name: puppyName))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)
            }
            .padding(.top, 8)
            .padding(.bottom, 16)

            // Breed list
            ScrollView {
                VStack(spacing: 10) {
                    // Predefined breeds
                    ForEach(Array(DogBreed.breeds.enumerated()), id: \.element.id) { index, breed in
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
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .offset(y: hasAppeared ? 0 : 15)
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.03), value: hasAppeared)
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
                    .opacity(hasAppeared ? 1.0 : 0.0)

                    // Custom breed text field (shown when "Other" selected)
                    if isCustomBreed {
                        OnboardingTextField(
                            placeholder: Strings.Onboarding.breedOptional,
                            text: $customBreed,
                            isFocused: $isCustomBreedFieldFocused
                        )
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)

            // Buttons
            HStack(spacing: 12) {
                OnboardingBackButton(action: onBack)
                OnboardingNextButton(enabled: selectedBreed != nil || isCustomBreed, action: onNext)
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
                VStack(alignment: .leading, spacing: 4) {
                    Text(breed.name)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(breed.weightRange)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.ollieAccent : Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.ollieAccent.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.ollieAccent.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Other Breed Button

private struct OtherBreedButton: View {
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.Onboarding.otherBreed)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(Strings.Onboarding.enterCustom)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.ollieAccent : Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.ollieAccent.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.ollieAccent.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
