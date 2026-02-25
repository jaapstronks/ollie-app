//
//  OnboardingView.swift
//  Ollie-app
//
//  Orchestrator for the onboarding flow
//

import SwiftUI
import OllieShared

/// Onboarding flow for new users
struct OnboardingView: View {
    @ObservedObject var profileStore: ProfileStore
    let onComplete: () -> Void

    // Step state
    @State private var currentStep: Int = 0

    // Profile data
    @State private var name: String = ""
    @State private var selectedBreed: DogBreed? = nil
    @State private var customBreed: String = ""
    @State private var isCustomBreed: Bool = false
    @State private var birthDate: Date = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()
    @State private var homeDate: Date = Date()
    @State private var sizeCategory: PuppyProfile.SizeCategory = .large

    // Focus state for keyboard management
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isCustomBreedFieldFocused: Bool

    // Accessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Computed Properties

    /// The breed string to save
    private var breedToSave: String {
        if isCustomBreed {
            return customBreed
        } else if let breed = selectedBreed {
            return breed.name
        }
        return ""
    }

    /// Whether size step should be shown (only for custom breeds)
    private var shouldShowSizeStep: Bool {
        isCustomBreed
    }

    /// Total steps shown in progress bar (excludes welcome and size step when not needed)
    /// Welcome step (0) doesn't show progress, so we count from step 1 onwards
    private var totalSteps: Int {
        shouldShowSizeStep ? 6 : 5
    }

    /// Maps the visual step (for progress indicator) to actual step
    /// Welcome step (0) is not shown in progress bar
    private var visualStep: Int {
        if currentStep == 0 {
            return -1 // Not shown in progress bar
        }
        let adjustedStep = currentStep - 1
        if !shouldShowSizeStep && currentStep == 6 {
            return 4
        }
        return adjustedStep
    }

    /// Whether to show progress indicator (hidden on welcome step)
    private var showProgress: Bool {
        currentStep > 0
    }

    // MARK: - Body

    var body: some View {
        VStack {
            // Progress indicator (hidden on welcome step)
            if showProgress {
                progressIndicator
            }

            // Content - always include all steps to keep TabView structure stable
            TabView(selection: $currentStep) {
                OnboardingWelcomeStep(
                    onNext: { navigateToStep(1) }
                ).tag(0)

                OnboardingNameStep(
                    name: $name,
                    isNameFieldFocused: $isNameFieldFocused,
                    onNext: { navigateToStep(2) }
                ).tag(1)

                OnboardingBreedStep(
                    puppyName: name,
                    selectedBreed: $selectedBreed,
                    customBreed: $customBreed,
                    isCustomBreed: $isCustomBreed,
                    sizeCategory: $sizeCategory,
                    isCustomBreedFieldFocused: $isCustomBreedFieldFocused,
                    onNext: { navigateToStep(3) },
                    onBack: { navigateToStep(1) }
                ).tag(2)

                OnboardingBirthStep(
                    puppyName: name,
                    birthDate: $birthDate,
                    onNext: { navigateToStep(4) },
                    onBack: { navigateToStep(2) }
                ).tag(3)

                OnboardingHomeStep(
                    puppyName: name,
                    homeDate: $homeDate,
                    minDate: birthDate,
                    onNext: { navigateToStep(shouldShowSizeStep ? 5 : 6) },
                    onBack: { navigateToStep(3) }
                ).tag(4)

                OnboardingSizeStep(
                    puppyName: name,
                    sizeCategory: $sizeCategory,
                    onNext: { navigateToStep(6) },
                    onBack: { navigateToStep(4) }
                ).tag(5)

                OnboardingConfirmStep(
                    name: name,
                    breedToSave: breedToSave,
                    birthDate: birthDate,
                    homeDate: homeDate,
                    sizeCategory: sizeCategory,
                    onSave: saveProfile,
                    onBack: { navigateToStep(shouldShowSizeStep ? 5 : 4) }
                ).tag(6)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .easeInOut, value: currentStep)
            // Disable swiping to prevent navigating to skipped steps
            .highPriorityGesture(DragGesture())
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= visualStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding()
        .animation(reduceMotion ? nil : .easeInOut, value: totalSteps)
    }

    // MARK: - Navigation

    private func navigateToStep(_ step: Int) {
        dismissKeyboard()
        if reduceMotion {
            currentStep = step
        } else {
            withAnimation {
                currentStep = step
            }
        }
    }

    private func dismissKeyboard() {
        isNameFieldFocused = false
        isCustomBreedFieldFocused = false
    }

    // MARK: - Save Profile

    private func saveProfile() {
        HapticFeedback.success()

        var profile = PuppyProfile.defaultProfile(
            name: name,
            birthDate: birthDate,
            homeDate: homeDate,
            size: sizeCategory
        )
        if !breedToSave.isEmpty {
            profile.breed = breedToSave
        }
        profileStore.saveProfile(profile)

        // Small delay to ensure profile is saved before completing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onComplete()
        }
    }
}

#Preview {
    OnboardingView(profileStore: ProfileStore()) {
        print("Onboarding complete")
    }
}
