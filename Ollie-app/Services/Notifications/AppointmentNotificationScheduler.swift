//
//  AppointmentNotificationScheduler.swift
//  Ollie-app
//
//  Handles scheduling appointment reminder notifications
//

import Foundation
import OllieShared
import UserNotifications
import os

/// Scheduler for appointment reminder notifications
@MainActor
final class AppointmentNotificationScheduler {
    let notificationPrefix = "appointment_"

    private let notificationCenter = UNUserNotificationCenter.current()
    private let logger = Logger.ollie(category: "AppointmentNotificationScheduler")

    /// Schedule notifications for upcoming appointments
    /// - Parameters:
    ///   - appointments: All appointments to consider
    ///   - profile: The puppy profile (for name in notifications)
    func schedule(appointments: [DogAppointment], profile: PuppyProfile) async {
        await cancel()

        let now = Date()
        let calendar = Calendar.current

        // Only schedule for appointments in the next 7 days that haven't been completed
        guard let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now) else { return }

        let upcomingAppointments = appointments.filter { appointment in
            !appointment.isCompleted &&
            appointment.startDate > now &&
            appointment.startDate <= weekFromNow &&
            appointment.reminderMinutesBefore > 0  // 0 means no reminder
        }

        for appointment in upcomingAppointments {
            let reminderDate = appointment.startDate.addingTimeInterval(TimeInterval(-appointment.reminderMinutesBefore * 60))

            // Skip if reminder time has already passed
            guard reminderDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = Strings.PushNotifications.appointmentReminderTitle
            content.body = Strings.PushNotifications.appointmentReminder(
                name: profile.name,
                title: appointment.title,
                time: formatTime(appointment.startDate)
            )
            content.sound = .default

            let timeInterval = reminderDate.timeIntervalSince(now)
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: timeInterval,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "\(notificationPrefix)\(appointment.id.uuidString)",
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
                logger.debug("Scheduled reminder for appointment: \(appointment.title)")
            } catch {
                logger.error("Failed to schedule appointment reminder for \(appointment.title): \(error.localizedDescription)")
            }
        }
    }

    /// Cancel all appointment notifications
    func cancel() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let appointmentIds = requests
            .filter { $0.identifier.hasPrefix(notificationPrefix) }
            .map { $0.identifier }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: appointmentIds)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
