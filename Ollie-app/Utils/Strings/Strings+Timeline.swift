//
//  Strings+Timeline.swift
//  Ollie-app
//
//  Timeline, upcoming events, potty status, and sleep status strings

import Foundation

extension Strings {

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
        static let logNow = String(localized: "Log potty")

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
        static let wakeUp = String(localized: "Wake up")
        static let startNap = String(localized: "Start nap")

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

    // MARK: - Duration Picker
    enum DurationPicker {
        static let startTime = String(localized: "Start")
        static let endTime = String(localized: "End")
        static let duration = String(localized: "Duration")
    }

    // MARK: - Walk Log Sheet
    enum WalkLog {
        static let title = String(localized: "Log Walk")
        static let startTime = String(localized: "Start time")
        static let endTime = String(localized: "End time")
        static let duration = String(localized: "Duration")
        static func durationMinutes(_ minutes: Int) -> String {
            String(localized: "\(minutes) min")
        }
        static let pottyDuringWalk = String(localized: "Potty during walk")
        static let pee = String(localized: "Pee")
        static let poop = String(localized: "Poop")
        static let pickSpot = String(localized: "Pick spot")
        static let notePlaceholder = String(localized: "Notes (optional)")
        static let logWalk = String(localized: "Log Walk")
    }

    // MARK: - Nap Log Sheet
    enum NapLog {
        static let title = String(localized: "Log Nap")
        static let startTime = String(localized: "Fell asleep")
        static let endTime = String(localized: "Woke up")
        static let duration = String(localized: "Duration")
        static func durationMinutes(_ minutes: Int) -> String {
            String(localized: "\(minutes) min")
        }
        static let notePlaceholder = String(localized: "Notes (optional)")
        static let logNap = String(localized: "Log Nap")
    }

    // MARK: - Walk Session Row
    enum WalkSession {
        static let walk = String(localized: "Walk")
        static let peed = String(localized: "peed")
        static let pooped = String(localized: "pooped")
    }

    // MARK: - Poop Status Card
    enum PoopStatus {
        static let accessibility = String(localized: "Poop status")
        static let title = String(localized: "Poop")
        static let logNow = String(localized: "Log poop")

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

    // MARK: - Upcoming Events Card
    enum Upcoming {
        static let title = String(localized: "Coming up")
        static let overdue = String(localized: "overdue")
        static let logNow = String(localized: "Log now")
        static func laterToday(_ count: Int) -> String {
            String(localized: "\(count) later today")
        }
        static func showAll(_ count: Int) -> String {
            String(localized: "Show all (\(count))")
        }
        static let showLess = String(localized: "Show less")
    }

    // MARK: - Actionable Event Card
    enum Actionable {
        // Approaching state (can start early)
        static func walkInMinutes(_ minutes: Int) -> String {
            String(localized: "Walk in \(minutes) min")
        }
        static func mealInMinutes(_ minutes: Int) -> String {
            String(localized: "Meal in \(minutes) min")
        }
        static let startEarly = String(localized: "Start early")

        // Due state (time to start)
        static let timeForWalk = String(localized: "Time for a walk")
        static let timeForMeal = String(localized: "Time for a meal")
        static let start = String(localized: "Start")

        // Overdue state
        static func walkOverdue(_ minutes: Int) -> String {
            String(localized: "Walk overdue by \(minutes) min")
        }
        static func mealOverdue(_ minutes: Int) -> String {
            String(localized: "Meal overdue by \(minutes) min")
        }

        // Status labels
        static let approaching = String(localized: "Soon")
        static let due = String(localized: "Now")
        static let overdueLabel = String(localized: "Overdue")
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

        // Pattern trigger names
        static let afterSleep = String(localized: "After sleep")
        static let afterEating = String(localized: "After eating")
        static let duringWalk = String(localized: "During walk")
        static let afterDrinking = String(localized: "After drinking")
        static let afterPlaying = String(localized: "After playing")
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

    // MARK: - Weather
    enum Weather {
        static let loading = String(localized: "Loading weather...")
        static let rainExpected = String(localized: "Rain expected")
        static let dryAhead = String(localized: "Dry ahead")
        static let rainSoon = String(localized: "Rain soon")
        static let freezing = String(localized: "Freezing")
        static let windy = String(localized: "Windy")
        static func temperature(_ temp: Int) -> String {
            String(localized: "\(temp)°")
        }
        static func precipitation(_ percent: Int) -> String {
            String(localized: "\(percent)%")
        }
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

    // MARK: - Combined Sleep + Potty Status
    enum CombinedStatus {
        // Combined card (sleeping + potty urgent)
        static func sleepingFor(duration: String) -> String {
            String(localized: "Sleeping for \(duration)")
        }
        static func pottyOverdueWhileSleeping(minutes: Int) -> String {
            String(localized: "Potty is \(minutes) min overdue")
        }
        static let pottyUrgentWhileSleeping = String(localized: "Potty needed soon")
        static let whenWakesTakeOutside = String(localized: "When she wakes, take her outside")
        static let wakeUp = String(localized: "Wake Up")
        static let sleepingPottyLabel = String(localized: "Sleeping")

        // Post-wake card
        static let awakeTimePotty = String(localized: "She's awake — time for potty!")
        static func pottyWasOverdue(minutes: Int) -> String {
            String(localized: "Potty was \(minutes) min overdue")
        }
        static let postNapPottyRecommended = String(localized: "Post-nap potty break recommended")
        static let logPotty = String(localized: "Log Potty")
        static let postWakeLabel = String(localized: "Just woke")

        // Accessibility
        static let combinedCardAccessibility = String(localized: "Sleep and potty status")
        static let postWakeCardAccessibility = String(localized: "Post-wake potty reminder")
    }
}
