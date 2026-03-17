//
//  FollowUpRemindersCard.swift
//  Ollie-app
//
//  Displays condition-based follow-up reminders with scheduling actions.
//

import SwiftUI
import OtisShared

/// Card showing follow-up reminders for conditions
struct FollowUpRemindersCard: View {
    let conditions: [HealthCondition]
    let onScheduleFollowUp: (ConditionFollowUp) -> Void

    @State private var isExpanded = false

    private var followUpStatuses: [FollowUpStatus] {
        let allFollowUps = ConditionFollowUp.allFollowUps(for: conditions)
        return allFollowUps.map { followUp in
            // Find the condition to get last review date
            let condition = conditions.first { $0.type == followUp.conditionType }
            return FollowUpStatus(followUp: followUp, lastCompleted: condition?.lastReviewDate)
        }.sorted { status1, status2 in
            // Sort by urgency: overdue first, then by days until due
            if status1.isOverdue && !status2.isOverdue { return true }
            if !status1.isOverdue && status2.isOverdue { return false }
            return status1.daysUntilDue < status2.daysUntilDue
        }
    }

    private var overdueFollowUps: [FollowUpStatus] {
        followUpStatuses.filter { $0.isOverdue }
    }

    private var upcomingFollowUps: [FollowUpStatus] {
        followUpStatuses.filter { !$0.isOverdue && $0.daysUntilDue <= 30 }
    }

    var body: some View {
        if !followUpStatuses.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title2)
                            .foregroundStyle(overdueFollowUps.isEmpty ? Color.otisInfo : Color.otisDanger)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(Strings.VetVisit.FollowUps.title)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            if !overdueFollowUps.isEmpty {
                                Text("\(overdueFollowUps.count) overdue")
                                    .font(.caption)
                                    .foregroundStyle(Color.otisDanger)
                            } else if !upcomingFollowUps.isEmpty {
                                Text("\(upcomingFollowUps.count) due soon")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        // Overdue badge
                        if !overdueFollowUps.isEmpty {
                            Text("\(overdueFollowUps.count)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.otisDanger)
                                .clipShape(Capsule())
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                // Expanded content
                if isExpanded {
                    VStack(alignment: .leading, spacing: 16) {
                        // Overdue section
                        if !overdueFollowUps.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(Strings.VetVisit.FollowUps.overdueTitle)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.otisDanger)

                                ForEach(overdueFollowUps, id: \.followUp.id) { status in
                                    followUpRow(status, isOverdue: true)
                                }
                            }
                        }

                        // Upcoming section
                        if !upcomingFollowUps.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(Strings.VetVisit.FollowUps.upcomingTitle)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)

                                ForEach(upcomingFollowUps, id: \.followUp.id) { status in
                                    followUpRow(status, isOverdue: false)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Row Component

    private func followUpRow(_ status: FollowUpStatus, isOverdue: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: status.followUp.followUpType.icon)
                    .foregroundStyle(isOverdue ? Color.otisDanger : Color.otisInfo)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(formatFollowUpType(status.followUp.followUpType))
                        .font(.subheadline.weight(.medium))

                    Text(status.followUp.conditionType.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Urgency
                Text(status.urgencyDescription)
                    .font(.caption)
                    .foregroundStyle(isOverdue ? Color.otisDanger : .secondary)
            }

            // Description
            Text(status.followUp.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Last completed / Schedule button
            HStack {
                if let lastCompleted = status.lastCompleted {
                    Text(Strings.VetVisit.FollowUps.lastCompleted(date: formatDate(lastCompleted)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    Text(Strings.VetVisit.FollowUps.neverCompleted)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Button {
                    onScheduleFollowUp(status.followUp)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.plus")
                        Text(Strings.VetVisit.FollowUps.scheduleNow)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isOverdue ? .white : Color.otisAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(isOverdue ? Color.otisAccent : Color.otisAccent.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(isOverdue ? Color.otisDanger.opacity(0.08) : Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func formatFollowUpType(_ type: ConditionFollowUp.FollowUpType) -> String {
        switch type {
        case .bloodWork: return "Blood Work"
        case .imaging: return "Imaging"
        case .specialist: return "Specialist Visit"
        case .generalCheckup: return "General Checkup"
        case .monitoring: return "Monitoring"
        case .dentalExam: return "Dental Exam"
        case .eyeExam: return "Eye Exam"
        case .heartCheck: return "Heart Check"
        case .urinalysis: return "Urinalysis"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        FollowUpRemindersCard(
            conditions: [
                HealthCondition(
                    type: .diabetes,
                    diagnosedDate: Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
                    severity: .moderate,
                    lastReviewDate: Calendar.current.date(byAdding: .month, value: -4, to: Date())
                ),
                HealthCondition(
                    type: .arthritis,
                    diagnosedDate: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
                    severity: .mild,
                    lastReviewDate: Calendar.current.date(byAdding: .month, value: -7, to: Date())
                )
            ],
            onScheduleFollowUp: { _ in }
        )
        .padding()
    }
}
