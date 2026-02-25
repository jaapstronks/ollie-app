//
//  MealSchedule.swift
//  OllieShared
//

import Foundation

/// Configurable meal schedule for a puppy
public struct MealSchedule: Codable, Sendable {
    public var mealsPerDay: Int
    public var portions: [MealPortion]

    public init(mealsPerDay: Int, portions: [MealPortion]) {
        self.mealsPerDay = mealsPerDay
        self.portions = portions
    }

    public struct MealPortion: Codable, Identifiable, Sendable {
        public var id: UUID
        public var label: String
        public var amount: String
        public var targetTime: String?

        public init(id: UUID = UUID(), label: String, amount: String, targetTime: String? = nil) {
            self.id = id
            self.label = label
            self.amount = amount
            self.targetTime = targetTime
        }
    }

    /// Default schedule based on age in weeks and size
    public static func defaultSchedule(ageWeeks: Int, size: PuppyProfile.SizeCategory) -> MealSchedule {
        let baseAmount: String
        switch size {
        case .small:
            baseAmount = "50g"
        case .medium:
            baseAmount = "80g"
        case .large:
            baseAmount = "110g"
        case .extraLarge:
            baseAmount = "140g"
        }

        if ageWeeks < 12 {
            return MealSchedule(
                mealsPerDay: 4,
                portions: [
                    MealPortion(label: Strings.Meals.breakfast, amount: baseAmount, targetTime: "07:00"),
                    MealPortion(label: Strings.Meals.lunch, amount: baseAmount, targetTime: "11:00"),
                    MealPortion(label: Strings.Meals.afternoon, amount: baseAmount, targetTime: "15:00"),
                    MealPortion(label: Strings.Meals.evening, amount: baseAmount, targetTime: "19:00")
                ]
            )
        } else if ageWeeks < 24 {
            return MealSchedule(
                mealsPerDay: 3,
                portions: [
                    MealPortion(label: Strings.Meals.breakfast, amount: baseAmount, targetTime: "07:00"),
                    MealPortion(label: Strings.Meals.afternoon, amount: baseAmount, targetTime: "13:00"),
                    MealPortion(label: Strings.Meals.evening, amount: baseAmount, targetTime: "19:00")
                ]
            )
        } else {
            return MealSchedule(
                mealsPerDay: 2,
                portions: [
                    MealPortion(label: Strings.Meals.morning, amount: baseAmount, targetTime: "07:00"),
                    MealPortion(label: Strings.Meals.evening, amount: baseAmount, targetTime: "18:00")
                ]
            )
        }
    }
}
