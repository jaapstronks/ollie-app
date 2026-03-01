//
//  WeightStore.swift
//  Otis-app
//
//  Manages weight measurements with Core Data and automatic CloudKit sync.
//  Weight measurements are stored separately from daily events since they follow
//  a different rhythm (monthly health checks vs daily activities).
//

import Foundation
import CoreData
import OtisShared
import Combine
import os

/// Manages weight measurements with Core Data and automatic CloudKit sync
@MainActor
final class WeightStore: ObservableObject {

    // MARK: - Published State

    @Published private(set) var measurements: [WeightMeasurement] = []

    // MARK: - Dependencies

    private let persistenceController: PersistenceController
    private weak var profileStore: ProfileStore?
    private let logger: Logger

    // MARK: - CloudKit Sync

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Cached Computed Properties

    private var _cachedLatestWeight: (weight: Double, date: Date)?
    private var _cachedWeightDelta: (delta: Double, previousDate: Date)?
    private var _cachedFirstWeight: (weight: Double, date: Date)?
    private var _cachedGrowthStory: GrowthStory?

    private func invalidateCaches() {
        _cachedLatestWeight = nil
        _cachedWeightDelta = nil
        _cachedFirstWeight = nil
        _cachedGrowthStory = nil
    }

    // MARK: - Convenience Accessors

    var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    // MARK: - Computed Properties

    /// Count of all measurements for current profile
    var measurementCount: Int {
        measurements.count
    }

    /// Latest weight measurement
    var latestWeight: (weight: Double, date: Date)? {
        if let cached = _cachedLatestWeight { return cached }
        let result = WeightCalculations.latestWeight(from: measurements)
        _cachedLatestWeight = result
        return result
    }

    /// Weight delta from previous measurement
    var weightDelta: (delta: Double, previousDate: Date)? {
        if let cached = _cachedWeightDelta { return cached }
        let result = WeightCalculations.weightDelta(from: measurements)
        _cachedWeightDelta = result
        return result
    }

    /// First weight measurement (for "journey begins" state)
    var firstWeight: (weight: Double, date: Date)? {
        if let cached = _cachedFirstWeight { return cached }
        let result = WeightCalculations.firstWeight(from: measurements)
        _cachedFirstWeight = result
        return result
    }

    /// Growth story for health display
    func growthStory(homeDate: Date, sizeCategory: PuppyProfile.SizeCategory, breed: Breed? = nil) -> GrowthStory? {
        // Use cached value if available
        if let cached = _cachedGrowthStory { return cached }

        let result = WeightCalculations.growthStory(
            from: measurements,
            homeDate: homeDate,
            sizeCategory: sizeCategory,
            breed: breed
        )
        _cachedGrowthStory = result
        return result
    }

    /// Chart points for weight chart display
    func chartPoints(birthDate: Date) -> [WeightChartPoint] {
        WeightCalculations.chartPoints(from: measurements, birthDate: birthDate)
    }

    // MARK: - Init

    init(
        persistenceController: PersistenceController = .shared,
        profileStore: ProfileStore? = nil
    ) {
        self.persistenceController = persistenceController
        self.profileStore = profileStore
        self.logger = Logger.otis(category: "WeightStore")
        setupRemoteChangeObserver()
    }

    /// Set the profile store (for when it's not available at init time)
    func setProfileStore(_ profileStore: ProfileStore) {
        self.profileStore = profileStore
        performInitialLoad()
    }

    // MARK: - Remote Change Observer

    private func setupRemoteChangeObserver() {
        NotificationCenter.default
            .publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleRemoteChange()
            }
            .store(in: &cancellables)
    }

    private func handleRemoteChange() {
        logger.debug("Detected CloudKit remote change")
        performInitialLoad()
    }

    // MARK: - Data Loading

    func performInitialLoad() {
        invalidateCaches()

        guard let profile = getCurrentProfile() else {
            measurements = []
            return
        }

        let cdMeasurements = CDWeightMeasurement.fetchMeasurementsChronological(for: profile, in: viewContext)
        measurements = cdMeasurements.compactMap { $0.toWeightMeasurement() }
        logger.info("Loaded \(self.measurements.count) weight measurements for profile")
    }

    // MARK: - Profile Access

    /// Get the current CDPuppyProfile from Core Data
    private func getCurrentProfile() -> CDPuppyProfile? {
        guard let profileId = profileStore?.profile?.id else {
            logger.warning("No profile available for weight operations")
            return nil
        }
        return CDPuppyProfile.fetch(byId: profileId, in: viewContext)
    }

    // MARK: - CRUD Operations

    /// Add a new weight measurement
    /// - Returns: `true` if the measurement was saved successfully
    @discardableResult
    func addMeasurement(_ measurement: WeightMeasurement) -> Bool {
        guard let profile = getCurrentProfile() else {
            logger.error("Cannot add weight: no profile")
            return false
        }

        _ = CDWeightMeasurement.create(from: measurement, profile: profile, in: viewContext)

        return performSave(operation: "Added weight: \(String(format: "%.2f", measurement.weightKg)) kg") {
            performInitialLoad()
        }
    }

    /// Convenience method to add a weight measurement with just the value and date
    @discardableResult
    func addWeight(_ weightKg: Double, date: Date = Date(), note: String? = nil) -> Bool {
        let measurement = WeightMeasurement(
            date: date,
            weightKg: weightKg,
            note: note
        )
        return addMeasurement(measurement)
    }

    /// Update an existing measurement
    /// - Returns: `true` if the measurement was updated successfully
    @discardableResult
    func updateMeasurement(_ measurement: WeightMeasurement) -> Bool {
        guard let cdMeasurement = CDWeightMeasurement.fetchMeasurement(byId: measurement.id, in: viewContext) else {
            logger.warning("Weight measurement not found for update: \(measurement.id)")
            return false
        }

        cdMeasurement.update(from: measurement)

        return performSave(operation: "Updated weight: \(String(format: "%.2f", measurement.weightKg)) kg") {
            performInitialLoad()
        }
    }

    /// Delete a measurement
    /// - Returns: `true` if the measurement was deleted successfully
    @discardableResult
    func deleteMeasurement(_ measurement: WeightMeasurement) -> Bool {
        guard let cdMeasurement = CDWeightMeasurement.fetchMeasurement(byId: measurement.id, in: viewContext) else {
            logger.warning("Weight measurement not found for deletion: \(measurement.id)")
            return false
        }

        viewContext.delete(cdMeasurement)

        return performSave(operation: "Deleted weight measurement") {
            measurements.removeAll { $0.id == measurement.id }
            invalidateCaches()
        }
    }

    // MARK: - Queries

    /// Get measurement by ID
    func measurement(withId id: UUID) -> WeightMeasurement? {
        measurements.first { $0.id == id }
    }

    /// Get measurements within a date range
    func measurements(from startDate: Date, to endDate: Date) -> [WeightMeasurement] {
        measurements.filter { measurement in
            measurement.date >= startDate && measurement.date <= endDate
        }
    }

    // MARK: - Save Operations

    /// Perform a save operation with error handling
    @discardableResult
    private func performSave(operation: String, onSuccess: () -> Void) -> Bool {
        do {
            try persistenceController.save()
            onSuccess()
            logger.info("\(operation)")
            return true
        } catch {
            viewContext.rollback()
            logger.error("Failed to \(operation): \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - CloudKit Sync

    /// Sync data from CloudKit (refreshes context and reloads)
    func syncFromCloud() async {
        viewContext.refreshAllObjects()
        performInitialLoad()
    }

    /// Force sync with CloudKit
    func forceSync() async {
        await syncFromCloud()
    }

    // MARK: - Migration Support

    /// Migrate orphaned measurements to the current profile
    func migrateOrphanedMeasurements() {
        guard let profile = getCurrentProfile() else { return }

        let orphanedMeasurements = CDWeightMeasurement.fetchOrphanedMeasurements(in: viewContext)

        guard !orphanedMeasurements.isEmpty else { return }

        logger.info("Migrating \(orphanedMeasurements.count) orphaned weight measurements to current profile")

        for cdMeasurement in orphanedMeasurements {
            cdMeasurement.profile = profile
        }

        performSave(operation: "Migrated orphaned weight measurements") {
            performInitialLoad()
        }
    }
}
