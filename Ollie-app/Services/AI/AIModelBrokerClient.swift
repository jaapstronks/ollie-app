//
//  AIModelBrokerClient.swift
//  Otis-app
//
//  Broker client for interoperable Anthropic/Mistral nudges.
//  Includes mock mode for development testing without API calls.
//

import Foundation
import os

private let brokerLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.otis", category: "AIBrokerClient")

protocol AIModelBrokerClientProtocol {
    func decide(_ request: AINudgeBrokerRequest) async throws -> AINudgeBrokerResponse
}

enum AIModelBrokerError: Error {
    case brokerNotConfigured
    case brokerKeyNotConfigured
    case invalidResponse(statusCode: Int, body: String)
    case decodingFailed(Error, rawBody: String)
}

// MARK: - Mock Client for Development

/// Returns mock AI responses without making API calls.
/// Enable via Settings > Debug > AI Test Mode, or set UserDefaults "ai.nudges.testMode" = true
final class MockAIModelBrokerClient: AIModelBrokerClientProtocol {

    func decide(_ request: AINudgeBrokerRequest) async throws -> AINudgeBrokerResponse {
        // Simulate network delay (50-200ms)
        let delayMs = Int.random(in: 50...200)
        try await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)

        brokerLogger.info("MockClient: returning mock response for \(request.surface.rawValue)")

        switch request.surface {
        case .insightBundle:
            return mockInsightBundleResponse(for: request)
        case .notificationPolicy:
            return mockNotificationPolicyResponse(for: request)
        }
    }

    private func mockInsightBundleResponse(for request: AINudgeBrokerRequest) -> AINudgeBrokerResponse {
        // Generate context-aware mock headline
        let ageWeeks = request.context.ageWeeks
        let headline: String
        let subtitle: String?

        if ageWeeks < 16 {
            headline = "[Mock] Potty time coming up"
            subtitle = "Young puppies need frequent breaks"
        } else if ageWeeks < 26 {
            headline = "[Mock] Looking good today"
            subtitle = "Keep up the routine"
        } else {
            headline = "[Mock] All set for now"
            subtitle = nil
        }

        let decision = AIInsightBundleDecision(
            confidence: 0.85,
            dailyStatusDecision: AIDailyStatusDecision(
                headline: headline,
                subtitle: subtitle,
                confidence: 0.85
            ),
            walkOrderingDecision: nil,
            trainingProgressText: nil,
            socializationProgressText: nil,
            loggingRecommendations: []
        )

        return AINudgeBrokerResponse(
            providerUsed: "mock",
            modelUsed: "mock-v1",
            reasoningTags: ["mock_response", "development_mode"],
            insightBundleDecision: decision,
            notificationPolicyDecision: nil,
            response: nil
        )
    }

    private func mockNotificationPolicyResponse(for request: AINudgeBrokerRequest) -> AINudgeBrokerResponse {
        let policy = AINotificationPolicyDecision(
            confidence: 0.80,
            validForMinutes: 60,
            pottyMinutesDelta: 0,
            walkMinutesDelta: 0,
            suppressPotty: false,
            suppressWalk: false
        )

        return AINudgeBrokerResponse(
            providerUsed: "mock",
            modelUsed: "mock-v1",
            reasoningTags: ["mock_response", "development_mode"],
            insightBundleDecision: nil,
            notificationPolicyDecision: policy,
            response: nil
        )
    }
}

final class AIModelBrokerClient: AIModelBrokerClientProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func decide(_ request: AINudgeBrokerRequest) async throws -> AINudgeBrokerResponse {
        // Debug: log raw UserDefaults values
        let rawURL = UserDefaults.standard.string(forKey: "ai.nudges.brokerBaseURL")
        let rawKey = UserDefaults.standard.string(forKey: "ai.nudges.brokerApiKey")
        brokerLogger.debug("decide: rawURL=\(rawURL ?? "nil"), rawKey=\(rawKey?.prefix(8).description ?? "nil")...")

        guard let baseURL = AINudgeRollout.brokerBaseURL else {
            brokerLogger.error("decide: broker URL not configured (rawURL was: \(rawURL ?? "nil"))")
            throw AIModelBrokerError.brokerNotConfigured
        }
        guard let brokerApiKey = AINudgeRollout.brokerApiKey else {
            brokerLogger.error("decide: broker API key not configured")
            throw AIModelBrokerError.brokerKeyNotConfigured
        }

        let endpoint = baseURL.appendingPathComponent("/ai/nudges/decide")
        brokerLogger.debug("decide: POST \(endpoint.absoluteString)")

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 30 // LLM API calls can take 10-20+ seconds
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(brokerApiKey, forHTTPHeaderField: "X-API-Key")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        let rawBody = String(data: data, encoding: .utf8) ?? "<non-utf8>"

        guard let httpResponse = response as? HTTPURLResponse else {
            brokerLogger.error("decide: response was not HTTPURLResponse")
            throw AIModelBrokerError.invalidResponse(statusCode: 0, body: rawBody)
        }

        brokerLogger.debug("decide: HTTP \(httpResponse.statusCode), body length=\(data.count)")

        guard (200...299).contains(httpResponse.statusCode) else {
            brokerLogger.error("decide: HTTP error \(httpResponse.statusCode): \(rawBody.prefix(500))")
            throw AIModelBrokerError.invalidResponse(statusCode: httpResponse.statusCode, body: rawBody)
        }

        do {
            let decoded = try JSONDecoder().decode(AINudgeBrokerResponse.self, from: data)
            brokerLogger.debug("decide: decoded OK, provider=\(decoded.providerUsed ?? "nil"), hasInsight=\(decoded.insightBundleDecision != nil)")
            return decoded
        } catch {
            brokerLogger.error("decide: decode failed: \(error.localizedDescription), raw=\(rawBody.prefix(1000))")
            throw AIModelBrokerError.decodingFailed(error, rawBody: rawBody)
        }
    }
}
