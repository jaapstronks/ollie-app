//
//  Strings+Events.swift
//  Ollie-app
//
//  Event types, locations, and logging strings

import Foundation

private let table = "Events"

extension Strings {

    // MARK: - Event Types
    enum EventType {
        static let eat = String(localized: "Eat", table: table)
        static let drink = String(localized: "Drink", table: table)
        static let pee = String(localized: "Pee", table: table)
        static let poop = String(localized: "Poop", table: table)
        static let sleep = String(localized: "Sleep", table: table)
        static let wakeUp = String(localized: "Wake up", table: table)
        static let walk = String(localized: "Walk", table: table)
        static let garden = String(localized: "Garden", table: table)
        static let training = String(localized: "Training", table: table)
        static let crate = String(localized: "Crate", table: table)
        static let social = String(localized: "Social", table: table)
        static let milestone = String(localized: "Milestone", table: table)
        static let behavior = String(localized: "Behavior", table: table)
        static let weight = String(localized: "Weight", table: table)
        static let moment = String(localized: "Moment", table: table)
        static let medication = String(localized: "Medication", table: table)
    }

    // MARK: - Event Locations
    enum EventLocation {
        static let outside = String(localized: "Outside", table: table)
        static let inside = String(localized: "Inside", table: table)
    }

    // MARK: - Quick Log Bar
    enum QuickLog {
        static let toilet = String(localized: "Toilet", table: table)
        static let more = String(localized: "More", table: table)
        static let photo = String(localized: "Photo", table: table)

        static let toiletAccessibility = String(localized: "Log toilet", table: table)
        static let toiletAccessibilityHint = String(localized: "Double-tap to log pee or poop", table: table)
        static let moreAccessibility = String(localized: "More event types", table: table)
        static let moreAccessibilityHint = String(localized: "Double-tap to see all event types", table: table)
        static let photoAccessibility = String(localized: "Take photo", table: table)
        static let photoAccessibilityHint = String(localized: "Double-tap to capture a photo moment", table: table)

        // Dynamic event logging accessibility
        static func logEventAccessibility(_ eventLabel: String) -> String {
            String(localized: "Log \(eventLabel)", table: table)
        }
        static func logEventAccessibilityHint(_ eventLabel: String) -> String {
            String(localized: "Double-tap to log \(eventLabel)", table: table)
        }
    }

    // MARK: - Quick Log Sheet
    enum QuickLogSheet {
        static let time = String(localized: "Time", table: table)
        static let timeHint = String(localized: "Double-tap to change time", table: table)
        static let where_ = String(localized: "Where?", table: table)
        static let what = String(localized: "What?", table: table)
        static let noteOptional = String(localized: "Note (optional)", table: table)
        static let notePlaceholder = String(localized: "E.g. after eating, in the garden...", table: table)
        static let selected = String(localized: "Selected", table: table)
        static let noteAccessibilityHint = String(localized: "Enter an optional note", table: table)

        static func minutesAgo(_ minutes: Int) -> String {
            String(localized: "\(minutes) min", table: table)
        }
        static func locationAccessibility(_ location: String) -> String {
            String(localized: "\(location) location", table: table)
        }
    }

    // MARK: - All Events Sheet
    enum AllEvents {
        static let title = String(localized: "Log event", table: table)
        static let moreEvents = String(localized: "More events", table: table)
        static let quickEvents = String(localized: "Quick events", table: table)
    }

    // MARK: - Log Event Sheet
    enum LogEvent {
        static let details = String(localized: "Details", table: table)
        static let note = String(localized: "Note", table: table)
        static let notePlaceholder = String(localized: "Optional note...", table: table)
        static let who = String(localized: "Who?", table: table)
        static let whoPlaceholder = String(localized: "Name of person or animal", table: table)
        static let training = String(localized: "Training", table: table)
        static let exercise = String(localized: "Exercise", table: table)
        static let result = String(localized: "Result", table: table)
        static let duration = String(localized: "Duration", table: table)

        // Accessibility
        static let noteAccessibilityHint = String(localized: "Enter an optional note", table: table)
        static let whoAccessibility = String(localized: "With who", table: table)
        static let whoAccessibilityHint = String(localized: "Enter the name of a person or animal", table: table)
        static let exerciseAccessibilityHint = String(localized: "Enter the training exercise name", table: table)
        static let resultAccessibilityHint = String(localized: "Enter the training result", table: table)
        static let durationAccessibility = String(localized: "Duration in minutes", table: table)
        static let durationAccessibilityHint = String(localized: "Enter the duration in minutes", table: table)
    }

    // MARK: - Potty Quick Log Sheet
    enum PottyQuickLog {
        static let toilet = String(localized: "Toilet", table: table)
        static let what = String(localized: "What?", table: table)
        static let where_ = String(localized: "Where?", table: table)
        static let noteOptional = String(localized: "Note (optional)", table: table)
        static let notePlaceholder = String(localized: "E.g. after eating, in the garden...", table: table)
        static let pee = String(localized: "Pee", table: table)
        static let poop = String(localized: "Poop", table: table)
        static let both = String(localized: "Both", table: table)
        static let time = String(localized: "Time", table: table)
        static func minutesAgo(_ minutes: Int) -> String {
            String(localized: "\(minutes) min", table: table)
        }

        // Accessibility
        static func timeAccessibility(_ time: String) -> String {
            String(localized: "Time: \(time)", table: table)
        }
        static let timeAccessibilityHint = String(localized: "Double-tap to change time", table: table)
        static let logAccessibility = String(localized: "Log toilet event", table: table)
        static let logAccessibilityHint = String(localized: "Double-tap to save", table: table)
        static let selectRequiredFields = String(localized: "Select type and location first", table: table)
        static func pottyTypeHint(_ type: String) -> String {
            String(localized: "Double-tap to select \(type)", table: table)
        }
    }

    // MARK: - Event Row
    enum EventRow {
        static func duration(_ minutes: Int) -> String {
            String(localized: "\(minutes) min", table: table)
        }
        static let tapToViewPhoto = String(localized: "Tap to view photo", table: table)
        static let tapToViewMedia = String(localized: "Double-tap to view attached media", table: table)
        static func withPerson(_ name: String) -> String {
            String(localized: "with \(name)", table: table)
        }
    }

    // MARK: - Log Moment Sheet
    enum LogMoment {
        static let title = String(localized: "Moment", table: table)
        static let dateFromPhoto = String(localized: "Date from photo", table: table)
        static let date = String(localized: "Date", table: table)
        static let nowNoDateInPhoto = String(localized: "Now (no date in photo)", table: table)
        static let locationFromPhoto = String(localized: "Location from photo", table: table)
        static let note = String(localized: "Note", table: table)
        static let whatHappened = String(localized: "What happened?", table: table)
    }

    // MARK: - Moments Gallery View
    enum MomentsGallery {
        static let title = String(localized: "Moments", table: table)
        static let noPhotos = String(localized: "No photos yet", table: table)
        static let makePhotosHint = String(localized: "Take photos using the camera button\nin the timeline", table: table)
    }

    // MARK: - Media Attachment Button
    enum MediaAttachment {
        static let remove = String(localized: "Remove", table: table)
        static let addPhoto = String(localized: "Add photo", table: table)
        static let addPhotoTitle = String(localized: "Add photo", table: table)
        static let camera = String(localized: "Camera", table: table)
        static let photoLibrary = String(localized: "Photo library", table: table)
    }

    // MARK: - Media Preview View
    enum MediaPreview {
        static let photoNotFound = String(localized: "Photo not found", table: table)
        static let deleteTitle = String(localized: "Delete?", table: table)
        static let deletePhoto = String(localized: "Delete photo", table: table)
        static let deleteConfirmMessage = String(localized: "Are you sure you want to delete this moment?", table: table)

        // Accessibility
        static func photoOf(_ eventType: String) -> String {
            String(localized: "Photo of \(eventType) event", table: table)
        }
        static let zoomHint = String(localized: "Pinch to zoom, double-tap to toggle zoom", table: table)
        static let hasLocation = String(localized: "Has location data", table: table)
    }

    // MARK: - Time Adjust Button
    enum TimeAdjust {
        static func accessibilityLabel(_ minutes: Int) -> String {
            String(localized: "\(minutes) minutes ago", table: table)
        }
        static let accessibilityHint = String(localized: "Double-tap to adjust time", table: table)
    }

    // MARK: - Location Picker
    enum LocationPicker {
        static let title = String(localized: "Where?", table: table)
    }

    // MARK: - Location Selection
    enum LocationSelection {
        static func accessibilityHint(_ location: String) -> String {
            String(localized: "Double-tap to select \(location)", table: table)
        }
    }
}
