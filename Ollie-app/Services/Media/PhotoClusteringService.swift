//
//  PhotoClusteringService.swift
//  Ollie-app
//
//  Handles spatial clustering of photos for map display.
//  Uses spatial hashing for efficient O(n) clustering.
//

import Foundation
import OtisShared

// MARK: - Photo Cluster Model

/// A cluster of nearby photos for map display
struct PhotoCluster: Identifiable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let events: [PuppyEvent]

    var count: Int { events.count }
    var isSinglePhoto: Bool { count == 1 }
    var firstEvent: PuppyEvent? { events.first }

    /// Whether this cluster contains any milestone photos
    var hasMilestonePhoto: Bool {
        events.contains { $0.type == .milestone }
    }
}

// MARK: - Photo Clustering Service

/// Service for clustering photos by location
struct PhotoClusteringService {

    /// Default clustering radius in meters
    static let defaultRadius: Double = 50

    // MARK: - Public API

    /// Cluster events by location
    /// - Parameters:
    ///   - events: Events to cluster (will filter to those with location)
    ///   - radiusMeters: Clustering radius in meters
    /// - Returns: Array of photo clusters
    static func cluster(events: [PuppyEvent], radiusMeters: Double = defaultRadius) -> [PhotoCluster] {
        let locatedEvents = events.filter { $0.latitude != nil && $0.longitude != nil }
        guard !locatedEvents.isEmpty else { return [] }

        return buildClusters(from: locatedEvents, radiusMeters: radiusMeters)
    }

    /// Filter events to those with location data
    static func eventsWithLocation(_ events: [PuppyEvent]) -> [PuppyEvent] {
        events.filter { $0.latitude != nil && $0.longitude != nil }
    }

    /// Find photos near a specific coordinate
    /// - Parameters:
    ///   - events: Events to search
    ///   - latitude: Center latitude
    ///   - longitude: Center longitude
    ///   - radiusMeters: Search radius
    /// - Returns: Events within the radius
    static func photosNear(
        events: [PuppyEvent],
        latitude: Double,
        longitude: Double,
        radiusMeters: Double = 100
    ) -> [PuppyEvent] {
        events.filter { event in
            guard let lat = event.latitude, let lon = event.longitude else { return false }
            let distance = haversineDistance(lat1: lat, lon1: lon, lat2: latitude, lon2: longitude)
            return distance <= radiusMeters
        }
    }

    /// Find photos near a walk spot
    /// - Parameters:
    ///   - events: Events to search
    ///   - spot: Walk spot to search near
    ///   - radiusMeters: Search radius
    /// - Returns: Events within the radius
    static func photosAtSpot(
        events: [PuppyEvent],
        spot: WalkSpot,
        radiusMeters: Double = 100
    ) -> [PuppyEvent] {
        photosNear(
            events: events,
            latitude: spot.latitude,
            longitude: spot.longitude,
            radiusMeters: radiusMeters
        )
    }

    // MARK: - Distance Calculation

    /// Calculate distance between two coordinates using Haversine formula
    /// - Returns: Distance in meters
    static func haversineDistance(
        lat1: Double,
        lon1: Double,
        lat2: Double,
        lon2: Double
    ) -> Double {
        let earthRadius: Double = 6371000 // meters

        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }

    // MARK: - Private Implementation

    /// Internal cluster accumulator during building
    private struct ClusterAccumulator {
        var id: UUID
        var latitude: Double
        var longitude: Double
        var count: Int
        var events: [PuppyEvent]
    }

    /// Spatial-hash clustering to avoid O(n²) scan
    private static func buildClusters(from locatedEvents: [PuppyEvent], radiusMeters: Double) -> [PhotoCluster] {
        let radius = max(1, radiusMeters)

        // Calculate scaling factors for bucket keys
        let averageLatitude = locatedEvents.compactMap(\.latitude).reduce(0, +) / Double(locatedEvents.count)
        let latScale: Double = 111_132
        let lonScale: Double = max(1, 111_320 * cos(averageLatitude * .pi / 180))

        func bucketKey(lat: Double, lon: Double) -> String {
            let x = Int(floor((lon * lonScale) / radius))
            let y = Int(floor((lat * latScale) / radius))
            return "\(x):\(y)"
        }

        func neighboringKeys(for key: String) -> [String] {
            let parts = key.split(separator: ":")
            guard parts.count == 2,
                  let x = Int(parts[0]),
                  let y = Int(parts[1]) else {
                return [key]
            }

            var keys: [String] = []
            keys.reserveCapacity(9)
            for dx in -1...1 {
                for dy in -1...1 {
                    keys.append("\(x + dx):\(y + dy)")
                }
            }
            return keys
        }

        var clusters: [ClusterAccumulator] = []
        var bucketToClusterIndices: [String: [Int]] = [:]

        for event in locatedEvents {
            guard let eventLat = event.latitude, let eventLon = event.longitude else { continue }

            let key = bucketKey(lat: eventLat, lon: eventLon)
            let candidateIndices = neighboringKeys(for: key).flatMap { bucketToClusterIndices[$0] ?? [] }

            var targetClusterIndex: Int?
            for candidateIndex in candidateIndices {
                let cluster = clusters[candidateIndex]
                let distance = haversineDistance(
                    lat1: eventLat, lon1: eventLon,
                    lat2: cluster.latitude, lon2: cluster.longitude
                )
                if distance <= radius {
                    targetClusterIndex = candidateIndex
                    break
                }
            }

            if let clusterIndex = targetClusterIndex {
                var cluster = clusters[clusterIndex]
                let nextCount = cluster.count + 1
                cluster.latitude = (cluster.latitude * Double(cluster.count) + eventLat) / Double(nextCount)
                cluster.longitude = (cluster.longitude * Double(cluster.count) + eventLon) / Double(nextCount)
                cluster.count = nextCount
                cluster.events.append(event)
                clusters[clusterIndex] = cluster
            } else {
                let cluster = ClusterAccumulator(
                    id: event.id,
                    latitude: eventLat,
                    longitude: eventLon,
                    count: 1,
                    events: [event]
                )
                clusters.append(cluster)
                bucketToClusterIndices[key, default: []].append(clusters.count - 1)
            }
        }

        return clusters.map { cluster in
            PhotoCluster(
                id: cluster.id,
                latitude: cluster.latitude,
                longitude: cluster.longitude,
                events: cluster.events.sorted { $0.time > $1.time }
            )
        }
    }
}
