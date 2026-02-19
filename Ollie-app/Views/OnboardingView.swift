//
//  OnboardingView.swift
//  Ollie-app
//

import SwiftUI

/// Predefined dog breeds with their typical size categories
struct DogBreed: Identifiable {
    let id = UUID()
    let name: String
    let size: PuppyProfile.SizeCategory
    let weightRange: String

    static let breeds: [DogBreed] = [
        DogBreed(name: "Golden Retriever", size: .large, weightRange: "25-40 kg"),
        DogBreed(name: "Labrador Retriever", size: .large, weightRange: "25-36 kg"),
        DogBreed(name: "Duitse Herder", size: .large, weightRange: "22-40 kg"),
        DogBreed(name: "Franse Bulldog", size: .medium, weightRange: "8-14 kg"),
        DogBreed(name: "Beagle", size: .medium, weightRange: "9-11 kg"),
        DogBreed(name: "Cavalier King Charles", size: .small, weightRange: "5-8 kg"),
        DogBreed(name: "Border Collie", size: .medium, weightRange: "14-20 kg"),
        DogBreed(name: "Jack Russell Terrier", size: .small, weightRange: "5-8 kg"),
        DogBreed(name: "Cocker Spaniel", size: .medium, weightRange: "12-16 kg"),
        DogBreed(name: "Berner Sennenhond", size: .extraLarge, weightRange: "35-55 kg"),
    ]
}

/// Onboarding flow for new users
struct OnboardingView: View {
    @ObservedObject var profileStore: ProfileStore
    let onComplete: () -> Void

    @State private var currentStep: Int = 0
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

    /// Total steps (5 if custom breed needs size selection, 4 otherwise)
    private var totalSteps: Int {
        shouldShowSizeStep ? 6 : 5
    }

    var body: some View {
        VStack {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding()
            .animation(.easeInOut, value: totalSteps)

            // Content
            TabView(selection: $currentStep) {
                nameStep.tag(0)
                breedStep.tag(1)
                birthStep.tag(2)
                homeStep.tag(3)
                if shouldShowSizeStep {
                    sizeStep.tag(4)
                    confirmStep.tag(5)
                } else {
                    confirmStep.tag(4)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
    }

    // MARK: - Steps

    private var nameStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            Text("Hoe heet je puppy?")
                .font(.title)
                .fontWeight(.bold)

            TextField("Naam", text: $name)
                .textFieldStyle(.roundedBorder)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .focused($isNameFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    dismissKeyboard()
                }

            Spacer()

            nextButton(enabled: !name.isEmpty)
        }
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Volgende") {
                    if !name.isEmpty {
                        dismissKeyboard()
                        currentStep = 1
                    } else {
                        dismissKeyboard()
                    }
                }
                .fontWeight(.semibold)
            }
        }
    }

    private var breedStep: some View {
        VStack(spacing: 16) {
            Text("🐕")
                .font(.system(size: 60))

            Text("Wat voor ras is \(name)?")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 10) {
                    // Predefined breeds
                    ForEach(DogBreed.breeds) { breed in
                        Button {
                            HapticFeedback.light()
                            selectedBreed = breed
                            isCustomBreed = false
                            sizeCategory = breed.size
                            customBreed = ""
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(breed.name)
                                        .font(.headline)
                                    Text(breed.weightRange)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedBreed?.name == breed.name && !isCustomBreed {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedBreed?.name == breed.name && !isCustomBreed
                                          ? Color.accentColor.opacity(0.1)
                                          : Color(.secondarySystemBackground))
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // "Other" option
                    Button {
                        HapticFeedback.light()
                        isCustomBreed = true
                        selectedBreed = nil
                        isCustomBreedFieldFocused = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Anders / Onbekend")
                                    .font(.headline)
                                Text("Vul zelf in")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if isCustomBreed {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isCustomBreed
                                      ? Color.accentColor.opacity(0.1)
                                      : Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)

                    // Custom breed text field (shown when "Other" selected)
                    if isCustomBreed {
                        TextField("Ras (optioneel)", text: $customBreed)
                            .textFieldStyle(.roundedBorder)
                            .focused($isCustomBreedFieldFocused)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
            }

            HStack {
                backButton
                nextButton(enabled: selectedBreed != nil || isCustomBreed)
            }
        }
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Klaar") {
                    dismissKeyboard()
                }
                .fontWeight(.semibold)
            }
        }
    }

    private func dismissKeyboard() {
        isNameFieldFocused = false
        isCustomBreedFieldFocused = false
    }

    private var birthStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🎂")
                .font(.system(size: 60))

            Text("Wanneer is \(name) geboren?")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            DatePicker(
                "Geboortedatum",
                selection: $birthDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal)

            Spacer()

            HStack {
                backButton
                nextButton(enabled: true)
            }
        }
        .padding()
    }

    private var homeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🏠")
                .font(.system(size: 60))

            Text("Wanneer kwam \(name) thuis?")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            DatePicker(
                "Thuiskomst",
                selection: $homeDate,
                in: birthDate...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal)

            Spacer()

            HStack {
                backButton
                nextButton(enabled: true)
            }
        }
        .padding()
    }

    private var sizeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("📏")
                .font(.system(size: 60))

            Text("Hoe groot wordt \(name)?")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(PuppyProfile.SizeCategory.allCases) { size in
                    Button {
                        sizeCategory = size
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(size.label)
                                    .font(.headline)
                                Text(size.examples)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if sizeCategory == size {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(sizeCategory == size ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                backButton
                nextButton(enabled: true)
            }
        }
        .padding()
    }

    private var confirmStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🎉")
                .font(.system(size: 60))

            Text("Klaar om te beginnen!")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                ProfileRow(label: "Naam", value: name)
                if !breedToSave.isEmpty {
                    ProfileRow(label: "Ras", value: breedToSave)
                }
                ProfileRow(label: "Geboren", value: formatDate(birthDate))
                ProfileRow(label: "Thuisgekomen", value: formatDate(homeDate))
                ProfileRow(label: "Grootte", value: sizeCategory.label)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()

            HStack {
                backButton

                Button {
                    saveProfile()
                } label: {
                    Text("Start!")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private func nextButton(enabled: Bool) -> some View {
        Button {
            withAnimation {
                currentStep += 1
            }
        } label: {
            Text("Volgende")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(enabled ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .disabled(!enabled)
    }

    private var backButton: some View {
        Button {
            withAnimation {
                currentStep -= 1
            }
        } label: {
            Text("Terug")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .foregroundColor(.primary)
                .cornerRadius(12)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

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

struct ProfileRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    OnboardingView(profileStore: ProfileStore()) {
        print("Onboarding complete")
    }
}
