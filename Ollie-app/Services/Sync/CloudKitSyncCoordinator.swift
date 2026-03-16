//
//  CloudKitSyncCoordinator.swift
//  Otis-app
//
//  Centralizes CloudKit sync notification handling with debouncing.
//  Replaces 12+ independent NSPersistentStoreRemoteChange listeners with
//  a single coordinated response.
//
//  Performance Impact:
//  - Before: 12+ simultaneous performInitialLoad() calls per notification
//  - After: 1 debounced, coordinated refresh
//
//  See PERFORMANCE-ANALYSIS.md for full context.
//

import Foundation
import Combine
import CoreData
import OtisShared
import os

/// Centralized coordinator for CloudKit sync notifications
/// Replaces individual store listeners with debounced, coordinated handling
@MainActor
final class CloudKitSyncCoordinator {

    // MARK: - Shared Instance

    static let shared = CloudKitSyncCoordinator()

    // MARK: - Dependencies

    private let logger = Logger.otis(category: "CloudKitSyncCoordinator")
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Debounce State

    /// Active debounce task (cancelled if new notification arrives)
    private var debounceTask: Task<Void, Never>?

    /// How long to wait before processing (coalesces rapid notifications)
    private let debounceInterval: Duration = .milliseconds(500)

    /// Last processed timestamp (prevents re-processing within debounce window)
    private var lastProcessedTime: Date = .distantPast

    /// Whether a refresh is currently in progress
    private var isRefreshing = false

    // MARK: - Registered Stores

    /// Stores registered for coordinated sync
    /// Using weak references to avoid retain cycles
    private var registeredStores: [WeakStore] = []

    // MARK: - Callbacks for Non-Store Handlers

    /// Additional refresh callbacks (for EventStore, ProfileStore which aren't BaseStore)
    private var refreshCallbacks: [String: @MainActor () async -> Void] = [:]

    // MARK: - Initialization

    private init() {
        setupNotificationObserver()
    }

    // MARK: - Setup

    private func setupNotificationObserver() {
        // Single listener for all CloudKit remote changes
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleRemoteChangeNotification()
            }
            .store(in: &cancellables)
    }

    // MARK: - Store Registration

    /// Register a BaseStore for coordinated sync
    /// Stores should call this instead of setting up their own observer
    func register(store: any CloudKitRefreshable, identifier: String) {
        // Remove any existing registration with same identifier
        registeredStores.removeAll { $0.identifier == identifier }
        registeredStores.append(WeakStore(store: store, identifier: identifier))
        logger.debug("Registered store: \(identifier)")
    }

    /// Register a refresh callback for non-BaseStore handlers
    func registerCallback(identifier: String, callback: @escaping @MainActor () async -> Void) {
        refreshCallbacks[identifier] = callback
        logger.debug("Registered callback: \(identifier)")
    }

    /// Unregister a store or callback
    func unregister(identifier: String) {
        registeredStores.removeAll { $0.identifier == identifier }
        refreshCallbacks.removeValue(forKey: identifier)
    }

    // MARK: - Notification Handling

    private func handleRemoteChangeNotification() {
        // Cancel any pending debounce task
        debounceTask?.cancel()

        // Start new debounced processing
        debounceTask = Task {
            // Wait for debounce interval (coalesces rapid notifications)
            try? await Task.sleep(for: debounceInterval)

            // Check if cancelled during wait
            guard !Task.isCancelled else { return }

            // Process the sync
            await processRemoteChange()
        }
    }

    private func processRemoteChange() async {
        // Prevent concurrent refreshes
        guard !isRefreshing else {
            logger.debug("Skipping refresh - already in progress")
            return
        }

        // Check if we already processed recently (within debounce window)
        let now = Date()
        if now.timeIntervalSince(lastProcessedTime) < 0.4 {
            logger.debug("Skipping refresh - processed recently")
            return
        }

        isRefreshing = true
        lastProcessedTime = now
        logger.info("Processing CloudKit remote change (coordinated)")

        // Clean up deallocated stores
        registeredStores.removeAll { $0.store == nil }

        // Execute refresh callbacks first (EventStore, ProfileStore)
        // These are critical path and should run before other stores
        for (identifier, callback) in refreshCallbacks {
            logger.debug("Refreshing callback: \(identifier)")
            await callback()
        }

        // Then refresh registered BaseStore instances
        // Run sequentially on MainActor (avoids Sendable issues with @MainActor stores)
        for weakStore in registeredStores {
            guard let store = weakStore.store else { continue }
            await store.refreshFromCloud()
        }

        isRefreshing = false
        logger.info("CloudKit remote change processing complete")
    }

    // MARK: - Manual Trigger

    /// Force a refresh (for foreground entry, manual sync, etc.)
    func forceRefresh() async {
        // Bypass debounce for explicit refresh requests
        debounceTask?.cancel()
        await processRemoteChange()
    }
}

// MARK: - Supporting Types

/// Protocol for stores that can be refreshed from CloudKit
@MainActor
protocol CloudKitRefreshable: AnyObject {
    func refreshFromCloud() async
}

/// Weak wrapper for store references
private struct WeakStore {
    weak var store: (any CloudKitRefreshable)?
    let identifier: String
}
