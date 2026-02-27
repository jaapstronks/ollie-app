//
//  AppointmentsView.swift
//  Ollie-app
//
//  Main view for managing dog appointments

import SwiftUI
import OllieShared

/// Main view for listing and managing appointments
struct AppointmentsView: View {
    @ObservedObject var appointmentStore: AppointmentStore

    @State private var showingAddSheet = false
    @State private var appointmentToDelete: DogAppointment?
    @State private var showingDeleteConfirmation = false
    @State private var selectedSegment: AppointmentSegment = .upcoming

    enum AppointmentSegment: String, CaseIterable {
        case upcoming
        case past

        var title: String {
            switch self {
            case .upcoming: return Strings.Appointments.upcoming
            case .past: return Strings.Appointments.past
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Segment picker
            Picker("", selection: $selectedSegment) {
                ForEach(AppointmentSegment.allCases, id: \.self) { segment in
                    Text(segment.title).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Content
            Group {
                switch selectedSegment {
                case .upcoming:
                    if appointmentStore.upcomingAppointments.isEmpty {
                        emptyState(for: .upcoming)
                    } else {
                        appointmentList(appointments: appointmentStore.upcomingAppointments)
                    }
                case .past:
                    if appointmentStore.pastAppointments.isEmpty {
                        emptyState(for: .past)
                    } else {
                        appointmentList(appointments: appointmentStore.pastAppointments)
                    }
                }
            }
        }
        .navigationTitle(Strings.Appointments.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditAppointmentSheet(appointmentStore: appointmentStore)
        }
        .alert(
            Strings.Appointments.deleteConfirmTitle,
            isPresented: $showingDeleteConfirmation,
            presenting: appointmentToDelete
        ) { appointment in
            Button(Strings.Common.cancel, role: .cancel) {
                appointmentToDelete = nil
            }
            Button(Strings.Common.delete, role: .destructive) {
                appointmentStore.deleteAppointment(appointment)
                appointmentToDelete = nil
            }
        } message: { _ in
            Text(Strings.Appointments.deleteConfirmMessage)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private func emptyState(for segment: AppointmentSegment) -> some View {
        ContentUnavailableView {
            Label(
                segment == .upcoming
                    ? Strings.Appointments.noUpcomingAppointments
                    : Strings.Appointments.noPastAppointments,
                systemImage: "calendar"
            )
        } description: {
            if segment == .upcoming {
                Text(Strings.Appointments.noAppointmentsHint)
            }
        } actions: {
            if segment == .upcoming {
                Button {
                    showingAddSheet = true
                } label: {
                    Text(Strings.Appointments.addAppointment)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Appointment List

    @ViewBuilder
    private func appointmentList(appointments: [DogAppointment]) -> some View {
        List {
            // Group by date
            ForEach(groupedDates(for: appointments), id: \.self) { date in
                Section(formattedSectionDate(date)) {
                    ForEach(appointmentsForDate(date, in: appointments)) { appointment in
                        NavigationLink {
                            AppointmentDetailView(
                                appointment: appointment,
                                appointmentStore: appointmentStore
                            )
                        } label: {
                            AppointmentRow(appointment: appointment)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                appointmentToDelete = appointment
                                showingDeleteConfirmation = true
                            } label: {
                                Label(Strings.Common.delete, systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Helpers

    /// Get unique dates from appointments, sorted
    private func groupedDates(for appointments: [DogAppointment]) -> [Date] {
        let calendar = Calendar.current
        let dates = appointments.map { calendar.startOfDay(for: $0.startDate) }
        let uniqueDates = Set(dates)
        return uniqueDates.sorted()
    }

    /// Appointments for a specific date
    private func appointmentsForDate(_ date: Date, in appointments: [DogAppointment]) -> [DogAppointment] {
        let calendar = Calendar.current
        return appointments.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Format date for section header
    private func formattedSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return String(localized: "Today")
        } else if calendar.isDateInTomorrow(date) {
            return String(localized: "Tomorrow")
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "Yesterday")
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

#Preview {
    NavigationStack {
        AppointmentsView(appointmentStore: AppointmentStore())
    }
}
