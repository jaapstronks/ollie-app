//
//  MomentsNotificationHandler.swift
//  Otis-app
//
//  Handles rich notifications for moments (photos) with like actions.
//  Sends notifications when household members capture new photos.
//

import Foundation
import OtisShared
import UserNotifications
import UIKit
import os

/// Handles moment notifications with image attachments and like actions
@MainActor
final class MomentsNotificationHandler: NSObject {
    static let shared = MomentsNotificationHandler()

    // MARK: - Constants

    /// Notification category identifier for moments
    static let categoryIdentifier = "MOMENT_CATEGORY"

    /// Action identifiers
    static let likeActionIdentifier = "LIKE_MOMENT"
    static let viewActionIdentifier = "VIEW_MOMENT"

    /// Notification identifier prefix
    private let notificationPrefix = "moment_"

    private let logger = Logger.otis(category: "MomentsNotificationHandler")
    private let notificationCenter = UNUserNotificationCenter.current()

    /// Track which events we've already sent notifications for (persisted)
    private var notifiedEventIds: Set<String> {
        get {
            Set(UserDefaults.standard.stringArray(forKey: "notifiedMomentEventIds") ?? [])
        }
        set {
            // Keep only the last 1000 to prevent unbounded growth
            let trimmed = Array(newValue.suffix(1000))
            UserDefaults.standard.set(trimmed, forKey: "notifiedMomentEventIds")
        }
    }

    private override init() {
        super.init()
    }

    // MARK: - Setup

    /// Register notification categories for moments.
    /// Call this once during app setup.
    func registerNotificationCategories() {
        let likeAction = UNNotificationAction(
            identifier: Self.likeActionIdentifier,
            title: Strings.PushNotifications.likeActionTitle,
            options: []  // No foreground needed - like happens in background
        )

        let viewAction = UNNotificationAction(
            identifier: Self.viewActionIdentifier,
            title: Strings.PushNotifications.viewActionTitle,
            options: .foreground  // Opens the app
        )

        let momentCategory = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [likeAction, viewAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: Strings.PushNotifications.newMomentTitle,
            options: []
        )

        notificationCenter.setNotificationCategories([momentCategory])
        logger.info("Registered moment notification category")
    }

    // MARK: - Send Notification

    /// Send a notification for a new moment from another household member.
    /// - Parameters:
    ///   - event: The moment event with a photo
    ///   - loggedByName: Display name of who logged the moment
    ///   - puppyName: The puppy's name
    ///   - settings: Current notification settings
    func sendNotification(
        for event: PuppyEvent,
        loggedByName: String,
        puppyName: String,
        settings: NotificationSettings
    ) async {
        // Check if moments notifications are enabled
        guard settings.isEnabled && settings.momentsReminders.isEnabled else {
            logger.debug("Moments notifications disabled")
            return
        }

        // Don't notify for events we've already notified about
        let eventIdString = event.id.uuidString
        guard !notifiedEventIds.contains(eventIdString) else {
            logger.debug("Already notified for event \(eventIdString)")
            return
        }

        // Check quiet hours (moments are social, not urgent)
        if settings.isInQuietHours() {
            logger.debug("Suppressing moment notification during quiet hours")
            return
        }

        // Build notification content
        let content = UNMutableNotificationContent()
        content.title = Strings.PushNotifications.newMomentTitle
        content.categoryIdentifier = Self.categoryIdentifier
        content.sound = .default

        // Use note if available, otherwise generic message
        if let note = event.note, !note.isEmpty {
            content.body = Strings.PushNotifications.newMomentWithNote(personName: loggedByName, note: note)
        } else {
            content.body = Strings.PushNotifications.newMomentBody(personName: loggedByName, puppyName: puppyName)
        }

        // Store event ID in userInfo for handling actions
        content.userInfo = [
            "eventId": event.id.uuidString,
            "type": "moment"
        ]

        // Try to attach the photo thumbnail
        if let thumbnailPath = event.thumbnailPath ?? event.photo {
            await attachImage(to: content, relativePath: thumbnailPath)
        }

        // Create immediate trigger (1 second delay)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "\(notificationPrefix)\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            notifiedEventIds.insert(eventIdString)
            logger.info("Sent moment notification for event \(eventIdString)")
        } catch {
            logger.error("Failed to send moment notification: \(error.localizedDescription)")
        }
    }

    /// Check for new moments from CloudKit sync and send notifications.
    /// Call this when remote changes are detected.
    /// - Parameters:
    ///   - newEvents: Events that appeared from sync
    ///   - currentUserRecordID: The current user's CloudKit record ID
    ///   - puppyName: The puppy's name
    ///   - settings: Current notification settings
    func handleRemoteChanges(
        newEvents: [PuppyEvent],
        currentUserRecordID: String?,
        puppyName: String,
        settings: NotificationSettings
    ) async {
        guard let currentUserRecordID = currentUserRecordID else {
            logger.debug("No current user record ID - skipping moment notifications")
            return
        }

        // Filter to moment events with photos from other users
        let momentsFromOthers = newEvents.filter { event in
            event.type == .moment &&
            event.photo != nil &&
            event.loggedBy != nil &&
            event.loggedBy != currentUserRecordID
        }

        guard !momentsFromOthers.isEmpty else {
            return
        }

        logger.info("Found \(momentsFromOthers.count) new moments from other users")

        for event in momentsFromOthers {
            // Resolve the name of who logged it
            let loggedByName = await resolveDisplayName(for: event.loggedBy)

            await sendNotification(
                for: event,
                loggedByName: loggedByName,
                puppyName: puppyName,
                settings: settings
            )
        }
    }

    // MARK: - Handle Actions

    /// Handle notification action response.
    /// - Parameter response: The notification response
    /// - Returns: true if the action was handled
    func handleNotificationResponse(_ response: UNNotificationResponse) async -> Bool {
        let userInfo = response.notification.request.content.userInfo

        guard let eventIdString = userInfo["eventId"] as? String,
              let eventId = UUID(uuidString: eventIdString),
              userInfo["type"] as? String == "moment" else {
            return false
        }

        switch response.actionIdentifier {
        case Self.likeActionIdentifier:
            await handleLikeAction(eventId: eventId)
            return true

        case Self.viewActionIdentifier, UNNotificationDefaultActionIdentifier:
            // View action or tap - let the app handle navigation
            // Post notification for the app to open the moment
            NotificationCenter.default.post(
                name: .openMomentFromNotification,
                object: nil,
                userInfo: ["eventId": eventId]
            )
            return true

        default:
            return false
        }
    }

    /// Handle the like action from a notification.
    private func handleLikeAction(eventId: UUID) async {
        logger.info("Handling like action for event \(eventId.uuidString)")

        // This needs to run on main actor to access stores
        // We'll post a notification that EventStore can handle
        NotificationCenter.default.post(
            name: .likeMomentFromNotification,
            object: nil,
            userInfo: ["eventId": eventId]
        )
    }

    // MARK: - Helpers

    /// Attach an image to the notification content.
    private func attachImage(to content: UNMutableNotificationContent, relativePath: String) async {
        let mediaStore = MediaStore()

        guard let url = mediaStore.fullURL(for: relativePath),
              FileManager.default.fileExists(atPath: url.path) else {
            logger.debug("Image not available locally for notification attachment")
            return
        }

        // Create a copy in temp directory (required for notification attachments)
        let tempDirectory = FileManager.default.temporaryDirectory
        let attachmentURL = tempDirectory.appendingPathComponent("notification_\(UUID().uuidString).jpg")

        do {
            // Copy file to temp location
            if FileManager.default.fileExists(atPath: attachmentURL.path) {
                try FileManager.default.removeItem(at: attachmentURL)
            }
            try FileManager.default.copyItem(at: url, to: attachmentURL)

            // Create attachment
            let attachment = try UNNotificationAttachment(
                identifier: "momentImage",
                url: attachmentURL,
                options: [
                    UNNotificationAttachmentOptionsTypeHintKey: "public.jpeg",
                    UNNotificationAttachmentOptionsThumbnailClippingRectKey:
                        CGRect(x: 0, y: 0, width: 1, height: 1).dictionaryRepresentation
                ]
            )

            content.attachments = [attachment]
            logger.debug("Attached image to notification")
        } catch {
            logger.warning("Could not attach image to notification: \(error.localizedDescription)")
        }
    }

    /// Resolve display name for a CloudKit record ID.
    private func resolveDisplayName(for recordID: String?) async -> String {
        guard let recordID = recordID else {
            return Strings.Common.someone
        }

        return await ParticipantResolver.shared.displayName(for: recordID)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when user taps on a moment notification to view it
    static let openMomentFromNotification = Notification.Name("openMomentFromNotification")

    /// Posted when user likes a moment from the notification action
    static let likeMomentFromNotification = Notification.Name("likeMomentFromNotification")
}
