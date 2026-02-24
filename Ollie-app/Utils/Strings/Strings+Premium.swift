//
//  Strings+Premium.swift
//  Ollie-app
//
//  Premium and Siri strings

import Foundation

extension Strings {

    // MARK: - Siri & Shortcuts
    enum Siri {
        // Settings section
        static let sectionTitle = String(localized: "Siri & Shortcuts")
        static let helpTitle = String(localized: "Voice Commands")
        static let helpDescription = String(localized: "Use Siri to log events and check on your puppy hands-free. Say \"Hey Siri\" followed by a command.")
        static let exampleCommands = String(localized: "Example commands:")
        static let examplePeedOutside = String(localized: "My puppy peed outside in Ollie")
        static let exampleSleeping = String(localized: "My puppy is sleeping in Ollie")
        static let exampleStatus = String(localized: "How is my puppy in Ollie")
        static let openShortcuts = String(localized: "Open Shortcuts App")
        static let openShortcutsDescription = String(localized: "See all Ollie shortcuts")
        static let helpFooter = String(localized: "Siri will respond using your puppy's name from your profile.")

        // Intent titles
        static let logPottyTitle = String(localized: "Log Potty")
        static let logPottyDescription = String(localized: "Log when your puppy peed or pooped")
        static let logMealTitle = String(localized: "Log Meal")
        static let logMealDescription = String(localized: "Log that your puppy ate")
        static let logWalkTitle = String(localized: "Log Walk")
        static let logWalkDescription = String(localized: "Log a walk with your puppy")
        static let logSleepTitle = String(localized: "Log Sleep")
        static let logSleepDescription = String(localized: "Log that your puppy is sleeping")
        static let logWakeUpTitle = String(localized: "Log Wake Up")
        static let logWakeUpDescription = String(localized: "Log that your puppy woke up")
        static let pottyStatusTitle = String(localized: "Potty Status")
        static let pottyStatusDescription = String(localized: "Find out when your puppy last peed")
        static let poopStatusTitle = String(localized: "Poop Status")
        static let poopStatusDescription = String(localized: "Find out when your puppy last pooped")

        // Dialog responses
        static let setupProfileFirst = String(localized: "Please set up your puppy profile in the Ollie app first.")
        static let trialEnded = String(localized: "Your free trial has ended. Please upgrade in the Ollie app to continue logging.")
        static let failedToLog = String(localized: "Failed to log event")

        static func loggedPotty(type: String, location: String, name: String) -> String {
            String(localized: "Logged \(type) \(location) for \(name)")
        }
        static func loggedMeal(name: String) -> String {
            String(localized: "\(name) ate - logged!")
        }
        static func loggedWalk(name: String, duration: Int?) -> String {
            if let duration = duration {
                return String(localized: "Logged \(duration) minute walk with \(name)")
            } else {
                return String(localized: "Logged walk with \(name)")
            }
        }
        static func alreadySleeping(name: String) -> String {
            String(localized: "\(name) is already sleeping. Say '\(name) woke up' when they wake.")
        }
        static func loggedSleep(name: String) -> String {
            String(localized: "\(name) is sleeping - logged. Say '\(name) woke up' when they wake.")
        }
        static func wasntSleeping(name: String) -> String {
            String(localized: "\(name) wasn't logged as sleeping. Logging wake up anyway.")
        }
        static func wokeUpAfter(name: String, duration: Int) -> String {
            String(localized: "\(name) woke up after \(duration) minutes - logged!")
        }
        static func wokeUp(name: String) -> String {
            String(localized: "\(name) woke up - logged!")
        }
        static func noPottyEvents(name: String) -> String {
            String(localized: "No pee events logged for \(name) in the last week.")
        }
        static func noPoopEvents(name: String) -> String {
            String(localized: "No poop events logged for \(name) in the last week.")
        }
        static func justPeed(name: String, location: String) -> String {
            String(localized: "\(name) just peed \(location).")
        }
        static func peedMinutesAgo(name: String, location: String, minutes: Int) -> String {
            String(localized: "\(name) peed \(location) \(minutes) minutes ago.")
        }
        static func peedHoursAgo(name: String, location: String, hours: Int, minutes: Int) -> String {
            if minutes > 0 {
                return String(localized: "\(name) peed \(location) \(hours) hours and \(minutes) minutes ago.")
            } else {
                return String(localized: "\(name) peed \(location) \(hours) hours ago.")
            }
        }
    }

    // MARK: - Premium / Monetization
    enum Premium {
        static let title = String(localized: "Ollie Premium")
        static let free = String(localized: "Free")
        static let premium = String(localized: "Premium")
        static let expired = String(localized: "Expired")

        static func daysRemaining(_ days: Int) -> String {
            String(localized: "\(days) days remaining")
        }
        static func freeDaysLeft(_ days: Int) -> String {
            String(localized: "\(days) days left free")
        }

        // Settings section
        static let status = String(localized: "Status")
        static let restorePurchases = String(localized: "Restore purchases")
        static let continueWithOllie = String(localized: "Continue with Ollie")
        static let price = String(localized: "€19")
        static func continueWithOlliePrice(_ price: String) -> String {
            String(localized: "Continue with Ollie — \(price)")
        }

        // Upgrade prompt
        static let freeTrialEnded = String(localized: "Your free trial has ended")
        static func freeTrialEndedTitle(name: String) -> String {
            String(localized: "Your free trial for \(name) has ended")
        }
        static let firstWeeksMessage = String(localized: "The first weeks with a puppy are the most important. Ollie helps you track patterns and build good habits.")
        static let unlockFeatures = String(localized: "Unlock unlimited logging, predictions, and insights for your puppy's journey.")
        static let oneTimePurchase = String(localized: "One-time purchase, per puppy profile")

        // Banner
        static func trialDaysLeft(_ days: Int) -> String {
            String(localized: "\(days) days left in trial")
        }
        static let tapToUpgrade = String(localized: "Tap to upgrade")

        // Success
        static let purchaseSuccessTitle = String(localized: "Success!")
        static func purchaseSuccessMessage(name: String) -> String {
            String(localized: "You can now log unlimited events for \(name).")
        }

        // Errors
        static let purchaseFailed = String(localized: "Purchase failed")
        static let tryAgain = String(localized: "Please try again")
        static let restoring = String(localized: "Restoring purchases...")
        static let noRestorablePurchases = String(localized: "No restorable purchases found")

        // Expired state
        static let loggingDisabled = String(localized: "Logging disabled")
        static let upgradeToLog = String(localized: "Upgrade to continue logging events")
    }
}
