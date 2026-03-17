//
//  ExploredTile.swift
//  OtisShared
//
//  Represents a map tile that has been explored during walks.
//  Uses Web Mercator projection (same as Google Maps, Apple Maps, etc.)
//

import CoreLocation
import Foundation

/// A map tile that has been explored during a walk
public struct ExploredTile: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var tileKey: String  // Format: "{zoom}_{x}_{y}"
    public var walkCount: Int
    public var firstExploredAt: Date
    public var lastExploredAt: Date
    public var createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        tileKey: String,
        walkCount: Int = 1,
        firstExploredAt: Date = Date(),
        lastExploredAt: Date? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date? = nil
    ) {
        self.id = id
        self.tileKey = tileKey
        self.walkCount = walkCount
        self.firstExploredAt = firstExploredAt
        self.lastExploredAt = lastExploredAt ?? firstExploredAt
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt ?? createdAt
    }

    // MARK: - Tile Coordinate Parsing

    /// Parse tile X coordinate from key
    public var tileX: Int? {
        let parts = tileKey.split(separator: "_")
        guard parts.count == 3 else { return nil }
        return Int(parts[1])
    }

    /// Parse tile Y coordinate from key
    public var tileY: Int? {
        let parts = tileKey.split(separator: "_")
        guard parts.count == 3 else { return nil }
        return Int(parts[2])
    }

    /// Parse zoom level from key
    public var zoomLevel: Int? {
        let parts = tileKey.split(separator: "_")
        guard parts.count == 3 else { return nil }
        return Int(parts[0])
    }

    // MARK: - Mutation Helpers

    /// Returns a copy with updated modifiedAt timestamp
    public func withUpdatedTimestamp() -> ExploredTile {
        var copy = self
        copy.modifiedAt = Date()
        return copy
    }

    /// Returns a copy with incremented walk count and updated lastExploredAt
    public func withIncrementedWalkCount() -> ExploredTile {
        var copy = self
        copy.walkCount += 1
        copy.lastExploredAt = Date()
        copy.modifiedAt = Date()
        return copy
    }
}

// MARK: - Tile Coordinate Conversion

extension ExploredTile {

    /// Default zoom level for exploration tiles (~610m per tile at equator)
    public static let defaultZoomLevel = 16

    /// Generate a tile key from a coordinate at the default zoom level
    /// - Parameter coordinate: The location coordinate
    /// - Returns: Tile key in format "{zoom}_{x}_{y}"
    public static func tileKey(for coordinate: CLLocationCoordinate2D) -> String {
        tileKey(for: coordinate, zoom: defaultZoomLevel)
    }

    /// Generate a tile key from a coordinate at a specific zoom level
    /// - Parameters:
    ///   - coordinate: The location coordinate
    ///   - zoom: The zoom level (0-22)
    /// - Returns: Tile key in format "{zoom}_{x}_{y}"
    public static func tileKey(for coordinate: CLLocationCoordinate2D, zoom: Int) -> String {
        let (x, y) = tileCoordinates(for: coordinate, zoom: zoom)
        return "\(zoom)_\(x)_\(y)"
    }

    /// Convert a coordinate to tile X,Y at a specific zoom level
    /// Uses Web Mercator projection (EPSG:3857)
    /// - Parameters:
    ///   - coordinate: The location coordinate
    ///   - zoom: The zoom level (0-22)
    /// - Returns: Tuple of (tileX, tileY)
    public static func tileCoordinates(for coordinate: CLLocationCoordinate2D, zoom: Int) -> (x: Int, y: Int) {
        let n = pow(2.0, Double(zoom))

        // Convert longitude to tile X
        let x = Int(floor((coordinate.longitude + 180.0) / 360.0 * n))

        // Convert latitude to tile Y using Web Mercator projection
        let latRad = coordinate.latitude * .pi / 180.0
        let y = Int(floor((1.0 - asinh(tan(latRad)) / .pi) / 2.0 * n))

        return (x, y)
    }

    /// Convert tile coordinates back to the center coordinate of the tile
    /// - Parameters:
    ///   - x: Tile X coordinate
    ///   - y: Tile Y coordinate
    ///   - zoom: The zoom level
    /// - Returns: The center coordinate of the tile
    public static func coordinate(forTileX x: Int, tileY y: Int, zoom: Int) -> CLLocationCoordinate2D {
        let n = pow(2.0, Double(zoom))

        // Convert tile X to longitude (center of tile)
        let lon = (Double(x) + 0.5) / n * 360.0 - 180.0

        // Convert tile Y to latitude (center of tile)
        let latRad = atan(sinh(.pi * (1.0 - 2.0 * (Double(y) + 0.5) / n)))
        let lat = latRad * 180.0 / .pi

        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Get the northwest corner coordinate of a tile
    /// - Parameters:
    ///   - x: Tile X coordinate
    ///   - y: Tile Y coordinate
    ///   - zoom: The zoom level
    /// - Returns: The northwest corner coordinate
    public static func northwestCorner(forTileX x: Int, tileY y: Int, zoom: Int) -> CLLocationCoordinate2D {
        let n = pow(2.0, Double(zoom))

        let lon = Double(x) / n * 360.0 - 180.0
        let latRad = atan(sinh(.pi * (1.0 - 2.0 * Double(y) / n)))
        let lat = latRad * 180.0 / .pi

        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Get the southeast corner coordinate of a tile
    /// - Parameters:
    ///   - x: Tile X coordinate
    ///   - y: Tile Y coordinate
    ///   - zoom: The zoom level
    /// - Returns: The southeast corner coordinate
    public static func southeastCorner(forTileX x: Int, tileY y: Int, zoom: Int) -> CLLocationCoordinate2D {
        let n = pow(2.0, Double(zoom))

        let lon = Double(x + 1) / n * 360.0 - 180.0
        let latRad = atan(sinh(.pi * (1.0 - 2.0 * Double(y + 1) / n)))
        let lat = latRad * 180.0 / .pi

        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Calculate the approximate tile size in meters at a given latitude
    /// - Parameters:
    ///   - latitude: The latitude
    ///   - zoom: The zoom level
    /// - Returns: Approximate tile size in meters
    public static func tileSizeMeters(atLatitude latitude: Double, zoom: Int) -> Double {
        // Earth's circumference at equator in meters
        let earthCircumference = 40_075_016.686
        let n = pow(2.0, Double(zoom))

        // Tile size varies with latitude due to Mercator projection
        let latRad = latitude * .pi / 180.0
        return earthCircumference * cos(latRad) / n
    }
}
