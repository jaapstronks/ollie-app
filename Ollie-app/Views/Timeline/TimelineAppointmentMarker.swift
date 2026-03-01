//
//  TimelineAppointmentMarker.swift
//  Otis-app
//
//  Appointment marker for the vertical timeline (dashed outline style)

import SwiftUI
import OtisShared

/// Appointment card for the vertical timeline with dashed outline style
struct TimelineAppointmentMarker: View {
    let appointment: DogAppointment
    let height: CGFloat
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Appointment type icon
                AppointmentIcon(appointment: appointment)

                // Title and time
                VStack(alignment: .leading, spacing: 2) {
                    Text(appointment.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(appointment.timeRangeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let location = appointment.location, !location.isEmpty {
                        Label(location, systemImage: "mappin.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Future indicator (chevron)
                if appointment.isUpcoming {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minHeight: max(height, LayoutConstants.timelineMinBlockHeight))
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM)
                    .fill(cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM)
                            .strokeBorder(
                                appointmentColor.opacity(0.5),
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Colors

    private var appointmentColor: Color {
        Color(appointment.appointmentType.color)
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? appointmentColor.opacity(0.08)
            : appointmentColor.opacity(0.05)
    }

    private var accessibilityLabel: String {
        var parts = [appointment.title, appointment.timeRangeString]
        if let location = appointment.location {
            parts.append(location)
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Appointment Icon

private struct AppointmentIcon: View {
    let appointment: DogAppointment

    private var iconColor: Color {
        Color(appointment.appointmentType.color)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 36, height: 36)

            Image(systemName: appointment.appointmentType.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(iconColor)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        TimelineAppointmentMarker(
            appointment: DogAppointment(
                title: "Vet Check-up",
                appointmentType: .vetCheckup,
                startDate: Date().addingTimeInterval(3600),
                endDate: Date().addingTimeInterval(5400),
                location: "Happy Paws Clinic"
            ),
            height: 60,
            onTap: {}
        )

        TimelineAppointmentMarker(
            appointment: DogAppointment(
                title: "Grooming Session",
                appointmentType: .grooming,
                startDate: Date().addingTimeInterval(7200),
                endDate: Date().addingTimeInterval(10800)
            ),
            height: 50,
            onTap: {}
        )
    }
    .padding()
}
