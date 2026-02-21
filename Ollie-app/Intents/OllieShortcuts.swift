//
//  OllieShortcuts.swift
//  Ollie-app
//
//  AppShortcutsProvider with Siri phrases for Ollie

import AppIntents

/// Provides App Shortcuts for Siri and the Shortcuts app
struct OllieShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Log pee outside - most common action
        AppShortcut(
            intent: LogPeeOutsideIntent(),
            phrases: [
                "Log pee outside with \(.applicationName)",
                "\(.applicationName) pee outside",
                "\(.applicationName) peed outside",
                "Puppy peed outside in \(.applicationName)",
                "Log outdoor pee with \(.applicationName)"
            ],
            shortTitle: "Pee Outside",
            systemImageName: "drop.fill"
        )

        // Log poop outside
        AppShortcut(
            intent: LogPoopOutsideIntent(),
            phrases: [
                "Log poop outside with \(.applicationName)",
                "\(.applicationName) poop outside",
                "\(.applicationName) pooped outside",
                "Puppy pooped outside in \(.applicationName)",
                "Log outdoor poop with \(.applicationName)"
            ],
            shortTitle: "Poop Outside",
            systemImageName: "circle.inset.filled"
        )

        // Log potty (with parameters)
        AppShortcut(
            intent: LogPottyIntent(),
            phrases: [
                "Log potty with \(.applicationName)",
                "\(.applicationName) went potty",
                "Log toilet with \(.applicationName)"
            ],
            shortTitle: "Log Potty",
            systemImageName: "drop.fill"
        )

        // Log meal
        AppShortcut(
            intent: LogMealIntent(),
            phrases: [
                "Log meal with \(.applicationName)",
                "\(.applicationName) ate",
                "\(.applicationName) had food",
                "Puppy ate in \(.applicationName)",
                "Log eating with \(.applicationName)"
            ],
            shortTitle: "Log Meal",
            systemImageName: "fork.knife"
        )

        // Log walk
        AppShortcut(
            intent: LogWalkIntent(),
            phrases: [
                "Log walk with \(.applicationName)",
                "\(.applicationName) went for a walk",
                "Puppy walked in \(.applicationName)",
                "Log dog walk with \(.applicationName)"
            ],
            shortTitle: "Log Walk",
            systemImageName: "figure.walk"
        )

        // Log sleep
        AppShortcut(
            intent: LogSleepIntent(),
            phrases: [
                "Log sleep with \(.applicationName)",
                "\(.applicationName) is sleeping",
                "\(.applicationName) went to sleep",
                "Puppy is sleeping in \(.applicationName)",
                "Log nap with \(.applicationName)"
            ],
            shortTitle: "Log Sleep",
            systemImageName: "moon.zzz.fill"
        )

        // Log wake up
        AppShortcut(
            intent: LogWakeUpIntent(),
            phrases: [
                "Log wake up with \(.applicationName)",
                "\(.applicationName) woke up",
                "\(.applicationName) is awake",
                "Puppy woke up in \(.applicationName)"
            ],
            shortTitle: "Log Wake Up",
            systemImageName: "sun.max.fill"
        )

        // Get potty status
        AppShortcut(
            intent: GetPottyStatusIntent(),
            phrases: [
                "When did puppy last pee in \(.applicationName)",
                "\(.applicationName) potty status",
                "When did \(.applicationName) last pee",
                "Last pee time in \(.applicationName)",
                "Check potty status with \(.applicationName)"
            ],
            shortTitle: "Potty Status",
            systemImageName: "clock.fill"
        )

        // Get poop status
        AppShortcut(
            intent: GetPoopStatusIntent(),
            phrases: [
                "When did puppy last poop in \(.applicationName)",
                "\(.applicationName) poop status",
                "When did \(.applicationName) last poop",
                "Last poop time in \(.applicationName)"
            ],
            shortTitle: "Poop Status",
            systemImageName: "clock.fill"
        )
    }
}
