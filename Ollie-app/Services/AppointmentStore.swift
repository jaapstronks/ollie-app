//
//  AppointmentStore.swift
//  Otis-app
//
//  Manages appointments with Core Data and automatic CloudKit sync
//  Appointments are stored per-profile and sync automatically via CloudKit

import Foundation
import CoreData
import OtisShared
import Combine
import os

/// Manages appointments with Core Data and automatic CloudKit sync
@MainActor
final class AppointmentStore: BaseStore, ProfileAccessible {

    // MARK: - State

    private(set) var appointments: [DogAppointment] = []

    // MARK: - ProfileAccessible

    weak var profileStore: ProfileStore?

    // MARK: - Cached Computed Properties

    private var _cachedUpcoming: [DogAppointment]?
    private var _cachedThisWeek: [DogAppointment]?
    private var _cachedComingUp: [DogAppointment]?

    private func invalidateCaches() {
        _cachedUpcoming = nil
        _cachedThisWeek = nil
        _cachedComingUp = nil
    }

    // MARK: - Computed Properties

    /// Count of all appointments for current profile
    var appointmentCount: Int {
        appointments.count
    }

    /// Upcoming appointments (sorted by start date)
    var upcomingAppointments: [DogAppointment] {
        if let cached = _cachedUpcoming { return cached }
        let result = appointments.filter { $0.isUpcoming || $0.isToday }
            .sorted { $0.startDate < $1.startDate }
        _cachedUpcoming = result
        return result
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

    /// Get count of upcoming appointments
    var upcomingCount: Int {
        upcomingAppointments.count
    }

    /// Appointments within this week (7 days)
    var appointmentsThisWeek: [DogAppointment] {
        if let cached = _cachedThisWeek { return cached }

        let calendar = Calendar.current
        let now = Date()
        guard let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now) else {
            return []
        }

        let result = appointments.filter { appointment in
            let startDay = calendar.startOfDay(for: appointment.startDate)
            let today = calendar.startOfDay(for: now)
            let endOfWeek = calendar.startOfDay(for: weekFromNow)

            return startDay >= today && startDay <= endOfWeek && !appointment.isCompleted
        }.sorted { $0.startDate < $1.startDate }

        _cachedThisWeek = result
        return result
    }

    /// Appointments coming up in 2-4 weeks
    var appointmentsComingUp: [DogAppointment] {
        if let cached = _cachedComingUp { return cached }

        let calendar = Calendar.current
        let now = Date()
        guard let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now),
              let monthFromNow = calendar.date(byAdding: .day, value: 28, to: now) else {
            return []
        }

        let result = appointments.filter { appointment in
            let startDay = calendar.startOfDay(for: appointment.startDate)
            let afterThisWeek = calendar.startOfDay(for: weekFromNow)
            let endOfMonth = calendar.startOfDay(for: monthFromNow)

            return startDay > afterThisWeek && startDay <= endOfMonth && !appointment.isCompleted
        }.sorted { $0.startDate < $1.startDate }

        _cachedComingUp = result
        return result
    }

    // MARK: - Init

    init(
        persistenceController: PersistenceController = .shared,
        profileStore: ProfileStore? = nil
    ) {
        self.profileStore = profileStore
        super.init(persistenceController: persistenceController, logCategory: "AppointmentStore")
    }

    /// Set the profile store (for when it's not available at init time)
    func setProfileStore(_ profileStore: ProfileStore) {
        configureProfileStore(profileStore)
    }

    // MARK: - Data Loading

    override func performInitialLoad() {
        invalidateCaches()

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
            setError(Strings.Common.notFound)
            return false
        }

        _ = CDDogAppointment.create(from: appointment, profile: profile, in: viewContext)

        return performSave(operation: "Added appointment: \(appointment.title)") {
            performInitialLoad()
        }
    }

    /// Update an existing appointment
    /// - Returns: `true` if the appointment was updated successfully
    @discardableResult
    func updateAppointment(_ appointment: DogAppointment) -> Bool {
        guard let cdAppointment = CDDogAppointment.fetch(byId: appointment.id, in: viewContext) else {
            logger.warning("Appointment not found for update: \(appointment.id)")
            setError(Strings.Common.notFound)
            return false
        }

        cdAppointment.update(from: appointment)

        return performSave(operation: "Updated appointment: \(appointment.title)") {
            performInitialLoad()
        }
    }

    /// Delete an appointment
    /// - Returns: `true` if the appointment was deleted successfully
    @discardableResult
    func deleteAppointment(_ appointment: DogAppointment) -> Bool {
        guard let cdAppointment = CDDogAppointment.fetch(byId: appointment.id, in: viewContext) else {
            logger.warning("Appointment not found for deletion: \(appointment.id)")
            setError(Strings.Common.notFound)
            return false
        }

        viewContext.delete(cdAppointment)

        return performDelete(operation: "Deleted appointment: \(appointment.title)") {
            appointments.removeAll { $0.id == appointment.id }
        }
    }

    /// Mark an appointment as completed
    /// If this is a grooming appointment with a linked grooming type, optionally mark the grooming activity as complete
    @discardableResult
    func completeAppointment(
        _ appointment: DogAppointment,
        notes: String? = nil,
        routineStore: RoutineStore? = nil
    ) -> Bool {
        var updatedAppointment = appointment
        updatedAppointment.isCompleted = true
        updatedAppointment.completionNotes = notes

        // If this is a grooming appointment with a linked type, mark it complete in RoutineStore
        if appointment.appointmentType == .grooming,
           let groomingType = appointment.linkedGroomingType,
           let routineStore = routineStore {
            routineStore.markGroomingCompleted(type: groomingType, at: Date())
            logger.info("Marked linked grooming activity \(groomingType.rawValue) as complete")
        }

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

        performSave(operation: "Migrated orphaned appointments") {
            performInitialLoad()
        }
    }
}
