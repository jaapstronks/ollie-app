//
//  EventAttachments.swift
//  OtisShared
//
//  Supporting types for PuppyEvent attachments: MediaInfo, EventLike, LocationInfo
//

import Foundation

// MARK: - Media Info

/// Encapsulates media attachments for an event
public struct MediaInfo: Codable, Equatable, Sendable {
    public var photoPath: String?
    public var videoPath: String?
    public var thumbnailPath: String?

    public init(photoPath: String? = nil, videoPath: String? = nil, thumbnailPath: String? = nil) {
        self.photoPath = photoPath
        self.videoPath = videoPath
        self.thumbnailPath = thumbnailPath
    }

    /// Whether this media info has any content
    public var hasMedia: Bool {
        photoPath != nil || videoPath != nil
    }

    /// Whether this has a photo (with or without thumbnail)
    public var hasPhoto: Bool {
        photoPath != nil
    }

    public static let empty = MediaInfo()
}

// MARK: - Event Like

/// Represents a like on an event from a household member
public struct EventLike: Codable, Equatable, Sendable {
    /// CloudKit user record ID of who liked the event
    public let likedBy: String

    /// When the like was added
    public let likedAt: Date

    public init(likedBy: String, likedAt: Date = Date()) {
        self.likedBy = likedBy
        self.likedAt = likedAt
    }
}

// MARK: - Location Info

/// Encapsulates GPS location data for walk events
public struct LocationInfo: Codable, Equatable, Sendable {
    public var latitude: Double?
    public var longitude: Double?
    public var spotId: UUID?
    public var spotName: String?

    public init(latitude: Double? = nil, longitude: Double? = nil, spotId: UUID? = nil, spotName: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.spotId = spotId
        self.spotName = spotName
    }

    /// Whether this has any location data
    public var hasLocation: Bool {
        hasCoordinates || spotId != nil
    }

    /// Whether this has GPS coordinates
    public var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    public static let empty = LocationInfo()
}
