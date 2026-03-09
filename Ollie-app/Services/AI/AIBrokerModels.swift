//
//  AIBrokerModels.swift
//  Ollie-app
//
//  Request and response models for the AI broker service.
//

import Foundation

// MARK: - Broker Request Model

/// Request structure sent to the AI broker.
struct AIBrokerRequest: Codable, Sendable {
    let surface: AISurface
    let profileId: UUID
    let locale: String
    let policyVersion: String
    let promptVersion: String
    let providerPolicy: AIVendorPolicy
    let shadowMode: Bool

    /// System instruction for the LLM
    let systemInstruction: String

    /// Output format specification
    let outputFormat: String

    /// Context components
    let context: [String: AnyCodable]

    /// Surface-specific payload (e.g., baseline values, items to sort)
    let surfacePayload: AnyCodable?
}

// MARK: - Broker Response Model

/// Response structure from the AI broker.
struct AIBrokerResponse: Codable, Sendable {
    let providerUsed: String?
    let modelUsed: String?
    let reasoningTags: [String]?

    /// Parsed response based on surface type
    let response: AnyCodable

    /// Raw response for debugging
    let rawResponse: String?

    /// Error message if request failed
    let error: String?
}

// MARK: - Encodable Wrapper

/// Helper wrapper to encode any Encodable type
struct AnyEncodableWrapper: Encodable {
    private let encodeFunc: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        self.encodeFunc = value.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
