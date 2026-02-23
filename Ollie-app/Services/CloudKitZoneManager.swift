//
//  CloudKitZoneManager.swift
//  Ollie-app
//
//  Manages CloudKit zone creation and subscriptions

import Foundation
import CloudKit
import os

/// Handles CloudKit zone setup and change subscriptions
struct CloudKitZoneManager {
    let privateDatabase: CKDatabase
    let sharedDatabase: CKDatabase
    let zoneID: CKRecordZone.ID
    let zoneName: String

    private let logger = Logger(subsystem: "nl.jaapstronks.Ollie", category: "CloudKitZone")

    // MARK: - Zone Management

    /// Create the custom zone if it doesn't exist
    func createZoneIfNeeded() async throws {
        let zone = CKRecordZone(zoneID: zoneID)

        do {
            _ = try await privateDatabase.save(zone)
            logger.info("Created CloudKit zone: \(self.zoneName)")
        } catch let error as CKError {
            // Zone might already exist, that's fine
            if error.code != .serverRecordChanged && error.code != .zoneNotFound {
                throw error
            }
            logger.info("Zone already exists or handled: \(error.code.rawValue)")
        }
    }

    // MARK: - Subscriptions

    /// Subscribe to zone changes for real-time updates
    func subscribeToChanges(
        targetZoneID: CKRecordZone.ID,
        isParticipant: Bool
    ) async throws {
        let subscriptionID = "ollie-events-changes"

        // Check if subscription exists
        do {
            _ = try await privateDatabase.subscription(for: subscriptionID)
            logger.info("Subscription already exists")
            return
        } catch {
            // Subscription doesn't exist, create it
        }

        let subscription = CKRecordZoneSubscription(
            zoneID: targetZoneID,
            subscriptionID: subscriptionID
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true // Silent push
        subscription.notificationInfo = notificationInfo

        let database = isParticipant ? sharedDatabase : privateDatabase
        _ = try await database.save(subscription)
        logger.info("Created CloudKit subscription for zone changes")
    }

    // MARK: - Participant Zone Detection

    /// Check for shared zones that we're participating in
    func findParticipantZone() async -> CKRecordZone.ID? {
        do {
            let zones = try await sharedDatabase.allRecordZones()
            if let sharedZone = zones.first(where: { $0.zoneID.zoneName == zoneName }) {
                logger.info("Found shared zone, user is participant")
                return sharedZone.zoneID
            }
        } catch {
            logger.warning("Could not check shared zones: \(error.localizedDescription)")
        }
        return nil
    }

    /// Get all zones from shared database matching our zone name
    func allSharedZones() async throws -> [CKRecordZone] {
        let zones = try await sharedDatabase.allRecordZones()
        return zones.filter { $0.zoneID.zoneName == zoneName }
    }
}
