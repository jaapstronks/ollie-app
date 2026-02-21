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

        // Relative dates
        static let today = String(localized: "Today")
        static let yesterday = String(localized: "Yesterday")
        static let tomorrow = String(localized: "Tomorrow")
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
        // 4-tab structure
        static let today = String(localized: "Today")
        static let insights = String(localized: "Insights")
        static let train = String(localized: "Train")
        static let walks = String(localized: "Walks")
        static let plan = String(localized: "Plan")
    }

    // MARK: - FAB (Floating Action Button)
    enum FAB {
        static let log = String(localized: "Log")
        static let peeOutside = String(localized: "Pee outside")
        static let poopOutside = String(localized: "Poop outside")
        static let eat = String(localized: "Eat")
        static let sleep = String(localized: "Sleep")
        static let wakeUp = String(localized: "Wake up")
        static let walk = String(localized: "Walk")
        static let training = String(localized: "Training")
        static let accessibilityLabel = String(localized: "Log event")
        static let accessibilityHint = String(localized: "Tap to log any event, or hold for quick actions")
        static let showQuickMenu = String(localized: "Show quick menu")
        static func quickActionHint(_ action: String) -> String {
            String(localized: "Double-tap to log \(action)")
        }
    }

    // MARK: - Insights View
    enum Insights {
        static let title = String(localized: "Insights")
        static let weekOverview = String(localized: "Week Overview")
        static let trends = String(localized: "Trends")
        static let explore = String(localized: "Explore")
        static let training = String(localized: "Training")
        static let trainingDescription = String(localized: "Track skills & progress")
        static let health = String(localized: "Health")
        static let healthDescription = String(localized: "Weight & milestones")
        static let momentsTitle = String(localized: "Moments")
        static let momentsDescription = String(localized: "Photos & memories")
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
        static let medication = String(localized: "Medication")
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
        static let justWent = String(localized: "All good")
        static let normal = String(localized: "On track")
        static let attention = String(localized: "Heads up")
        static let soonTime = String(localized: "Soon")
        static let now = String(localized: "Now!")
        static let accident = String(localized: "Accident")
        static let unknown = String(localized: "No data")

        static func predictionHint(name: String) -> String {
            String(localized: "Shows prediction for when \(name) needs to pee")
        }
    }

    // MARK: - Sleep Status Card
    enum SleepStatus {
        static let title = String(localized: "Sleep status")
        static let sleeping = String(localized: "Napping")
        static let awake = String(localized: "Awake")
        static let napTime = String(localized: "Nap time!")
        static let attention = String(localized: "Tired?")

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

    // MARK: - Sleep Session (Timeline display)
    enum SleepSession {
        static let nap = String(localized: "Nap")
        static let sleeping = String(localized: "Sleeping...")
        static let endSleep = String(localized: "End sleep")
        static let wakeUpTime = String(localized: "Wake-up time")
        static let logWakeUp = String(localized: "Log wake-up")
        static let shortNap = String(localized: "short")
        static let deleteSessionTitle = String(localized: "Delete sleep session?")
        static let deleteSessionMessage = String(localized: "This will delete both the sleep and wake-up events.")
        static let editStartTime = String(localized: "Edit sleep time")
        static let editEndTime = String(localized: "Edit wake-up time")
    }

    // MARK: - Poop Status Card
    enum PoopStatus {
        static let accessibility = String(localized: "Poop status")
        static let title = String(localized: "Poop")

        // Count display
        static func todayCount(_ count: Int, expectedLower: Int, expectedUpper: Int) -> String {
            if count == 1 {
                return String(localized: "1 poop today (expect ~\(expectedLower)-\(expectedUpper))")
            } else {
                return String(localized: "\(count) poops today (expect ~\(expectedLower)-\(expectedUpper))")
            }
        }
        static func todayCountSimple(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 poop today")
            } else {
                return String(localized: "\(count) poops today")
            }
        }

        // Status labels
        static let good = String(localized: "On track")
        static let info = String(localized: "Info")
        static let note = String(localized: "Note")

        // Status messages (subtle, not alarming)
        static let noPoopYetEarly = String(localized: "No poop yet this morning")
        static let noPoopYet = String(localized: "No poop yet today")
        static let walkCompletedNoPoop = String(localized: "Walk done — no poop logged")
        static let longerThanUsual = String(localized: "Longer gap than usual")
        static let longGap = String(localized: "Been a while since last poop")
        static let belowExpected = String(localized: "Below usual for this time")

        // Time since formatting
        static func minutesAgo(_ minutes: Int) -> String {
            String(localized: "\(minutes) min ago")
        }
        static func hoursAgo(_ hours: Int) -> String {
            String(localized: "\(hours)h ago")
        }
        static func hoursMinutesAgo(hours: Int, minutes: Int) -> String {
            String(localized: "\(hours)h\(minutes)m ago")
        }
    }

    // MARK: - Streak Card
    enum Streak {
        static let accessibility = String(localized: "Outdoor pee streak")
        static func outdoorStreak(count: Int) -> String {
            if count == 1 {
                return String(localized: "1 pee outside")
            } else {
                return String(localized: "\(count) pees outside in a row")
            }
        }
        static let onFire = String(localized: "On fire!")
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
            String(localized: "\(current) pees outside in a row. Record: \(record)")
        }
        static func progressAccessibilityValue(current: Int, milestone: Int) -> String {
            String(localized: "\(current) of \(milestone)")
        }
    }

    // MARK: - Digest Card
    enum Digest {
        static let dayLabel = String(localized: "Day")
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

    // MARK: - Location Selection
    enum LocationSelection {
        static func accessibilityHint(_ location: String) -> String {
            String(localized: "Double-tap to select \(location)")
        }
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
        static let tapToViewMedia = String(localized: "Double-tap to view attached media")
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
            String(localized: "Pee in ~\(minutes) min")
        }
        static let soon = String(localized: "Pee soon!")
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

    // MARK: - Time Adjust Button
    enum TimeAdjust {
        static func accessibilityLabel(_ minutes: Int) -> String {
            String(localized: "\(minutes) minutes ago")
        }
        static let accessibilityHint = String(localized: "Double-tap to adjust time")
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

        // Accessibility
        static func timeAccessibility(_ time: String) -> String {
            String(localized: "Time: \(time)")
        }
        static let timeAccessibilityHint = String(localized: "Double-tap to change time")
        static let logAccessibility = String(localized: "Log toilet event")
        static let logAccessibilityHint = String(localized: "Double-tap to save")
        static let selectRequiredFields = String(localized: "Select type and location first")
        static func pottyTypeHint(_ type: String) -> String {
            String(localized: "Double-tap to select \(type)")
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
        // Walk schedule labels
        static let earlyMorning = String(localized: "Early morning")
        static let morningWalk = String(localized: "Morning walk")
        static let midMorning = String(localized: "Mid-morning")
        static let lunchWalk = String(localized: "Lunch walk")
        static let earlyAfternoon = String(localized: "Early afternoon")
        static let afternoonWalk = String(localized: "Afternoon walk")
        static let eveningWalk = String(localized: "Evening walk")
        static let lateEvening = String(localized: "Late evening")
        static let nightWalk = String(localized: "Night walk")

        // Walk progress
        static func walksProgress(completed: Int, total: Int) -> String {
            String(localized: "\(completed) of \(total) walks")
        }
        static let nextWalk = String(localized: "Next walk")
        static let walksDone = String(localized: "All walks done for today!")
        static func nextWalkSuggestion(time: String) -> String {
            String(localized: "Suggested: ~\(time)")
        }
        static func overdueBy(minutes: Int) -> String {
            String(localized: "\(minutes) min overdue")
        }
        static let noWalkDataYet = String(localized: "Log your first walk to start tracking")
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

    // MARK: - Health View
    enum Health {
        static let title = String(localized: "Health")
        static let weight = String(localized: "Weight")
        static let milestones = String(localized: "Milestones")
        static let noWeightData = String(localized: "No weight data yet")
        static let logFirstWeight = String(localized: "Log your first weight measurement")
        static let logWeight = String(localized: "Log weight")
        static let currentWeight = String(localized: "Current weight")
        static let growthCurve = String(localized: "Growth curve")
        static let referenceRange = String(localized: "Reference range")

        // Weight status
        static let weightOnTrack = String(localized: "On track")
        static let weightAboveReference = String(localized: "Above reference")
        static let weightBelowReference = String(localized: "Below reference")

        // Weight delta
        static func sinceLast(_ delta: String) -> String {
            String(localized: "\(delta) since last")
        }
        static func sincePrevious(_ delta: String, date: String) -> String {
            String(localized: "\(delta) since \(date)")
        }

        // Chart
        static let weeks = String(localized: "Weeks")
        static let kg = String(localized: "kg")
        static let yourPuppy = String(localized: "Your puppy")
        static let reference = String(localized: "Reference")

        // Milestones
        static let done = String(localized: "Done")
        static let nextUp = String(localized: "Next up")
        static let future = String(localized: "Upcoming")
        static let overdue = String(localized: "Overdue")

        // Default milestones (Dutch vaccination schedule)
        static let firstDewormingBreeder = String(localized: "First deworming (breeder)")
        static let firstVaccination = String(localized: "First vaccination (DHP + Lepto)")
        static let firstVetVisit = String(localized: "First vet visit")
        static let firstDewormingHome = String(localized: "First deworming (home)")
        static let secondVaccination = String(localized: "Second vaccination (DHP + Lepto + Rabies)")
        static let thirdVaccination = String(localized: "Third vaccination (cocktail)")
        static let neuteredDiscussion = String(localized: "Spay/neuter discussion with vet")
        static let yearlyVaccination = String(localized: "Yearly vaccination")

        // Week/month labels
        static func weekNumber(_ week: Int) -> String {
            String(localized: "Week \(week)")
        }
        static func monthNumber(_ month: Int) -> String {
            String(localized: "\(month) months")
        }

        // Weight log sheet
        static let weightKg = String(localized: "Weight (kg)")
        static let enterWeight = String(localized: "Enter weight")
        static let weightPlaceholder = String(localized: "e.g. 8.5")
    }

    // MARK: - Training
    enum Training {
        static let title = String(localized: "Training")
        static let skillTracker = String(localized: "Skill Tracker")

        // Categories
        static let categoryFoundations = String(localized: "Foundations")
        static let categoryBasicCommands = String(localized: "Basic Commands")
        static let categoryCare = String(localized: "Care")
        static let categorySafety = String(localized: "Safety")
        static let categoryImpulseControl = String(localized: "Impulse Control")

        // Status
        static let statusNotStarted = String(localized: "Not started")
        static let statusStarted = String(localized: "Started")
        static let statusPracticing = String(localized: "Practicing")
        static let statusMastered = String(localized: "Mastered")

        // Week hero card
        static func weekNumber(_ week: Int) -> String {
            String(localized: "Week \(week)")
        }
        static let focusSkills = String(localized: "Focus skills")
        static func progressCount(started: Int, total: Int) -> String {
            String(localized: "\(started)/\(total) started")
        }

        // Skill card
        static func sessionCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 session")
            } else {
                return String(localized: "\(count) sessions")
            }
        }
        static let locked = String(localized: "Locked")
        static let requires = String(localized: "Requires")
        static let howTo = String(localized: "How to train")
        static let doneWhen = String(localized: "Done when")
        static let tips = String(localized: "Tips")
        static let recentSessions = String(localized: "Recent sessions")
        static let logSession = String(localized: "Log session")
        static let markMastered = String(localized: "Mark as mastered")
        static let unmarkMastered = String(localized: "Unmark mastered")

        // Log sheet
        static let logTrainingSession = String(localized: "Log Training Session")
        static let duration = String(localized: "Duration")
        static let durationMinutes = String(localized: "minutes")
        static let result = String(localized: "Result")
        static let resultPlaceholder = String(localized: "e.g. Good focus, needed help")
        static let note = String(localized: "Note")
        static let notePlaceholder = String(localized: "Optional note...")

        // Empty state
        static let noSkillsStarted = String(localized: "No skills started yet")
        static let tapToBegin = String(localized: "Tap a skill to begin training")

        // Week plan titles
        enum WeekTitles {
            static let week1 = String(localized: "Foundation Week")
            static let week2 = String(localized: "First Commands")
            static let week3 = String(localized: "Safety & Movement")
            static let week4 = String(localized: "Impulse Control")
            static let week5 = String(localized: "Duration Training")
            static let week6 = String(localized: "Consolidation Week")

            static func title(for week: Int) -> String {
                switch week {
                case 1: return week1
                case 2: return week2
                case 3: return week3
                case 4: return week4
                case 5: return week5
                case 6: return week6
                default: return week6
                }
            }
        }

        // Skill content - names, descriptions, done criteria, how-to steps, tips
        enum Skills {
            // MARK: - Clicker
            static let clickerName = String(localized: "Clicker")
            static let clickerDescription = String(localized: "Teach your puppy that the click sound means a treat is coming. This is the foundation for all marker-based training.")
            static let clickerDoneWhen = String(localized: "Your puppy immediately looks at you or your hand when they hear the click, expecting a treat.")
            static let clickerHowTo1 = String(localized: "Hold treats ready in your hand")
            static let clickerHowTo2 = String(localized: "Click the clicker (or use a marker word like 'yes')")
            static let clickerHowTo3 = String(localized: "Immediately give a treat within 1-2 seconds")
            static let clickerHowTo4 = String(localized: "Repeat 10-15 times per session")
            static let clickerHowTo5 = String(localized: "Your puppy should start looking for treats when they hear the click")
            static let clickerTip1 = String(localized: "Keep sessions short (2-3 minutes)")
            static let clickerTip2 = String(localized: "Use high-value treats")
            static let clickerTip3 = String(localized: "The click must ALWAYS be followed by a treat")
            static let clickerTip4 = String(localized: "Don't click to get attention - click to mark behavior")

            // MARK: - Name Recognition
            static let nameRecognitionName = String(localized: "Name Recognition")
            static let nameRecognitionDescription = String(localized: "Your puppy learns to look at you when they hear their name. Essential for getting attention before giving commands.")
            static let nameRecognitionDoneWhen = String(localized: "Your puppy immediately looks at you when you say their name, even with mild distractions.")
            static let nameRecognitionHowTo1 = String(localized: "Wait until your puppy looks away")
            static let nameRecognitionHowTo2 = String(localized: "Say their name once in a happy voice")
            static let nameRecognitionHowTo3 = String(localized: "When they look at you, click and treat")
            static let nameRecognitionHowTo4 = String(localized: "Gradually add distractions")
            static let nameRecognitionHowTo5 = String(localized: "Practice in different locations")
            static let nameRecognitionTip1 = String(localized: "Never use their name negatively")
            static let nameRecognitionTip2 = String(localized: "Only say the name once - don't repeat it")
            static let nameRecognitionTip3 = String(localized: "If they don't respond, try again later or reduce distractions")
            static let nameRecognitionTip4 = String(localized: "Pair with eye contact for maximum attention")

            // MARK: - Luring
            static let luringName = String(localized: "Luring")
            static let luringDescription = String(localized: "Use a treat to guide your puppy into positions. This technique is used to teach many other commands.")
            static let luringDoneWhen = String(localized: "Your puppy follows the treat smoothly in any direction without jumping or grabbing.")
            static let luringHowTo1 = String(localized: "Hold a treat between your thumb and fingers")
            static let luringHowTo2 = String(localized: "Let your puppy sniff the treat but not eat it")
            static let luringHowTo3 = String(localized: "Move the treat slowly - your puppy's nose should follow")
            static let luringHowTo4 = String(localized: "Practice moving in different directions")
            static let luringHowTo5 = String(localized: "Reward when they follow the lure smoothly")
            static let luringTip1 = String(localized: "Move slowly and smoothly")
            static let luringTip2 = String(localized: "Keep the treat close to their nose")
            static let luringTip3 = String(localized: "If they lose interest, use higher value treats")
            static let luringTip4 = String(localized: "Eventually fade the lure into a hand signal")

            // MARK: - Handling
            static let handlingName = String(localized: "Handling")
            static let handlingDescription = String(localized: "Get your puppy comfortable being touched everywhere. Important for vet visits, grooming, and health checks.")
            static let handlingDoneWhen = String(localized: "Your puppy stays relaxed when you touch their ears, paws, mouth, and tail.")
            static let handlingHowTo1 = String(localized: "Start when puppy is calm and relaxed")
            static let handlingHowTo2 = String(localized: "Gently touch ears, paws, tail, mouth")
            static let handlingHowTo3 = String(localized: "Give treats while handling")
            static let handlingHowTo4 = String(localized: "Keep sessions very short at first")
            static let handlingHowTo5 = String(localized: "Gradually increase duration and pressure")
            static let handlingTip1 = String(localized: "Go slowly - this builds lifelong trust")
            static let handlingTip2 = String(localized: "Stop if puppy shows stress signals")
            static let handlingTip3 = String(localized: "Practice lifting paws and looking in ears")
            static let handlingTip4 = String(localized: "Make it part of daily routine")

            // MARK: - Collar & Leash
            static let collarLeashName = String(localized: "Collar & Leash")
            static let collarLeashDescription = String(localized: "Get your puppy comfortable wearing a collar and being on a leash. Foundation for all outdoor training.")
            static let collarLeashDoneWhen = String(localized: "Your puppy ignores the collar and doesn't panic when leash is attached or lifted.")
            static let collarLeashHowTo1 = String(localized: "Let puppy sniff the collar first")
            static let collarLeashHowTo2 = String(localized: "Put collar on during positive moments (meals, play)")
            static let collarLeashHowTo3 = String(localized: "Start with short periods")
            static let collarLeashHowTo4 = String(localized: "Attach leash and let them drag it supervised")
            static let collarLeashHowTo5 = String(localized: "Pick up leash and follow puppy around")
            static let collarLeashTip1 = String(localized: "Check collar fit - two fingers should fit underneath")
            static let collarLeashTip2 = String(localized: "Never leave leash on unsupervised")
            static let collarLeashTip3 = String(localized: "If puppy freezes, lure them forward with treats")
            static let collarLeashTip4 = String(localized: "Practice inside before going outside")

            // MARK: - Sit
            static let sitName = String(localized: "Sit")
            static let sitDescription = String(localized: "The classic sit command. A building block for many other behaviors.")
            static let sitDoneWhen = String(localized: "Your puppy sits on command with just the verbal cue, no lure needed.")
            static let sitHowTo1 = String(localized: "Hold treat above puppy's nose")
            static let sitHowTo2 = String(localized: "Move treat slowly back over their head")
            static let sitHowTo3 = String(localized: "As their head goes up, their bottom goes down")
            static let sitHowTo4 = String(localized: "Click and treat the moment bottom touches floor")
            static let sitHowTo5 = String(localized: "Add the word 'sit' once behavior is reliable")
            static let sitTip1 = String(localized: "Don't push their bottom down")
            static let sitTip2 = String(localized: "If they jump, hold treat closer to nose")
            static let sitTip3 = String(localized: "Practice before meals for extra motivation")
            static let sitTip4 = String(localized: "Gradually phase out hand movement")

            // MARK: - Watch Me
            static let watchMeName = String(localized: "Watch Me")
            static let watchMeDescription = String(localized: "Your puppy learns to make eye contact on command. Great for getting focus before other commands.")
            static let watchMeDoneWhen = String(localized: "Your puppy makes eye contact for 3-5 seconds on command.")
            static let watchMeHowTo1 = String(localized: "Hold a treat near your face")
            static let watchMeHowTo2 = String(localized: "Wait for eye contact")
            static let watchMeHowTo3 = String(localized: "The moment they look at your eyes, click and treat")
            static let watchMeHowTo4 = String(localized: "Add the cue 'watch' or 'look'")
            static let watchMeHowTo5 = String(localized: "Gradually increase duration")
            static let watchMeTip1 = String(localized: "Start in low-distraction environment")
            static let watchMeTip2 = String(localized: "Some dogs find direct eye contact uncomfortable - be patient")
            static let watchMeTip3 = String(localized: "Use this to redirect attention from distractions")
            static let watchMeTip4 = String(localized: "Great to use before crossing streets")

            // MARK: - Touch
            static let touchName = String(localized: "Touch")
            static let touchDescription = String(localized: "Puppy learns to touch their nose to your palm. Useful for positioning and recall.")
            static let touchDoneWhen = String(localized: "Your puppy touches their nose to your palm on command from 1 meter away.")
            static let touchHowTo1 = String(localized: "Present flat palm near puppy's nose")
            static let touchHowTo2 = String(localized: "Most puppies will naturally investigate")
            static let touchHowTo3 = String(localized: "Click and treat when nose touches palm")
            static let touchHowTo4 = String(localized: "Add the cue 'touch'")
            static let touchHowTo5 = String(localized: "Practice at different heights and distances")
            static let touchTip1 = String(localized: "Don't push your hand into their face")
            static let touchTip2 = String(localized: "Rub treat on palm if they need encouragement")
            static let touchTip3 = String(localized: "Great alternative to 'come' for recall")
            static let touchTip4 = String(localized: "Can be used to guide puppy into positions")

            // MARK: - Loose Leash Walking
            static let looseLeashName = String(localized: "Loose Leash Walking")
            static let looseLeashDescription = String(localized: "Walk nicely on a loose leash without pulling. Makes walks enjoyable for both of you.")
            static let looseLeashDoneWhen = String(localized: "Your puppy can walk 10 meters on a loose leash with moderate distractions.")
            static let looseLeashHowTo1 = String(localized: "Start inside or in a boring area")
            static let looseLeashHowTo2 = String(localized: "Reward frequently for staying beside you")
            static let looseLeashHowTo3 = String(localized: "If puppy pulls, stop walking immediately")
            static let looseLeashHowTo4 = String(localized: "Wait for loose leash before continuing")
            static let looseLeashHowTo5 = String(localized: "Change direction frequently to keep attention")
            static let looseLeashTip1 = String(localized: "This takes weeks to master - be patient")
            static let looseLeashTip2 = String(localized: "Use a front-clip harness if pulling is severe")
            static let looseLeashTip3 = String(localized: "Practice 'let's go' turns to redirect")
            static let looseLeashTip4 = String(localized: "Tired puppies walk better - play first")

            // MARK: - Down
            static let downName = String(localized: "Down")
            static let downDescription = String(localized: "Puppy lies down on command. A calm position useful for settling.")
            static let downDoneWhen = String(localized: "Your puppy lies down on command from a sit, without lure.")
            static let downHowTo1 = String(localized: "Start with puppy in sit")
            static let downHowTo2 = String(localized: "Lure treat from nose straight down to floor")
            static let downHowTo3 = String(localized: "Then slowly pull treat away from puppy along floor")
            static let downHowTo4 = String(localized: "Click and treat when elbows touch ground")
            static let downHowTo5 = String(localized: "Add the cue 'down' once behavior is reliable")
            static let downTip1 = String(localized: "Don't push puppy down")
            static let downTip2 = String(localized: "If they stand, you moved the treat too far")
            static let downTip3 = String(localized: "Practice on a comfortable surface first")
            static let downTip4 = String(localized: "Great for restaurant and café visits")

            // MARK: - Come
            static let comeName = String(localized: "Come")
            static let comeDescription = String(localized: "Recall - the most important safety command. Your puppy comes to you when called.")
            static let comeDoneWhen = String(localized: "Your puppy comes immediately when called in the house and garden.")
            static let comeHowTo1 = String(localized: "Start very close with high-value treats")
            static let comeHowTo2 = String(localized: "Say puppy's name + 'come' in excited voice")
            static let comeHowTo3 = String(localized: "Reward generously when they reach you")
            static let comeHowTo4 = String(localized: "Always make coming to you worthwhile")
            static let comeHowTo5 = String(localized: "Never call for something negative")
            static let comeTip1 = String(localized: "Use a long line for safety during training")
            static let comeTip2 = String(localized: "Never chase your puppy if they don't come")
            static let comeTip3 = String(localized: "Practice randomly throughout the day")
            static let comeTip4 = String(localized: "Coming to you should be the best thing ever")

            // MARK: - Wait
            static let waitName = String(localized: "Wait")
            static let waitDescription = String(localized: "Short-term stay - puppy pauses briefly at doors, before meals, etc.")
            static let waitDoneWhen = String(localized: "Your puppy waits for 10 seconds at doors and before meals.")
            static let waitHowTo1 = String(localized: "Put puppy in sit")
            static let waitHowTo2 = String(localized: "Show palm and say 'wait'")
            static let waitHowTo3 = String(localized: "Take one small step back")
            static let waitHowTo4 = String(localized: "Return and treat before they move")
            static let waitHowTo5 = String(localized: "Gradually increase distance and duration")
            static let waitTip1 = String(localized: "This is different from 'stay' - shorter and more casual")
            static let waitTip2 = String(localized: "Great for safety at doors and curbs")
            static let waitTip3 = String(localized: "Release with 'okay' or 'free'")
            static let waitTip4 = String(localized: "Practice before putting food bowl down")

            // MARK: - Place
            static let placeName = String(localized: "Place")
            static let placeDescription = String(localized: "Puppy goes to their bed or mat and stays there. Great for settling at home.")
            static let placeDoneWhen = String(localized: "Your puppy goes to their bed and lies down for 2 minutes.")
            static let placeHowTo1 = String(localized: "Lure puppy onto their bed or mat")
            static let placeHowTo2 = String(localized: "Ask for a down on the mat")
            static let placeHowTo3 = String(localized: "Reward for staying on the mat")
            static let placeHowTo4 = String(localized: "Add the cue 'place' or 'bed'")
            static let placeHowTo5 = String(localized: "Gradually add duration and distance")
            static let placeTip1 = String(localized: "Use a portable mat to transfer this skill anywhere")
            static let placeTip2 = String(localized: "Great for when guests arrive")
            static let placeTip3 = String(localized: "Build duration very slowly")
            static let placeTip4 = String(localized: "Practice during meals and TV time")

            // MARK: - Stay
            static let stayName = String(localized: "Stay")
            static let stayDescription = String(localized: "Long-duration stay - puppy remains in position until released.")
            static let stayDoneWhen = String(localized: "Your puppy stays for 30 seconds while you walk 5 meters away.")
            static let stayHowTo1 = String(localized: "Start from sit or down")
            static let stayHowTo2 = String(localized: "Add duration first (stay close but longer)")
            static let stayHowTo3 = String(localized: "Then add distance (stay far but shorter)")
            static let stayHowTo4 = String(localized: "Return to puppy before releasing")
            static let stayHowTo5 = String(localized: "Add distractions last")
            static let stayTip1 = String(localized: "The three Ds: Duration, Distance, Distraction - increase one at a time")
            static let stayTip2 = String(localized: "Always return to puppy - don't call them to break stay")
            static let stayTip3 = String(localized: "If they break, simply reset without punishment")
            static let stayTip4 = String(localized: "This takes months to master - be patient")
        }
    }

    // MARK: - Walk Locations
    enum WalkLocations {
        static let location = String(localized: "Location")
        static let here = String(localized: "Here")
        static let pickSpot = String(localized: "Pick a spot")
        static let savedSpots = String(localized: "Saved spots")
        static let favorites = String(localized: "Favorites")
        static let recent = String(localized: "Recent")
        static let useCurrentLocation = String(localized: "Use current location")
        static let nameThisSpot = String(localized: "Name this spot")
        static let spotNamePlaceholder = String(localized: "e.g. Park, Trail, Corner")
        static let saveSpot = String(localized: "Save spot")
        static let noFavorites = String(localized: "No favorite spots yet")
        static let noRecentSpots = String(localized: "No recent spots")
        static let addToFavorites = String(localized: "Add to favorites")
        static let removeFromFavorites = String(localized: "Remove from favorites")
        static let deleteSpot = String(localized: "Delete spot")
        static let favoriteSpots = String(localized: "Favorite spots")
        static let manageSpots = String(localized: "Manage spots")
        static let gettingLocation = String(localized: "Getting location...")
        static let locationCaptured = String(localized: "Location captured")
        static let optional = String(localized: "(optional)")
        static let walkLocation = String(localized: "Walk location")
        static let addSpot = String(localized: "Add spot")

        // Spot categories
        static let categoryPark = String(localized: "Park")
        static let categoryTrail = String(localized: "Trail")
        static let categoryNeighborhood = String(localized: "Neighborhood")
        static let categoryBeach = String(localized: "Beach")
        static let categoryForest = String(localized: "Forest")
        static let categoryOther = String(localized: "Other")

        // Errors
        static let locationNotAuthorized = String(localized: "Location access not authorized")
        static let locationUnavailable = String(localized: "Location unavailable")
        static let locationTimeout = String(localized: "Location request timed out")
        static let enableLocationInSettings = String(localized: "Enable location in Settings to capture walk spots")

        // Visit count
        static func visitCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 visit")
            } else {
                return String(localized: "\(count) visits")
            }
        }

        // Map
        static let showOnMap = String(localized: "Show on map")
        static let openInMaps = String(localized: "Open in Maps")
    }

    // MARK: - Spot Detail
    enum SpotDetail {
        static let addSpot = String(localized: "Add Spot")
        static let visits = String(localized: "Visits")
        static let created = String(localized: "Created")
        static let deleteConfirmMessage = String(localized: "This will permanently delete this spot.")
        static let notesOptional = String(localized: "Notes (optional)")
        static let recapture = String(localized: "Recapture")
        static let tryAgain = String(localized: "Try again")
        static let pickOnMap = String(localized: "Pick on map")
        static let selectLocation = String(localized: "Select Location")
        static let moveMapToSelect = String(localized: "Move map to position the pin")
    }

    // MARK: - Edit Walk
    enum EditWalk {
        static let title = String(localized: "Edit Walk")
        static let deleteWalk = String(localized: "Delete Walk")
        static let deleteConfirmMessage = String(localized: "This will permanently delete this walk.")
        static let changeSpot = String(localized: "Change")
    }

    // MARK: - Walks Tab
    enum WalksTab {
        static let title = String(localized: "Walks")
        static let todaysWalks = String(localized: "Today's walks")
        static let noWalksToday = String(localized: "No walks logged today")
        static let startWalk = String(localized: "Start a walk")
        static let yourSpots = String(localized: "Your spots")
        static let nearbySpots = String(localized: "Nearby spots")
        static let allSpots = String(localized: "All spots")
        static let walkWeather = String(localized: "Walk weather")
        static let goodTimeForWalk = String(localized: "Good time for a walk")
        static let notIdealForWalk = String(localized: "Not ideal for a walk")

        static func walksCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 walk")
            } else {
                return String(localized: "\(count) walks")
            }
        }

        static func totalDuration(_ minutes: Int) -> String {
            String(localized: "\(minutes) min total")
        }
    }

    // MARK: - Plan Tab
    enum PlanTab {
        static let title = String(localized: "Plan")
        static let puppyAge = String(localized: "Puppy age")
        static let upcomingMilestones = String(localized: "Upcoming milestones")
        static let moments = String(localized: "Moments")
        static let seeAllMoments = String(localized: "See all moments")
        static let noUpcomingMilestones = String(localized: "No upcoming milestones")
        static let allMilestonesDone = String(localized: "All milestones completed!")
        static let nextUp = String(localized: "Next up")
        static let overdue = String(localized: "Overdue")

        static func weeksOld(_ weeks: Int) -> String {
            String(localized: "\(weeks) weeks old")
        }

        static func monthsOld(_ months: Int) -> String {
            if months == 1 {
                return String(localized: "1 month old")
            } else {
                return String(localized: "\(months) months old")
            }
        }

        static func daysHome(_ days: Int) -> String {
            String(localized: "\(days) days home")
        }
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

    // MARK: - Medications
    enum Medications {
        static let title = String(localized: "Medications")
        static let addMedication = String(localized: "Add medication")
        static let editMedication = String(localized: "Edit medication")
        static let name = String(localized: "Name")
        static let instructions = String(localized: "Instructions")
        static let instructionsPlaceholder = String(localized: "Dosage, notes...")
        static let schedule = String(localized: "Schedule")
        static let daily = String(localized: "Daily")
        static let weekly = String(localized: "Weekly")
        static let times = String(localized: "Times")
        static let addTime = String(localized: "Add time")
        static let linkToMeal = String(localized: "Link to meal")
        static let startDate = String(localized: "Start date")
        static let endDate = String(localized: "End date")
        static let indefinitely = String(localized: "Indefinitely")
        static let untilDate = String(localized: "Until date")
        static let markAsDone = String(localized: "Slide to complete")
        static let overdue = String(localized: "Overdue")
        static let scheduled = String(localized: "scheduled")
        static let noMedications = String(localized: "No medications")
        static let noMedicationsHint = String(localized: "Tap to add your puppy's medications")
        static let active = String(localized: "Active")
        static let paused = String(localized: "Paused")
        static let icon = String(localized: "Icon")
        static let daysOfWeek = String(localized: "Days of week")
        static let duration = String(localized: "Duration")

        // Day names (short)
        static let sunday = String(localized: "Sun")
        static let monday = String(localized: "Mon")
        static let tuesday = String(localized: "Tue")
        static let wednesday = String(localized: "Wed")
        static let thursday = String(localized: "Thu")
        static let friday = String(localized: "Fri")
        static let saturday = String(localized: "Sat")

        static func dayShort(_ index: Int) -> String {
            switch index {
            case 0: return sunday
            case 1: return monday
            case 2: return tuesday
            case 3: return wednesday
            case 4: return thursday
            case 5: return friday
            case 6: return saturday
            default: return ""
            }
        }

        // Delete confirmation
        static let deleteConfirmTitle = String(localized: "Delete medication?")
        static let deleteConfirmMessage = String(localized: "This will remove the medication from your schedule.")
    }

    // MARK: - In-Progress Activity
    enum Activity {
        // Start activity
        static let startWalkNow = String(localized: "Start walk now")
        static let startNapNow = String(localized: "Start nap now")
        static let logCompletedWalk = String(localized: "Log completed walk")
        static let logCompletedNap = String(localized: "Log completed nap")

        // Activity in progress
        static let walkInProgress = String(localized: "Walk in progress")
        static let napInProgress = String(localized: "Napping")
        static func inProgressSince(time: String) -> String {
            String(localized: "Started \(time)")
        }

        // End activity
        static let endNow = String(localized: "End now")
        static let endWalk = String(localized: "End walk")
        static let wakeUp = String(localized: "Wake up")
        static func endedMinutesAgo(_ minutes: Int) -> String {
            String(localized: "Ended \(minutes) min ago")
        }
        static let cancel = String(localized: "Cancel activity")
        static let discardActivity = String(localized: "Discard without logging")

        // Time display
        static func elapsed(_ duration: String) -> String {
            String(localized: "\(duration) elapsed")
        }

        // Suggestions
        static let usuallyWakesAroundNow = String(localized: "Usually wakes around now")
        static let napTimeEnding = String(localized: "Nap time ending")
        static let walkDue = String(localized: "Walk is due")
        static let timeForPotty = String(localized: "Time for potty")

        // Sheet titles
        static let startActivity = String(localized: "Start or Log?")
        static let endActivity = String(localized: "End Activity")

        // Presets
        static func minutesAgo(_ minutes: Int) -> String {
            String(localized: "\(minutes) min ago")
        }
    }

    // MARK: - Live Activity (Nap Timer)
    enum LiveActivity {
        static func isNapping(name: String) -> String {
            String(localized: "\(name) is napping")
        }
        static let wake = String(localized: "Wake")
        static let wakeUp = String(localized: "Wake Up")
        static let started = String(localized: "Started")
        static let openAppToEndNap = String(localized: "Open app to end nap")
    }

    // MARK: - Siri & Shortcuts
    enum Siri {
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
