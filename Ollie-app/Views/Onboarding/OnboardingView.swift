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

    // Step state - default to Name step for faster time-to-value
    @State private var currentStep: Int = 1

    // Awaiting invite state (for family members joining existing profile)
    @AppStorage(UserPreferences.Key.isAwaitingInvite.rawValue) private var isAwaitingInvite = false

    // Profile data
    @State private var name: String = ""
    @State private var selectedBreed: Breed? = nil
    @State private var customBreed: String = ""
    @State private var isCustomBreed: Bool = false
    @State private var selectedCoatType: CoatType? = nil
    @State private var birthDate: Date = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()
    @State private var isExpecting: Bool = false  // true = dog hasn't arrived yet
    @State private var homeDate: Date = Date()
    @State private var sizeCategory: PuppyProfile.SizeCategory = .large
    @State private var gender: PuppyProfile.Gender = .unspecified
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

    /// Suggested coat type based on selected breed
    private var suggestedCoatType: CoatType? {
        CoatType.suggested(for: breedToSave)
    }

    /// Whether coat type step should be shown (show if breed was selected, skip if custom/unknown)
    private var shouldShowCoatTypeStep: Bool {
        selectedBreed != nil || !customBreed.isEmpty
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
    /// Steps: Name(1), Breed(2), [CoatType(3)], Birth(4), Gender(5), Status(6), Home(7), [Size(8)], [Photo(9)], Confirm(10)
    /// Permission steps (11, 12, 13, 14) are not counted in progress bar
    private var totalSteps: Int {
        var count = 7  // Base: Name, Breed, Birth, Gender, Status, Home, Confirm
        if shouldShowCoatTypeStep { count += 1 }
        if shouldShowSizeStep { count += 1 }
        if shouldShowPhotoStep { count += 1 }
        return count
    }

    /// Maps the visual step (for progress indicator) to actual step
    /// Welcome step (0) and permission steps (11+) are not shown in progress bar
    private var visualStep: Int {
        if currentStep == 0 || currentStep >= 11 {
            return -1 // Not shown in progress bar
        }
        var adjustedStep = currentStep - 1
        // Adjust for skipped steps
        var skippedSteps = 0
        if !shouldShowCoatTypeStep && currentStep >= 3 { skippedSteps += 1 }
        if !shouldShowSizeStep && currentStep >= 8 { skippedSteps += 1 }
        if !shouldShowPhotoStep && currentStep >= 9 { skippedSteps += 1 }
        adjustedStep -= skippedSteps
        return adjustedStep
    }

    /// Whether to show progress indicator (hidden on welcome step and permission steps)
    private var showProgress: Bool {
        currentStep > 0 && currentStep < 11
    }

    /// Whether to skip permission steps (skip when adding profile, already granted)
    private var shouldSkipPermissions: Bool {
        isAddingProfile
    }

    // MARK: - Body

    var body: some View {
        // Show awaiting invite view if user chose to join existing profile
        if isAwaitingInvite && !isAddingProfile {
            AwaitingInviteView(
                onCreateOwnProfile: {
                    isAwaitingInvite = false
                    currentStep = 0
                }
            )
            .onReceive(NotificationCenter.default.publisher(for: .cloudKitShareAccepted)) { _ in
                // Share was accepted - complete onboarding
                isAwaitingInvite = false
                onComplete()
            }
        } else {
            onboardingFlow
        }
    }

    // MARK: - Onboarding Flow

    @ViewBuilder
    private var onboardingFlow: some View {
        VStack {
            // Cancel button when adding a profile (user already has dogs)
            if isAddingProfile {
                HStack {
                    Button {
                        onComplete()
                    } label: {
                        Text(Strings.Common.cancel)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading)
                    Spacer()
                }
                .padding(.top, 8)
            }

            // Progress indicator (hidden on welcome step)
            if showProgress {
                progressIndicator
            }

            // Content - always include all steps to keep TabView structure stable
            // Steps: Welcome(0), Name(1), Breed(2), [CoatType(3)], Birth(4), Gender(5), Status(6), Home(7), [Size(8)], [Photo(9)], Confirm(10), Notifications(11), Location(12), UserProfile(13), Trial(14)
            TabView(selection: $currentStep) {
                OnboardingWelcomeStep(
                    onNext: { navigateToStep(1) },
                    onJoinExisting: {
                        isAwaitingInvite = true
                    }
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
                    onNext: {
                        // Navigate: CoatType(3) if breed selected, else Birth(4)
                        navigateToStep(shouldShowCoatTypeStep ? 3 : 4)
                    },
                    onBack: { navigateToStep(1) }
                ).tag(2)

                OnboardingCoatTypeStep(
                    puppyName: name,
                    suggestedCoatType: suggestedCoatType,
                    selectedCoatType: $selectedCoatType,
                    onNext: { navigateToStep(4) },
                    onBack: { navigateToStep(2) }
                ).tag(3)

                OnboardingBirthStep(
                    puppyName: name,
                    birthDate: $birthDate,
                    onNext: { navigateToStep(5) },
                    onBack: { navigateToStep(shouldShowCoatTypeStep ? 3 : 2) }
                ).tag(4)

                OnboardingGenderStep(
                    puppyName: name,
                    gender: $gender,
                    onNext: { navigateToStep(6) },
                    onBack: { navigateToStep(4) }
                ).tag(5)

                OnboardingStatusStep(
                    puppyName: name,
                    isExpecting: $isExpecting,
                    onNext: { navigateToStep(7) },
                    onBack: { navigateToStep(5) }
                ).tag(6)

                OnboardingHomeStep(
                    puppyName: name,
                    homeDate: $homeDate,
                    minDate: birthDate,
                    isExpecting: isExpecting,
                    onNext: {
                        // Navigate: Size(8) if custom breed, else Photo(9) if not expecting, else Confirm(10)
                        if shouldShowSizeStep {
                            navigateToStep(8)
                        } else if shouldShowPhotoStep {
                            navigateToStep(9)
                        } else {
                            navigateToStep(10)
                        }
                    },
                    onBack: { navigateToStep(6) }
                ).tag(7)

                OnboardingSizeStep(
                    puppyName: name,
                    sizeCategory: $sizeCategory,
                    onNext: {
                        // Navigate: Photo(9) if not expecting, else Confirm(10)
                        navigateToStep(shouldShowPhotoStep ? 9 : 10)
                    },
                    onBack: { navigateToStep(7) }
                ).tag(8)

                OnboardingPhotoStep(
                    puppyName: name,
                    selectedImage: $profilePhoto,
                    onNext: { navigateToStep(10) },
                    onBack: { navigateToStep(shouldShowSizeStep ? 8 : 7) }
                ).tag(9)

                OnboardingConfirmStep(
                    name: name,
                    breedToSave: breedToSave,
                    birthDate: birthDate,
                    homeDate: homeDate,
                    sizeCategory: sizeCategory,
                    gender: gender,
                    profilePhoto: profilePhoto,
                    onSave: saveProfile,
                    onBack: {
                        // Navigate back: Photo(9) if shown, else Size(8) if shown, else Home(7)
                        if shouldShowPhotoStep {
                            navigateToStep(9)
                        } else if shouldShowSizeStep {
                            navigateToStep(8)
                        } else {
                            navigateToStep(7)
                        }
                    }
                ).tag(10)

                OnboardingNotificationsStep(
                    onNext: { navigateToStep(12) }
                ).tag(11)

                OnboardingLocationStep(
                    onComplete: { navigateToStep(13) }
                ).tag(12)

                OnboardingUserProfileStep(
                    onNext: { navigateToStep(14) },
                    onSkip: { navigateToStep(14) }
                ).tag(13)

                OnboardingTrialStartStep(
                    puppyName: name,
                    onStartTrial: {
                        TrialManager.shared.startTrial()
                        completeOnboarding()
                    },
                    onSkip: {
                        TrialManager.shared.declineTrial()
                        completeOnboarding()
                    }
                ).tag(14)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .easeInOut, value: currentStep)
            // Disable swiping to prevent navigating to skipped steps
            .highPriorityGesture(DragGesture())
        }
        .onAppear {
            // Keep add-profile flow aligned with first profile flow: jump directly to Name.
            if currentStep == 0 {
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
            size: sizeCategory,
            gender: gender
        )

        // Set breed info
        if !breedToSave.isEmpty {
            profile.breed = breedToSave
        }
        if let breed = selectedBreed {
            profile.breedId = breed.id
        }

        // Set coat type if selected
        if let coatType = selectedCoatType {
            profile.coatType = coatType
        }

        // Save profile photo if selected (with CloudKit sync)
        if let photo = profilePhoto {
            Task {
                if let filename = try? await ProfilePhotoStore.shared.save(image: photo, for: profile.id) {
                    await MainActor.run {
                        profileStore.updateProfilePhoto(filename, for: profile.id)
                    }
                }
            }
        }

        if isAddingProfile {
            // Use createProfile for multi-puppy (checks subscription limits)
            let success = profileStore.createProfile(profile)
            if success {
                // Switch to the new profile
                profileStore.switchToProfile(profile.id)
                // Skip permission screens when adding a profile (already granted)
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.1))
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
            Analytics.trackProfileCreated(
                profileId: profile.id,
                hasBreed: !breedToSave.isEmpty,
                hasPhoto: profilePhoto != nil,
                isExpecting: isExpecting,
                usedCustomBreed: isCustomBreed
            )

            // Navigate to permission screens after saving profile
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.1))
                navigateToStep(11)
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
