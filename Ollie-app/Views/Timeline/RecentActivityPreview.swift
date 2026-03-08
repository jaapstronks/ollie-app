//
//  RecentActivityPreview.swift
//  Otis-app
//
//  Compact preview of recent activity for the Today tab
//  Shows last 5 events or events from the last 3 hours

import SwiftUI
import OtisShared

/// Compact preview of recent activity for the Today tab
struct RecentActivityPreview: View {
    let events: [PuppyEvent]
    let onViewFullTimeline: () -> Void
    var onEditEvent: ((PuppyEvent) -> Void)?
    var onDeleteEvent: ((PuppyEvent) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var userIdentityStore = UserIdentityStore.shared
    @ObservedObject private var participantResolver = ParticipantResolver.shared

    /// Filter events to show recent activity
    /// Shows events from the last 3 hours OR most recent 5, whichever is more
    private var recentEvents: [PuppyEvent] {
        let now = Date()
        let threeHoursAgo = now.addingTimeInterval(-3 * 60 * 60)

        // Get events from the last 3 hours
        let recentByTime = events.filter { $0.time >= threeHoursAgo }

        // If we have at least 1 event in the last 3 hours, use time-based filtering
        // Otherwise, just show the most recent 5
        if !recentByTime.isEmpty {
            // Cap at 5 events
            return Array(recentByTime.sorted(by: { $0.time > $1.time }).prefix(5))
        } else {
            // Show most recent 5 events regardless of time
            return Array(events.sorted(by: { $0.time > $1.time }).prefix(5))
        }
    }

    /// Represents a group of events logged by the same person
    @MainActor
    private struct EventGroup: Identifiable {
        let id = UUID()
        let events: [PuppyEvent]
        let loggedByRecordID: String?
        let isPartner: Bool  // true if logged by someone other than current user

        var partnerName: String? {
            guard isPartner, let recordID = loggedByRecordID else { return nil }
            return ParticipantResolver.shared.resolve(cloudKitRecordID: recordID).displayName
        }
    }

    /// Group consecutive events by the same logger
    private var eventGroups: [EventGroup] {
        guard !recentEvents.isEmpty else { return [] }

        var groups: [EventGroup] = []
        var currentGroupEvents: [PuppyEvent] = []
        var currentLoggedBy: String?

        for event in recentEvents {
            let eventLoggedBy = event.loggedBy

            // Check if this event belongs to the same group
            if eventLoggedBy == currentLoggedBy {
                currentGroupEvents.append(event)
            } else {
                // Save the previous group if it exists
                if !currentGroupEvents.isEmpty {
                    let isPartner = currentLoggedBy != nil &&
                        !userIdentityStore.isCurrentUser(currentLoggedBy!)
                    groups.append(EventGroup(
                        events: currentGroupEvents,
                        loggedByRecordID: currentLoggedBy,
                        isPartner: isPartner
                    ))
                }
                // Start a new group
                currentGroupEvents = [event]
                currentLoggedBy = eventLoggedBy
            }
        }

        // Don't forget the last group
        if !currentGroupEvents.isEmpty {
            let isPartner = currentLoggedBy != nil &&
                !userIdentityStore.isCurrentUser(currentLoggedBy!)
            groups.append(EventGroup(
                events: currentGroupEvents,
                loggedByRecordID: currentLoggedBy,
                isPartner: isPartner
            ))
        }

        return groups
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Text(Strings.RecentActivity.sectionTitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)

            // Content card
            VStack(spacing: 0) {
                if recentEvents.isEmpty {
                    emptyState
                } else {
                    // Event rows with grouped attribution
                    ForEach(eventGroups) { group in
                        if group.isPartner, let partnerName = group.partnerName {
                            // Partner-logged events: wrap in visual container
                            PartnerEventGroupContainer(
                                name: partnerName,
                                recordID: group.loggedByRecordID,
                                eventCount: group.events.count
                            ) {
                                ForEach(group.events) { event in
                                    RecentActivityRow(
                                        event: event,
                                        onTap: { onEditEvent?(event) },
                                        onDelete: onDeleteEvent != nil ? { onDeleteEvent?(event) } : nil
                                    )

                                    // Divider between events within the group
                                    if event.id != group.events.last?.id {
                                        Divider()
                                            .padding(.leading, 44)
                                    }
                                }
                            }

                            // Divider after partner group if not the last group
                            if group.id != eventGroups.last?.id {
                                Divider()
                            }
                        } else {
                            // Current user events: no special styling
                            ForEach(group.events) { event in
                                RecentActivityRow(
                                    event: event,
                                    onTap: { onEditEvent?(event) },
                                    onDelete: onDeleteEvent != nil ? { onDeleteEvent?(event) } : nil
                                )

                                // Divider after each event except the last overall
                                if event.id != recentEvents.last?.id {
                                    Divider()
                                        .padding(.leading, 44)
                                }
                            }
                        }
                    }
                }

                // View full timeline row
                Divider()

                Button(action: onViewFullTimeline) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.otisAccent)
                            .frame(width: 28)

                        Text(Strings.RecentActivity.viewFullTimeline)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.otisAccent)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "pawprint")
                .font(.system(size: 28))
                .foregroundStyle(.secondary.opacity(0.5))

            Text(Strings.RecentActivity.noRecentActivity)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(Strings.RecentActivity.startLogging)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Styling

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.95)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color.black.opacity(0.05)
    }
}

// MARK: - Recent Activity Row

/// Single row in the recent activity preview
private struct RecentActivityRow: View {
    let event: PuppyEvent
    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?

    @State private var offset: CGFloat = 0
    @State private var showingDeleteConfirmation = false

    @Environment(\.colorScheme) private var colorScheme

    private var iconColor: Color {
        switch event.type {
        case .plassen, .poepen:
            return event.location == .buiten ? .otisSuccess : .otisDanger
        case .eten, .drinken:
            return .otisAccent
        case .slapen, .ontwaken:
            return .otisSleep
        case .uitlaten:
            return .otisSuccess
        case .training:
            return .otisPurple
        case .sociaal:
            return .otisSuccess
        case .milestone:
            return .otisRose
        case .gewicht, .medicatie:
            return .otisHealth
        default:
            return .secondary
        }
    }

    private var eventLabel: String {
        switch event.type {
        case .plassen:
            return event.location == .buiten ? Strings.VerticalTimeline.pee : Strings.VerticalTimeline.accident
        case .poepen:
            return event.location == .buiten ? Strings.VerticalTimeline.poop : Strings.VerticalTimeline.accident
        case .eten:
            return Strings.VerticalTimeline.meal
        case .drinken:
            return Strings.VerticalTimeline.water
        case .slapen:
            return Strings.VerticalTimeline.sleep
        case .ontwaken:
            return Strings.EventType.wakeUp
        case .uitlaten:
            return Strings.VerticalTimeline.walk
        case .training:
            return event.exercise ?? Strings.VerticalTimeline.training
        case .sociaal:
            return event.who ?? Strings.VerticalTimeline.social
        case .gewicht:
            if let kg = event.weightKg {
                return String(format: "%.1f kg", kg)
            }
            return Strings.VerticalTimeline.weighed
        case .medicatie:
            return Strings.VerticalTimeline.medication
        default:
            return event.type.label
        }
    }

    var body: some View {
        Button {
            HapticFeedback.light()
            onTap?()
        } label: {
            HStack(spacing: 10) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 28, height: 28)

                    Image(systemName: event.type.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                // Time
                Text(event.time.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .leading)

                // Label
                Text(eventLabel)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                // Edit indicator chevron
                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if onTap != nil {
                Button {
                    onTap?()
                } label: {
                    Label(Strings.Common.edit, systemImage: "pencil")
                }
            }

            if onDelete != nil {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label(Strings.Common.delete, systemImage: "trash")
                }
            }
        }
        .confirmationDialog(
            Strings.Timeline.deleteConfirmTitle,
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(Strings.Common.delete, role: .destructive) {
                onDelete?()
            }
            Button(Strings.Common.cancel, role: .cancel) {}
        } message: {
            Text(Strings.Timeline.deleteConfirmMessage(event: event.type.label, time: event.time.timeString))
        }
    }
}

// MARK: - Partner Event Group Container

/// Container that visually groups events logged by a partner with a left accent bar
private struct PartnerEventGroupContainer<Content: View>: View {
    let name: String
    let recordID: String?
    let eventCount: Int
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var colorScheme

    private var accentColor: Color {
        Color.otisAccent
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? accentColor.opacity(0.08)
            : accentColor.opacity(0.04)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Attribution header inside the group
            HStack(spacing: 6) {
                UserAvatarFromRecordID(cloudKitRecordID: recordID, size: 18)

                Text(Strings.Handoff.loggedThese(name))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Event rows
            content
        }
        .background(
            HStack(spacing: 0) {
                // Left accent bar
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 3)

                // Background fill
                Rectangle()
                    .fill(backgroundColor)
            }
        )
    }
}

// MARK: - Preview

#Preview("Mixed Events") {
    // Simulate events from different users - the loggedBy field determines attribution
    let sampleEvents: [PuppyEvent] = [
        PuppyEvent(time: Date().addingTimeInterval(-30 * 60), type: .plassen, location: .buiten),
        PuppyEvent(time: Date().addingTimeInterval(-60 * 60), type: .eten),
        PuppyEvent(time: Date().addingTimeInterval(-90 * 60), type: .uitlaten)
    ]

    VStack {
        RecentActivityPreview(
            events: sampleEvents,
            onViewFullTimeline: { print("View full timeline") },
            onEditEvent: { event in print("Edit event: \(event.type.label)") },
            onDeleteEvent: { event in print("Delete event: \(event.type.label)") }
        )
        .padding()

        Spacer()
    }
    .background(Color(.systemGray6))
}

#Preview("Partner Group Container") {
    VStack(spacing: 16) {
        // Example of the new partner event group styling
        PartnerEventGroupContainer(
            name: "Sarah",
            recordID: nil,
            eventCount: 3
        ) {
            VStack(spacing: 0) {
                HStack {
                    Text("09:30")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Potty (outside)")
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Divider().padding(.leading, 44)

                HStack {
                    Text("10:15")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Training - Sit")
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Divider().padding(.leading, 44)

                HStack {
                    Text("11:00")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Walk")
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    .background(Color(.systemGray6))
}
