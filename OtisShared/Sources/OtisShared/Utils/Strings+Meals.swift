//
//  Strings+Meals.swift
//  OtisShared
//
//  Meal-related strings for the meal scheduler and tracking.
//

import Foundation

extension Strings {
    // MARK: - Meals
    public enum Meals {
        public static var title: String { String(localized: "Edit meals", bundle: Strings.bundle) }
        public static var numberOfMeals: String { String(localized: "Number of meals", bundle: Strings.bundle) }
        public static var mealsPerDay: String { String(localized: "Meals per day", bundle: Strings.bundle) }
        public static func perDay(_ count: Int) -> String {
            String(localized: "\(count)x per day", bundle: Strings.bundle)
        }
        public static var mealsSection: String { String(localized: "Meals", bundle: Strings.bundle) }
        public static var name: String { String(localized: "Name", bundle: Strings.bundle) }
        public static var amount: String { String(localized: "Amount", bundle: Strings.bundle) }
        public static var amountExample: String { String(localized: "e.g. 80g", bundle: Strings.bundle) }
        public static var time: String { String(localized: "Time", bundle: Strings.bundle) }
        public static var breakfast: String { String(localized: "Breakfast", bundle: Strings.bundle) }
        public static var lunch: String { String(localized: "Lunch", bundle: Strings.bundle) }
        public static var afternoon: String { String(localized: "Afternoon", bundle: Strings.bundle) }
        public static var dinner: String { String(localized: "Dinner", bundle: Strings.bundle) }
        public static var morning: String { String(localized: "Morning", bundle: Strings.bundle) }
        public static var evening: String { String(localized: "Evening", bundle: Strings.bundle) }
        public static func mealNumber(_ n: Int) -> String {
            String(localized: "Meal \(n)", bundle: Strings.bundle)
        }
    }
}
