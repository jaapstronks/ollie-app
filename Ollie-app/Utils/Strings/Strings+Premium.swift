//
//  Strings+Premium.swift
//  Ollie-app
//
//  Premium and Siri strings

import Foundation

private let table = "Premium"

extension Strings {

    // MARK: - Siri & Shortcuts
    enum Siri {
        // Settings section
        static let sectionTitle = String(localized: "Siri & Shortcuts", table: table)
        static let helpTitle = String(localized: "Voice Commands", table: table)
        static let helpDescription = String(localized: "Use Siri to log events and check on your puppy hands-free. Say \"Hey Siri\" followed by a command.", table: table)
        static let exampleCommands = String(localized: "Example commands:", table: table)
        static let examplePeedOutside = String(localized: "My puppy peed outside in Ollie", table: table)
        static let exampleSleeping = String(localized: "My puppy is sleeping in Ollie", table: table)
        static let exampleStatus = String(localized: "How is my puppy in Ollie", table: table)
        static let openShortcuts = String(localized: "Open Shortcuts App", table: table)
        static let openShortcutsDescription = String(localized: "See all Ollie shortcuts", table: table)
        static let helpFooter = String(localized: "Siri will respond using your puppy's name from your profile.", table: table)

        // Intent titles
        static let logPottyTitle = String(localized: "Log Potty", table: table)
        static let logPottyDescription = String(localized: "Log when your puppy peed or pooped", table: table)
        static let logMealTitle = String(localized: "Log Meal", table: table)
        static let logMealDescription = String(localized: "Log that your puppy ate", table: table)
        static let logWalkTitle = String(localized: "Log Walk", table: table)
        static let logWalkDescription = String(localized: "Log a walk with your puppy", table: table)
        static let logSleepTitle = String(localized: "Log Sleep", table: table)
        static let logSleepDescription = String(localized: "Log that your puppy is sleeping", table: table)
        static let logWakeUpTitle = String(localized: "Log Wake Up", table: table)
        static let logWakeUpDescription = String(localized: "Log that your puppy woke up", table: table)
        static let pottyStatusTitle = String(localized: "Potty Status", table: table)
        static let pottyStatusDescription = String(localized: "Find out when your puppy last peed", table: table)
        static let poopStatusTitle = String(localized: "Poop Status", table: table)
        static let poopStatusDescription = String(localized: "Find out when your puppy last pooped", table: table)

        // Dialog responses
        static let setupProfileFirst = String(localized: "Please set up your puppy profile in the Ollie app first.", table: table)
        static let trialEnded = String(localized: "Your free trial has ended. Please upgrade in the Ollie app to continue logging.", table: table)
        static let failedToLog = String(localized: "Failed to log event", table: table)

        static func loggedPotty(type: String, location: String, name: String) -> String {
            String(localized: "Logged \(type) \(location) for \(name)", table: table)
        }
        static func loggedMeal(name: String) -> String {
            String(localized: "\(name) ate - logged!", table: table)
        }
        static func loggedWalk(name: String, duration: Int?) -> String {
            if let duration = duration {
                return String(localized: "Logged \(duration) minute walk with \(name)", table: table)
            } else {
                return String(localized: "Logged walk with \(name)", table: table)
            }
        }
        static func alreadySleeping(name: String) -> String {
            String(localized: "\(name) is already sleeping. Say '\(name) woke up' when they wake.", table: table)
        }
        static func loggedSleep(name: String) -> String {
            String(localized: "\(name) is sleeping - logged. Say '\(name) woke up' when they wake.", table: table)
        }
        static func wasntSleeping(name: String) -> String {
            String(localized: "\(name) wasn't logged as sleeping. Logging wake up anyway.", table: table)
        }
        static func wokeUpAfter(name: String, duration: Int) -> String {
            String(localized: "\(name) woke up after \(duration) minutes - logged!", table: table)
        }
        static func wokeUp(name: String) -> String {
            String(localized: "\(name) woke up - logged!", table: table)
        }
        static func noPottyEvents(name: String) -> String {
            String(localized: "No pee events logged for \(name) in the last week.", table: table)
        }
        static func noPoopEvents(name: String) -> String {
            String(localized: "No poop events logged for \(name) in the last week.", table: table)
        }
        static func justPeed(name: String, location: String) -> String {
            String(localized: "\(name) just peed \(location).", table: table)
        }
        static func peedMinutesAgo(name: String, location: String, minutes: Int) -> String {
            String(localized: "\(name) peed \(location) \(minutes) minutes ago.", table: table)
        }
        static func peedHoursAgo(name: String, location: String, hours: Int, minutes: Int) -> String {
            if minutes > 0 {
                return String(localized: "\(name) peed \(location) \(hours) hours and \(minutes) minutes ago.", table: table)
            } else {
                return String(localized: "\(name) peed \(location) \(hours) hours ago.", table: table)
            }
        }
    }

    // MARK: - Premium / Monetization
    enum Premium {
        static let title = String(localized: "Ollie Premium", table: table)
        static let free = String(localized: "Free", table: table)
        static let premium = String(localized: "Premium", table: table)
        static let expired = String(localized: "Expired", table: table)

        static func daysRemaining(_ days: Int) -> String {
            String(localized: "\(days) days remaining", table: table)
        }
        static func freeDaysLeft(_ days: Int) -> String {
            String(localized: "\(days) days left free", table: table)
        }

        // Settings section
        static let status = String(localized: "Status", table: table)
        static let restorePurchases = String(localized: "Restore purchases", table: table)
        static let continueWithOllie = String(localized: "Continue with Ollie", table: table)
        static let price = String(localized: "€19", table: table)
        static func continueWithOlliePrice(_ price: String) -> String {
            String(localized: "Continue with Ollie — \(price)", table: table)
        }

        // Upgrade prompt
        static let freeTrialEnded = String(localized: "Your free trial has ended", table: table)
        static func freeTrialEndedTitle(name: String) -> String {
            String(localized: "Your free trial for \(name) has ended", table: table)
        }
        static let firstWeeksMessage = String(localized: "The first weeks with a puppy are the most important. Ollie helps you track patterns and build good habits.", table: table)
        static let unlockFeatures = String(localized: "Unlock unlimited logging, predictions, and insights for your puppy's journey.", table: table)
        static let oneTimePurchase = String(localized: "One-time purchase, per puppy profile", table: table)

        // Banner
        static func trialDaysLeft(_ days: Int) -> String {
            String(localized: "\(days) days left in trial", table: table)
        }
        static let tapToUpgrade = String(localized: "Tap to upgrade", table: table)

        // Success
        static let purchaseSuccessTitle = String(localized: "Success!", table: table)
        static func purchaseSuccessMessage(name: String) -> String {
            String(localized: "You can now log unlimited events for \(name).", table: table)
        }

        // Errors
        static let purchaseFailed = String(localized: "Purchase failed", table: table)
        static let tryAgain = String(localized: "Please try again", table: table)
        static let restoring = String(localized: "Restoring purchases...", table: table)
        static let noRestorablePurchases = String(localized: "No restorable purchases found", table: table)

        // Expired state
        static let loggingDisabled = String(localized: "Logging disabled", table: table)
        static let upgradeToLog = String(localized: "Upgrade to continue logging events", table: table)
    }
}
