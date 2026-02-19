//
//  MealSchedule.swift
//  Ollie-app
//

import Foundation

/// Configurable meal schedule for a puppy
struct MealSchedule: Codable {
    var mealsPerDay: Int
    var portions: [MealPortion]

    struct MealPortion: Codable, Identifiable {
        var id: UUID
        var label: String
        var amount: String
        var targetTime: String?

        init(id: UUID = UUID(), label: String, amount: String, targetTime: String? = nil) {
            self.id = id
            self.label = label
            self.amount = amount
            self.targetTime = targetTime
        }
    }

    /// Default schedule based on age in weeks and size
    static func defaultSchedule(ageWeeks: Int, size: PuppyProfile.SizeCategory) -> MealSchedule {
        // Puppies < 12 weeks: 4 meals/day
        // Puppies 12-24 weeks: 3 meals/day
        // Puppies > 24 weeks: 2 meals/day

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
                    MealPortion(label: "Ontbijt", amount: baseAmount, targetTime: "07:00"),
                    MealPortion(label: "Lunch", amount: baseAmount, targetTime: "11:00"),
                    MealPortion(label: "Middag", amount: baseAmount, targetTime: "15:00"),
                    MealPortion(label: "Avond", amount: baseAmount, targetTime: "19:00")
                ]
            )
        } else if ageWeeks < 24 {
            return MealSchedule(
                mealsPerDay: 3,
                portions: [
                    MealPortion(label: "Ontbijt", amount: baseAmount, targetTime: "07:00"),
                    MealPortion(label: "Middag", amount: baseAmount, targetTime: "13:00"),
                    MealPortion(label: "Avond", amount: baseAmount, targetTime: "19:00")
                ]
            )
        } else {
            return MealSchedule(
                mealsPerDay: 2,
                portions: [
                    MealPortion(label: "Ochtend", amount: baseAmount, targetTime: "07:00"),
                    MealPortion(label: "Avond", amount: baseAmount, targetTime: "18:00")
                ]
            )
        }
    }
}
