//
//  AIContextComponent.swift
//  Ollie-app
//
//  Protocol for modular AI context components
//

import Foundation

// MARK: - Context Component Protocol

/// Protocol for modular context components that can be composed into AI requests.
/// Each component represents a specific domain of information.
protocol AIContextComponent: Codable, Sendable {
    /// Unique identifier for this component type
    static var componentKey: String { get }

    /// Approximate token cost for budget estimation
    static var estimatedTokens: Int { get }
}
