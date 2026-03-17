//
//  OtisShortcuts.swift
//  Otis-app
//
//  AppShortcutsProvider with Siri phrases for Otis

import AppIntents
import OtisShared

/// Provides App Shortcuts for Siri and the Shortcuts app
/// Note: "Otis" in phrases refers to the app name, not the dog's name.
/// The dog's actual name (from profile) is used in responses.
struct OtisShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Log pee outside - most common action
        AppShortcut(
            intent: LogPeeOutsideIntent(),
            phrases: [
                "Log pee outside in \(.applicationName)",
                "My puppy peed outside in \(.applicationName)",
                "My dog peed outside in \(.applicationName)",
                "Log outdoor pee in \(.applicationName)"
            ],
            shortTitle: "Pee Outside",
            systemImageName: "drop.fill"
        )

        // Log poop outside
        AppShortcut(
            intent: LogPoopOutsideIntent(),
            phrases: [
                "Log poop outside in \(.applicationName)",
                "My puppy pooped outside in \(.applicationName)",
                "My dog pooped outside in \(.applicationName)",
                "Log outdoor poop in \(.applicationName)"
            ],
            shortTitle: "Poop Outside",
            systemImageName: "circle.inset.filled"
        )

        // Log pee inside (accident) - removed to stay under 10 shortcut limit
        // Users can still log accidents via the app

        // Log poop inside (accident) - removed to stay under 10 shortcut limit
        // Users can still log accidents via the app

        // Log meal
        AppShortcut(
            intent: LogMealIntent(),
            phrases: [
                "Log meal in \(.applicationName)",
                "My puppy ate in \(.applicationName)",
                "My dog had food in \(.applicationName)",
                "Log feeding in \(.applicationName)"
            ],
            shortTitle: "Log Meal",
            systemImageName: "fork.knife"
        )

        // Start walk (with GPS tracking)
        AppShortcut(
            intent: StartWalkIntent(),
            phrases: [
                "Start walk in \(.applicationName)",
                "Start a walk with my puppy in \(.applicationName)",
                "Let's go for a walk in \(.applicationName)",
                "Begin walk in \(.applicationName)",
                "Going for a walk in \(.applicationName)"
            ],
            shortTitle: "Start Walk",
            systemImageName: "figure.walk"
        )

        // Log walk (completed walk)
        AppShortcut(
            intent: LogWalkIntent(),
            phrases: [
                "Log walk in \(.applicationName)",
                "My puppy went for a walk in \(.applicationName)",
                "Log dog walk in \(.applicationName)",
                "We went for a walk in \(.applicationName)"
            ],
            shortTitle: "Log Walk",
            systemImageName: "figure.walk"
        )

        // Log sleep
        AppShortcut(
            intent: LogSleepIntent(),
            phrases: [
                "Log sleep in \(.applicationName)",
                "My puppy is sleeping in \(.applicationName)",
                "My dog fell asleep in \(.applicationName)",
                "Log nap in \(.applicationName)"
            ],
            shortTitle: "Log Sleep",
            systemImageName: "moon.zzz.fill"
        )

        // Log wake up
        AppShortcut(
            intent: LogWakeUpIntent(),
            phrases: [
                "Log wake up in \(.applicationName)",
                "My puppy woke up in \(.applicationName)",
                "My dog is awake in \(.applicationName)",
                "Log awake in \(.applicationName)"
            ],
            shortTitle: "Log Wake Up",
            systemImageName: "sun.max.fill"
        )

        // Get potty status (combined pee and poop)
        AppShortcut(
            intent: GetPottyStatusIntent(),
            phrases: [
                "Potty status in \(.applicationName)",
                "When did my puppy last go potty in \(.applicationName)",
                "Check potty status in \(.applicationName)",
                "When did my dog last pee in \(.applicationName)"
            ],
            shortTitle: "Potty Status",
            systemImageName: "clock.fill"
        )

        // Get comprehensive puppy status
        AppShortcut(
            intent: GetPuppyStatusIntent(),
            phrases: [
                "How is my puppy in \(.applicationName)",
                "Puppy status in \(.applicationName)",
                "How is my dog doing in \(.applicationName)",
                "Is my puppy sleeping in \(.applicationName)",
                "How long has my puppy been asleep in \(.applicationName)"
            ],
            shortTitle: "Puppy Status",
            systemImageName: "pawprint.fill"
        )
    }
}
