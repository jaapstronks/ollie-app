//
//  Strings+Timeline.swift
//  Ollie-app
//
//  Timeline, upcoming events, potty status, and sleep status strings

import Foundation

private let table = "Timeline"

extension Strings {

    // MARK: - Timeline
    enum Timeline {
        static let previousDay = String(localized: "Previous day", table: table)
        static let nextDay = String(localized: "Next day", table: table)
        static func dateLabel(date: String) -> String {
            String(localized: "Date: \(date)", table: table)
        }

        static let noEvents = String(localized: "No events yet", table: table)
        static let tapToLog = String(localized: "Tap below to log the first one", table: table)

        static let deleteConfirmTitle = String(localized: "Delete?", table: table)
        static func deleteConfirmMessage(event: String, time: String) -> String {
            String(localized: "Are you sure you want to delete '\(event)' from \(time)?", table: table)
        }
        static let eventDeleted = String(localized: "Event deleted", table: table)
        static let undoAccessibility = String(localized: "Double-tap Undo to restore", table: table)
        static let goToTodayHint = String(localized: "Double-tap to go to today", table: table)
    }

    // MARK: - Potty Status Card
    enum PottyStatus {
        static let accessibility = String(localized: "Potty status", table: table)
        static let justWent = String(localized: "All good", table: table)
        static let normal = String(localized: "On track", table: table)
        static let attention = String(localized: "Heads up", table: table)
        static let soonTime = String(localized: "Soon", table: table)
        static let now = String(localized: "Now!", table: table)
        static let accident = String(localized: "Accident", table: table)
        static let unknown = String(localized: "No data", table: table)
        static let logNow = String(localized: "Log potty", table: table)

        static func predictionHint(name: String) -> String {
            String(localized: "Shows prediction for when \(name) needs to pee", table: table)
        }
    }

    // MARK: - Sleep Status Card
    enum SleepStatus {
        static let title = String(localized: "Sleep status", table: table)
        static let sleeping = String(localized: "Napping", table: table)
        static let awake = String(localized: "Awake", table: table)
        static let napTime = String(localized: "Nap time!", table: table)
        static let attention = String(localized: "Tired?", table: table)
        static let wakeUp = String(localized: "Wake up", table: table)
        static let startNap = String(localized: "Start nap", table: table)

        // Sleep duration variants based on how long sleeping
        static let justFellAsleep = String(localized: "Just fell asleep", table: table)
        static func sleepingBriefly(duration: String) -> String {
            String(localized: "Sleeping for \(duration)", table: table)
        }
        static func sleepingFor(duration: String) -> String {
            String(localized: "Been sleeping for \(duration)", table: table)
        }
        static func awakeTooLong(duration: String) -> String {
            String(localized: "Awake for \(duration) — time for a nap!", table: table)
        }
        static func awakeWithNapSuggestion(duration: String, remaining: Int) -> String {
            String(localized: "Awake \(duration) — nap in \(remaining) min?", table: table)
        }
        static func awakeSince(duration: String) -> String {
            String(localized: "Awake for \(duration)", table: table)
        }
        static let noSleepData = String(localized: "No sleep data", table: table)
        static func started(time: String) -> String {
            String(localized: "Started: \(time)", table: table)
        }
        static func awakeSinceTime(time: String) -> String {
            String(localized: "Awake since: \(time)", table: table)
        }

        // Pending activities while sleeping (shown in subtitle)
        static let afterWakeTimeForWalk = String(localized: "After waking: time for a walk", table: table)
        static let afterWakeTimeForMeal = String(localized: "After waking: time for a meal", table: table)
    }

    // MARK: - Sleep Session (Timeline display)
    enum SleepSession {
        static let nap = String(localized: "Nap", table: table)
        static let sleeping = String(localized: "Sleeping...", table: table)
        static let endSleep = String(localized: "End sleep", table: table)
        static let wakeUpTime = String(localized: "Wake-up time", table: table)
        static let logWakeUp = String(localized: "Log wake-up", table: table)
        static let shortNap = String(localized: "short", table: table)
        static let deleteSessionTitle = String(localized: "Delete sleep session?", table: table)
        static let deleteSessionMessage = String(localized: "This will delete both the sleep and wake-up events.", table: table)
        static let editStartTime = String(localized: "Edit sleep time", table: table)
        static let editEndTime = String(localized: "Edit wake-up time", table: table)
    }

    // MARK: - Duration Picker
    enum DurationPicker {
        static let startTime = String(localized: "Start", table: table)
        static let endTime = String(localized: "End", table: table)
        static let duration = String(localized: "Duration", table: table)
    }

    // MARK: - Walk Log Sheet
    enum WalkLog {
        static let title = String(localized: "Log Walk", table: table)
        static let startTime = String(localized: "Start time", table: table)
        static let endTime = String(localized: "End time", table: table)
        static let duration = String(localized: "Duration", table: table)
        static func durationMinutes(_ minutes: Int) -> String {
            String(localized: "\(minutes) min", table: table)
        }
        static let pottyDuringWalk = String(localized: "Potty during walk", table: table)
        static let pee = String(localized: "Pee", table: table)
        static let poop = String(localized: "Poop", table: table)
        static let pickSpot = String(localized: "Pick spot", table: table)
        static let notePlaceholder = String(localized: "Notes (optional)", table: table)
        static let logWalk = String(localized: "Log Walk", table: table)
    }

    // MARK: - Nap Log Sheet
    enum NapLog {
        static let title = String(localized: "Log Nap", table: table)
        static let startTime = String(localized: "Fell asleep", table: table)
        static let endTime = String(localized: "Woke up", table: table)
        static let duration = String(localized: "Duration", table: table)
        static func durationMinutes(_ minutes: Int) -> String {
            String(localized: "\(minutes) min", table: table)
        }
        static let notePlaceholder = String(localized: "Notes (optional)", table: table)
        static let logNap = String(localized: "Log Nap", table: table)
        static let napDate = String(localized: "Date", table: table)
        static let startedPreviousNight = String(localized: "Started previous night", table: table)
        static let overnightHint = String(localized: "The nap started before midnight and ended on the selected date", table: table)
    }

    // MARK: - Walk Session Row
    enum WalkSession {
        static let walk = String(localized: "Walk", table: table)
        static let peed = String(localized: "peed", table: table)
        static let pooped = String(localized: "pooped", table: table)
    }

    // MARK: - Poop Status Card
    enum PoopStatus {
        static let accessibility = String(localized: "Poop status", table: table)
        static let title = String(localized: "Poop", table: table)
        static let logNow = String(localized: "Log poop", table: table)

        // Count display
        static func todayCount(_ count: Int, expectedLower: Int, expectedUpper: Int) -> String {
            if count == 1 {
                return String(localized: "1 poop today (expect ~\(expectedLower)-\(expectedUpper))", table: table)
            } else {
                return String(localized: "\(count) poops today (expect ~\(expectedLower)-\(expectedUpper))", table: table)
            }
        }
        static func todayCountSimple(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 poop today", table: table)
            } else {
                return String(localized: "\(count) poops today", table: table)
            }
        }

        // Status labels
        static let good = String(localized: "On track", table: table)
        static let info = String(localized: "Info", table: table)
        static let note = String(localized: "Note", table: table)

        // Status messages (subtle, not alarming)
        static let noPoopYetEarly = String(localized: "No poop yet this morning", table: table)
        static let noPoopYet = String(localized: "No poop yet today", table: table)
        static let walkCompletedNoPoop = String(localized: "Walk done — no poop logged", table: table)
        static let longerThanUsual = String(localized: "Longer gap than usual", table: table)
        static let longGap = String(localized: "Been a while since last poop", table: table)
        static let belowExpected = String(localized: "Below usual for this time", table: table)

        // Time since formatting
        static func minutesAgo(_ minutes: Int) -> String {
            String(localized: "\(minutes) min ago", table: table)
        }
        static func hoursAgo(_ hours: Int) -> String {
            String(localized: "\(hours)h ago", table: table)
        }
        static func hoursMinutesAgo(hours: Int, minutes: Int) -> String {
            String(localized: "\(hours)h\(minutes)m ago", table: table)
        }
    }

    // MARK: - Upcoming Events Card
    enum Upcoming {
        static let title = String(localized: "Coming up", table: table)
        static let overdue = String(localized: "overdue", table: table)
        static let logNow = String(localized: "Log now", table: table)
        static func laterToday(_ count: Int) -> String {
            String(localized: "\(count) later today", table: table)
        }
        static func showAll(_ count: Int) -> String {
            String(localized: "Show all (\(count))", table: table)
        }
        static let showLess = String(localized: "Show less", table: table)
    }

    // MARK: - Actionable Event Card
    enum Actionable {
        // Approaching state (can start early)
        static func walkInMinutes(_ minutes: Int) -> String {
            String(localized: "Walk in \(minutes) min", table: table)
        }
        static func mealInMinutes(_ minutes: Int) -> String {
            String(localized: "Meal in \(minutes) min", table: table)
        }
        static let startEarly = String(localized: "Start early", table: table)

        // Due state (time to start)
        static let timeForWalk = String(localized: "Time for a walk", table: table)
        static let timeForMeal = String(localized: "Time for a meal", table: table)
        static let start = String(localized: "Start", table: table)

        // Overdue state
        static func walkOverdue(_ minutes: Int) -> String {
            String(localized: "Walk overdue by \(minutes) min", table: table)
        }
        static func mealOverdue(_ minutes: Int) -> String {
            String(localized: "Meal overdue by \(minutes) min", table: table)
        }
        static func wasScheduledAt(time: String) -> String {
            String(localized: "Was scheduled at \(time)", table: table)
        }

        // Status labels
        static let approaching = String(localized: "Soon", table: table)
        static let due = String(localized: "Now", table: table)
        static let overdueLabel = String(localized: "Overdue", table: table)
    }

    // MARK: - Digest Card
    enum Digest {
        static let dayLabel = String(localized: "Day", table: table)
        static func dayNumber(_ day: Int) -> String {
            String(localized: "Day \(day)", table: table)
        }
        static func withPuppy(name: String) -> String {
            String(localized: "with \(name)", table: table)
        }
    }

    // MARK: - Pattern Analysis Card
    enum Patterns {
        static let insufficientData = String(localized: "Not enough data for patterns yet", table: table)
        static func successRate(_ rate: Int) -> String {
            String(localized: "\(rate)%", table: table)
        }
        static func count(_ count: Int) -> String {
            String(localized: "(\(count)x)", table: table)
        }
        static let percentSuccess = String(localized: "percent success", table: table)
        static let timesMeasured = String(localized: "times measured", table: table)

        // Pattern trigger names
        static let afterSleep = String(localized: "After sleep", table: table)
        static let afterEating = String(localized: "After eating", table: table)
        static let duringWalk = String(localized: "During walk", table: table)
        static let afterDrinking = String(localized: "After drinking", table: table)
        static let afterPlaying = String(localized: "After playing", table: table)
    }

    // MARK: - Time Formatting
    enum TimeFormat {
        static let noData = String(localized: "No data", table: table)
        static func minutesAgo(_ minutes: Int) -> String {
            String(localized: "\(minutes) min ago", table: table)
        }
        static func hoursAgo(_ hours: Int) -> String {
            String(localized: "\(hours) hours ago", table: table)
        }
        static func hoursMinutesAgo(hours: Int, minutes: Int) -> String {
            String(localized: "\(hours)h \(minutes)m ago", table: table)
        }
        static func stillMinutes(_ minutes: Int) -> String {
            String(localized: "~\(minutes) min remaining", table: table)
        }
        static func afterEatingAgo(_ minutes: Int) -> String {
            String(localized: "(after eating \(minutes)m ago)", table: table)
        }
        static func afterNapAgo(_ minutes: Int) -> String {
            String(localized: "(after nap \(minutes)m ago)", table: table)
        }
        static let inside = String(localized: "- inside", table: table)
    }

    // MARK: - Prediction Display
    enum Prediction {
        static let justPeed = String(localized: "Just peed", table: table)
        static func nextIn(_ minutes: Int) -> String {
            String(localized: "Pee in ~\(minutes) min", table: table)
        }
        static let soon = String(localized: "Pee soon!", table: table)
        static func needsToPeeNow(name: String) -> String {
            String(localized: "\(name) needs to pee now!", table: table)
        }
        static func needsToPeeNowOverdue(name: String, minutes: Int) -> String {
            String(localized: "\(name) needs to pee now! (\(minutes) min overdue)", table: table)
        }
        static let afterAccidentGoOutside = String(localized: "After accident — go outside now!", table: table)
    }

    // MARK: - Weather
    enum Weather {
        static let loading = String(localized: "Loading weather...", table: table)
        static let rainExpected = String(localized: "Rain expected", table: table)
        static let dryAhead = String(localized: "Dry ahead", table: table)
        static let rainSoon = String(localized: "Rain soon", table: table)
        static let freezing = String(localized: "Freezing", table: table)
        static let windy = String(localized: "Windy", table: table)
        static func temperature(_ temp: Int) -> String {
            String(localized: "\(temp)°", table: table)
        }
        static func precipitation(_ percent: Int) -> String {
            String(localized: "\(percent)%", table: table)
        }
    }

    // MARK: - In-Progress Activity
    enum Activity {
        // Start activity
        static let startWalkNow = String(localized: "Start walk now", table: table)
        static let startNapNow = String(localized: "Start nap now", table: table)
        static let logCompletedWalk = String(localized: "Log completed walk", table: table)
        static let logCompletedNap = String(localized: "Log completed nap", table: table)

        // Activity in progress
        static let walkInProgress = String(localized: "Walk in progress", table: table)
        static let napInProgress = String(localized: "Napping", table: table)
        static func inProgressSince(time: String) -> String {
            String(localized: "Started \(time)", table: table)
        }

        // End activity
        static let endNow = String(localized: "End now", table: table)
        static let endWalk = String(localized: "End walk", table: table)
        static let wakeUp = String(localized: "Wake up", table: table)
        static func endedMinutesAgo(_ minutes: Int) -> String {
            String(localized: "Ended \(minutes) min ago", table: table)
        }
        static let cancel = String(localized: "Cancel activity", table: table)
        static let discardActivity = String(localized: "Discard without logging", table: table)

        // Time display
        static func elapsed(_ duration: String) -> String {
            String(localized: "\(duration) elapsed", table: table)
        }

        // Suggestions
        static let usuallyWakesAroundNow = String(localized: "Usually wakes around now", table: table)
        static let napTimeEnding = String(localized: "Nap time ending", table: table)
        static let walkDue = String(localized: "Walk is due", table: table)
        static let timeForPotty = String(localized: "Time for potty", table: table)

        // Sheet titles
        static let startActivity = String(localized: "Start or Log?", table: table)
        static let endActivity = String(localized: "End Activity", table: table)

        // Presets
        static func minutesAgo(_ minutes: Int) -> String {
            String(localized: "\(minutes) min ago", table: table)
        }
    }

    // MARK: - Live Activity (Nap Timer)
    enum LiveActivity {
        static func isNapping(name: String) -> String {
            String(localized: "\(name) is napping", table: table)
        }
        static let wake = String(localized: "Wake", table: table)
        static let wakeUp = String(localized: "Wake Up", table: table)
        static let started = String(localized: "Started", table: table)
        static let openAppToEndNap = String(localized: "Open app to end nap", table: table)
    }

    // MARK: - Combined Sleep + Potty Status
    enum CombinedStatus {
        // Combined card (sleeping + potty urgent)
        // Sleep duration variants based on how long sleeping
        static let justFellAsleep = String(localized: "Just fell asleep", table: table)
        static func sleepingBriefly(duration: String) -> String {
            String(localized: "Sleeping for \(duration)", table: table)
        }
        static func sleepingFor(duration: String) -> String {
            String(localized: "Been sleeping for \(duration)", table: table)
        }
        static func pottyOverdueWhileSleeping(minutes: Int) -> String {
            String(localized: "Potty is \(minutes) min overdue", table: table)
        }
        static let pottyUrgentWhileSleeping = String(localized: "Potty needed soon", table: table)
        static let whenWakesTakeOutside = String(localized: "When she wakes, take her outside", table: table)
        static let wakeUp = String(localized: "Wake Up", table: table)
        static let sleepingPottyLabel = String(localized: "Sleeping", table: table)

        // Post-wake card
        static let awakeTimePotty = String(localized: "She's awake — time for potty!", table: table)
        static func pottyWasOverdue(minutes: Int) -> String {
            String(localized: "Potty was \(minutes) min overdue", table: table)
        }
        static let postNapPottyRecommended = String(localized: "Post-nap potty break recommended", table: table)
        static let logPotty = String(localized: "Log Potty", table: table)
        static let postWakeLabel = String(localized: "Just woke", table: table)

        // Accessibility
        static let combinedCardAccessibility = String(localized: "Sleep and potty status", table: table)
        static let postWakeCardAccessibility = String(localized: "Post-wake potty reminder", table: table)
    }
}
