//
//  BehaviorSupportComponents.swift
//  Otis-app
//
//  Supporting views for BehaviorSupportView
//

import SwiftUI
import OtisShared

// MARK: - Trend Direction

enum BehaviorTrendDirection {
    case improving, stable, worsening, new

    var icon: String {
        switch self {
        case .improving: return "arrow.down"
        case .stable: return "arrow.right"
        case .worsening: return "arrow.up"
        case .new: return "sparkles"
        }
    }

    var label: String {
        switch self {
        case .improving: return OtisShared.Strings.BehaviorSupport.trendImproving
        case .stable: return OtisShared.Strings.BehaviorSupport.trendStable
        case .worsening: return OtisShared.Strings.BehaviorSupport.trendWorsening
        case .new: return OtisShared.Strings.BehaviorSupport.trendNew
        }
    }

    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .secondary
        case .worsening: return .orange
        case .new: return .blue
        }
    }
}

// MARK: - Behavior Category Row

struct BehaviorCategoryRow: View {
    let category: BehaviorCategory
    let thisWeekCount: Int
    let lastWeekCount: Int
    let totalCount: Int
    let commonTriggers: [String]

    @Environment(\.colorScheme) private var colorScheme

    private var trend: BehaviorTrendDirection {
        if lastWeekCount == 0 && thisWeekCount > 0 {
            return .new
        } else if thisWeekCount < lastWeekCount {
            return .improving
        } else if thisWeekCount > lastWeekCount {
            return .worsening
        }
        return .stable
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.orange.badgeOpacity(colorScheme: colorScheme))
                    )

                // Title and count
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.label)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(OtisShared.Strings.BehaviorSupport.incidentsThisWeek(thisWeekCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Trend badge
                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .font(.caption2)
                    Text(trend.label)
                        .font(.caption2)
                }
                .foregroundStyle(trend.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(trend.color.opacity(0.15))
                )
            }

            // Common triggers
            if !commonTriggers.isEmpty {
                HStack(spacing: 4) {
                    Text(OtisShared.Strings.BehaviorSupport.commonTriggers + ":")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(commonTriggers.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 44)
            }
        }
        .padding()
        .glassCard(tint: .warning)
    }
}

// MARK: - Recent Incident Row

struct RecentIncidentRow: View {
    let incident: PuppyEvent

    @Environment(\.colorScheme) private var colorScheme

    private var category: BehaviorCategory? {
        incident.behaviorCategoryEnum
    }

    private var timeString: String {
        incident.time.relativeFormatted()
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            if let cat = category {
                Image(systemName: cat.icon)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color.orange.badgeOpacity(colorScheme: colorScheme))
                    )
            }

            // Details
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    if let cat = category {
                        Text(cat.label)
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    if let trigger = incident.behaviorTrigger {
                        Text("- \(trigger)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let note = incident.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Time
            Text(timeString)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Intervention Row

struct InterventionRow: View {
    let intervention: BehaviorIntervention
    var onMarkPracticed: () -> Void
    var onToggleActive: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var practiceStatus: String {
        if let days = intervention.daysSinceLastPractice {
            return OtisShared.Strings.BehaviorSupport.lastPracticed(days: days)
        }
        return OtisShared.Strings.BehaviorSupport.practicedCount(intervention.practiceCountThisWeek)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: intervention.category.icon)
                .font(.subheadline)
                .foregroundStyle(.orange)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.orange.badgeOpacity(colorScheme: colorScheme))
                )

            // Intervention details
            VStack(alignment: .leading, spacing: 2) {
                Text(intervention.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(intervention.category.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if intervention.practiceCountThisWeek > 0 || intervention.daysSinceLastPractice != nil {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(practiceStatus)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if let notes = intervention.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Mark practiced button
            Button {
                onMarkPracticed()
            } label: {
                Image(systemName: "checkmark.circle")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .glassCard(tint: .warning)
        .contextMenu {
            Button {
                onMarkPracticed()
            } label: {
                Label(OtisShared.Strings.BehaviorSupport.markPracticed, systemImage: "checkmark.circle")
            }

            Button(role: intervention.isActive ? .destructive : nil) {
                onToggleActive()
            } label: {
                Label(
                    intervention.isActive ? Strings.Common.deactivate : Strings.Common.activate,
                    systemImage: intervention.isActive ? "xmark.circle" : "checkmark.circle"
                )
            }
        }
    }
}
