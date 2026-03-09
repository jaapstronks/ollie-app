//
//  HealthView+CalendarSections.swift
//  Ollie-app
//
//  Health calendar and upcoming appointments sections for the health view.
//

import SwiftUI
import OtisShared

extension HealthView {

    // MARK: - Health Calendar Section

    @ViewBuilder
    var healthCalendarSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            SectionHeader(title: Strings.VetVisit.Calendar.title, icon: "calendar", tint: .otisAccent) {
                NavigationLink {
                    HealthCalendarView()
                        .environmentObject(appointmentStore)
                        .environmentObject(milestoneStore)
                        .environmentObject(viewModel.profileStore)
                } label: {
                    HStack(spacing: 4) {
                        Text(Strings.Common.seeAll)
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
            }

            // Quick preview of upcoming events
            upcomingAppointmentsSection
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .sheet(isPresented: $showHealthCalendar) {
            NavigationStack {
                HealthCalendarView()
                    .environmentObject(appointmentStore)
                    .environmentObject(milestoneStore)
                    .environmentObject(viewModel.profileStore)
            }
        }
    }

    // MARK: - Upcoming Appointments Section

    @ViewBuilder
    var upcomingAppointmentsSection: some View {
        let appointments = Array(appointmentStore.upcomingAppointments.prefix(2))
        VStack(spacing: 12) {
            if appointments.isEmpty {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(.secondary)
                    Text(Strings.VetVisit.Calendar.noEvents)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
            } else {
                ForEach(appointments, id: \.id) { appointment in
                    HStack(spacing: 12) {
                        Image(systemName: appointment.appointmentType.icon)
                            .foregroundStyle(appointment.appointmentType.isHealthRelated ? Color.otisHealth : Color.otisAccent)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(appointment.title)
                                .font(.subheadline.weight(.medium))

                            Text(appointment.dateString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if appointment.isToday {
                            CapsuleBadge(Strings.VetVisit.visitToday, color: .otisDanger, style: .filled)
                        }
                    }
                }
                .padding()
            }
        }
    }
}
