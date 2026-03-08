//
//  VetVisitTipsCard.swift
//  Ollie-app
//
//  Compact card showing upcoming vet visit with tip count.
//  Shown on TodayView when vet appointment is within 3 days.
//

import SwiftUI
import OtisShared

/// Card displaying upcoming vet visit information with tips preview
struct VetVisitTipsCard: View {
    let appointment: DogAppointment
    let tipCount: Int
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var daysUntil: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let appointmentDay = calendar.startOfDay(for: appointment.startDate)
        return calendar.dateComponents([.day], from: today, to: appointmentDay).day ?? 0
    }

    private var daysLabel: String {
        switch daysUntil {
        case 0: return Strings.VetVisit.visitToday
        case 1: return Strings.VetVisit.visitTomorrow
        default: return Strings.VetVisit.visitInDays(daysUntil)
        }
    }

    private var urgencyColor: Color {
        switch daysUntil {
        case 0: return Color.otisDanger
        case 1: return Color.otisWarning
        default: return Color.otisInfo
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(urgencyColor.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(urgencyColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.VetVisit.upcomingVisit)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(daysLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Days badge
                    if daysUntil <= 1 {
                        Text(daysUntil == 0 ? "!" : "")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(urgencyColor)
                            .clipShape(Capsule())
                    }
                }

                // Appointment details
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(appointment.dateString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text(appointment.timeRangeString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Tips preview
                if tipCount > 0 {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(Color.otisWarning)

                        Text("\(tipCount) \(Strings.VetVisit.questionsToConsider)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(urgencyColor.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Today") {
    VetVisitTipsCard(
        appointment: DogAppointment(
            title: "Annual Checkup",
            appointmentType: .vetCheckup,
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600)
        ),
        tipCount: 5,
        onTap: {}
    )
    .padding()
}

#Preview("Tomorrow") {
    VetVisitTipsCard(
        appointment: DogAppointment(
            title: "Vaccination",
            appointmentType: .vetCheckup,
            startDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!.addingTimeInterval(1800)
        ),
        tipCount: 3,
        onTap: {}
    )
    .padding()
}
