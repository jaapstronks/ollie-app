//
//  WalkRoute.swift
//  OtisShared
//
//  Model for storing GPS route data from walk tracking
//

import Foundation
import CoreLocation

// MARK: - Coordinate Point

/// A single coordinate point with timestamp
public struct RouteCoordinate: Codable, Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let timestamp: Date
    public let altitude: Double?
    public let horizontalAccuracy: Double?

    public init(
        latitude: Double,
        longitude: Double,
        timestamp: Date = Date(),
        altitude: Double? = nil,
        horizontalAccuracy: Double? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
    }

    public init(location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = location.timestamp
        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public var clLocation: CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: altitude ?? 0,
            horizontalAccuracy: horizontalAccuracy ?? 0,
            verticalAccuracy: 0,
            timestamp: timestamp
        )
    }
}

// MARK: - Walk Route

/// Complete GPS route for a walk, including all coordinate points and computed metrics
public struct WalkRoute: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var walkEventId: UUID?
    public var startTime: Date
    public var endTime: Date?
    public var coordinates: [RouteCoordinate]

    // Cached metrics (computed when route is finalized)
    public var totalDistanceMeters: Double?
    public var averageSpeedMetersPerSecond: Double?

    public init(
        id: UUID = UUID(),
        walkEventId: UUID? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        coordinates: [RouteCoordinate] = [],
        totalDistanceMeters: Double? = nil,
        averageSpeedMetersPerSecond: Double? = nil
    ) {
        self.id = id
        self.walkEventId = walkEventId
        self.startTime = startTime
        self.endTime = endTime
        self.coordinates = coordinates
        self.totalDistanceMeters = totalDistanceMeters
        self.averageSpeedMetersPerSecond = averageSpeedMetersPerSecond
    }

    // MARK: - Computed Properties

    /// Duration in seconds
    public var durationSeconds: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    /// Duration in minutes
    public var durationMinutes: Int {
        Int(durationSeconds / 60)
    }

    /// Distance in kilometers
    public var distanceKilometers: Double {
        (totalDistanceMeters ?? calculateDistance()) / 1000
    }

    /// Distance in miles
    public var distanceMiles: Double {
        distanceKilometers * 0.621371
    }

    /// Average speed in km/h
    public var averageSpeedKmh: Double {
        guard durationSeconds > 0 else { return 0 }
        let speed = averageSpeedMetersPerSecond ?? (calculateDistance() / durationSeconds)
        return speed * 3.6 // m/s to km/h
    }

    /// Formatted distance string (e.g., "1.2 km" or "0.8 mi")
    public func formattedDistance(useMetric: Bool = true) -> String {
        if useMetric {
            if distanceKilometers < 1 {
                return String(format: "%.0f m", totalDistanceMeters ?? calculateDistance())
            }
            return String(format: "%.1f km", distanceKilometers)
        } else {
            return String(format: "%.1f mi", distanceMiles)
        }
    }

    /// Formatted duration string (e.g., "23 min" or "1h 15m")
    public var formattedDuration: String {
        let minutes = durationMinutes
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }

    /// Bounding box for the route (for map camera)
    public var boundingBox: (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double)? {
        guard !coordinates.isEmpty else { return nil }
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        return (
            minLat: lats.min()!,
            maxLat: lats.max()!,
            minLon: lons.min()!,
            maxLon: lons.max()!
        )
    }

    /// Center coordinate for the route
    public var centerCoordinate: CLLocationCoordinate2D? {
        guard let bounds = boundingBox else { return nil }
        return CLLocationCoordinate2D(
            latitude: (bounds.minLat + bounds.maxLat) / 2,
            longitude: (bounds.minLon + bounds.maxLon) / 2
        )
    }

    // MARK: - Methods

    /// Add a coordinate to the route
    public mutating func addCoordinate(_ coordinate: RouteCoordinate) {
        coordinates.append(coordinate)
    }

    /// Add a CLLocation to the route
    public mutating func addLocation(_ location: CLLocation) {
        coordinates.append(RouteCoordinate(location: location))
    }

    /// Calculate total distance from coordinates
    public func calculateDistance() -> Double {
        guard coordinates.count >= 2 else { return 0 }

        var totalDistance: Double = 0
        for i in 1..<coordinates.count {
            let prev = coordinates[i - 1].clLocation
            let curr = coordinates[i].clLocation
            totalDistance += curr.distance(from: prev)
        }
        return totalDistance
    }

    /// Finalize the route with computed metrics
    public mutating func finalize() {
        endTime = Date()
        totalDistanceMeters = calculateDistance()
        if durationSeconds > 0 {
            averageSpeedMetersPerSecond = totalDistanceMeters! / durationSeconds
        }
    }

    /// Simplify the route by removing points that don't significantly change direction
    /// Uses Ramer-Douglas-Peucker algorithm with given tolerance in meters
    public func simplified(tolerance: Double = 5.0) -> WalkRoute {
        guard coordinates.count > 2 else { return self }

        let simplified = rdpSimplify(coordinates, tolerance: tolerance)

        var route = self
        route.coordinates = simplified
        return route
    }

    // MARK: - Private

    /// Ramer-Douglas-Peucker line simplification
    private func rdpSimplify(_ points: [RouteCoordinate], tolerance: Double) -> [RouteCoordinate] {
        guard points.count > 2 else { return points }

        // Find the point with maximum distance from line between first and last
        var maxDistance: Double = 0
        var maxIndex = 0

        let first = points.first!.clLocation
        let last = points.last!.clLocation

        for i in 1..<(points.count - 1) {
            let point = points[i].clLocation
            let distance = perpendicularDistance(point: point, lineStart: first, lineEnd: last)
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }

        // If max distance is greater than tolerance, recursively simplify
        if maxDistance > tolerance {
            let left = rdpSimplify(Array(points[0...maxIndex]), tolerance: tolerance)
            let right = rdpSimplify(Array(points[maxIndex...]), tolerance: tolerance)
            return Array(left.dropLast()) + right
        } else {
            return [points.first!, points.last!]
        }
    }

    /// Calculate perpendicular distance from a point to a line
    private func perpendicularDistance(point: CLLocation, lineStart: CLLocation, lineEnd: CLLocation) -> Double {
        let dx = lineEnd.coordinate.longitude - lineStart.coordinate.longitude
        let dy = lineEnd.coordinate.latitude - lineStart.coordinate.latitude

        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else {
            return point.distance(from: lineStart)
        }

        let t = max(0, min(1, (
            (point.coordinate.longitude - lineStart.coordinate.longitude) * dx +
            (point.coordinate.latitude - lineStart.coordinate.latitude) * dy
        ) / lengthSquared))

        let projectedLat = lineStart.coordinate.latitude + t * dy
        let projectedLon = lineStart.coordinate.longitude + t * dx

        let projected = CLLocation(latitude: projectedLat, longitude: projectedLon)
        return point.distance(from: projected)
    }
}

// MARK: - Walk Route Statistics

public extension WalkRoute {
    /// Pace in minutes per kilometer
    var paceMinutesPerKm: Double? {
        guard distanceKilometers > 0 else { return nil }
        return Double(durationMinutes) / distanceKilometers
    }

    /// Formatted pace string (e.g., "12:30 /km")
    var formattedPace: String? {
        guard let pace = paceMinutesPerKm else { return nil }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d /km", minutes, seconds)
    }
}
