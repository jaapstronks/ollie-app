//
//  GovernmentDataProviders.swift
//  Ollie-app
//
//  Fetches dog park data from government open data sources.
//  City-specific providers are in Services/Discovery/Cities/
//

import Foundation
import OtisShared
import os

/// Coordinates fetching dog park data from various government APIs
actor GovernmentDataProviders {

    // MARK: - Properties

    private let logger = Logger.otis(category: "GovernmentData")

    /// All registered city providers
    private let providers: [any CityDataProvider] = [
        // Netherlands
        EindhovenProvider(),
        AmsterdamProvider(),
        // Germany
        BerlinProvider(),
        HamburgProvider(),
        // USA
        NYCProvider(),
        SeattleProvider(),
        SanFranciscoProvider(),
        WashingtonDCProvider(),
        PhoenixProvider(),
        // Canada
        VancouverProvider(),
        CalgaryProvider(),
        // Australia
        SydneyProvider(),
        CanberraProvider(),
        // Europe
        ViennaProvider(),
        BrusselsProvider()
    ]

    // MARK: - Main Fetcher

    /// Fetch dog parks from government sources based on location
    func fetchAll(latitude: Double, longitude: Double) async -> [DiscoveredSpot] {
        var spots: [DiscoveredSpot] = []

        for provider in providers {
            // Only fetch if location is within provider's bounds
            if provider.bounds.contains(latitude: latitude, longitude: longitude) {
                let providerSpots = await fetchSafely(provider.cityName) {
                    try await provider.fetch()
                }
                spots.append(contentsOf: providerSpots)
            }
        }

        return spots
    }

    // MARK: - Private Helpers

    /// Safely fetch from a source, logging errors but not throwing
    private func fetchSafely(_ source: String, _ fetcher: () async throws -> [DiscoveredSpot]) async -> [DiscoveredSpot] {
        do {
            let spots = try await fetcher()
            logger.debug("Fetched \(spots.count) spots from \(source)")
            return spots
        } catch {
            logger.warning("Failed to fetch \(source) data: \(error.localizedDescription)")
            return []
        }
    }
}
