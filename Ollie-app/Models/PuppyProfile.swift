//
//  PuppyProfile.swift
//  Ollie-app
//

import Foundation

/// Profile for a puppy, configurable by the user
struct PuppyProfile: Codable {
    var name: String
    var breed: String?
    var birthDate: Date
    var homeDate: Date
    var sizeCategory: SizeCategory
    var mealSchedule: MealSchedule
    var exerciseConfig: ExerciseConfig
    var predictionConfig: PredictionConfig

    enum SizeCategory: String, Codable, CaseIterable, Identifiable {
        case small
        case medium
        case large
        case extraLarge

        var id: String { rawValue }

        var label: String {
            switch self {
            case .small: return "Klein (<10kg)"
            case .medium: return "Middel (10-25kg)"
            case .large: return "Groot (25-45kg)"
            case .extraLarge: return "Extra groot (>45kg)"
            }
        }

        var examples: String {
            switch self {
            case .small: return "Chihuahua, Maltezer, Yorkshire Terrier"
            case .medium: return "Beagle, Cocker Spaniel, Border Collie"
            case .large: return "Labrador, Golden Retriever, Duitse Herder"
            case .extraLarge: return "Berner Sennen, Deense Dog, Sint Bernard"
            }
        }
    }

    /// Age in weeks from birth date
    var ageInWeeks: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: birthDate, to: Date())
        return components.weekOfYear ?? 0
    }

    /// Age in months (approximate)
    var ageInMonths: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: birthDate, to: Date())
        return components.month ?? 0
    }

    /// Days since coming home
    var daysHome: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: homeDate, to: Date())
        return components.day ?? 0
    }

    /// Maximum exercise minutes based on age
    var maxExerciseMinutes: Int {
        ageInMonths * exerciseConfig.minutesPerMonthOfAge
    }

    /// Creates a default profile for onboarding
    static func defaultProfile(name: String, birthDate: Date, homeDate: Date, size: SizeCategory) -> PuppyProfile {
        let ageWeeks = Calendar.current.dateComponents([.weekOfYear], from: birthDate, to: Date()).weekOfYear ?? 8

        return PuppyProfile(
            name: name,
            breed: nil,
            birthDate: birthDate,
            homeDate: homeDate,
            sizeCategory: size,
            mealSchedule: MealSchedule.defaultSchedule(ageWeeks: ageWeeks, size: size),
            exerciseConfig: ExerciseConfig.defaultConfig(),
            predictionConfig: PredictionConfig.defaultConfig()
        )
    }
}
