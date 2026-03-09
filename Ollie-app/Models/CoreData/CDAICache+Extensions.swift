//
//  CDAICache+Extensions.swift
//  Ollie-app
//
//  Extensions for CloudKit-synced AI response caching.
//  Reduces API costs by sharing cached responses across household members.
//

@preconcurrency import CoreData
import OtisShared

extension CDAICache {

    // MARK: - Cache Key

    /// Generate a time window stamp for the given surface's cache duration.
    static func timeWindow(for surface: AISurface) -> String {
        Date().windowStamp(hours: max(1, surface.cacheDurationMinutes / 60))
    }

    // MARK: - Update from Response

    /// Update this cache entry from an AI broker response.
    func update(surface: AISurface, response: AIBrokerResponse, locale: String?) {
        self.id = UUID()
        self.surface = surface.rawValue
        self.timeWindow = Self.timeWindow(for: surface)
        self.locale = locale
        self.responseData = try? JSONEncoder().encode(response)
        self.cachedAt = Date()
        self.expiresAt = Date().addingTimeInterval(TimeInterval(surface.cacheDurationMinutes * 60))
        self.providerUsed = response.providerUsed
        self.modelUsed = response.modelUsed
    }

    // MARK: - Convert to Response

    /// Decode and return the cached AI broker response.
    func toResponse() -> AIBrokerResponse? {
        guard let data = responseData else { return nil }
        return try? JSONDecoder().decode(AIBrokerResponse.self, from: data)
    }

    /// Check if this cache entry has expired.
    var isExpired: Bool {
        guard let expiresAt else { return true }
        return Date() > expiresAt
    }

    // MARK: - Fetch Valid Cache

    /// Fetch a valid (non-expired) cache entry for the given surface and profile.
    /// Includes locale matching to ensure responses are in the correct language.
    static func fetchValid(
        surface: AISurface,
        profile: CDPuppyProfile,
        in context: NSManagedObjectContext
    ) -> CDAICache? {
        let window = timeWindow(for: surface)
        let currentLocale = profile.preferredLocale ?? Locale.current.identifier
        let request = NSFetchRequest<CDAICache>(entityName: "CDAICache")

        // Include locale in cache key to ensure language-specific responses
        var predicates: [NSPredicate] = [
            NSPredicate(format: "profile == %@", profile),
            NSPredicate(format: "surface == %@", surface.rawValue),
            NSPredicate(format: "timeWindow == %@", window),
            NSPredicate(format: "expiresAt > %@", Date() as CVarArg)
        ]

        // Match locale (handle nil locale for legacy cache entries)
        predicates.append(NSPredicate(format: "locale == %@", currentLocale))

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.fetchLimit = 1

        nonisolated(unsafe) var result: CDAICache?
        context.performAndWait {
            result = try? context.fetch(request).first
        }
        return result
    }

    // MARK: - Upsert

    /// Insert or update a cache entry for the given surface and response.
    /// Includes locale to ensure language-specific caching.
    @discardableResult
    static func upsert(
        surface: AISurface,
        response: AIBrokerResponse,
        profile: CDPuppyProfile,
        in context: NSManagedObjectContext
    ) -> CDAICache {
        let window = timeWindow(for: surface)
        let currentLocale = profile.preferredLocale ?? Locale.current.identifier
        let request = NSFetchRequest<CDAICache>(entityName: "CDAICache")

        // Include locale in lookup to maintain separate cache entries per language
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "profile == %@", profile),
            NSPredicate(format: "surface == %@", surface.rawValue),
            NSPredicate(format: "timeWindow == %@", window),
            NSPredicate(format: "locale == %@", currentLocale)
        ])
        request.fetchLimit = 1

        // Mark as nonisolated(unsafe) since performAndWait is synchronous and safe
        nonisolated(unsafe) let capturedProfile = profile
        let capturedLocale = currentLocale  // String is Sendable, no unsafe needed
        nonisolated(unsafe) var cache: CDAICache!
        context.performAndWait {
            if let existing = try? context.fetch(request).first {
                cache = existing
                cache.callCount += 1  // Track how many times this was "requested"
            } else {
                cache = CDAICache(context: context)
                cache.profile = capturedProfile
                cache.callCount = 1
            }
            cache.update(surface: surface, response: response, locale: capturedLocale)
        }
        return cache
    }

    // MARK: - Cleanup

    /// Delete all expired cache entries.
    static func cleanupExpired(in context: NSManagedObjectContext) {
        let request = NSFetchRequest<CDAICache>(entityName: "CDAICache")
        request.predicate = NSPredicate(format: "expiresAt < %@", Date() as CVarArg)

        context.performAndWait {
            if let expired = try? context.fetch(request) {
                expired.forEach { context.delete($0) }
            }
        }
    }

    // MARK: - Budget Check (by counting today's entries)

    /// Count the number of cache entries for a surface today.
    static func todayCallCount(
        surface: AISurface,
        profile: CDPuppyProfile,
        in context: NSManagedObjectContext
    ) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let request = NSFetchRequest<CDAICache>(entityName: "CDAICache")
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "profile == %@", profile),
            NSPredicate(format: "surface == %@", surface.rawValue),
            NSPredicate(format: "cachedAt >= %@", startOfDay as CVarArg)
        ])

        nonisolated(unsafe) var count = 0
        context.performAndWait {
            count = (try? context.count(for: request)) ?? 0
        }
        return count
    }

    /// Count the total number of cache entries for a profile today.
    static func todayTotalCallCount(
        profile: CDPuppyProfile,
        in context: NSManagedObjectContext
    ) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let request = NSFetchRequest<CDAICache>(entityName: "CDAICache")
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "profile == %@", profile),
            NSPredicate(format: "cachedAt >= %@", startOfDay as CVarArg)
        ])

        nonisolated(unsafe) var count = 0
        context.performAndWait {
            count = (try? context.count(for: request)) ?? 0
        }
        return count
    }
}

