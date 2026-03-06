//
//  AIModelBrokerClient.swift
//  Otis-app
//
//  Broker client for interoperable Anthropic/Mistral nudges.
//

import Foundation

protocol AIModelBrokerClientProtocol {
    func decide(_ request: AINudgeBrokerRequest) async throws -> AINudgeBrokerResponse
}

enum AIModelBrokerError: Error {
    case brokerNotConfigured
    case brokerKeyNotConfigured
    case invalidResponse
}

final class AIModelBrokerClient: AIModelBrokerClientProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func decide(_ request: AINudgeBrokerRequest) async throws -> AINudgeBrokerResponse {
        guard let baseURL = AINudgeRollout.brokerBaseURL else {
            throw AIModelBrokerError.brokerNotConfigured
        }
        guard let brokerApiKey = AINudgeRollout.brokerApiKey else {
            throw AIModelBrokerError.brokerKeyNotConfigured
        }

        let endpoint = baseURL.appendingPathComponent("/ai/nudges/decide")
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 30 // LLM API calls can take 10-20+ seconds
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(brokerApiKey, forHTTPHeaderField: "X-API-Key")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIModelBrokerError.invalidResponse
        }

        return try JSONDecoder().decode(AINudgeBrokerResponse.self, from: data)
    }
}
