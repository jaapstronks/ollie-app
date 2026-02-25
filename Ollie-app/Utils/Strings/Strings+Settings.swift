//
//  Strings+Settings.swift
//  Ollie-app
//
//  Settings, meals, exercise, and notification strings

import Foundation

extension Strings {

    // MARK: - Settings View
    enum Settings {
        static let title = String(localized: "Settings")

        // Hub navigation
        static let dogProfile = String(localized: "Dog Profile")
        static let dogProfileSubtitle = String(localized: "Walks, meals, meds, spots")
        static let appSettings = String(localized: "App Settings")
        static let appSettingsSubtitle = String(localized: "Subscription, notifications, sync")

        // Profile section
        static let profile = String(localized: "Profile")
        static let name = String(localized: "Name")
        static let breed = String(localized: "Breed")
        static let size = String(localized: "Size")

        // Stats section
        static let stats = String(localized: "Stats")
        static let age = String(localized: "Age")
        static let daysHome = String(localized: "Days home")

        // Exercise section
        static let exercise = String(localized: "Exercise")
        static let maxExercise = String(localized: "Max exercise")
        static let minPerWalk = String(localized: "min/walk")
        static let editExerciseLimit = String(localized: "Edit exercise limit")

        // Meals section
        static func mealsPerDay(_ count: Int) -> String {
            String(localized: "Meals (\(count)x per day)")
        }
        static let editMeals = String(localized: "Edit meals")

        // Reminders section
        static let reminders = String(localized: "Reminders")
        static let notifications = String(localized: "Notifications")

        // Appearance section
        static let appearance = String(localized: "Appearance")
        static let theme = String(localized: "Theme")
        static let soundFeedback = String(localized: "Sound feedback")

        // Sync section
        static let sync = String(localized: "Sync")
        static let syncing = String(localized: "Syncing...")
        static let iCloudActive = String(localized: "iCloud Sync active")
        static func lastSync(date: String) -> String {
            String(localized: "Last: \(date)")
        }
        static let iCloudUnavailable = String(localized: "iCloud unavailable")
        static let syncNow = String(localized: "Sync now")
        static let syncFooter = String(localized: "Data is automatically synced between all your devices via iCloud.")

        // Data section
        static let data = String(localized: "Data")
        static let importFromGitHub = String(localized: "Import from GitHub")
        static func lastImport(date: String) -> String {
            String(localized: "Last import: \(date)")
        }
        static func importStats(days: Int, events: Int) -> String {
            String(localized: "\(days) days, \(events) events")
        }
        static func skippedExisting(_ count: Int) -> String {
            String(localized: "\(count) skipped (already existed)")
        }
        static let overwriteExisting = String(localized: "Overwrite existing data")
        static let importAction = String(localized: "Import")
        static let importConfirmMessage = String(localized: "Do you want to import data from GitHub? This will fetch all available days.")

        static let resetProfile = String(localized: "Reset profile")
        static let advanced = String(localized: "Advanced")
    }

    // MARK: - Exercise Edit View
    enum ExerciseEdit {
        static let title = String(localized: "Exercise")
        static let minutesPerMonth = String(localized: "Minutes per month of age")
        static let fiveMinuteRule = String(localized: "The well-known '5-minute rule' — adjust based on your puppy's energy level.")
        static let minMonth = String(localized: "min/month")
        static let exerciseLimit = String(localized: "Exercise limit")
        static func maxAtAge(age: Int, minutes: Int) -> String {
            String(localized: "At \(age) months old: max \(minutes) minutes per walk")
        }
        static let walksPerDay = String(localized: "walks/day")
    }

    // MARK: - Exercise (expanded)
    enum Exercise {
        static let title = String(localized: "Exercise")
        static let minutesPerMonth = String(localized: "Minutes per month of age")
        static let fiveMinuteRule = String(localized: "The well-known '5-minute rule' — puppies can walk for a maximum of 5 minutes per month of age per session. Adjust based on your puppy's energy level.")
        static let minMonth = String(localized: "min/month")
        static let exerciseLimit = String(localized: "Exercise limit")
        static func maxAtAge(age: Int, minutes: Int) -> String {
            String(localized: "At \(age) months old: max \(minutes) minutes per walk")
        }
        static let walksPerDay = String(localized: "Walks per day")
        static let walksPerDayUnit = String(localized: "walks/day")
    }

    // MARK: - Meal Edit View
    enum MealEdit {
        static let title = String(localized: "Edit meals")
        static func mealsPerDay(_ count: Int) -> String {
            String(localized: "\(count)x per day")
        }
        static let amount = String(localized: "Amount")
        static let time = String(localized: "Time")
    }

    // MARK: - Meals (expanded)
    enum Meals {
        static let title = String(localized: "Edit meals")
        static let numberOfMeals = String(localized: "Number of meals")
        static let mealsPerDay = String(localized: "Meals per day")
        static func perDay(_ count: Int) -> String {
            String(localized: "\(count)x per day")
        }
        static let mealsSection = String(localized: "Meals")
        static let name = String(localized: "Name")
        static let amount = String(localized: "Amount")
        static let amountExample = String(localized: "e.g. 80g")
        static let time = String(localized: "Time")
        static let breakfast = String(localized: "Breakfast")
        static let lunch = String(localized: "Lunch")
        static let afternoon = String(localized: "Afternoon")
        static let dinner = String(localized: "Dinner")
        static let morning = String(localized: "Morning")
        static let evening = String(localized: "Evening")
        static func mealNumber(_ n: Int) -> String {
            String(localized: "Meal \(n)")
        }

        // Meal Schedule Editor
        static let addMeal = String(localized: "Add meal")
        static let editMeal = String(localized: "Edit meal")
        static let namePlaceholder = String(localized: "e.g. Breakfast")
        static let footerHint = String(localized: "Tap a meal to edit. Swipe to delete.")

        // Accessibility
        static let mealNameAccessibility = String(localized: "Meal name")
        static let mealNameHint = String(localized: "Enter the name for this meal, like Breakfast or Dinner")
        static func mealAmountAccessibility(_ mealName: String) -> String {
            String(localized: "Amount for \(mealName)")
        }
        static let mealAmountHint = String(localized: "Enter the portion size, like 80g")
        static func mealTimeAccessibility(_ mealName: String) -> String {
            String(localized: "Time for \(mealName)")
        }
    }

    // MARK: - Notification Settings View
    enum NotificationSettings {
        static let title = String(localized: "Reminders")
        static let enableInSettings = String(localized: "Enable notifications in Settings to receive reminders.")
        static let notificationsDisabled = String(localized: "Notifications disabled")
        static let enableToReceive = String(localized: "Enable notifications to receive reminders")

        static let remindersDescription = String(localized: "Receive smart reminders for potty, meals, naps, and walks.")

        // Potty
        static let pottyReminders = String(localized: "Potty reminders")
        static let pottyAlarm = String(localized: "Potty alarm")

        // Meals
        static let mealReminder = String(localized: "Meal reminder")
        static let mealReminderDescription = String(localized: "Reminder before it's time for the next meal.")

        // Naps
        static let napNeeded = String(localized: "Nap needed")
        static func napReminderDescription(name: String) -> String {
            String(localized: "Reminder when \(name) has been awake too long.")
        }

        // Walks
        static let walkReminders = String(localized: "Walk reminders")
        static let addWalk = String(localized: "Add walk")
        static let removeLast = String(localized: "Remove last")
        static let walks = String(localized: "Walks")
        static let walkReminderDescription = String(localized: "Reminder before it's time for a walk.")

        // Potty notification levels
        static let pottyLevelEarly = String(localized: "Early (~20 min)")
        static let pottyLevelSoon = String(localized: "Soon (~10 min)")
        static let pottyLevelOnTime = String(localized: "On time (0 min)")
        static let pottyLevelEarlyDesc = String(localized: "Reminder when ~20 minutes remaining")
        static let pottyLevelSoonDesc = String(localized: "Reminder when ~10 minutes remaining")
        static let pottyLevelOnTimeDesc = String(localized: "Reminder when it's time")
    }

    // MARK: - Notifications (expanded)
    enum Notifications {
        static let title = String(localized: "Reminders")
        static let disabledTitle = String(localized: "Notifications disabled")
        static let enableInSettings = String(localized: "Enable notifications in Settings to receive reminders.")
        static let enableToReceive = String(localized: "Enable notifications to receive reminders")
        static let remindersLabel = String(localized: "Reminders")
        static let remindersDescription = String(localized: "Receive smart reminders for potty, meals, naps, and walks.")
        static let settings = String(localized: "Settings")

        // Potty
        static let pottyReminders = String(localized: "Potty reminders")
        static let pottyAlarm = String(localized: "Potty alarm")
        static let whenToNotify = String(localized: "When to notify")

        // Meals
        static let mealReminder = String(localized: "Meal reminder")
        static let mealsSection = String(localized: "Meals")
        static func minutesBefore(_ minutes: Int) -> String {
            String(localized: "\(minutes) min before")
        }
        static let mealReminderDescription = String(localized: "Reminder before it's time for the next meal.")

        // Naps
        static let napNeeded = String(localized: "Nap needed")
        static let napsSection = String(localized: "Naps")
        static func awakeThreshold(_ minutes: Int) -> String {
            String(localized: "After \(minutes) min awake")
        }
        static func napReminderDescription(name: String) -> String {
            String(localized: "Reminder when \(name) has been awake too long.")
        }

        // Walks
        static let walkReminders = String(localized: "Walk reminders")
        static let walksSection = String(localized: "Walks")
        static let addWalk = String(localized: "Add walk")
        static let removeLast = String(localized: "Remove last")
        static let label = String(localized: "Label")
        static let walkReminderDescription = String(localized: "Reminder before it's time for a walk.")
        static func walkNumber(_ n: Int) -> String {
            String(localized: "Walk \(n)")
        }
    }

    // MARK: - Cloud Sharing View
    enum CloudSharing {
        static let iCloudUnavailable = String(localized: "iCloud unavailable")
        static let sharedData = String(localized: "Shared data")
        static let viewingOthersData = String(localized: "You're viewing someone else's data")
        static let shared = String(localized: "Shared")
        static let noParticipants = String(localized: "No participants yet")
        static let manageSharing = String(localized: "Manage sharing")
        static let stopSharing = String(localized: "Stop sharing")
        static let shareWithPartner = String(localized: "Share with partner")
        static let inviteAnother = String(localized: "Invite another person")
        static let sharing = String(localized: "Sharing")
        static let sharingDescription = String(localized: "Share your puppy's data with your partner so you can both track and log events.")
        static let stopSharingConfirm = String(localized: "Are you sure you want to stop sharing? The other person will lose access.")
        static func lastSynced(time: String) -> String {
            String(localized: "Synced \(time)")
        }

        // iCloud status messages
        static let iCloudStatusUnknown = String(localized: "iCloud status unknown")
        static let noICloudAccount = String(localized: "No iCloud account configured")
        static let iCloudRestricted = String(localized: "iCloud is restricted")
        static let iCloudTemporarilyUnavailable = String(localized: "iCloud temporarily unavailable")
        static let iCloudNotAvailable = String(localized: "iCloud not available")
        static let couldNotCheckICloudStatus = String(localized: "Could not check iCloud status")
        static let saveFailed = String(localized: "Save failed")
        static let deleteFailed = String(localized: "Delete failed")

        // Participant status
        static let statusPending = String(localized: "Invited")
        static let statusAccepted = String(localized: "Active")
        static let statusRemoved = String(localized: "Removed")

        // Error messages
        static let cloudKitNotAvailable = String(localized: "CloudKit is not available")
        static func saveFailedMessage(_ message: String) -> String {
            String(localized: "Save failed: \(message)")
        }
        static func deleteFailedMessage(_ message: String) -> String {
            String(localized: "Delete failed: \(message)")
        }
        static func syncFailedMessage(_ message: String) -> String {
            String(localized: "Sync failed: \(message)")
        }
        static func migrationFailedMessage(_ message: String) -> String {
            String(localized: "Migration failed: \(message)")
        }
        static let cannotShareAsParticipant = String(localized: "You cannot share as a participant")
        static let couldNotLoadShare = String(localized: "Could not load share")
    }

    // MARK: - Data Import
    enum DataImport {
        static let done = String(localized: "Done!")
        static let fetchingFiles = String(localized: "Fetching files...")
        static func foundDays(_ count: Int) -> String {
            String(localized: "Found: \(count) days")
        }
        static func downloading(current: Int, total: Int) -> String {
            String(localized: "Downloading: \(current)/\(total)")
        }
        static let apiError = String(localized: "Could not reach GitHub API")
        static let invalidResponse = String(localized: "Invalid response from GitHub")
        static let downloadFailed = String(localized: "Download failed")
        static let invalidContent = String(localized: "File content invalid")
    }

    // MARK: - CloudKit Setup
    enum CloudKitSetup {
        static func setupFailed(_ error: String) -> String {
            String(localized: "Setup failed: \(error)")
        }
    }
}
