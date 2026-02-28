//
//  WebhookConfig.swift
//  OllieShared
//
//  Configuration for webhook integrations

import Foundation

/// Settings for webhook integrations
public struct WebhookConfig: Codable, Sendable {
    public var isEnabled: Bool
    public var webhookURL: String?
    public var enabledEventTypes: Set<EventType>?
    public var includeEventDetails: Bool
    public var includePuppyName: Bool

    public init(
        isEnabled: Bool = false,
        webhookURL: String? = nil,
        enabledEventTypes: Set<EventType>? = nil,
        includeEventDetails: Bool = true,
        includePuppyName: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.webhookURL = webhookURL
        self.enabledEventTypes = enabledEventTypes
        self.includeEventDetails = includeEventDetails
        self.includePuppyName = includePuppyName
    }

    public static func defaultConfig() -> WebhookConfig {
        WebhookConfig()
    }

    /// Check if a specific event type should trigger a webhook
    public func shouldSendWebhook(for eventType: EventType) -> Bool {
        guard isEnabled, webhookURL != nil else { return false }

        // If no specific types are set, send for all events
        guard let enabledTypes = enabledEventTypes else { return true }

        return enabledTypes.contains(eventType)
    }

    /// Parsed URL for the webhook endpoint
    public var url: URL? {
        guard let urlString = webhookURL, !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }
}

// MARK: - Webhook Payload

/// Payload sent to webhook endpoints
public struct WebhookPayload: Codable, Sendable {
    public let event: String
    public let timestamp: String
    public let data: WebhookEventData

    public init(event: PuppyEvent, puppyName: String?, includeDetails: Bool) {
        self.event = "event.logged"
        self.timestamp = ISO8601DateFormatter().string(from: Date())
        self.data = WebhookEventData(event: event, puppyName: puppyName, includeDetails: includeDetails)
    }
}

/// Event data included in webhook payload
public struct WebhookEventData: Codable, Sendable {
    public let eventId: String
    public let eventType: String
    public let eventTime: String
    public let puppyName: String?
    public let location: String?
    public let note: String?
    public let durationMinutes: Int?
    public let who: String?
    public let exercise: String?
    public let result: String?
    public let weightKg: Double?

    public init(event: PuppyEvent, puppyName: String?, includeDetails: Bool) {
        self.eventId = event.id.uuidString
        self.eventType = event.type.rawValue
        self.eventTime = ISO8601DateFormatter().string(from: event.time)
        self.puppyName = puppyName

        if includeDetails {
            self.location = event.location?.rawValue
            self.note = event.note
            self.durationMinutes = event.durationMin
            self.who = event.who
            self.exercise = event.exercise
            self.result = event.result
            self.weightKg = event.weightKg
        } else {
            self.location = nil
            self.note = nil
            self.durationMinutes = nil
            self.who = nil
            self.exercise = nil
            self.result = nil
            self.weightKg = nil
        }
    }
}
