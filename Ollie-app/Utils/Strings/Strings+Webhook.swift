//
//  Strings+Webhook.swift
//  Otis-app
//
//  Strings for webhook settings and errors

import Foundation

private let table = "Webhook"

extension Strings {

    // MARK: - Webhook Settings
    enum Webhook {
        // Section titles
        static let title = String(localized: "Webhooks", table: table)
        static let description = String(localized: "Send event data to external services when events are logged.", table: table)

        // Configuration
        static let webhookURL = String(localized: "Webhook URL", table: table)
        static let webhookURLPlaceholder = String(localized: "https://example.com/webhook", table: table)
        static let enabled = String(localized: "Enable webhooks", table: table)

        // Event types section
        static let eventTypes = String(localized: "Event types", table: table)
        static let eventTypesDescription = String(localized: "Select which events trigger webhooks. If none selected, all events will trigger.", table: table)
        static let allEvents = String(localized: "All events", table: table)
        static let selectEvents = String(localized: "Select events", table: table)

        // Options section
        static let options = String(localized: "Options", table: table)
        static let includeDetails = String(localized: "Include event details", table: table)
        static let includeDetailsDescription = String(localized: "Include notes, location, duration, and other details.", table: table)
        static let includePuppyName = String(localized: "Include puppy name", table: table)

        // Test section
        static let test = String(localized: "Test", table: table)
        static let testWebhook = String(localized: "Test webhook", table: table)
        static let testing = String(localized: "Testing...", table: table)
        static let testSuccess = String(localized: "Webhook test successful!", table: table)
        static func testSuccessWithCode(_ code: Int) -> String {
            String(localized: "Webhook test successful (HTTP \(code))", table: table)
        }
        static let testFailed = String(localized: "Webhook test failed", table: table)

        // Status
        static func lastSent(_ time: String) -> String {
            String(localized: "Last sent: \(time)", table: table)
        }

        // URL validation
        static let urlInvalid = String(localized: "Invalid URL format", table: table)
        static let urlInvalidScheme = String(localized: "URL must start with http:// or https://", table: table)
        static let urlNoHost = String(localized: "URL must include a host", table: table)
        static let urlInsecureWarning = String(localized: "Warning: HTTP is not secure. Consider using HTTPS.", table: table)

        // Errors
        static let errorInvalidURL = String(localized: "Invalid webhook URL", table: table)
        static let errorInvalidResponse = String(localized: "Invalid response from server", table: table)
        static func errorHTTP(code: Int) -> String {
            String(localized: "Server returned error (HTTP \(code))", table: table)
        }
        static func errorNetwork(message: String) -> String {
            String(localized: "Network error: \(message)", table: table)
        }

        // Footer help
        static let footer = String(localized: "Webhooks send a POST request with JSON data whenever you log an event. Use this to integrate with home automation, IFTTT, Zapier, or custom services.", table: table)
    }
}
