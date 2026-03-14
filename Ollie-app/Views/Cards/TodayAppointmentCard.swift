//
//  TodayAppointmentCard.swift
//  Ollie-app
//
//  Card showing today's upcoming appointment with quick actions (call, navigate)
//

import SwiftUI
import OtisShared

/// Card shown on Today tab when there's an appointment scheduled for today
struct TodayAppointmentCard: View {
    let appointment: DogAppointment
    let linkedContact: DogContact?
    let onTap: () -> Void
    let onCallContact: ((String) -> Void)?
    let onGetDirections: ((Double, Double) -> Void)?

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and type
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.otisAccent.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: appointment.appointmentType.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(Color.otisAccent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Calendar.todayAppointment)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(appointment.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    // Time badge
                    if !appointment.isAllDay {
                        Text(appointment.startDate.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.otisAccent)
                            .clipShape(Capsule())
                    }
                }

                // Location if set
                if let location = appointment.location, !location.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                // Contact info and action buttons
                if let contact = linkedContact {
                    Divider()

                    HStack(spacing: 12) {
                        // Contact name
                        HStack(spacing: 6) {
                            Image(systemName: contact.contactType.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(contact.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        // Action buttons
                        HStack(spacing: 8) {
                            // Get directions button
                            if contact.hasLocation, let lat = contact.latitude, let lon = contact.longitude {
                                Button {
                                    onGetDirections?(lat, lon)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "location.fill")
                                            .font(.caption2)
                                        Text(Strings.Calendar.getDirections)
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.otisInfo)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }

                            // Call button
                            if let phone = contact.phone, !phone.isEmpty {
                                Button {
                                    onCallContact?(phone)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "phone.fill")
                                            .font(.caption2)
                                        Text(Strings.Contacts.call)
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.otisSuccess)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let appointment = DogAppointment(
        title: "Annual Checkup",
        appointmentType: .vetCheckup,
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600),
        location: "Happy Paws Veterinary Clinic"
    )

    let contact = DogContact(
        name: "Happy Paws Vet",
        contactType: .vet,
        phone: "555-1234",
        address: "123 Pet Street",
        latitude: 52.3676,
        longitude: 4.9041
    )

    TodayAppointmentCard(
        appointment: appointment,
        linkedContact: contact,
        onTap: { print("Tapped") },
        onCallContact: { phone in print("Call: \(phone)") },
        onGetDirections: { lat, lon in print("Directions: \(lat), \(lon)") }
    )
    .padding()
}
