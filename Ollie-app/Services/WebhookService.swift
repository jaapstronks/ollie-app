//
//  WebhookService.swift
//  Ollie-app
//
//  Sends webhook notifications when events are logged

import Foundation
import OllieShared
import os

/// Service for sending webhook notifications
@MainActor
class WebhookService: ObservableObject {
    static let shared = WebhookService()

    @Published private(set) var lastError: Error?
    @Published private(set) var isSending = false
    @Published private(set) var lastSentTime: Date?
    @Published private(set) var lastStatusCode: Int?

    private let logger = Logger.ollie(category: "WebhookService")

    /// Request timeout in seconds
    private let requestTimeout: TimeInterval = 10

    private init() {}

    // MARK: - Public Methods

    /// Send a webhook for an event if configured
    func sendEventWebhook(_ event: PuppyEvent, config: WebhookConfig, puppyName: String?) async {
        // Check if we should send for this event type
        guard config.shouldSendWebhook(for: event.type),
              let url = config.url else {
            return
        }

        isSending = true
        lastError = nil

        do {
            let payload = WebhookPayload(
                event: event,
                puppyName: config.includePuppyName ? puppyName : nil,
                includeDetails: config.includeEventDetails
            )

            try await sendWebhook(payload: payload, to: url)
            lastSentTime = Date()
            logger.info("Webhook sent successfully for event: \(event.type.rawValue)")
        } catch {
            lastError = error
            logger.error("Webhook failed: \(error.localizedDescription)")
        }

        isSending = false
    }

    /// Test webhook configuration by sending a test payload
    func testWebhook(config: WebhookConfig, puppyName: String?) async -> Result<Int, WebhookError> {
        guard let url = config.url else {
            return .failure(.invalidURL)
        }

        // Create a test event
        let testEvent = PuppyEvent(
            time: Date(),
            type: .milestone,
            note: "Webhook test"
        )

        let payload = WebhookPayload(
            event: testEvent,
            puppyName: config.includePuppyName ? puppyName : nil,
            includeDetails: config.includeEventDetails
        )

        do {
            let statusCode = try await sendWebhook(payload: payload, to: url)
            return .success(statusCode)
        } catch let error as WebhookError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }

    /// Validate a webhook URL
    func validateURL(_ urlString: String) -> WebhookURLValidation {
        guard !urlString.isEmpty else {
            return .empty
        }

        guard let url = URL(string: urlString) else {
            return .invalid
        }

        guard url.scheme == "https" || url.scheme == "http" else {
            return .invalidScheme
        }

        guard url.host != nil else {
            return .noHost
        }

        // Warn about HTTP (non-secure)
        if url.scheme == "http" {
            return .validButInsecure
        }

        return .valid
    }

    // MARK: - Private Methods

    @discardableResult
    private func sendWebhook(payload: WebhookPayload, to url: URL) async throws -> Int {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Ollie-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = requestTimeout

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        request.httpBody = try encoder.encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebhookError.invalidResponse
        }

        lastStatusCode = httpResponse.statusCode

        // Accept 2xx status codes as success
        guard (200...299).contains(httpResponse.statusCode) else {
            throw WebhookError.httpError(httpResponse.statusCode)
        }

        return httpResponse.statusCode
    }
}

// MARK: - Webhook Errors

enum WebhookError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return Strings.Webhook.errorInvalidURL
        case .invalidResponse:
            return Strings.Webhook.errorInvalidResponse
        case .httpError(let code):
            return Strings.Webhook.errorHTTP(code: code)
        case .networkError(let message):
            return Strings.Webhook.errorNetwork(message: message)
        }
    }
}

// MARK: - URL Validation Result

enum WebhookURLValidation {
    case empty
    case invalid
    case invalidScheme
    case noHost
    case validButInsecure
    case valid

    var isValid: Bool {
        self == .valid || self == .validButInsecure
    }

    var message: String? {
        switch self {
        case .empty:
            return nil
        case .invalid:
            return Strings.Webhook.urlInvalid
        case .invalidScheme:
            return Strings.Webhook.urlInvalidScheme
        case .noHost:
            return Strings.Webhook.urlNoHost
        case .validButInsecure:
            return Strings.Webhook.urlInsecureWarning
        case .valid:
            return nil
        }
    }
}
