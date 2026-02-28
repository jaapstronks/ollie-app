//
//  AppointmentStore.swift
//  Ollie-app
//
//  Manages appointments with Core Data and automatic CloudKit sync
//  Appointments are stored per-profile and sync automatically via CloudKit

import Foundation
import CoreData
import OllieShared
import Combine
import os

/// Manages appointments with Core Data and automatic CloudKit sync
@MainActor
class AppointmentStore: ObservableObject {

    // MARK: - Published State

    @Published private(set) var appointments: [DogAppointment] = []
    @Published private(set) var isSyncing = false

    /// Last error that occurred during a store operation (for UI display)
    @Published private(set) var lastError: (message: String, date: Date)?

    /// Clear the last error (call when user dismisses error banner)
    func clearError() {
        lastError = nil
    }

    // MARK: - Dependencies

    private let persistenceController: PersistenceController
    private weak var profileStore: ProfileStore?
    private let logger = Logger.ollie(category: "AppointmentStore")
    private var cancellables = Set<AnyCancellable>()

    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    // MARK: - Computed Properties

    /// Count of all appointments for current profile
    var appointmentCount: Int {
        appointments.count
    }

    /// Upcoming appointments (sorted by start date)
    var upcomingAppointments: [DogAppointment] {
        appointments.filter { $0.isUpcoming || $0.isToday }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Past appointments (sorted by start date, most recent first)
    var pastAppointments: [DogAppointment] {
        appointments.filter { $0.isPast }
            .sorted { $0.startDate > $1.startDate }
    }

    /// Today's appointments
    var todaysAppointments: [DogAppointment] {
        appointments.filter { $0.isToday }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Appointments grouped by type
    var appointmentsByType: [AppointmentType: [DogAppointment]] {
        Dictionary(grouping: appointments, by: { $0.appointmentType })
    }

    // MARK: - Init

    init(
        persistenceController: PersistenceController = .shared,
        profileStore: ProfileStore? = nil
    ) {
        self.persistenceController = persistenceController
        self.profileStore = profileStore
        setupObservers()
        loadAppointments()
    }

    /// Set the profile store (for when it's not available at init time)
    func setProfileStore(_ profileStore: ProfileStore) {
        self.profileStore = profileStore
        loadAppointments()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observe CloudKit remote changes
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleRemoteChange()
            }
            .store(in: &cancellables)
    }

    private func handleRemoteChange() {
        logger.debug("Detected CloudKit remote change for appointments")
        loadAppointments()
    }

    // MARK: - Profile Access

    /// Get the current CDPuppyProfile from Core Data
    private func getCurrentProfile() -> CDPuppyProfile? {
        guard let profileId = profileStore?.profile?.id else {
            logger.warning("No profile available for appointment operations")
            return nil
        }
        return CDPuppyProfile.fetch(byId: profileId, in: viewContext)
    }

    // MARK: - Appointment Loading

    func loadAppointments() {
        guard let profile = getCurrentProfile() else {
            appointments = []
            return
        }

        let cdAppointments = CDDogAppointment.fetchAppointments(for: profile, in: viewContext)
        appointments = cdAppointments.compactMap { $0.toAppointment() }
        logger.info("Loaded \(self.appointments.count) appointments for profile")
    }

    // MARK: - CRUD Operations

    /// Add a new appointment
    /// - Returns: `true` if the appointment was saved successfully
    @discardableResult
    func addAppointment(_ appointment: DogAppointment) -> Bool {
        guard let profile = getCurrentProfile() else {
            lastError = (Strings.Common.notFound, Date())
            return false
        }

        _ = CDDogAppointment.create(from: appointment, profile: profile, in: viewContext)

        do {
            try persistenceController.save()
            loadAppointments()
            lastError = nil
            logger.info("Added appointment: \(appointment.title)")
            return true
        } catch {
            viewContext.rollback()
            lastError = (Strings.Common.saveFailed, Date())
            logger.error("Failed to add appointment: \(error.localizedDescription)")
            return false
        }
    }

    /// Update an existing appointment
    /// - Returns: `true` if the appointment was updated successfully
    @discardableResult
    func updateAppointment(_ appointment: DogAppointment) -> Bool {
        guard let cdAppointment = CDDogAppointment.fetch(byId: appointment.id, in: viewContext) else {
            logger.warning("Appointment not found for update: \(appointment.id)")
            lastError = (Strings.Common.notFound, Date())
            return false
        }

        cdAppointment.update(from: appointment)

        do {
            try persistenceController.save()
            loadAppointments()
            lastError = nil
            logger.info("Updated appointment: \(appointment.title)")
            return true
        } catch {
            viewContext.rollback()
            lastError = (Strings.Common.saveFailed, Date())
            logger.error("Failed to update appointment: \(error.localizedDescription)")
            return false
        }
    }

    /// Delete an appointment
    /// - Returns: `true` if the appointment was deleted successfully
    @discardableResult
    func deleteAppointment(_ appointment: DogAppointment) -> Bool {
        guard let cdAppointment = CDDogAppointment.fetch(byId: appointment.id, in: viewContext) else {
            logger.warning("Appointment not found for deletion: \(appointment.id)")
            lastError = (Strings.Common.notFound, Date())
            return false
        }

        viewContext.delete(cdAppointment)

        do {
            try persistenceController.save()
            appointments.removeAll { $0.id == appointment.id }
            lastError = nil
            logger.info("Deleted appointment: \(appointment.title)")
            return true
        } catch {
            viewContext.rollback()
            lastError = (Strings.Common.deleteFailed, Date())
            logger.error("Failed to delete appointment: \(error.localizedDescription)")
            return false
        }
    }

    /// Mark an appointment as completed
    @discardableResult
    func completeAppointment(_ appointment: DogAppointment, notes: String? = nil) -> Bool {
        var updatedAppointment = appointment
        updatedAppointment.isCompleted = true
        updatedAppointment.completionNotes = notes
        return updateAppointment(updatedAppointment)
    }

    // MARK: - Filtering & Queries

    /// Get appointments by type
    func appointments(ofType type: AppointmentType) -> [DogAppointment] {
        appointments.filter { $0.appointmentType == type }
    }

    /// Get appointment by ID
    func appointment(withId id: UUID) -> DogAppointment? {
        appointments.first { $0.id == id }
    }

    /// Get appointments for a specific date
    func appointments(for date: Date) -> [DogAppointment] {
        let calendar = Calendar.current
        return appointments.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Get appointments linked to a milestone
    func appointments(linkedToMilestoneId milestoneId: UUID) -> [DogAppointment] {
        appointments.filter { $0.linkedMilestoneID == milestoneId }
    }

    /// Get appointments linked to a contact
    func appointments(linkedToContactId contactId: UUID) -> [DogAppointment] {
        appointments.filter { $0.linkedContactID == contactId }
    }

    /// Get count of upcoming appointments
    var upcomingCount: Int {
        upcomingAppointments.count
    }

    /// Appointments within this week (7 days)
    var appointmentsThisWeek: [DogAppointment] {
        let calendar = Calendar.current
        let now = Date()
        guard let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now) else {
            return []
        }

        return appointments.filter { appointment in
            let startDay = calendar.startOfDay(for: appointment.startDate)
            let today = calendar.startOfDay(for: now)
            let endOfWeek = calendar.startOfDay(for: weekFromNow)

            return startDay >= today && startDay <= endOfWeek && !appointment.isCompleted
        }.sorted { $0.startDate < $1.startDate }
    }

    /// Appointments coming up in 2-4 weeks
    var appointmentsComingUp: [DogAppointment] {
        let calendar = Calendar.current
        let now = Date()
        guard let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now),
              let monthFromNow = calendar.date(byAdding: .day, value: 28, to: now) else {
            return []
        }

        return appointments.filter { appointment in
            let startDay = calendar.startOfDay(for: appointment.startDate)
            let afterThisWeek = calendar.startOfDay(for: weekFromNow)
            let endOfMonth = calendar.startOfDay(for: monthFromNow)

            return startDay > afterThisWeek && startDay <= endOfMonth && !appointment.isCompleted
        }.sorted { $0.startDate < $1.startDate }
    }

    /// Get appointments for a date range (for calendar month view efficiency)
    func appointments(from startDate: Date, to endDate: Date) -> [DogAppointment] {
        appointments.filter { appointment in
            appointment.startDate >= startDate && appointment.startDate < endDate
        }
    }

    /// Get appointments within the month containing the given date
    func appointments(inMonthOf date: Date) -> [DogAppointment] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let monthStart = calendar.date(from: components),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return []
        }

        // Add buffer for days from adjacent months visible in the grid
        guard let startBuffer = calendar.date(byAdding: .day, value: -7, to: monthStart),
              let endBuffer = calendar.date(byAdding: .day, value: 7, to: monthEnd) else {
            return []
        }

        return appointments(from: startBuffer, to: endBuffer)
    }

    // MARK: - CloudKit Sync

    /// Force refresh appointments from Core Data (useful after CloudKit sync)
    func syncFromCloud() async {
        viewContext.refreshAllObjects()
        loadAppointments()
    }

    // MARK: - Migration Support

    /// Migrate orphaned appointments to the current profile
    /// Call this once after updating the Core Data model to add profile relationships
    func migrateOrphanedAppointments() {
        guard let profile = getCurrentProfile() else { return }

        let orphanedAppointments = CDDogAppointment.fetchAllAppointmentsForMigration(in: viewContext)
            .filter { $0.profile == nil }

        guard !orphanedAppointments.isEmpty else { return }

        logger.info("Migrating \(orphanedAppointments.count) orphaned appointments to current profile")

        for cdAppointment in orphanedAppointments {
            cdAppointment.profile = profile
        }

        do {
            try persistenceController.save()
            loadAppointments()
            logger.info("Successfully migrated orphaned appointments")
        } catch {
            viewContext.rollback()
            logger.error("Failed to migrate orphaned appointments: \(error.localizedDescription)")
        }
    }
}
