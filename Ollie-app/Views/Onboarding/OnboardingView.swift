//
//  OnboardingView.swift
//  Ollie-app
//
//  Orchestrator for the onboarding flow
//

import SwiftUI
import UIKit
import OllieShared

/// Onboarding flow for new users
struct OnboardingView: View {
    @ObservedObject var profileStore: ProfileStore
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var locationManager: LocationManager
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
    @State private var profilePhoto: UIImage? = nil

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

    /// Total steps shown in progress bar (excludes welcome, size step when not needed, and permission steps)
    /// Welcome step (0) doesn't show progress, permission steps don't show progress
    /// Steps: Name(1), Breed(2), Birth(3), Home(4), [Size(5)], Photo(6), Confirm(7)
    /// Permission steps (8, 9) are not counted in progress bar
    private var totalSteps: Int {
        shouldShowSizeStep ? 7 : 6
    }

    /// Maps the visual step (for progress indicator) to actual step
    /// Welcome step (0) and permission steps (8, 9) are not shown in progress bar
    private var visualStep: Int {
        if currentStep == 0 || currentStep >= 8 {
            return -1 // Not shown in progress bar
        }
        var adjustedStep = currentStep - 1
        // Adjust for skipped size step
        if !shouldShowSizeStep && currentStep >= 6 {
            adjustedStep = currentStep - 2
        }
        return adjustedStep
    }

    /// Whether to show progress indicator (hidden on welcome step and permission steps)
    private var showProgress: Bool {
        currentStep > 0 && currentStep < 8
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

                OnboardingPhotoStep(
                    puppyName: name,
                    selectedImage: $profilePhoto,
                    onNext: { navigateToStep(7) },
                    onBack: { navigateToStep(shouldShowSizeStep ? 5 : 4) }
                ).tag(6)

                OnboardingConfirmStep(
                    name: name,
                    breedToSave: breedToSave,
                    birthDate: birthDate,
                    homeDate: homeDate,
                    sizeCategory: sizeCategory,
                    profilePhoto: profilePhoto,
                    onSave: saveProfile,
                    onBack: { navigateToStep(6) }
                ).tag(7)

                OnboardingNotificationsStep(
                    onNext: { navigateToStep(9) }
                ).tag(8)

                OnboardingLocationStep(
                    onComplete: completeOnboarding
                ).tag(9)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Onboarding.progressAccessibility)
        .accessibilityValue(Strings.Onboarding.progressValue(current: visualStep + 1, total: totalSteps))
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

        // Save profile photo if selected
        if let photo = profilePhoto {
            if let filename = try? ProfilePhotoStore.shared.save(image: photo) {
                profile.profilePhotoFilename = filename
            }
        }

        profileStore.saveProfile(profile)

        // Navigate to permission screens after saving profile
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            navigateToStep(8)
        }
    }

    // MARK: - Complete Onboarding

    private func completeOnboarding() {
        onComplete()
    }
}

#Preview {
    OnboardingView(profileStore: ProfileStore()) {
        print("Onboarding complete")
    }
    .environmentObject(NotificationService())
    .environmentObject(LocationManager())
}
