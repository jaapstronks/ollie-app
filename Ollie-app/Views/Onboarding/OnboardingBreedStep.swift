//
//  OnboardingBreedStep.swift
//  Otis-app
//
//  Breed selection step for onboarding with searchable breed list from TheDogAPI
//

import SwiftUI
import OtisShared

/// Breed selection step
struct OnboardingBreedStep: View {
    let puppyName: String
    @Binding var selectedBreed: Breed?
    @Binding var customBreed: String
    @Binding var isCustomBreed: Bool
    @Binding var sizeCategory: PuppyProfile.SizeCategory
    @FocusState.Binding var isCustomBreedFieldFocused: Bool
    let onNext: () -> Void
    let onBack: () -> Void

    @StateObject private var breedService = BreedService.shared
    @State private var searchQuery = ""
    @State private var hasAppeared = false
    @FocusState private var isSearchFocused: Bool

    /// Filtered breeds based on search query
    private var filteredBreeds: [Breed] {
        breedService.searchBreeds(query: searchQuery)
    }

    /// Popular breeds to show when no search query (first 15)
    private var popularBreeds: [Breed] {
        Array(breedService.breeds.prefix(15))
    }

    /// Breeds to display - either search results or popular breeds
    private var displayedBreeds: [Breed] {
        searchQuery.isEmpty ? popularBreeds : filteredBreeds
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "dog.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.otisAccent)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.Onboarding.breedQuestion(name: puppyName))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.Onboarding.breedSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .opacity(hasAppeared ? 1.0 : 0.0)
            }
            .padding(.top, 8)
            .padding(.bottom, 16)

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(Strings.Onboarding.searchBreeds, text: $searchQuery)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .focused($isSearchFocused)
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            .opacity(hasAppeared ? 1.0 : 0.0)

            // Breed list
            if breedService.isLoading && breedService.breeds.isEmpty {
                Spacer()
                ProgressView()
                    .padding()
                Text(Strings.Common.loading)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        // Show search hint if no results
                        if displayedBreeds.isEmpty && !searchQuery.isEmpty {
                            Text(Strings.Onboarding.noBreedResults)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 20)
                        }

                        // Breed buttons
                        ForEach(Array(displayedBreeds.enumerated()), id: \.element.id) { index, breed in
                            BreedSelectionButton(
                                breed: breed,
                                isSelected: selectedBreed?.id == breed.id && !isCustomBreed,
                                onSelect: {
                                    HapticFeedback.light()
                                    selectedBreed = breed
                                    isCustomBreed = false
                                    sizeCategory = breed.weightRange.sizeCategory
                                    customBreed = ""
                                    isSearchFocused = false
                                }
                            )
                            .opacity(hasAppeared ? 1.0 : 0.0)
                            .offset(y: hasAppeared ? 0 : 15)
                            .animation(.easeOut(duration: 0.4).delay(Double(min(index, 10)) * 0.02), value: hasAppeared)
                        }

                        // "Other" option
                        OtherBreedButton(
                            isSelected: isCustomBreed,
                            onSelect: {
                                HapticFeedback.light()
                                isCustomBreed = true
                                selectedBreed = nil
                                isCustomBreedFieldFocused = true
                                isSearchFocused = false
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

                        // Show total breed count hint
                        if searchQuery.isEmpty && breedService.breeds.count > popularBreeds.count {
                            Text(Strings.Onboarding.searchForMore(count: breedService.breeds.count))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }

            // Buttons
            HStack(spacing: 12) {
                OnboardingBackButton(action: onBack)
                OnboardingNextButton(enabled: selectedBreed != nil || isCustomBreed, action: onNext)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .opacity(hasAppeared ? 1.0 : 0.0)

            Button {
                selectedBreed = nil
                isCustomBreed = false
                customBreed = ""
                isSearchFocused = false
                isCustomBreedFieldFocused = false
                onNext()
            } label: {
                Text(Strings.Onboarding.skipForNow)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 16)
            .opacity(hasAppeared ? 1.0 : 0.0)
        }
        .task {
            // Fetch breeds on appear
            await breedService.fetchBreeds()
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
                    isSearchFocused = false
                }
                .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Breed Selection Button

private struct BreedSelectionButton: View {
    let breed: Breed
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(breed.name)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(breed.weightRange.displayString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
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
