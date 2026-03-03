//
//  OnboardingView.swift
//  Otis-app
//
//  Orchestrator for the onboarding flow
//

import SwiftUI
import UIKit
import OtisShared

/// Onboarding flow for new users
struct OnboardingView: View {
    @ObservedObject var profileStore: ProfileStore
    /// When true, this is adding a second profile (skip welcome/permissions)
    var isAddingProfile: Bool = false
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var locationManager: LocationManager
    let onComplete: () -> Void

    // Step state - start at step 1 (Name) when adding a profile to skip welcome
    @State private var currentStep: Int = 0

    // Profile data
    @State private var name: String = ""
    @State private var selectedBreed: Breed? = nil
    @State private var customBreed: String = ""
    @State private var isCustomBreed: Bool = false
    @State private var birthDate: Date = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()
    @State private var isExpecting: Bool = false  // true = dog hasn't arrived yet
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

    /// Whether photo step should be shown (skip if expecting puppy - will prompt when they arrive)
    private var shouldShowPhotoStep: Bool {
        !isExpecting
    }

    /// Total steps shown in progress bar (excludes welcome, size step when not needed, photo step when expecting, and permission steps)
    /// Welcome step (0) doesn't show progress, permission steps don't show progress
    /// Steps: Name(1), Breed(2), Birth(3), Status(4), Home(5), [Size(6)], [Photo(7)], Confirm(8)
    /// Permission steps (9, 10) are not counted in progress bar
    private var totalSteps: Int {
        var count = 6  // Base: Name, Breed, Birth, Status, Home, Confirm
        if shouldShowSizeStep { count += 1 }
        if shouldShowPhotoStep { count += 1 }
        return count
    }

    /// Maps the visual step (for progress indicator) to actual step
    /// Welcome step (0) and permission steps (9, 10) are not shown in progress bar
    private var visualStep: Int {
        if currentStep == 0 || currentStep >= 9 {
            return -1 // Not shown in progress bar
        }
        var adjustedStep = currentStep - 1
        // Adjust for skipped steps
        var skippedSteps = 0
        if !shouldShowSizeStep && currentStep >= 6 { skippedSteps += 1 }
        if !shouldShowPhotoStep && currentStep >= 7 { skippedSteps += 1 }
        adjustedStep -= skippedSteps
        return adjustedStep
    }

    /// Whether to show progress indicator (hidden on welcome step and permission steps)
    private var showProgress: Bool {
        currentStep > 0 && currentStep < 9
    }

    /// Whether to skip permission steps (skip when adding profile, already granted)
    private var shouldSkipPermissions: Bool {
        isAddingProfile
    }

    // MARK: - Body

    var body: some View {
        VStack {
            // Progress indicator (hidden on welcome step)
            if showProgress {
                progressIndicator
            }

            // Content - always include all steps to keep TabView structure stable
            // Steps: Welcome(0), Name(1), Breed(2), Birth(3), Status(4), Home(5), Size(6), Photo(7), Confirm(8), Notifications(9), Location(10)
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

                OnboardingStatusStep(
                    puppyName: name,
                    isExpecting: $isExpecting,
                    onNext: { navigateToStep(5) },
                    onBack: { navigateToStep(3) }
                ).tag(4)

                OnboardingHomeStep(
                    puppyName: name,
                    homeDate: $homeDate,
                    minDate: birthDate,
                    isExpecting: isExpecting,
                    onNext: {
                        // Navigate: Size(6) if custom breed, else Photo(7) if not expecting, else Confirm(8)
                        if shouldShowSizeStep {
                            navigateToStep(6)
                        } else if shouldShowPhotoStep {
                            navigateToStep(7)
                        } else {
                            navigateToStep(8)
                        }
                    },
                    onBack: { navigateToStep(4) }
                ).tag(5)

                OnboardingSizeStep(
                    puppyName: name,
                    sizeCategory: $sizeCategory,
                    onNext: {
                        // Navigate: Photo(7) if not expecting, else Confirm(8)
                        navigateToStep(shouldShowPhotoStep ? 7 : 8)
                    },
                    onBack: { navigateToStep(5) }
                ).tag(6)

                OnboardingPhotoStep(
                    puppyName: name,
                    selectedImage: $profilePhoto,
                    onNext: { navigateToStep(8) },
                    onBack: { navigateToStep(shouldShowSizeStep ? 6 : 5) }
                ).tag(7)

                OnboardingConfirmStep(
                    name: name,
                    breedToSave: breedToSave,
                    birthDate: birthDate,
                    homeDate: homeDate,
                    sizeCategory: sizeCategory,
                    profilePhoto: profilePhoto,
                    onSave: saveProfile,
                    onBack: {
                        // Navigate back: Photo(7) if shown, else Size(6) if shown, else Home(5)
                        if shouldShowPhotoStep {
                            navigateToStep(7)
                        } else if shouldShowSizeStep {
                            navigateToStep(6)
                        } else {
                            navigateToStep(5)
                        }
                    }
                ).tag(8)

                OnboardingNotificationsStep(
                    onNext: { navigateToStep(10) }
                ).tag(9)

                OnboardingLocationStep(
                    onComplete: completeOnboarding
                ).tag(10)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .easeInOut, value: currentStep)
            // Disable swiping to prevent navigating to skipped steps
            .highPriorityGesture(DragGesture())
        }
        .onAppear {
            // When adding a profile, skip the welcome step
            if isAddingProfile && currentStep == 0 {
                currentStep = 1
            }
        }
        .alert(Strings.Profile.atProfileLimit, isPresented: $showProfileLimitAlert) {
            Button(Strings.Common.ok) {
                onComplete()
            }
        } message: {
            Text(Strings.Profile.upgradeForMoreDogs)
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

    @State private var showProfileLimitAlert = false

    private func saveProfile() {
        HapticFeedback.success()

        var profile = PuppyProfile.defaultProfile(
            name: name,
            birthDate: birthDate,
            homeDate: homeDate,
            size: sizeCategory
        )

        // Set breed info
        if !breedToSave.isEmpty {
            profile.breed = breedToSave
        }
        if let breed = selectedBreed {
            profile.breedId = breed.id
        }

        // Save profile photo if selected
        if let photo = profilePhoto {
            if let filename = try? ProfilePhotoStore.shared.save(image: photo) {
                profile.profilePhotoFilename = filename
            }
        }

        if isAddingProfile {
            // Use createProfile for multi-puppy (checks subscription limits)
            let success = profileStore.createProfile(profile)
            if success {
                // Switch to the new profile
                profileStore.switchToProfile(profile.id)
                // Skip permission screens when adding a profile (already granted)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    completeOnboarding()
                }
            } else {
                // At profile limit - show error
                HapticFeedback.error()
                showProfileLimitAlert = true
            }
        } else {
            // First profile - use saveProfile
            profileStore.saveProfile(profile)

            // Navigate to permission screens after saving profile
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navigateToStep(9)
            }
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
