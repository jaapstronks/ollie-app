//
//  OnboardingHelpers.swift
//  Ollie-app
//
//  Helper types and views for onboarding flow
//

import SwiftUI

// MARK: - Dog Breed

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

// MARK: - Profile Row

/// Simple key-value row for profile summary display
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

// MARK: - Date Formatting

/// Format date for display in onboarding confirmation
func formatOnboardingDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "nl_NL")
    formatter.dateStyle = .long
    return formatter.string(from: date)
}
