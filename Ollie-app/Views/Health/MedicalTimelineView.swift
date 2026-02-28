//
//  MedicalTimelineView.swift
//  Ollie-app
//
//  Comprehensive medical timeline showing health milestones and medical appointments

import SwiftUI
import OllieShared

/// A unified timeline item for sorting milestones and appointments together
private struct MedicalTimelineItem: Identifiable {
    let id: UUID
    let date: Date
    let ageWeeks: Int
    let type: ItemType

    enum ItemType {
        case milestone(Milestone)
        case appointment(DogAppointment)
    }

    var isCompleted: Bool {
        switch type {
        case .milestone(let milestone):
            return milestone.isCompleted
        case .appointment(let appointment):
            return appointment.isCompleted
        }
    }
}

/// Medical timeline view showing all health milestones and appointments chronologically
struct MedicalTimelineView: View {
    @ObservedObject var milestoneStore: MilestoneStore
    @ObservedObject var appointmentStore: AppointmentStore
    let birthDate: Date
    let puppyName: String

    @State private var selectedMilestone: Milestone?

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Properties

    private var currentAgeWeeks: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.weekOfYear], from: birthDate, to: Date()).weekOfYear ?? 0
    }

    /// Combine health milestones and health-related appointments into a single sorted timeline
    private var timelineItems: [MedicalTimelineItem] {
        var items: [MedicalTimelineItem] = []
        let calendar = Calendar.current

        // Add health milestones
        let healthMilestones = milestoneStore.milestones(for: .health)
        for milestone in healthMilestones {
            let targetDate = milestone.completedDate ?? milestone.targetDate(birthDate: birthDate) ?? birthDate
            let ageWeeks = calendar.dateComponents([.weekOfYear], from: birthDate, to: targetDate).weekOfYear ?? 0
            items.append(MedicalTimelineItem(
                id: milestone.id,
                date: targetDate,
                ageWeeks: max(0, ageWeeks),
                type: .milestone(milestone)
            ))
        }

        // Add health-related appointments
        let healthAppointments = appointmentStore.appointments.filter { $0.appointmentType.isHealthRelated }
        for appointment in healthAppointments {
            let ageWeeks = calendar.dateComponents([.weekOfYear], from: birthDate, to: appointment.startDate).weekOfYear ?? 0
            items.append(MedicalTimelineItem(
                id: appointment.id,
                date: appointment.startDate,
                ageWeeks: max(0, ageWeeks),
                type: .appointment(appointment)
            ))
        }

        // Sort by date (earliest first for chronological view)
        return items.sorted { $0.date < $1.date }
    }

    /// Group items by age period for display
    private var groupedItems: [(period: String, items: [MedicalTimelineItem])] {
        var groups: [Int: [MedicalTimelineItem]] = [:]

        for item in timelineItems {
            // Group by week for first 16 weeks, then by month
            let groupKey: Int
            if item.ageWeeks < 16 {
                groupKey = item.ageWeeks
            } else {
                // Group by month (4 weeks = 1 month approximately)
                groupKey = 100 + (item.ageWeeks / 4) // Add 100 to distinguish from weeks
            }
            groups[groupKey, default: []].append(item)
        }

        // Sort groups and create display format
        return groups.keys.sorted().compactMap { key -> (String, [MedicalTimelineItem])? in
            guard let items = groups[key], !items.isEmpty else { return nil }

            let period: String
            if key < 100 {
                period = Strings.Health.weekNumber(key)
            } else {
                let months = key - 100
                period = Strings.Health.monthNumber(months)
            }

            return (period, items)
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Birth header card at the top
                birthHeaderCard
                    .padding(.horizontal)
                    .padding(.top)

                if timelineItems.isEmpty {
                    emptyStateView
                        .padding(.top, 40)
                } else {
                    // Timeline content
                    timelineContent
                        .padding(.horizontal)
                        .padding(.top, 16)
                }
            }
            .padding(.bottom, 20)
        }
        .navigationTitle(Strings.Health.medicalTimeline)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedMilestone) { milestone in
            MilestoneCompletionSheet(
                milestone: milestone,
                onDismiss: { selectedMilestone = nil },
                onComplete: { notes, photoID, vetClinic, completionDate in
                    milestoneStore.completeMilestone(
                        milestone,
                        notes: notes,
                        photoID: photoID,
                        vetClinicName: vetClinic,
                        completionDate: completionDate
                    )
                    selectedMilestone = nil
                }
            )
        }
    }

    // MARK: - Birth Header Card

    @ViewBuilder
    private var birthHeaderCard: some View {
        VStack(spacing: 12) {
            // Birth icon
            ZStack {
                Circle()
                    .fill(Color.ollieAccent.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.ollieAccent)
            }

            // Puppy name and birth date
            VStack(spacing: 4) {
                Text(puppyName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(birthDate.formatted(date: .long, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(Strings.Health.currentAge(weeks: currentAgeWeeks))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text(Strings.Health.noMedicalHistory)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(Strings.Health.noMedicalHistoryHint)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }

    // MARK: - Timeline Content

    @ViewBuilder
    private var timelineContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(groupedItems.enumerated()), id: \.offset) { index, group in
                VStack(alignment: .leading, spacing: 8) {
                    // Period header
                    Text(group.period)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 44)
                        .padding(.top, index == 0 ? 0 : 16)

                    // Items in this period
                    ForEach(group.items) { item in
                        timelineRow(for: item, isLast: item.id == timelineItems.last?.id)
                    }
                }
            }
        }
    }

    // MARK: - Timeline Row

    @ViewBuilder
    private func timelineRow(for item: MedicalTimelineItem, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline indicator (dot and line)
            VStack(spacing: 0) {
                // Dot
                Circle()
                    .fill(item.isCompleted ? Color.ollieSuccess : Color.ollieHealth)
                    .frame(width: 12, height: 12)
                    .padding(.top, 6)

                // Connecting line
                if !isLast {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 20)

            // Content based on item type
            Group {
                switch item.type {
                case .milestone(let milestone):
                    milestoneCard(for: milestone)
                case .appointment(let appointment):
                    appointmentCard(for: appointment)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Milestone Card

    @ViewBuilder
    private func milestoneCard(for milestone: Milestone) -> some View {
        Button {
            selectedMilestone = milestone
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(milestone.isCompleted ? Color.ollieSuccess.opacity(0.2) : Color.ollieHealth.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : milestone.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(milestone.isCompleted ? Color.ollieSuccess : Color.ollieHealth)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(milestone.localizedLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    if let detail = milestone.localizedDetail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    // Date info
                    if milestone.isCompleted, let completedDate = milestone.completedDate {
                        Text(completedDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else if let targetDate = milestone.targetDate(birthDate: birthDate) {
                        Text(targetDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Appointment Card

    @ViewBuilder
    private func appointmentCard(for appointment: DogAppointment) -> some View {
        NavigationLink {
            AppointmentDetailView(
                appointment: appointment,
                appointmentStore: appointmentStore
            )
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.ollieAccent.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: appointment.appointmentType.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.ollieAccent)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(appointment.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        if appointment.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Color.ollieSuccess)
                        }
                    }

                    Text(appointment.appointmentType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(appointment.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let milestoneStore = MilestoneStore()
    let appointmentStore = AppointmentStore()
    let birthDate = Calendar.current.date(byAdding: .weekOfYear, value: -12, to: Date())!

    NavigationStack {
        MedicalTimelineView(
            milestoneStore: milestoneStore,
            appointmentStore: appointmentStore,
            birthDate: birthDate,
            puppyName: "Luna"
        )
    }
}
