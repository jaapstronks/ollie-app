//
//  Strings+Events.swift
//  Ollie-app
//
//  Event types, locations, and logging strings

import Foundation

extension Strings {

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
        static let timeHint = String(localized: "Double-tap to change time")
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

        // Accessibility
        static func photoOf(_ eventType: String) -> String {
            String(localized: "Photo of \(eventType) event")
        }
        static let zoomHint = String(localized: "Pinch to zoom, double-tap to toggle zoom")
        static let hasLocation = String(localized: "Has location data")
    }

    // MARK: - Time Adjust Button
    enum TimeAdjust {
        static func accessibilityLabel(_ minutes: Int) -> String {
            String(localized: "\(minutes) minutes ago")
        }
        static let accessibilityHint = String(localized: "Double-tap to adjust time")
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
}
