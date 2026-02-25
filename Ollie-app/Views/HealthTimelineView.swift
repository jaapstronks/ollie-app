//
//  HealthTimelineView.swift
//  Ollie-app
//
//  Vertical timeline of health milestones (vaccinations, deworming, vet visits)

import SwiftUI
import OllieShared

/// Vertical timeline showing health milestones with status indicators
struct HealthTimelineView: View {
    let milestones: [HealthMilestone]
    let onToggle: (HealthMilestone) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(milestones.enumerated()), id: \.element.id) { index, milestone in
                HStack(alignment: .top, spacing: 16) {
                    // Timeline indicator
                    VStack(spacing: 0) {
                        // Status indicator
                        statusIndicator(for: milestone)

                        // Connecting line (except for last item)
                        if index < milestones.count - 1 {
                            Rectangle()
                                .fill(lineColor(for: milestone))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 28)

                    // Content
                    milestoneRow(milestone)
                        .padding(.bottom, index < milestones.count - 1 ? 16 : 0)
                }
            }
        }
    }

    @ViewBuilder
    private func statusIndicator(for milestone: HealthMilestone) -> some View {
        ZStack {
            Circle()
                .fill(backgroundColor(for: milestone))
                .frame(width: 28, height: 28)

            switch milestone.status {
            case .done:
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            case .nextUp:
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            case .future:
                Circle()
                    .strokeBorder(Color.secondary.opacity(0.5), lineWidth: 2)
                    .frame(width: 12, height: 12)
            case .overdue:
                Image(systemName: "exclamationmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    @ViewBuilder
    private func milestoneRow(_ milestone: HealthMilestone) -> some View {
        Button {
            onToggle(milestone)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                // Label
                Text(milestone.label)
                    .font(.subheadline)
                    .fontWeight(milestone.status == .nextUp ? .semibold : .regular)
                    .foregroundStyle(textColor(for: milestone))
                    .multilineTextAlignment(.leading)

                // Period and date
                HStack(spacing: 8) {
                    if let period = milestone.period {
                        Text(period)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(formattedDate(milestone.date))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                // Status badge for special states
                if milestone.status == .nextUp || milestone.status == .overdue {
                    HStack(spacing: 4) {
                        Image(systemName: statusIcon(for: milestone.status))
                            .font(.system(size: 10, weight: .semibold))
                        Text(statusLabel(for: milestone.status))
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(statusColor(for: milestone.status))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: milestone.status).opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .clipShape(Capsule())
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(rowBackground(for: milestone))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Styling

    private func backgroundColor(for milestone: HealthMilestone) -> Color {
        switch milestone.status {
        case .done: return .ollieSuccess
        case .nextUp: return .ollieAccent
        case .future: return .clear
        case .overdue: return .ollieWarning
        }
    }

    private func lineColor(for milestone: HealthMilestone) -> Color {
        switch milestone.status {
        case .done: return .ollieSuccess.opacity(0.3)
        case .nextUp, .future, .overdue: return .secondary.opacity(0.2)
        }
    }

    private func textColor(for milestone: HealthMilestone) -> Color {
        switch milestone.status {
        case .done: return .primary.opacity(0.6)
        case .nextUp: return .primary
        case .future: return .secondary
        case .overdue: return .ollieWarning
        }
    }

    private func rowBackground(for milestone: HealthMilestone) -> Color {
        switch milestone.status {
        case .nextUp:
            return colorScheme == .dark ? Color.ollieAccent.opacity(0.1) : Color.ollieAccent.opacity(0.05)
        case .overdue:
            return colorScheme == .dark ? Color.ollieWarning.opacity(0.1) : Color.ollieWarning.opacity(0.05)
        default:
            return .clear
        }
    }

    private func statusIcon(for status: HealthMilestone.MilestoneStatus) -> String {
        switch status {
        case .nextUp: return "arrow.right.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        default: return ""
        }
    }

    private func statusLabel(for status: HealthMilestone.MilestoneStatus) -> String {
        switch status {
        case .done: return Strings.Health.done
        case .nextUp: return Strings.Health.nextUp
        case .future: return Strings.Health.future
        case .overdue: return Strings.Health.overdue
        }
    }

    private func statusColor(for status: HealthMilestone.MilestoneStatus) -> Color {
        switch status {
        case .done: return .ollieSuccess
        case .nextUp: return .ollieAccent
        case .future: return .secondary
        case .overdue: return .ollieWarning
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    let birthDate = Calendar.current.date(byAdding: .weekOfYear, value: -9, to: Date())!
    let milestones = DefaultMilestones.create(birthDate: birthDate)

    return ScrollView {
        HealthTimelineView(milestones: milestones) { milestone in
            print("Toggled: \(milestone.label)")
        }
        .padding()
    }
}
