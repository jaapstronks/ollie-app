//
//  Strings+Settings.swift
//  Ollie-app
//
//  Settings, meals, exercise, and notification strings

import Foundation

private let table = "Settings"

extension Strings {

    // MARK: - Settings View
    enum Settings {
        static let title = String(localized: "Settings", table: table)

        // Hub navigation - 4 sections
        static let dogProfile = String(localized: "Dog Profile", table: table)
        static let dogProfileSubtitle = String(localized: "Name, breed, size, photo", table: table)
        static let schedulePreferences = String(localized: "Schedule & Preferences", table: table)
        static let schedulePreferencesSubtitle = String(localized: "Walks, meals, reminders", table: table)
        static let healthDocuments = String(localized: "Health & Documents", table: table)
        static let healthDocumentsSubtitle = String(localized: "Medications, documents, contacts", table: table)
        static let appSettings = String(localized: "App Settings", table: table)
        static let appSettingsSubtitle = String(localized: "Sharing, appearance, sync", table: table)

        // Profile section
        static let profile = String(localized: "Profile", table: table)
        static let name = String(localized: "Name", table: table)
        static let changeName = String(localized: "Change name", table: table)
        static let breed = String(localized: "Breed", table: table)
        static let size = String(localized: "Size", table: table)

        // Stats section
        static let stats = String(localized: "Stats", table: table)
        static let age = String(localized: "Age", table: table)
        static let daysHome = String(localized: "Days home", table: table)

        // Exercise section
        static let exercise = String(localized: "Exercise", table: table)
        static let maxExercise = String(localized: "Max exercise", table: table)
        static let minPerWalk = String(localized: "min/walk", table: table)
        static let editExerciseLimit = String(localized: "Edit exercise limit", table: table)

        // Meals section
        static func mealsPerDay(_ count: Int) -> String {
            String(localized: "Meals (\(count)x per day)", table: table)
        }
        static let editMeals = String(localized: "Edit meals", table: table)

        // Reminders section
        static let reminders = String(localized: "Reminders", table: table)
        static let notifications = String(localized: "Notifications", table: table)

        // Appearance section
        static let appearance = String(localized: "Appearance", table: table)
        static let theme = String(localized: "Theme", table: table)
        static let soundFeedback = String(localized: "Sound feedback", table: table)
        static let systemTheme = String(localized: "System", table: table)
        static let lightTheme = String(localized: "Light", table: table)
        static let darkTheme = String(localized: "Dark", table: table)

        // Units section
        static let units = String(localized: "Units", table: table)
        static let temperature = String(localized: "Temperature", table: table)
        static let weight = String(localized: "Weight", table: table)

        // Sync section
        static let sync = String(localized: "Sync", table: table)
        static let syncing = String(localized: "Syncing...", table: table)
        static let iCloudActive = String(localized: "iCloud Sync active", table: table)
        static func lastSync(date: String) -> String {
            String(localized: "Last: \(date)", table: table)
        }
        static let iCloudUnavailable = String(localized: "iCloud unavailable", table: table)
        static let syncNow = String(localized: "Sync now", table: table)
        static let syncFooter = String(localized: "Data is automatically synced between all your devices via iCloud.", table: table)

        // Data section
        static let data = String(localized: "Data", table: table)
        static let importFromGitHub = String(localized: "Import from GitHub", table: table)
        static func lastImport(date: String) -> String {
            String(localized: "Last import: \(date)", table: table)
        }
        static func importStats(days: Int, events: Int) -> String {
            String(localized: "\(days) days, \(events) events", table: table)
        }
        static func skippedExisting(_ count: Int) -> String {
            String(localized: "\(count) skipped (already existed)", table: table)
        }
        static let overwriteExisting = String(localized: "Overwrite existing data", table: table)
        static let importAction = String(localized: "Import", table: table)
        static let importConfirmMessage = String(localized: "Do you want to import data from GitHub? This will fetch all available days.", table: table)

        static let resetProfile = String(localized: "Reset profile", table: table)
        static let advanced = String(localized: "Advanced", table: table)
    }

    // MARK: - Exercise Edit View
    enum ExerciseEdit {
        static let title = String(localized: "Exercise", table: table)
        static let minutesPerMonth = String(localized: "Minutes per month of age", table: table)
        static let fiveMinuteRule = String(localized: "The well-known '5-minute rule' — adjust based on your puppy's energy level.", table: table)
        static let minMonth = String(localized: "min/month", table: table)
        static let exerciseLimit = String(localized: "Exercise limit", table: table)
        static func maxAtAge(age: Int, minutes: Int) -> String {
            String(localized: "At \(age) months old: max \(minutes) minutes per walk", table: table)
        }
        static let walksPerDay = String(localized: "walks/day", table: table)
    }

    // MARK: - Exercise (expanded)
    enum Exercise {
        static let title = String(localized: "Exercise", table: table)
        static let minutesPerMonth = String(localized: "Minutes per month of age", table: table)
        static let fiveMinuteRule = String(localized: "The well-known '5-minute rule' — puppies can walk for a maximum of 5 minutes per month of age per session. Adjust based on your puppy's energy level.", table: table)
        static let minMonth = String(localized: "min/month", table: table)
        static let exerciseLimit = String(localized: "Exercise limit", table: table)
        static func maxAtAge(age: Int, minutes: Int) -> String {
            String(localized: "At \(age) months old: max \(minutes) minutes per walk", table: table)
        }
        static let walksPerDay = String(localized: "Walks per day", table: table)
        static let walksPerDayUnit = String(localized: "walks/day", table: table)
    }

    // MARK: - Meal Edit View
    enum MealEdit {
        static let title = String(localized: "Edit meals", table: table)
        static func mealsPerDay(_ count: Int) -> String {
            String(localized: "\(count)x per day", table: table)
        }
        static let amount = String(localized: "Amount", table: table)
        static let time = String(localized: "Time", table: table)
    }

    // MARK: - Meals (expanded)
    enum Meals {
        static let title = String(localized: "Edit meals", table: table)
        static let numberOfMeals = String(localized: "Number of meals", table: table)
        static let mealsPerDay = String(localized: "Meals per day", table: table)
        static func perDay(_ count: Int) -> String {
            String(localized: "\(count)x per day", table: table)
        }
        static let mealsSection = String(localized: "Meals", table: table)
        static let name = String(localized: "Name", table: table)
        static let amount = String(localized: "Amount", table: table)
        static let amountExample = String(localized: "e.g. 80g", table: table)
        static let time = String(localized: "Time", table: table)
        static let breakfast = String(localized: "Breakfast", table: table)
        static let lunch = String(localized: "Lunch", table: table)
        static let afternoon = String(localized: "Afternoon", table: table)
        static let dinner = String(localized: "Dinner", table: table)
        static let morning = String(localized: "Morning", table: table)
        static let evening = String(localized: "Evening", table: table)
        static func mealNumber(_ n: Int) -> String {
            String(localized: "Meal \(n)", table: table)
        }

        // Meal Schedule Editor
        static let addMeal = String(localized: "Add meal", table: table)
        static let editMeal = String(localized: "Edit meal", table: table)
        static let namePlaceholder = String(localized: "e.g. Breakfast", table: table)
        static let footerHint = String(localized: "Tap a meal to edit. Swipe to delete.", table: table)

        // Accessibility
        static let mealNameAccessibility = String(localized: "Meal name", table: table)
        static let mealNameHint = String(localized: "Enter the name for this meal, like Breakfast or Dinner", table: table)
        static func mealAmountAccessibility(_ mealName: String) -> String {
            String(localized: "Amount for \(mealName)", table: table)
        }
        static let mealAmountHint = String(localized: "Enter the portion size, like 80g", table: table)
        static func mealTimeAccessibility(_ mealName: String) -> String {
            String(localized: "Time for \(mealName)", table: table)
        }
    }

    // MARK: - Notification Settings View
    enum NotificationSettings {
        static let title = String(localized: "Reminders", table: table)
        static let enableInSettings = String(localized: "Enable notifications in Settings to receive reminders.", table: table)
        static let notificationsDisabled = String(localized: "Notifications disabled", table: table)
        static let enableToReceive = String(localized: "Enable notifications to receive reminders", table: table)

        static let remindersDescription = String(localized: "Receive smart reminders for potty, meals, naps, walks, and appointments.", table: table)

        // Potty
        static let pottyReminders = String(localized: "Potty reminders", table: table)
        static let pottyAlarm = String(localized: "Potty alarm", table: table)

        // Meals
        static let mealReminder = String(localized: "Meal reminder", table: table)
        static let mealReminderDescription = String(localized: "Reminder before it's time for the next meal.", table: table)

        // Naps
        static let napNeeded = String(localized: "Nap needed", table: table)
        static func napReminderDescription(name: String) -> String {
            String(localized: "Reminder when \(name) has been awake too long.", table: table)
        }

        // Walks
        static let walkReminders = String(localized: "Walk reminders", table: table)
        static let addWalk = String(localized: "Add walk", table: table)
        static let removeLast = String(localized: "Remove last", table: table)
        static let walks = String(localized: "Walks", table: table)
        static let walkReminderDescription = String(localized: "Reminder before it's time for a walk.", table: table)

        // Potty notification levels
        static let pottyLevelEarly = String(localized: "Early (~20 min)", table: table)
        static let pottyLevelSoon = String(localized: "Soon (~10 min)", table: table)
        static let pottyLevelOnTime = String(localized: "On time (0 min)", table: table)
        static let pottyLevelEarlyDesc = String(localized: "Reminder when ~20 minutes remaining", table: table)
        static let pottyLevelSoonDesc = String(localized: "Reminder when ~10 minutes remaining", table: table)
        static let pottyLevelOnTimeDesc = String(localized: "Reminder when it's time", table: table)
    }

    // MARK: - Notifications (expanded)
    enum Notifications {
        static let title = String(localized: "Reminders", table: table)
        static let disabledTitle = String(localized: "Notifications disabled", table: table)
        static let enableInSettings = String(localized: "Enable notifications in Settings to receive reminders.", table: table)
        static let enableToReceive = String(localized: "Enable notifications to receive reminders", table: table)
        static let remindersLabel = String(localized: "Reminders", table: table)
        static let remindersDescription = String(localized: "Receive smart reminders for potty, meals, naps, walks, and appointments.", table: table)
        static let settings = String(localized: "Settings", table: table)

        // Potty
        static let pottyReminders = String(localized: "Potty reminders", table: table)
        static let pottyAlarm = String(localized: "Potty alarm", table: table)
        static let whenToNotify = String(localized: "When to notify", table: table)

        // Meals
        static let mealReminder = String(localized: "Meal reminder", table: table)
        static let mealsSection = String(localized: "Meals", table: table)
        static func minutesBefore(_ minutes: Int) -> String {
            String(localized: "\(minutes) min before", table: table)
        }
        static let mealReminderDescription = String(localized: "Reminder when it's time for the next meal.", table: table)

        // Naps
        static let napNeeded = String(localized: "Nap needed", table: table)
        static let napsSection = String(localized: "Naps", table: table)
        static func awakeThreshold(_ minutes: Int) -> String {
            String(localized: "After \(minutes) min awake", table: table)
        }
        static func napReminderDescription(name: String) -> String {
            String(localized: "Reminder when \(name) has been awake too long.", table: table)
        }

        // Walks
        static let walkReminders = String(localized: "Walk reminders", table: table)
        static let walksSection = String(localized: "Walks", table: table)
        static let addWalk = String(localized: "Add walk", table: table)
        static let removeLast = String(localized: "Remove last", table: table)
        static let label = String(localized: "Label", table: table)
        static let walkReminderDescription = String(localized: "Reminder when it's time for a walk.", table: table)
        static func walkNumber(_ n: Int) -> String {
            String(localized: "Walk \(n)", table: table)
        }

        // Appointments
        static let appointmentReminders = String(localized: "Appointment reminders", table: table)
        static let appointmentsSection = String(localized: "Appointments", table: table)
        static let appointmentReminderDescription = String(localized: "Reminder for upcoming vet visits, training, and other appointments.", table: table)

        // Timing options
        static let atScheduledTime = String(localized: "At scheduled time", table: table)
        static func minutesOverdue(_ minutes: Int) -> String {
            String(localized: "\(minutes) min overdue", table: table)
        }
    }

    // MARK: - Cloud Sharing View
    enum CloudSharing {
        static let iCloudUnavailable = String(localized: "iCloud unavailable", table: table)
        static let sharedData = String(localized: "Shared data", table: table)
        static let viewingOthersData = String(localized: "You're viewing someone else's data", table: table)
        static let shared = String(localized: "Shared", table: table)
        static let noParticipants = String(localized: "No participants yet", table: table)
        static let manageSharing = String(localized: "Manage sharing", table: table)
        static let stopSharing = String(localized: "Stop sharing", table: table)
        static let shareWithPartner = String(localized: "Share with partner", table: table)
        static let inviteAnother = String(localized: "Invite another person", table: table)
        static let sharing = String(localized: "Sharing", table: table)
        static let sharingDescription = String(localized: "Share your puppy's data with your partner so you can both track and log events.", table: table)
        static let stopSharingConfirm = String(localized: "Are you sure you want to stop sharing? The other person will lose access.", table: table)

        // Share acceptance
        static let acceptingShare = String(localized: "Accepting Share...", table: table)
        static let connectingToSharedData = String(localized: "Connecting to shared data", table: table)
        static let shareAccepted = String(localized: "Share Accepted!", table: table)
        static let shareAcceptedMessage = String(localized: "You now have access to shared puppy data.", table: table)
        static let shareFailed = String(localized: "Share Failed", table: table)
        static let shareError = String(localized: "Share Error", table: table)
        static let couldNotFetchShareInfo = String(localized: "Could not fetch share information", table: table)

        // Existing profile conflict warning
        static let existingProfileTitle = String(localized: "Replace Existing Profile?", table: table)
        static func existingProfileMessage(existingName: String, sharedOwner: String) -> String {
            String(localized: "You already have a profile for \(existingName). Accepting this share will replace it with the shared puppy from \(sharedOwner). Your current profile data will be deleted.", table: table)
        }
        static let existingProfileMessageGeneric = String(localized: "You already have a puppy profile. Accepting this share will replace it with the shared puppy. Your current profile data will be deleted.", table: table)
        static let acceptAndReplace = String(localized: "Accept & Replace", table: table)
        static func lastSynced(time: String) -> String {
            String(localized: "Synced \(time)", table: table)
        }

        // iCloud status messages
        static let iCloudStatusUnknown = String(localized: "iCloud status unknown", table: table)
        static let noICloudAccount = String(localized: "No iCloud account configured", table: table)
        static let iCloudRestricted = String(localized: "iCloud is restricted", table: table)
        static let iCloudTemporarilyUnavailable = String(localized: "iCloud temporarily unavailable", table: table)
        static let iCloudNotAvailable = String(localized: "iCloud not available", table: table)
        static let couldNotCheckICloudStatus = String(localized: "Could not check iCloud status", table: table)
        static let saveFailed = String(localized: "Save failed", table: table)
        static let deleteFailed = String(localized: "Delete failed", table: table)

        // Participant status
        static let statusPending = String(localized: "Invited", table: table)
        static let statusAccepted = String(localized: "Active", table: table)
        static let statusRemoved = String(localized: "Removed", table: table)

        // Error messages
        static let cloudKitNotAvailable = String(localized: "CloudKit is not available", table: table)
        static func saveFailedMessage(_ message: String) -> String {
            String(localized: "Save failed: \(message)", table: table)
        }
        static func deleteFailedMessage(_ message: String) -> String {
            String(localized: "Delete failed: \(message)", table: table)
        }
        static func syncFailedMessage(_ message: String) -> String {
            String(localized: "Sync failed: \(message)", table: table)
        }
        static func migrationFailedMessage(_ message: String) -> String {
            String(localized: "Migration failed: \(message)", table: table)
        }
        static let cannotShareAsParticipant = String(localized: "You cannot share as a participant", table: table)
        static let couldNotLoadShare = String(localized: "Could not load share", table: table)
    }

    // MARK: - Data Import
    enum DataImport {
        static let done = String(localized: "Done!", table: table)
        static let fetchingFiles = String(localized: "Fetching files...", table: table)
        static func foundDays(_ count: Int) -> String {
            String(localized: "Found: \(count) days", table: table)
        }
        static func downloading(current: Int, total: Int) -> String {
            String(localized: "Downloading: \(current)/\(total)", table: table)
        }
        static let apiError = String(localized: "Could not reach GitHub API", table: table)
        static let invalidResponse = String(localized: "Invalid response from GitHub", table: table)
        static let downloadFailed = String(localized: "Download failed", table: table)
        static let invalidContent = String(localized: "File content invalid", table: table)
    }

    // MARK: - CloudKit Setup
    enum CloudKitSetup {
        static func setupFailed(_ error: String) -> String {
            String(localized: "Setup failed: \(error)", table: table)
        }
    }

    // MARK: - Units
    enum Units {
        static let celsius = String(localized: "Celsius (°C)", table: table)
        static let fahrenheit = String(localized: "Fahrenheit (°F)", table: table)
        static let kilograms = String(localized: "Kilograms (kg)", table: table)
        static let pounds = String(localized: "Pounds (lbs)", table: table)
    }

    // MARK: - Atmosphere Settings
    enum Atmosphere {
        static let title = String(localized: "Atmosphere", table: table)
        static let description = String(localized: "Subtle visual changes based on time, weather, and your puppy's activity.", table: table)

        static let timeOfDay = String(localized: "Time of day", table: table)
        static let timeOfDayDescription = String(localized: "Background shifts from cool mornings to warm evenings.", table: table)

        static let weather = String(localized: "Weather", table: table)
        static let weatherDescription = String(localized: "Colors reflect current weather conditions.", table: table)

        static let puppyState = String(localized: "Puppy state", table: table)
        static let puppyStateDescription = String(localized: "Calmer visuals when sleeping, brighter when awake.", table: table)

        static let seasonal = String(localized: "Seasonal touches", table: table)
        static let seasonalDescription = String(localized: "Light color adjustments for the current season.", table: table)
    }

    // MARK: - Data Export
    enum Export {
        // Main UI
        static let title = String(localized: "Export Data", table: table)
        static let exportData = String(localized: "Export data", table: table)
        static let exportDescription = String(localized: "Export all your puppy's data to share or back up.", table: table)
        static let exportButton = String(localized: "Export", table: table)
        static let share = String(localized: "Share", table: table)

        // Options
        static let optionsSection = String(localized: "Include in export", table: table)
        static let includeProfile = String(localized: "Profile", table: table)
        static let includeEvents = String(localized: "Events", table: table)
        static let includeDocuments = String(localized: "Documents", table: table)
        static let includeContacts = String(localized: "Contacts", table: table)
        static let includeAppointments = String(localized: "Appointments", table: table)
        static let includeMilestones = String(localized: "Milestones", table: table)
        static let includeSocialization = String(localized: "Socialization", table: table)
        static let includeWalkSpots = String(localized: "Saved places", table: table)
        static let includeProfilePhoto = String(localized: "Profile photo", table: table)
        static let includeMedia = String(localized: "Photos", table: table)
        static let includeMediaDescription = String(localized: "Include all event photos (may be large)", table: table)

        // Progress steps
        static let stepPreparing = String(localized: "Preparing export...", table: table)
        static let stepProfile = String(localized: "Exporting profile...", table: table)
        static let stepEvents = String(localized: "Exporting events...", table: table)
        static let stepDocuments = String(localized: "Exporting documents...", table: table)
        static let stepContacts = String(localized: "Exporting contacts...", table: table)
        static let stepAppointments = String(localized: "Exporting appointments...", table: table)
        static let stepMilestones = String(localized: "Exporting milestones...", table: table)
        static let stepExposures = String(localized: "Exporting socialization...", table: table)
        static let stepWalkSpots = String(localized: "Exporting places...", table: table)
        static let stepMedia = String(localized: "Exporting photos...", table: table)
        static let stepProfilePhoto = String(localized: "Exporting profile photo...", table: table)
        static let stepFinalizing = String(localized: "Finalizing export...", table: table)

        // Results
        static let exportComplete = String(localized: "Export Complete", table: table)
        static func exportSummary(items: Int, size: String) -> String {
            String(localized: "\(items) items exported (\(size))", table: table)
        }
        static let readyToShare = String(localized: "Your export is ready to share.", table: table)

        // Errors
        static let errorNoProfile = String(localized: "No puppy profile found. Please create a profile first.", table: table)
        static func errorExportFailed(_ message: String) -> String {
            String(localized: "Export failed: \(message)", table: table)
        }
        static let errorFileCreation = String(localized: "Could not create export files.", table: table)
        static func errorEncoding(_ type: String) -> String {
            String(localized: "Could not encode \(type) data.", table: table)
        }
    }
}
