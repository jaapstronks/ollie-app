import Foundation

// MARK: - Localized Strings
// All user-facing strings in one place for easy localization.
// English is the development language. Dutch translations will be added later.
//
// Usage: Text(Strings.Timeline.noEvents)
// For interpolation: Text(Strings.Timeline.dayWith(puppyName: profile.name))

enum Strings {

    // MARK: - Common
    enum Common {
        static let cancel = String(localized: "Cancel")
        static let save = String(localized: "Save")
        static let delete = String(localized: "Delete")
        static let done = String(localized: "Done")
        static let ok = String(localized: "OK")
        static let next = String(localized: "Next")
        static let back = String(localized: "Back")
        static let edit = String(localized: "Edit")
        static let undo = String(localized: "Undo")
        static let error = String(localized: "Error")
        static let loading = String(localized: "Loading...")
        static let log = String(localized: "Log")
        static let start = String(localized: "Start!")
        static let allow = String(localized: "Allow")
        static let on = String(localized: "On")
        static let off = String(localized: "Off")

        // Time units
        static let minutes = String(localized: "min")
        static let minutesFull = String(localized: "minutes")
        static let weeks = String(localized: "weeks")
        static let days = String(localized: "days")
        static let hours = String(localized: "hours")
    }

    // MARK: - App
    enum App {
        static let name = String(localized: "Ollie")
        static let subtitle = String(localized: "Puppy Tracker")
        static let tagline = String(localized: "Puppyhood is chaos. Ollie brings the calm.")
    }

    // MARK: - Tabs
    enum Tabs {
        static let journal = String(localized: "Journal")
        static let stats = String(localized: "Stats")
        static let moments = String(localized: "Moments")
        static let settings = String(localized: "Settings")
    }

    // MARK: - Event Types
    enum EventType {
        static let eat = String(localized: "Eat")
        static let drink = String(localized: "Drink")
        static let pee = String(localized: "Pee")
        static let poop = String(localized: "Poop")
        static let sleep = String(localized: "Sleep")
        static let wakeUp = String(localized: "Wake up")
        static let walk = String(localized: "Walk")
        static let garden = String(localized: "Garden")
        static let training = String(localized: "Training")
        static let crate = String(localized: "Crate")
        static let social = String(localized: "Social")
        static let milestone = String(localized: "Milestone")
        static let behavior = String(localized: "Behavior")
        static let weight = String(localized: "Weight")
        static let moment = String(localized: "Moment")
    }

    // MARK: - Event Locations
    enum EventLocation {
        static let outside = String(localized: "Outside")
        static let inside = String(localized: "Inside")
    }

    // MARK: - Size Categories
    enum SizeCategory {
        static let small = String(localized: "Small (<10kg)")
        static let medium = String(localized: "Medium (10-25kg)")
        static let large = String(localized: "Large (25-45kg)")
        static let extraLarge = String(localized: "Extra large (>45kg)")

        static let smallExamples = String(localized: "Chihuahua, Maltese, Yorkshire Terrier")
        static let mediumExamples = String(localized: "Beagle, Cocker Spaniel, Border Collie")
        static let largeExamples = String(localized: "Labrador, Golden Retriever, German Shepherd")
        static let extraLargeExamples = String(localized: "Bernese Mountain Dog, Great Dane, Saint Bernard")
    }

    // MARK: - Onboarding
    enum Onboarding {
        // Welcome step
        static let welcomeSubtitle = String(localized: "Track meals, potty, sleep & walks — and actually understand what your puppy needs.")
        static let preparingTitle = String(localized: "Preparing for your puppy?")
        static let preparingSubtitle = String(localized: "Start logging from day one. You'll thank yourself in week two.")
        static let alreadyInTitle = String(localized: "Already in the deep end?")
        static let alreadyInSubtitle = String(localized: "Just start tracking. Patterns emerge fast.")
        static let getStarted = String(localized: "Get Started")

        static let nameQuestion = String(localized: "What's your puppy's name?")
        static let namePlaceholder = String(localized: "Name")
        static let nameAccessibility = String(localized: "Enter your puppy's name")

        static func breedQuestion(name: String) -> String {
            String(localized: "What breed is \(name)?")
        }
        static let otherBreed = String(localized: "Other / Unknown")
        static let enterCustom = String(localized: "Enter custom")

        static func birthDateQuestion(name: String) -> String {
            String(localized: "When was \(name) born?")
        }
        static let birthDate = String(localized: "Birth date")
        static func birthDateAccessibility(name: String) -> String {
            String(localized: "\(name)'s birth date")
        }

        static func homeDateQuestion(name: String) -> String {
            String(localized: "When did \(name) come home?")
        }
        static let homeDate = String(localized: "Home date")
        static func homeDateAccessibility(name: String) -> String {
            String(localized: "Date \(name) came home")
        }

        static func sizeQuestion(name: String) -> String {
            String(localized: "How big will \(name) get?")
        }

        static let readyToStart = String(localized: "Ready to begin!")

        // Confirmation step
        static let born = String(localized: "Born")
        static let cameHome = String(localized: "Came home")
        static let breedOptional = String(localized: "Breed (optional)")
    }

    // MARK: - Timeline
    enum Timeline {
        static let previousDay = String(localized: "Previous day")
        static let nextDay = String(localized: "Next day")
        static func dateLabel(date: String) -> String {
            String(localized: "Date: \(date)")
        }

        static let noEvents = String(localized: "No events yet")
        static let tapToLog = String(localized: "Tap below to log the first one")

        static let deleteConfirmTitle = String(localized: "Delete?")
        static func deleteConfirmMessage(event: String, time: String) -> String {
            String(localized: "Are you sure you want to delete '\(event)' from \(time)?")
        }
        static let eventDeleted = String(localized: "Event deleted")
        static let undoAccessibility = String(localized: "Double-tap Undo to restore")
        static let goToTodayHint = String(localized: "Double-tap to go to today")
    }

    // MARK: - Quick Log Bar
    enum QuickLog {
        static let toilet = String(localized: "Toilet")
        static let more = String(localized: "More")
        static let photo = String(localized: "Photo")

        static let toiletAccessibility = String(localized: "Log toilet")
        static let toiletAccessibilityHint = String(localized: "Double-tap to log pee or poop")
        static let moreAccessibility = String(localized: "More event types")
        static let moreAccessibilityHint = String(localized: "Double-tap to see all event types")
        static let photoAccessibility = String(localized: "Take photo")
        static let photoAccessibilityHint = String(localized: "Double-tap to capture a photo moment")

        // Dynamic event logging accessibility
        static func logEventAccessibility(_ eventLabel: String) -> String {
            String(localized: "Log \(eventLabel)")
        }
        static func logEventAccessibilityHint(_ eventLabel: String) -> String {
            String(localized: "Double-tap to log \(eventLabel)")
        }
    }

    // MARK: - Quick Log Sheet
    enum QuickLogSheet {
        static let time = String(localized: "Time")
        static let where_ = String(localized: "Where?")
        static let what = String(localized: "What?")
        static let noteOptional = String(localized: "Note (optional)")
        static let notePlaceholder = String(localized: "E.g. after eating, in the garden...")
        static let selected = String(localized: "Selected")
        static let noteAccessibilityHint = String(localized: "Enter an optional note")

        static func minutesAgo(_ minutes: Int) -> String {
            String(localized: "\(minutes) min")
        }
        static func locationAccessibility(_ location: String) -> String {
            String(localized: "\(location) location")
        }
    }

    // MARK: - All Events Sheet
    enum AllEvents {
        static let title = String(localized: "Log event")
        static let moreEvents = String(localized: "More events")
        static let quickEvents = String(localized: "Quick events")
    }

    // MARK: - Log Event Sheet
    enum LogEvent {
        static let details = String(localized: "Details")
        static let note = String(localized: "Note")
        static let notePlaceholder = String(localized: "Optional note...")
        static let who = String(localized: "Who?")
        static let whoPlaceholder = String(localized: "Name of person or animal")
        static let training = String(localized: "Training")
        static let exercise = String(localized: "Exercise")
        static let result = String(localized: "Result")
        static let duration = String(localized: "Duration")

        // Accessibility
        static let noteAccessibilityHint = String(localized: "Enter an optional note")
        static let whoAccessibility = String(localized: "With who")
        static let whoAccessibilityHint = String(localized: "Enter the name of a person or animal")
        static let exerciseAccessibilityHint = String(localized: "Enter the training exercise name")
        static let resultAccessibilityHint = String(localized: "Enter the training result")
        static let durationAccessibility = String(localized: "Duration in minutes")
        static let durationAccessibilityHint = String(localized: "Enter the duration in minutes")
    }

    // MARK: - Potty Status Card
    enum PottyStatus {
        static let accessibility = String(localized: "Potty status")
        static let justWent = String(localized: "Just went")
        static let normal = String(localized: "Normal")
        static let attention = String(localized: "Attention")
        static let soonTime = String(localized: "Soon")
        static let now = String(localized: "Now!")
        static let accident = String(localized: "Accident")
        static let unknown = String(localized: "Unknown")

        static func predictionHint(name: String) -> String {
            String(localized: "Shows prediction for when \(name) needs to pee")
        }
    }

    // MARK: - Sleep Status Card
    enum SleepStatus {
        static let title = String(localized: "Sleep status")
        static let sleeping = String(localized: "Sleeping")
        static let awake = String(localized: "Awake")
        static let napTime = String(localized: "Nap time!")
        static let attention = String(localized: "Attention")

        static func sleepingFor(duration: String) -> String {
            String(localized: "Sleeping for \(duration)")
        }
        static func awakeTooLong(duration: String) -> String {
            String(localized: "Awake for \(duration) — time for a nap!")
        }
        static func awakeWithNapSuggestion(duration: String, remaining: Int) -> String {
            String(localized: "Awake \(duration) — nap in \(remaining) min?")
        }
        static func awakeSince(duration: String) -> String {
            String(localized: "Awake for \(duration)")
        }
        static let noSleepData = String(localized: "No sleep data")
        static func started(time: String) -> String {
            String(localized: "Started: \(time)")
        }
        static func awakeSinceTime(time: String) -> String {
            String(localized: "Awake since: \(time)")
        }
    }

    // MARK: - Streak Card
    enum Streak {
        static let accessibility = String(localized: "Outdoor streak")
        static func outdoorStreak(count: Int) -> String {
            String(localized: "\(count)x outside")
        }
        static let inARow = String(localized: "in a row!")
        static let streakBroken = String(localized: "Streak broken")
        static func recordTryAgain(count: Int) -> String {
            String(localized: "Record: \(count)x — try again!")
        }
        static func record(count: Int) -> String {
            String(localized: "Record: \(count)x")
        }
        static let progressHint = String(localized: "Progress toward next milestone")

        // Accessibility values
        static func accessibilityValue(current: Int, record: Int) -> String {
            String(localized: "\(current) times outside in a row. Record: \(record)")
        }
        static func progressAccessibilityValue(current: Int, milestone: Int) -> String {
            String(localized: "\(current) of \(milestone)")
        }
    }

    // MARK: - Digest Card
    enum Digest {
        static func dayNumber(_ day: Int) -> String {
            String(localized: "Day \(day)")
        }
        static func withPuppy(name: String) -> String {
            String(localized: "with \(name)")
        }
    }

    // MARK: - Pattern Analysis Card
    enum Patterns {
        static let insufficientData = String(localized: "Not enough data for patterns yet")
        static func successRate(_ rate: Int) -> String {
            String(localized: "\(rate)%")
        }
        static func count(_ count: Int) -> String {
            String(localized: "(\(count)x)")
        }
        static let percentSuccess = String(localized: "percent success")
        static let timesMeasured = String(localized: "times measured")
    }

    // MARK: - Location Picker
    enum LocationPicker {
        static let title = String(localized: "Where?")
    }

    // MARK: - Upcoming Events Card
    enum Upcoming {
        static let title = String(localized: "Coming up")
        static let overdue = String(localized: "overdue")
        static func laterToday(_ count: Int) -> String {
            String(localized: "\(count) later today")
        }
    }

    // MARK: - Event Row
    enum EventRow {
        static func duration(_ minutes: Int) -> String {
            String(localized: "\(minutes) min")
        }
        static let tapToViewPhoto = String(localized: "Tap to view photo")
        static func withPerson(_ name: String) -> String {
            String(localized: "with \(name)")
        }
    }

    // MARK: - Stats View
    enum Stats {
        static let title = String(localized: "Statistics")
        static let outdoorStreak = String(localized: "Outdoor Streak")
        static let pottyGaps = String(localized: "Pee Intervals (7 days)")
        static let today = String(localized: "Today")
        static let sleepToday = String(localized: "Sleep Today")
        static let patterns = String(localized: "Patterns (7 days)")

        static let currentStreak = String(localized: "Current streak")
        static let bestEver = String(localized: "Best ever")
        static let median = String(localized: "Median")
        static let average = String(localized: "Average")
        static let shortest = String(localized: "Shortest")
        static let longest = String(localized: "Longest")

        static func outsideCount(_ count: Int) -> String {
            String(localized: "\(count) outside")
        }
        static func insideCount(_ count: Int) -> String {
            String(localized: "\(count) inside")
        }
        static let outsidePercent = String(localized: "% outside")
        static let insufficientData = String(localized: "Not enough data yet")

        static let timesPeed = String(localized: "Times peed")
        static let meals = String(localized: "Meals")
        static let timesPooped = String(localized: "Times pooped")
        static let totalSlept = String(localized: "Total slept")
        static let naps = String(localized: "Naps")
        static let sleepGoal = String(localized: "Goal: 18 hours")
        static let sleepProgress = String(localized: "Sleep progress")
        static let percentOfGoal = String(localized: "percent of goal")
    }

    // MARK: - Settings View
    enum Settings {
        static let title = String(localized: "Settings")

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

    // MARK: - Meal Edit View
    enum MealEdit {
        static let title = String(localized: "Edit meals")
        static func mealsPerDay(_ count: Int) -> String {
            String(localized: "\(count)x per day")
        }
        static let amount = String(localized: "Amount")
        static let time = String(localized: "Time")
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

    // MARK: - Time Formatting
    enum TimeFormat {
        static let noData = String(localized: "No data")
        static func minutesAgo(_ minutes: Int) -> String {
            String(localized: "\(minutes) min ago")
        }
        static func hoursAgo(_ hours: Int) -> String {
            String(localized: "\(hours) hours ago")
        }
        static func hoursMinutesAgo(hours: Int, minutes: Int) -> String {
            String(localized: "\(hours)h \(minutes)m ago")
        }
        static func stillMinutes(_ minutes: Int) -> String {
            String(localized: "~\(minutes) min remaining")
        }
        static func afterEatingAgo(_ minutes: Int) -> String {
            String(localized: "(after eating \(minutes)m ago)")
        }
        static func afterNapAgo(_ minutes: Int) -> String {
            String(localized: "(after nap \(minutes)m ago)")
        }
        static let inside = String(localized: "- inside")
    }

    // MARK: - Prediction Display
    enum Prediction {
        static let justPeed = String(localized: "Just peed")
        static func nextIn(_ minutes: Int) -> String {
            String(localized: "Next in ~\(minutes) min")
        }
        static let soon = String(localized: "Soon!")
        static func needsToPeeNow(name: String) -> String {
            String(localized: "\(name) needs to pee now!")
        }
        static func needsToPeeNowOverdue(name: String, minutes: Int) -> String {
            String(localized: "\(name) needs to pee now! (\(minutes) min overdue)")
        }
        static let afterAccidentGoOutside = String(localized: "After accident — go outside now!")
    }

    // MARK: - Log Moment Sheet
    enum LogMoment {
        static let title = String(localized: "Moment")
        static let dateFromPhoto = String(localized: "Date from photo")
        static let date = String(localized: "Date")
        static let nowNoDateInPhoto = String(localized: "Now (no date in photo)")
        static let locationFromPhoto = String(localized: "Location from photo")
        static let note = String(localized: "Note")
        static let whatHappened = String(localized: "What happened?")
    }

    // MARK: - Moments Gallery View
    enum MomentsGallery {
        static let title = String(localized: "Moments")
        static let noPhotos = String(localized: "No photos yet")
        static let makePhotosHint = String(localized: "Take photos using the camera button\nin the timeline")
    }

    // MARK: - Media Attachment Button
    enum MediaAttachment {
        static let remove = String(localized: "Remove")
        static let addPhoto = String(localized: "Add photo")
        static let addPhotoTitle = String(localized: "Add photo")
        static let camera = String(localized: "Camera")
        static let photoLibrary = String(localized: "Photo library")
    }

    // MARK: - Media Preview View
    enum MediaPreview {
        static let photoNotFound = String(localized: "Photo not found")
        static let deleteTitle = String(localized: "Delete?")
        static let deletePhoto = String(localized: "Delete photo")
        static let deleteConfirmMessage = String(localized: "Are you sure you want to delete this moment?")
    }

    // MARK: - Potty Quick Log Sheet
    enum PottyQuickLog {
        static let toilet = String(localized: "Toilet")
        static let what = String(localized: "What?")
        static let where_ = String(localized: "Where?")
        static let noteOptional = String(localized: "Note (optional)")
        static let notePlaceholder = String(localized: "E.g. after eating, in the garden...")
        static let pee = String(localized: "Pee")
        static let poop = String(localized: "Poop")
        static let both = String(localized: "Both")
        static let time = String(localized: "Time")
        static func minutesAgo(_ minutes: Int) -> String {
            String(localized: "\(minutes) min")
        }
    }

    // MARK: - Weather Bar
    enum Weather {
        static let loading = String(localized: "Loading weather...")
        static func temperature(_ temp: Int) -> String {
            String(localized: "\(temp)°")
        }
        static func precipitation(_ percent: Int) -> String {
            String(localized: "\(percent)%")
        }
    }

    // MARK: - Exercise Edit View (expanded)
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

    // MARK: - Meal Edit View (expanded)
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
    }

    // MARK: - Walks
    enum Walks {
        static let morningWalk = String(localized: "Morning walk")
        static let afternoonWalk = String(localized: "Afternoon walk")
        static let eveningWalk = String(localized: "Evening walk")
    }

    // MARK: - Tips
    enum Tips {
        static let swipeToDeleteTitle = String(localized: "Swipe to delete")
        static let swipeToDeleteMessage = String(localized: "Swipe an event left to delete it.")

        static let longPressTitle = String(localized: "Hold for options")
        static let longPressMessage = String(localized: "Hold an event for extra options like edit.")

        static let mealRemindersTitle = String(localized: "Set up meal reminders")
        static let mealRemindersMessage = String(localized: "Get notified when it's time for the next meal.")

        static let quickLogTitle = String(localized: "Quick log")
        static let quickLogMessage = String(localized: "Use the bar at the bottom to quickly log events with one tap.")

        static let patternsTitle = String(localized: "Discover patterns")
        static let patternsMessage = String(localized: "Check statistics to discover patterns in your puppy's behavior.")

        static let predictionTitle = String(localized: "Prediction")
        static let predictionMessage = String(localized: "The app learns from patterns and predicts when your puppy needs to pee.")
    }

    // MARK: - Errors
    enum Errors {
        static let title = String(localized: "Error")
        static let networkError = String(localized: "Network error")
        static let fileError = String(localized: "File error")
        static let dataCorrupted = String(localized: "Data corrupted")
        static let unknownError = String(localized: "Unknown error")

        static let networkRecovery = String(localized: "Check your internet connection and try again.")
        static let fileRecovery = String(localized: "Something went wrong while saving. Please try again.")
        static let dataRecovery = String(localized: "The data could not be read. Try restarting the app.")
        static let unknownRecovery = String(localized: "Please try again later.")

        static let cloudKitNotConfigured = String(localized: "CloudKit not configured")
        static let cloudKitNotAvailable = String(localized: "CloudKit not available")
        static let cloudKitSimulator = String(localized: "CloudKit not available on simulator")
        static let couldNotShare = String(localized: "Could not share")
        static let couldNotStopSharing = String(localized: "Could not stop sharing")
        static let couldNotProcessWeather = String(localized: "Could not process weather data")
    }

    // MARK: - Notifications (push)
    enum PushNotifications {
        static let pottyAlarmTitle = String(localized: "Potty alarm!")
        static let goOutsideNowTitle = String(localized: "Go outside now!")
        static let mealTimeTitle = String(localized: "Time to eat!")
        static let walkTimeTitle = String(localized: "Time for a walk!")

        static func needsToPeeSoon(name: String) -> String {
            String(localized: "\(name) needs to pee soon!")
        }
        static func needsToPeeIn(name: String, minutes: Int) -> String {
            String(localized: "\(name) needs to pee in ~\(minutes) min")
        }
        static func needsToPeeNow(name: String) -> String {
            String(localized: "\(name) needs to pee now!")
        }
        static func mealReminder(name: String, meal: String) -> String {
            String(localized: "Time for \(name)'s \(meal)")
        }
        static func walkReminder(name: String) -> String {
            String(localized: "Time for \(name)'s walk")
        }
    }

    // MARK: - Weather Alerts
    enum WeatherAlerts {
        static func rainExpected(time: String) -> String {
            String(localized: "Rain expected at \(time) — maybe go outside now?")
        }
        static func dryUntil(time: String) -> String {
            String(localized: "Dry until \(time) — good time for a walk")
        }
    }

    // MARK: - Streaks
    enum StreakMessages {
        static let startAgain = String(localized: "Start again!")
    }

    // MARK: - Notification Settings (expanded)
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
