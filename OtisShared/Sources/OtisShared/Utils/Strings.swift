//
//  Strings.swift
//  OtisShared
//
//  Core user-facing strings. Domain-specific strings are in extension files:
//  - Strings+Health.swift: Health, symptoms, conditions, senior wellness
//  - Strings+Behavior.swift: Behavior tracking, support module
//  - Strings+Walks.swift: Walks, locations, schedule
//  - Strings+Stats.swift: Statistics, predictions, coverage gap
//  - Strings+CloudKit.swift: Sharing, sync status
//  - Strings+Socialization.swift: Exposure tracking
//  - Strings+Medications.swift: Medication scheduling
//  - Strings+Notifications.swift: Reminder settings
//  - Strings+Documents.swift: Document types
//  - Strings+Meals.swift: Meal scheduling
//  - Strings+Timeline.swift: Timeline UI
//  - Strings+Places.swift: Places discovery
//
//  Usage: Text(Strings.Common.cancel)
//  For interpolation: Text(Strings.Lifecycle.Phrases.petsDay(name: profile.name))

import Foundation

// MARK: - Localized Strings

public enum Strings {
    /// Bundle for localization - set this to your app's bundle to enable localization
    nonisolated(unsafe) public static var bundle: Bundle = .main

    // MARK: - Common
    public enum Common {
        public static var cancel: String { String(localized: "Cancel", bundle: Strings.bundle) }
        public static var save: String { String(localized: "Save", bundle: Strings.bundle) }
        public static var delete: String { String(localized: "Delete", bundle: Strings.bundle) }
        public static var done: String { String(localized: "Done", bundle: Strings.bundle) }
        public static var ok: String { String(localized: "OK", bundle: Strings.bundle) }
        public static var next: String { String(localized: "Next", bundle: Strings.bundle) }
        public static var back: String { String(localized: "Back", bundle: Strings.bundle) }
        public static var edit: String { String(localized: "Edit", bundle: Strings.bundle) }
        public static var undo: String { String(localized: "Undo", bundle: Strings.bundle) }
        public static var error: String { String(localized: "Error", bundle: Strings.bundle) }
        public static var loading: String { String(localized: "Loading...", bundle: Strings.bundle) }
        public static var log: String { String(localized: "Log", bundle: Strings.bundle) }
        public static var start: String { String(localized: "Start!", bundle: Strings.bundle) }
        public static var allow: String { String(localized: "Allow", bundle: Strings.bundle) }
        public static var on: String { String(localized: "On", bundle: Strings.bundle) }
        public static var off: String { String(localized: "Off", bundle: Strings.bundle) }

        // Time units
        public static var minutes: String { String(localized: "min", bundle: Strings.bundle) }
        public static var minutesFull: String { String(localized: "minutes", bundle: Strings.bundle) }
        public static var weeks: String { String(localized: "weeks", bundle: Strings.bundle) }
        public static var days: String { String(localized: "days", bundle: Strings.bundle) }
        public static var hours: String { String(localized: "hours", bundle: Strings.bundle) }

        // Relative dates
        public static var today: String { String(localized: "Today", bundle: Strings.bundle) }
        public static var yesterday: String { String(localized: "Yesterday", bundle: Strings.bundle) }
        public static var tomorrow: String { String(localized: "Tomorrow", bundle: Strings.bundle) }

        // Navigation
        public static var seeAll: String { String(localized: "See all", bundle: Strings.bundle) }
    }

    // MARK: - Duration (Natural Language)
    /// Natural language duration strings for notifications and conversational UI
    public enum Duration {
        public static var aMoment: String { String(localized: "a moment", bundle: Strings.bundle) }
        public static var aFewMinutes: String { String(localized: "a few minutes", bundle: Strings.bundle) }
        public static var halfAnHour: String { String(localized: "half an hour", bundle: Strings.bundle) }
        public static var anHour: String { String(localized: "an hour", bundle: Strings.bundle) }
        public static var anHourAndAHalf: String { String(localized: "an hour and a half", bundle: Strings.bundle) }
        public static var twoHours: String { String(localized: "two hours", bundle: Strings.bundle) }

        public static func minutesNatural(_ minutes: Int) -> String {
            String(localized: "\(minutes) minutes", bundle: Strings.bundle)
        }
        public static func aboutHours(_ hours: Int) -> String {
            String(localized: "about \(hours) hours", bundle: Strings.bundle)
        }
        public static func hoursAndAHalf(_ hours: Int) -> String {
            String(localized: "\(hours) and a half hours", bundle: Strings.bundle)
        }
    }

    // MARK: - App
    public enum App {
        public static var name: String { String(localized: "Otis", bundle: Strings.bundle) }
        public static var subtitle: String { String(localized: "Puppy Tracker", bundle: Strings.bundle) }
        public static var tagline: String { String(localized: "Puppyhood is chaos. Otis brings the calm.", bundle: Strings.bundle) }
    }

    // MARK: - Lifecycle
    /// Strings for lifecycle-aware terminology
    /// Use these to avoid hardcoding "puppy" throughout the app
    public enum Lifecycle {
        // Phase labels
        public static var puppy: String { String(localized: "Puppy", bundle: Strings.bundle) }
        public static var teenage: String { String(localized: "Adolescent", bundle: Strings.bundle) }
        public static var adult: String { String(localized: "Adult", bundle: Strings.bundle) }
        public static var senior: String { String(localized: "Senior", bundle: Strings.bundle) }

        // Generic terms based on phase
        public enum Terms {
            /// "puppy" - for young dogs
            public static var puppy: String { String(localized: "puppy", bundle: Strings.bundle) }
            /// "dog" - for older dogs
            public static var dog: String { String(localized: "dog", bundle: Strings.bundle) }
            /// "puppy's" - possessive for young dogs
            public static var puppyPossessive: String { String(localized: "puppy's", bundle: Strings.bundle) }
            /// "dog's" - possessive for older dogs
            public static var dogPossessive: String { String(localized: "dog's", bundle: Strings.bundle) }
        }

        // Common phrases that need lifecycle awareness
        public enum Phrases {
            /// "Your puppy" or "Your dog" based on lifecycle
            public static func yourPet(isPuppy: Bool) -> String {
                isPuppy
                    ? String(localized: "Your puppy", bundle: Strings.bundle)
                    : String(localized: "Your dog", bundle: Strings.bundle)
            }

            /// "your puppy's" or "your dog's" based on lifecycle
            public static func yourPetPossessive(isPuppy: Bool) -> String {
                isPuppy
                    ? String(localized: "your puppy's", bundle: Strings.bundle)
                    : String(localized: "your dog's", bundle: Strings.bundle)
            }

            /// "{Name}'s day" - always uses the dog's actual name
            public static func petsDay(name: String) -> String {
                String(localized: "\(name)'s day", bundle: Strings.bundle)
            }
        }
    }

    // MARK: - Tabs
    public enum Tabs {
        public static var journal: String { String(localized: "Journal", bundle: Strings.bundle) }
        public static var stats: String { String(localized: "Stats", bundle: Strings.bundle) }
        public static var moments: String { String(localized: "Moments", bundle: Strings.bundle) }
        public static var settings: String { String(localized: "Settings", bundle: Strings.bundle) }
        public static var today: String { String(localized: "Today", bundle: Strings.bundle) }
        public static var insights: String { String(localized: "Insights", bundle: Strings.bundle) }
        public static var train: String { String(localized: "Train", bundle: Strings.bundle) }
        public static var walks: String { String(localized: "Walks", bundle: Strings.bundle) }
        public static var plan: String { String(localized: "Plan", bundle: Strings.bundle) }
    }

    // MARK: - Event Types
    public enum EventType {
        private static let table = "Events"
        public static var eat: String { String(localized: "Eat", table: table, bundle: Strings.bundle) }
        public static var drink: String { String(localized: "Drink", table: table, bundle: Strings.bundle) }
        public static var pee: String { String(localized: "Pee", table: table, bundle: Strings.bundle) }
        public static var poop: String { String(localized: "Poop", table: table, bundle: Strings.bundle) }
        public static var sleep: String { String(localized: "Sleep", table: table, bundle: Strings.bundle) }
        public static var wakeUp: String { String(localized: "Woke up", table: table, bundle: Strings.bundle) }
        public static var walk: String { String(localized: "Walk", table: table, bundle: Strings.bundle) }
        public static var garden: String { String(localized: "Garden", table: table, bundle: Strings.bundle) }
        public static var training: String { String(localized: "Training", table: table, bundle: Strings.bundle) }
        public static var crate: String { String(localized: "Crate", table: table, bundle: Strings.bundle) }
        public static var social: String { String(localized: "Social", table: table, bundle: Strings.bundle) }
        public static var milestone: String { String(localized: "Milestone", table: table, bundle: Strings.bundle) }
        public static var behavior: String { String(localized: "Behavior", table: table, bundle: Strings.bundle) }
        public static var weight: String { String(localized: "Weight", table: table, bundle: Strings.bundle) }
        public static var moment: String { String(localized: "Moment", table: table, bundle: Strings.bundle) }
        public static var medication: String { String(localized: "Medication", table: table, bundle: Strings.bundle) }
        public static var grooming: String { String(localized: "Grooming", table: table, bundle: Strings.bundle) }
    }

    // MARK: - Event Locations
    public enum EventLocation {
        private static let table = "Events"
        public static var outside: String { String(localized: "Outside", table: table, bundle: Strings.bundle) }
        public static var inside: String { String(localized: "Inside", table: table, bundle: Strings.bundle) }
    }

    // MARK: - Nap Locations
    public enum NapLocation {
        private static let table = "Events"
        public static var crate: String { String(localized: "Crate", table: table, bundle: Strings.bundle) }
        public static var dogBed: String { String(localized: "Dog bed", table: table, bundle: Strings.bundle) }
        public static var other: String { String(localized: "Other", table: table, bundle: Strings.bundle) }
        public static var wherePrompt: String { String(localized: "Where?", table: table, bundle: Strings.bundle) }
    }

    // MARK: - Size Categories
    public enum SizeCategory {
        public static var small: String { String(localized: "Small (<10kg)", bundle: Strings.bundle) }
        public static var medium: String { String(localized: "Medium (10-25kg)", bundle: Strings.bundle) }
        public static var large: String { String(localized: "Large (25-45kg)", bundle: Strings.bundle) }
        public static var extraLarge: String { String(localized: "Extra large (>45kg)", bundle: Strings.bundle) }

        public static var smallExamples: String { String(localized: "Chihuahua, Maltese, Yorkshire Terrier", bundle: Strings.bundle) }
        public static var mediumExamples: String { String(localized: "Beagle, Cocker Spaniel, Border Collie", bundle: Strings.bundle) }
        public static var largeExamples: String { String(localized: "Labrador, Golden Retriever, German Shepherd", bundle: Strings.bundle) }
        public static var extraLargeExamples: String { String(localized: "Bernese Mountain Dog, Great Dane, Saint Bernard", bundle: Strings.bundle) }
    }

    // MARK: - Gender
    public enum Gender {
        public static var male: String { String(localized: "Male", bundle: Strings.bundle) }
        public static var female: String { String(localized: "Female", bundle: Strings.bundle) }
        public static var preferNotToSay: String { String(localized: "Prefer not to say", bundle: Strings.bundle) }
    }

    // MARK: - Pronouns
    /// Pronouns for referring to dogs based on their gender setting
    public enum Pronouns {
        // Subject pronouns
        public static var he: String { String(localized: "he", bundle: Strings.bundle) }
        public static var she: String { String(localized: "she", bundle: Strings.bundle) }
        public static var they: String { String(localized: "they", bundle: Strings.bundle) }

        // Object pronouns
        public static var him: String { String(localized: "him", bundle: Strings.bundle) }
        public static var her: String { String(localized: "her", bundle: Strings.bundle) }
        public static var them: String { String(localized: "them", bundle: Strings.bundle) }

        // Possessive pronouns
        public static var his: String { String(localized: "his", bundle: Strings.bundle) }
        public static var hers: String { String(localized: "her", bundle: Strings.bundle, comment: "Possessive pronoun for female dogs") }
        public static var their: String { String(localized: "their", bundle: Strings.bundle) }

        // Reflexive pronouns
        public static var himself: String { String(localized: "himself", bundle: Strings.bundle) }
        public static var herself: String { String(localized: "herself", bundle: Strings.bundle) }
        public static var themselves: String { String(localized: "themselves", bundle: Strings.bundle) }

        // Swedish gender-neutral pronouns (hen)
        // These are only used when locale is Swedish and gender is unspecified
        public static var hen: String { String(localized: "hen", bundle: Strings.bundle, comment: "Swedish gender-neutral subject/object pronoun") }
        public static var hens: String { String(localized: "hens", bundle: Strings.bundle, comment: "Swedish gender-neutral possessive pronoun") }
        public static var sigSjalv: String { String(localized: "sig själv", bundle: Strings.bundle, comment: "Swedish gender-neutral reflexive pronoun") }
    }
}
