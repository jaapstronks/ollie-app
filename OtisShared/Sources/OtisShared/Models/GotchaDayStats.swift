//
//  GotchaDayStats.swift
//  OtisShared
//
//  Statistics for Gotcha Day anniversary celebrations

import Foundation

/// Statistics for a Gotcha Day anniversary celebration
public struct GotchaDayStats: Identifiable, Sendable {
    public let id = UUID()
    public let homeDate: Date
    public let puppyName: String
    public let yearsHome: Int
    public let totalWalks: Int
    public let totalWalkMinutes: Int
    public let totalPhotos: Int
    public let totalTrainingSessions: Int
    public let totalSocialEvents: Int
    public let skillsMastered: Int
    public let totalPottyEvents: Int
    public let outdoorPottyCount: Int

    public init(
        homeDate: Date,
        puppyName: String,
        yearsHome: Int,
        totalWalks: Int,
        totalWalkMinutes: Int,
        totalPhotos: Int,
        totalTrainingSessions: Int,
        totalSocialEvents: Int,
        skillsMastered: Int,
        totalPottyEvents: Int,
        outdoorPottyCount: Int
    ) {
        self.homeDate = homeDate
        self.puppyName = puppyName
        self.yearsHome = yearsHome
        self.totalWalks = totalWalks
        self.totalWalkMinutes = totalWalkMinutes
        self.totalPhotos = totalPhotos
        self.totalTrainingSessions = totalTrainingSessions
        self.totalSocialEvents = totalSocialEvents
        self.skillsMastered = skillsMastered
        self.totalPottyEvents = totalPottyEvents
        self.outdoorPottyCount = outdoorPottyCount
    }

    // MARK: - Computed Properties

    /// Anniversary text (e.g., "1 Year Together" or "2 Years Together")
    public var anniversaryText: String {
        if yearsHome == 1 {
            return "1 Year Together"
        } else {
            return "\(yearsHome) Years Together"
        }
    }

    /// Days since coming home
    public var daysHome: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: homeDate, to: Date())
        return components.day ?? 0
    }

    /// Formatted home date
    public var formattedHomeDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: homeDate)
    }

    /// Short home date for cards
    public var shortHomeDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: homeDate)
    }

    /// Formatted total walk time
    public var formattedTotalWalkTime: String {
        let hours = totalWalkMinutes / 60
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(totalWalkMinutes)m"
    }

    /// Outdoor potty percentage
    public var outdoorPottyPercentage: Int {
        guard totalPottyEvents > 0 else { return 0 }
        return Int(round(Double(outdoorPottyCount) / Double(totalPottyEvents) * 100))
    }

    /// Whether this is the first anniversary
    public var isFirstAnniversary: Bool {
        yearsHome == 1
    }

    /// Celebratory emoji based on years
    public var celebrationEmoji: String {
        switch yearsHome {
        case 1: return "1"
        case 2: return "2"
        case 3: return "3"
        case 4: return "4"
        case 5: return "5"
        default: return "\(yearsHome)"
        }
    }
}
