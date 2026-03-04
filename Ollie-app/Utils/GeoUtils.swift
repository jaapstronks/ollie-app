//
//  GeoUtils.swift
//  Ollie-app
//
//  Reusable geographic calculation utilities
//

import Foundation

/// Utility functions for geographic calculations
enum GeoUtils {

    /// Calculate distance between two coordinates using Haversine formula
    /// - Returns: Distance in meters
    static func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius: Double = 6371000 // meters

        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }

    /// Check if a coordinate is within a bounding box
    static func isInBounds(
        lat: Double,
        lon: Double,
        bounds: (south: Double, west: Double, north: Double, east: Double)
    ) -> Bool {
        return lat >= bounds.south && lat <= bounds.north && lon >= bounds.west && lon <= bounds.east
    }

    /// Calculate centroid from GeoJSON geometry
    static func calculateGeoJSONCentroid(from geometry: GeoJSONGeometry) -> (lat: Double, lon: Double)? {
        switch geometry.type {
        case "Point":
            if let coords = geometry.pointCoordinates, coords.count >= 2 {
                return (lat: coords[1], lon: coords[0])
            }
        case "Polygon":
            if let coords = geometry.polygonCoordinates,
               let ring = coords.first, !ring.isEmpty {
                let sumLon = ring.reduce(0.0) { $0 + $1[0] }
                let sumLat = ring.reduce(0.0) { $0 + $1[1] }
                return (lat: sumLat / Double(ring.count), lon: sumLon / Double(ring.count))
            }
        case "MultiPolygon":
            if let coords = geometry.multiPolygonCoordinates,
               let firstPolygon = coords.first,
               let ring = firstPolygon.first, !ring.isEmpty {
                let sumLon = ring.reduce(0.0) { $0 + $1[0] }
                let sumLat = ring.reduce(0.0) { $0 + $1[1] }
                return (lat: sumLat / Double(ring.count), lon: sumLon / Double(ring.count))
            }
        default:
            break
        }
        return nil
    }

    /// Calculate centroid from Amsterdam-specific geometry (different coordinate format)
    static func calculateAmsterdamCentroid(from geometry: AmsterdamGeometry) -> (lat: Double, lon: Double)? {
        if let coords = geometry.polygonCoordinates,
           let ring = coords.first, !ring.isEmpty {
            let sumLon = ring.reduce(0.0) { $0 + $1[0] }
            let sumLat = ring.reduce(0.0) { $0 + $1[1] }
            return (lat: sumLat / Double(ring.count), lon: sumLon / Double(ring.count))
        }

        if let coords = geometry.multiPolygonCoordinates,
           let firstPolygon = coords.first,
           let ring = firstPolygon.first, !ring.isEmpty {
            let sumLon = ring.reduce(0.0) { $0 + $1[0] }
            let sumLat = ring.reduce(0.0) { $0 + $1[1] }
            return (lat: sumLat / Double(ring.count), lon: sumLon / Double(ring.count))
        }

        return nil
    }
}
