//
//  OlliePlusStatus.swift
//  Ollie-app
//
//  Subscription state for Ollie+ feature gating

import Foundation

/// Represents the user's current Ollie+ subscription state
/// Named to avoid conflict with StoreKit's Product.SubscriptionInfo.Status
enum OlliePlusStatus: Codable, Equatable {
    /// Never subscribed - free tier
    case free

    /// In 7-day free trial
    case trial(until: Date)

    /// Active paid subscription
    case active(until: Date)

    /// Subscription has expired
    case expired

    /// Legacy one-time purchaser (grandfathered in)
    case legacy

    /// Whether the user has access to Ollie+ features
    var hasOlliePlus: Bool {
        switch self {
        case .free, .expired:
            return false
        case .trial, .active, .legacy:
            return true
        }
    }

    /// Display label for settings
    var displayLabel: String {
        switch self {
        case .free:
            return Strings.OlliePlus.statusFree
        case .trial(let until):
            let days = Calendar.current.dateComponents([.day], from: Date(), to: until).day ?? 0
            return Strings.OlliePlus.statusTrial(daysLeft: max(0, days))
        case .active(let until):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return Strings.OlliePlus.statusActive(renewDate: formatter.string(from: until))
        case .expired:
            return Strings.OlliePlus.statusExpired
        case .legacy:
            return Strings.OlliePlus.statusLegacy
        }
    }

    /// Whether the user is in trial period
    var isInTrial: Bool {
        if case .trial = self { return true }
        return false
    }

    /// Whether the user has an active subscription (not trial or legacy)
    var isActiveSubscription: Bool {
        if case .active = self { return true }
        return false
    }

    /// Days remaining in trial (nil if not in trial)
    var trialDaysRemaining: Int? {
        if case .trial(let until) = self {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: until).day ?? 0
            return max(0, days)
        }
        return nil
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type
        case date
    }

    private enum StatusType: String, Codable {
        case free, trial, active, expired, legacy
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(StatusType.self, forKey: .type)

        switch type {
        case .free:
            self = .free
        case .trial:
            let date = try container.decode(Date.self, forKey: .date)
            self = .trial(until: date)
        case .active:
            let date = try container.decode(Date.self, forKey: .date)
            self = .active(until: date)
        case .expired:
            self = .expired
        case .legacy:
            self = .legacy
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .free:
            try container.encode(StatusType.free, forKey: .type)
        case .trial(let until):
            try container.encode(StatusType.trial, forKey: .type)
            try container.encode(until, forKey: .date)
        case .active(let until):
            try container.encode(StatusType.active, forKey: .type)
            try container.encode(until, forKey: .date)
        case .expired:
            try container.encode(StatusType.expired, forKey: .type)
        case .legacy:
            try container.encode(StatusType.legacy, forKey: .type)
        }
    }
}
