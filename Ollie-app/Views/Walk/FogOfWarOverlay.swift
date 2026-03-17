//
//  FogOfWarOverlay.swift
//  Otis-app
//
//  A "fog of war" style overlay that reveals explored areas on a map.
//  Uses Canvas for efficient rendering with blend modes to cut out explored tiles.
//

import MapKit
import OtisShared
import SwiftUI

/// Overlay that shows fog over unexplored areas and reveals explored tiles
struct FogOfWarOverlay: View {
    /// The exploration store containing explored tile data
    let explorationStore: ExplorationStore

    /// Current map visible rect (in map coordinates)
    let mapRect: MKMapRect

    /// Size of the map view in screen points
    let mapSize: CGSize

    /// Current walk path coordinates (for real-time reveal during walks)
    var currentPathCoordinates: [CLLocationCoordinate2D] = []

    /// Radius in meters for current path reveal circles
    var revealRadiusMeters: Double = 50

    /// Opacity of the fog overlay (0-1)
    var fogOpacity: Double = 0.7

    var body: some View {
        Canvas { context, size in
            // 1. Fill entire canvas with fog color
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.black.opacity(fogOpacity))
            )

            // 2. Use destination out blend mode to "cut out" explored areas
            context.blendMode = .destinationOut

            // 3. Cut out explored tiles
            for (x, y) in explorationStore.exploredTileCoordinates() {
                let tilePath = tilePath(tileX: x, tileY: y, size: size)
                context.fill(tilePath, with: .color(.white))
            }

            // 4. Cut out current walk path (real-time reveal)
            for coordinate in currentPathCoordinates {
                let point = screenPoint(for: coordinate, size: size)
                let screenRadius = metersToScreenPoints(revealRadiusMeters, at: coordinate, size: size)

                let circlePath = Path(ellipseIn: CGRect(
                    x: point.x - screenRadius,
                    y: point.y - screenRadius,
                    width: screenRadius * 2,
                    height: screenRadius * 2
                ))
                context.fill(circlePath, with: .color(.white))
            }
        }
        .allowsHitTesting(false)  // Pass through all touches
    }

    // MARK: - Coordinate Conversion

    /// Convert a CLLocationCoordinate2D to screen points
    private func screenPoint(for coordinate: CLLocationCoordinate2D, size: CGSize) -> CGPoint {
        let mapPoint = MKMapPoint(coordinate)

        // Convert map point to normalized position within mapRect (0-1)
        let normalizedX = (mapPoint.x - mapRect.origin.x) / mapRect.size.width
        let normalizedY = (mapPoint.y - mapRect.origin.y) / mapRect.size.height

        // Convert to screen coordinates
        return CGPoint(
            x: normalizedX * size.width,
            y: normalizedY * size.height
        )
    }

    /// Create a path for a tile at the given coordinates
    private func tilePath(tileX: Int, tileY: Int, size: CGSize) -> Path {
        let zoom = ExploredTile.defaultZoomLevel

        // Get tile corners
        let nw = ExploredTile.northwestCorner(forTileX: tileX, tileY: tileY, zoom: zoom)
        let se = ExploredTile.southeastCorner(forTileX: tileX, tileY: tileY, zoom: zoom)

        // Convert to screen points
        let topLeft = screenPoint(for: nw, size: size)
        let bottomRight = screenPoint(for: se, size: size)

        // Create rectangle path
        return Path(CGRect(
            x: topLeft.x,
            y: topLeft.y,
            width: bottomRight.x - topLeft.x,
            height: bottomRight.y - topLeft.y
        ))
    }

    /// Convert meters to screen points at a given coordinate
    private func metersToScreenPoints(_ meters: Double, at coordinate: CLLocationCoordinate2D, size: CGSize) -> CGFloat {
        // Get the map points per meter at this latitude
        let metersPerMapPoint = MKMetersPerMapPointAtLatitude(coordinate.latitude)
        let mapPointsForRadius = meters / metersPerMapPoint

        // Convert map points to screen points
        let screenPointsPerMapPoint = size.width / mapRect.size.width
        return CGFloat(mapPointsForRadius * screenPointsPerMapPoint)
    }
}

// MARK: - Preview

#Preview {
    // Create a preview with mock data
    ZStack {
        Color.green.opacity(0.3)  // Simulate map background

        FogOfWarOverlay(
            explorationStore: ExplorationStore(),
            mapRect: MKMapRect(
                x: 0,
                y: 0,
                width: 1000000,
                height: 1000000
            ),
            mapSize: CGSize(width: 400, height: 600)
        )
    }
}
