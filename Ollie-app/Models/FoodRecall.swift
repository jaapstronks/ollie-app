//
//  FoodRecall.swift
//  Ollie-app
//
//  Pet food recall data model

import Foundation

/// Represents a pet food recall alert from FDA or other sources
struct FoodRecall: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let date: Date
    let brand: String
    let product: String
    let reason: String
    let severity: Severity
    let affectedRegions: [String]
    let sourceURL: URL?

    enum Severity: String, Codable, Sendable {
        case low      // Quality issue
        case medium   // Potential health risk
        case high     // Confirmed health risk
        case critical // Death/serious illness reported

        var label: String {
            switch self {
            case .low: return Strings.FoodRecall.severityLow
            case .medium: return Strings.FoodRecall.severityMedium
            case .high: return Strings.FoodRecall.severityHigh
            case .critical: return Strings.FoodRecall.severityCritical
            }
        }

        var icon: String {
            switch self {
            case .low: return "info.circle.fill"
            case .medium: return "exclamationmark.triangle.fill"
            case .high: return "exclamationmark.octagon.fill"
            case .critical: return "xmark.octagon.fill"
            }
        }
    }
}

/// User's food alert settings stored locally
struct FoodAlertSettings: Codable, Sendable, Equatable {
    var enabled: Bool
    var savedBrands: [String]
    var checkFrequency: CheckFrequency
    var lastChecked: Date?
    var acknowledgedRecallIds: Set<String>

    enum CheckFrequency: String, Codable, Sendable, CaseIterable {
        case daily
        case weekly

        var label: String {
            switch self {
            case .daily: return Strings.FoodRecall.daily
            case .weekly: return Strings.FoodRecall.weekly
            }
        }
    }

    static func defaultSettings() -> FoodAlertSettings {
        FoodAlertSettings(
            enabled: false,
            savedBrands: [],
            checkFrequency: .daily,
            lastChecked: nil,
            acknowledgedRecallIds: []
        )
    }
}
