//
//  AICacheManager.swift
//  Ollie-app
//
//  Manages AI response caching using Core Data (CloudKit-synced).
//  Handles cache retrieval, storage, expiration, and cleanup.
//

@preconcurrency import CoreData
import Foundation

/// Manages AI response caching with Core Data persistence
@MainActor
final class AICacheManager {

    // MARK: - Dependencies

    private let persistenceController: PersistenceController

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        cleanupExpiredOnStartup()
    }

    // MARK: - Public API

    /// Fetch a valid cached response for a surface and profile.
    /// Returns nil if no valid cache entry exists or if expired.
    func validCachedResponse(for surface: AISurface, profileId: UUID) -> AIBrokerResponse? {
        let context = persistenceController.viewContext
        guard let cdProfile = CDPuppyProfile.fetch(byId: profileId, in: context) else {
            return nil
        }
        guard let entry = CDAICache.fetchValid(surface: surface, profile: cdProfile, in: context),
              !entry.isExpired else {
            return nil
        }
        return entry.toResponse()
    }

    /// Cache a response for a surface and profile.
    func cacheResponse(_ response: AIBrokerResponse, surface: AISurface, profileId: UUID) {
        let context = persistenceController.viewContext
        context.perform {
            guard let cdProfile = CDPuppyProfile.fetch(byId: profileId, in: context) else { return }
            CDAICache.upsert(surface: surface, response: response, profile: cdProfile, in: context)
            try? context.save()
        }
    }

    /// Clear all cached responses.
    func clearAll() {
        let context = persistenceController.newBackgroundContext()
        context.perform {
            let request = NSFetchRequest<CDAICache>(entityName: "CDAICache")
            if let entries = try? context.fetch(request) {
                entries.forEach { context.delete($0) }
            }
            try? context.save()
        }
    }

    /// Clear cached responses for a specific profile.
    func clearForProfile(_ profileId: UUID) {
        let context = persistenceController.newBackgroundContext()
        context.perform {
            guard let cdProfile = CDPuppyProfile.fetch(byId: profileId, in: context) else { return }
            let request = NSFetchRequest<CDAICache>(entityName: "CDAICache")
            request.predicate = NSPredicate(format: "profile == %@", cdProfile)
            if let entries = try? context.fetch(request) {
                entries.forEach { context.delete($0) }
            }
            try? context.save()
        }
    }

    /// Clear cached responses for a specific surface.
    func clearForSurface(_ surface: AISurface) {
        let context = persistenceController.newBackgroundContext()
        context.perform {
            let request = NSFetchRequest<CDAICache>(entityName: "CDAICache")
            request.predicate = NSPredicate(format: "surface == %@", surface.rawValue)
            if let entries = try? context.fetch(request) {
                entries.forEach { context.delete($0) }
            }
            try? context.save()
        }
    }

    /// Decode a cached response to a specific type.
    func decodeCachedResponse<Response: Codable>(
        surface: AISurface,
        profileId: UUID,
        as type: Response.Type
    ) -> Response? {
        guard let brokerResponse = validCachedResponse(for: surface, profileId: profileId) else {
            return nil
        }

        // Try decoding from the parsed response first
        if let data = try? JSONEncoder().encode(brokerResponse.response),
           let response = try? JSONDecoder().decode(Response.self, from: data) {
            return response
        }

        // Fall back to raw response string
        guard let rawString = brokerResponse.rawResponse,
              let data = rawString.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(Response.self, from: data)
    }

    // MARK: - Private

    private func cleanupExpiredOnStartup() {
        Task {
            let context = persistenceController.newBackgroundContext()
            context.perform {
                CDAICache.cleanupExpired(in: context)
                try? context.save()
            }
        }
    }
}
