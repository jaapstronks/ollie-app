//
//  Strings+Settings.swift
//  Otis-app
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
        static let appSettingsSubtitle = String(localized: "Appearance, sync, integrations", table: table)

        // Profile section
        static let profile = String(localized: "Profile", table: table)
        static let name = String(localized: "Name", table: table)
        static let changeName = String(localized: "Change name", table: table)
        static let breed = String(localized: "Breed", table: table)
        static let gender = String(localized: "Gender", table: table)
        static let size = String(localized: "Size", table: table)
        static let aiLanguage = String(localized: "AI Language", table: table)

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

        // Maps preferences
        static let mapsApp = String(localized: "Maps app", table: table)
        static let appleMaps = String(localized: "Apple Maps", table: table)
        static let googleMaps = String(localized: "Google Maps", table: table)
        static let mapsAppDescription = String(localized: "Choose which app opens when viewing locations.", table: table)

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
        static let importData = String(localized: "Import data", table: table)
        static let overwriteExisting = String(localized: "Overwrite existing data", table: table)
        static let importAction = String(localized: "Import", table: table)

        static let resetProfile = String(localized: "Reset profile", table: table)
        static let advanced = String(localized: "Advanced", table: table)
        static let integrations = String(localized: "Integrations", table: table)
        static let celebrateEveryLog = String(localized: "Celebrate every log", table: table)
        static let celebrateEveryLogDescription = String(localized: "Debug mode: trigger a full celebration each time an event is logged.", table: table)

        // Help section
        static let help = String(localized: "Help", table: table)
        static let viewAppTour = String(localized: "View App Tour", table: table)
        static let viewAppTourDescription = String(localized: "Take a guided tour of the app features.", table: table)

        // Nudge preferences
        static let nudgePreferences = String(localized: "What You See", table: table)
        static let yourRole = String(localized: "Your role", table: table)
        static let roleDescription = String(localized: "This sets sensible defaults for what you'll see. You can customize further below.", table: table)
        static let whatToSee = String(localized: "Reminders & nudges", table: table)
        static let nudgesFooter = String(localized: "These settings control which reminders and suggestions you see in the app and as notifications.", table: table)
        static let resetToDefaults = String(localized: "Reset to defaults", table: table)
        static func resetNudgesFooter(_ role: String) -> String {
            String(localized: "Restore the default settings for your role (\(role)).", table: table)
        }
    }

    // MARK: - Exercise Edit View
    enum ExerciseEdit {
        static let title = String(localized: "Exercise", table: table)
        static let minutesPerMonth = String(localized: "Minutes per month of age", table: table)
        static func fiveMinuteRule(isPuppy: Bool) -> String {
            isPuppy
                ? String(localized: "The well-known '5-minute rule' — adjust based on your puppy's energy level.", table: table)
                : String(localized: "Adjust based on your dog's energy level and fitness.", table: table)
        }
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
        static func fiveMinuteRule(isPuppy: Bool) -> String {
            isPuppy
                ? String(localized: "The well-known '5-minute rule' — puppies can walk for a maximum of 5 minutes per month of age per session. Adjust based on your puppy's energy level.", table: table)
                : String(localized: "Adjust based on your dog's energy level and fitness. The 5-minute rule applies to growing puppies.", table: table)
        }
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

        // Moments
        static let momentsReminders = String(localized: "Photo notifications", table: table)
        static let momentsSection = String(localized: "Photos", table: table)
        static let momentsReminderDescription = String(localized: "Get notified when household members capture new photos.", table: table)

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
        static let partner = String(localized: "Partner", table: table)
        static let manageSharing = String(localized: "Manage sharing", table: table)
        static let stopSharing = String(localized: "Stop sharing", table: table)
        static let shareWithPartner = String(localized: "Share with partner", table: table)
        static let inviteAnother = String(localized: "Invite another person", table: table)
        static let sharing = String(localized: "Sharing", table: table)
        static func sharingDescription(name: String) -> String {
            String(localized: "Share \(name)'s data with your partner so you can both track and log events.", table: table)
        }
        /// Legacy static version
        static let sharingDescription = String(localized: "Share data with your partner so you can both track and log events.", table: table)
        static let stopSharingConfirm = String(localized: "Are you sure you want to stop sharing? The other person will lose access.", table: table)

        // Share acceptance
        static let acceptingShare = String(localized: "Accepting Share...", table: table)
        static let connectingToSharedData = String(localized: "Connecting to shared data", table: table)
        static let shareAccepted = String(localized: "Share Accepted!", table: table)
        static let shareAcceptedMessage = String(localized: "You now have access to shared data.", table: table)
        static let shareAcceptedSyncingMessage = String(localized: "Share accepted. The shared dog may take a moment to appear while iCloud sync completes.", table: table)
        static let sharedDogReadyTitle = String(localized: "Shared dog added", table: table)
        static func sharedDogReadyMessage(name: String) -> String {
            String(localized: "You're now viewing \(name). You can switch dogs anytime in Settings.", table: table)
        }
        static let shareFailed = String(localized: "Share Failed", table: table)
        static let shareError = String(localized: "Share Error", table: table)
        static let couldNotFetchShareInfo = String(localized: "Could not fetch share information", table: table)

        // Existing profile conflict warning (legacy - kept for backwards compatibility)
        static let existingProfileTitle = String(localized: "Replace Existing Profile?", table: table)
        static func existingProfileMessage(existingName: String, sharedOwner: String) -> String {
            String(localized: "You already have a profile for \(existingName). Accepting this share will replace it with the shared dog from \(sharedOwner). Your current profile data will be deleted.", table: table)
        }
        static let existingProfileMessageGeneric = String(localized: "You already have a profile. Accepting this share will replace it with the shared dog. Your current profile data will be deleted.", table: table)
        static let acceptAndReplace = String(localized: "Accept & Replace", table: table)

        // Non-destructive share acceptance (multi-puppy support)
        static let addSharedProfileTitle = String(localized: "Add Shared Dog?", table: table)
        static func addSharedProfileMessage(existingName: String, sharedOwner: String) -> String {
            String(localized: "\(sharedOwner) wants to share their dog with you. This will add their dog to your profile list alongside \(existingName).", table: table)
        }
        static func addSharedProfileMessageGeneric(ownerName: String) -> String {
            String(localized: "\(ownerName) wants to share their dog with you. This will add their dog to your profile list.", table: table)
        }
        static let acceptShare = String(localized: "Accept", table: table)

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
        // Title and navigation
        static let title = String(localized: "Import Data", table: table)

        // File selection
        static let selectFolder = String(localized: "Select file or folder", table: table)
        static let selectFolderDescription = String(localized: "Choose an exported JSON file or folder to import.", table: table)
        static let chooseFolder = String(localized: "Choose File", table: table)

        // Preview
        static let couldNotLoadPreview = String(localized: "Could not load preview", table: table)
        static func dataFor(name: String) -> String {
            String(localized: "Data for \(name)", table: table)
        }
        static func exportedOn(date: String) -> String {
            String(localized: "Exported on \(date)", table: table)
        }
        static let componentsToImport = String(localized: "Components to import:", table: table)
        static let overwriteDescription = String(localized: "Replace existing items with imported data", table: table)

        // Progress
        static let importing = String(localized: "Importing...", table: table)
        static func importingComponent(_ component: String) -> String {
            String(localized: "Importing \(component)...", table: table)
        }
        static func itemsImported(_ count: Int) -> String {
            String(localized: "\(count) items imported", table: table)
        }

        // Results
        static let done = String(localized: "Done!", table: table)
        static let importComplete = String(localized: "Import complete!", table: table)
        static func componentsImported(_ count: Int) -> String {
            String(localized: "\(count) components imported", table: table)
        }
        static func totalItems(_ count: Int) -> String {
            String(localized: "\(count) items total", table: table)
        }
        static func errors(_ count: Int) -> String {
            String(localized: "\(count) errors", table: table)
        }
        static let lastImportResult = String(localized: "Last import", table: table)
        static func importSummary(components: Int, items: Int) -> String {
            String(localized: "\(components) components, \(items) items", table: table)
        }

        // Errors
        static let importFailed = String(localized: "Import failed", table: table)
        static let accessDenied = String(localized: "Could not access the selected folder", table: table)
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

    // MARK: - Memorial
    enum Memorial {
        static let sectionTitle = String(localized: "Memories", table: table)
        static let memoryBookTitle = String(localized: "Memory Book", table: table)
        static let memoryBookDescription = String(localized: "When the time comes, create a keepsake with all your memories together.", table: table)
        static let createMemoryBook = String(localized: "Create Memory Book", table: table)

        // Marking as passed
        static let markAsPassed = String(localized: "If your dog has passed away...", table: table)
        static let passedDateLabel = String(localized: "Passed away", table: table)
        static let confirmTitle = String(localized: "We're so sorry", table: table)
        static func confirmMessage(name: String) -> String {
            String(localized: "\(name) was clearly loved. We can see it in every walk logged, every milestone celebrated.\n\nWhen you're ready, we can help you create a memory book to remember \(name) by.", table: table)
        }
        static let notYet = String(localized: "Not yet", table: table)
        static let idLikeThat = String(localized: "I'd like that", table: table)
        static let whenDidPass = String(localized: "When did they pass?", table: table)
        static let continue_ = String(localized: "Continue", table: table)

        // Memory book content
        static let generating = String(localized: "Creating your memory book...", table: table)
        static let gatheringMemories = String(localized: "Gathering memories...", table: table)
        static let coverTitle = String(localized: "In Loving Memory", table: table)
        static let theBeginning = String(localized: "The Beginning", table: table)
        static func cameHome(name: String, date: String) -> String {
            String(localized: "On \(date), \(name) came home.", table: table)
        }
        static func weeksOldWhenArrived(weeks: Int) -> String {
            String(localized: "\(weeks) weeks old when they arrived.", table: table)
        }
        static let milestones = String(localized: "Milestones", table: table)
        static let adventures = String(localized: "Adventures", table: table)
        static func exploredPlaces(count: Int) -> String {
            String(localized: "Together, you explored \(count) places.", table: table)
        }
        static let learningAndGrowing = String(localized: "Learning & Growing", table: table)
        static func practicedExercise(name: String, exercise: String, count: Int) -> String {
            String(localized: "\(name) practiced \(exercise) \(count) times.", table: table)
        }
        static let friends = String(localized: "Friends", table: table)
        static func madeFriends(count: Int) -> String {
            String(localized: "Made \(count) friends along the way.", table: table)
        }
        static let theNumbers = String(localized: "By the Numbers", table: table)
        static func daysTogether(count: Int) -> String {
            String(localized: "\(count) days together", table: table)
        }
        static func walksShared(count: Int) -> String {
            String(localized: "\(count) walks shared", table: table)
        }
        static func mealsTogether(count: Int) -> String {
            String(localized: "\(count) meals together", table: table)
        }
        static func napsObserved(count: Int) -> String {
            String(localized: "\(count) naps observed", table: table)
        }
        static let moments = String(localized: "Moments", table: table)
        static let finalMessage = String(localized: "This is their story. Not all of it — the best parts happened between the logged moments. The head on your lap. The excited spin at the door. The way they looked at you.\n\nThose don't need an app to remember.", table: table)

        // Share
        static let shareMemoryBook = String(localized: "Share Memory Book", table: table)
        static let memoryBookReady = String(localized: "Memory Book Ready", table: table)
        static let saveOrShare = String(localized: "Your memory book is ready. You can save it or share it.", table: table)

        // Undo passed status
        static let undoPassedStatus = String(localized: "Undo passed status", table: table)
        static let remembered = String(localized: "Remembered", table: table)
    }

    // MARK: - Training Settings
    enum TrainingSettings {
        static let title = String(localized: "Training", table: table)
        static let floatingClicker = String(localized: "Floating clicker", table: table)
        static let floatingClickerDescription = String(localized: "Show a clicker button on all screens for quick access during training.", table: table)
    }

    // MARK: - Atmosphere Settings
    enum Atmosphere {
        static let title = String(localized: "Atmosphere", table: table)
        static func description(name: String) -> String {
            String(localized: "Subtle visual changes based on time, weather, and \(name)'s activity.", table: table)
        }
        /// Legacy static version
        static let description = String(localized: "Subtle visual changes based on time, weather, and activity.", table: table)

        static let timeOfDay = String(localized: "Time of day", table: table)
        static let timeOfDayDescription = String(localized: "Background shifts from cool mornings to warm evenings.", table: table)

        static let weather = String(localized: "Weather", table: table)
        static let weatherDescription = String(localized: "Colors reflect current weather conditions.", table: table)

        static let activityState = String(localized: "Activity state", table: table)
        static let activityStateDescription = String(localized: "Calmer visuals when sleeping, brighter when awake.", table: table)

        static let seasonal = String(localized: "Seasonal touches", table: table)
        static let seasonalDescription = String(localized: "Light color adjustments for the current season.", table: table)
    }

    // MARK: - Beta Feedback
    enum Beta {
        static let sectionTitle = String(localized: "Beta Feedback", table: table)
        static let sendFeedback = String(localized: "Send Feedback", table: table)
        static let feedbackDescription = String(localized: "Help us improve by sharing your thoughts.", table: table)
        static let subscriptionOverride = String(localized: "Test Subscription", table: table)
        static let deviceId = String(localized: "Device ID", table: table)
        static let copiedToClipboard = String(localized: "Copied!", table: table)
        static let betaIndicator = String(localized: "Beta", table: table)
    }

    // MARK: - Delete Profile
    enum DeleteProfile {
        static func deleteButton(_ name: String) -> String {
            String(localized: "Delete \(name)...", table: table)
        }
        static func leaveButton(_ name: String) -> String {
            String(localized: "Leave \(name)...", table: table)
        }
        static let deleteTitle = String(localized: "Delete Profile?", table: table)
        static let deleteMessage = String(localized: "All data including events, photos, and training progress will be permanently deleted. This cannot be undone.", table: table)
        static let deleteConfirm = String(localized: "Delete Permanently", table: table)
        static let leaveTitle = String(localized: "Leave Profile?", table: table)
        static let leaveMessage = String(localized: "You'll no longer have access to this dog's data. The owner can invite you again later.", table: table)
        static let leaveConfirm = String(localized: "Leave", table: table)
        static let cannotDeleteOnly = String(localized: "You must have at least one dog profile.", table: table)
        static let lastProfileWarning = String(localized: "Deleting your only profile will return you to the start screen.", table: table)
        static let deleteWarningFooter = String(localized: "This action cannot be undone.", table: table)
    }

    // MARK: - Data Export
    enum Export {
        // Main UI
        static let title = String(localized: "Export Data", table: table)
        static let exportData = String(localized: "Export data", table: table)
        static func exportDescription(name: String) -> String {
            String(localized: "Export all of \(name)'s data to share or back up.", table: table)
        }
        /// Legacy static version
        static let exportDescription = String(localized: "Export your data to share or back up.", table: table)
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

        // Progress steps (nonisolated for use in ExportStep enum - hardcoded table name)
        nonisolated static let stepPreparing = String(localized: "Preparing export...", table: "Settings")
        nonisolated static let stepProfile = String(localized: "Exporting profile...", table: "Settings")
        nonisolated static let stepEvents = String(localized: "Exporting events...", table: "Settings")
        nonisolated static let stepDocuments = String(localized: "Exporting documents...", table: "Settings")
        nonisolated static let stepContacts = String(localized: "Exporting contacts...", table: "Settings")
        nonisolated static let stepAppointments = String(localized: "Exporting appointments...", table: "Settings")
        nonisolated static let stepMilestones = String(localized: "Exporting milestones...", table: "Settings")
        nonisolated static let stepExposures = String(localized: "Exporting socialization...", table: "Settings")
        nonisolated static let stepWalkSpots = String(localized: "Exporting places...", table: "Settings")
        nonisolated static let stepMedia = String(localized: "Exporting photos...", table: "Settings")
        nonisolated static let stepProfilePhoto = String(localized: "Exporting profile photo...", table: "Settings")
        nonisolated static let stepFinalizing = String(localized: "Finalizing export...", table: "Settings")

        // Results
        static let exportComplete = String(localized: "Export Complete", table: table)
        static func exportSummary(items: Int, size: String) -> String {
            String(localized: "\(items) items exported (\(size))", table: table)
        }
        static let readyToShare = String(localized: "Your export is ready to share.", table: table)

        // Errors (nonisolated for use in ExportError enum - hardcoded table name)
        nonisolated static let errorNoProfile = String(localized: "No profile found. Please create a profile first.", table: "Settings")
        nonisolated static func errorExportFailed(_ message: String) -> String {
            String(localized: "Export failed: \(message)", table: "Settings")
        }
        nonisolated static let errorFileCreation = String(localized: "Could not create export files.", table: "Settings")
        nonisolated static func errorEncoding(_ type: String) -> String {
            String(localized: "Could not encode \(type) data.", table: "Settings")
        }
    }
}
