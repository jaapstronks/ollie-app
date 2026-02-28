//
//  TimelineBlockDetailView.swift
//  Ollie-app
//
//  Detail sheet shown when tapping an activity block on the visual timeline

import SwiftUI
import OllieShared

/// Detail view for an activity block
struct TimelineBlockDetailView: View {
    let block: ActivityBlock
    let events: [PuppyEvent]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with block info
                    headerSection

                    // Events in this block
                    if !containedEvents.isEmpty {
                        eventsSection
                    }
                }
                .padding()
            }
            .background(colorScheme == .dark ? Color.ollieBackgroundDark : Color.ollieBackgroundLight)
            .navigationTitle(blockTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(blockColor.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: block.type.icon)
                    .font(.title)
                    .foregroundStyle(blockColor)
            }

            // Time info
            VStack(spacing: 4) {
                Text(block.timeRangeString)
                    .font(.headline)

                if block.type.hasDuration {
                    Text(block.durationString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if block.isOngoing {
                    Text(Strings.VisualTimeline.ongoing)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(blockColor))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM)
                .fill(cardBackground)
        )
    }

    // MARK: - Events Section

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.VisualTimeline.containedEvents)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(containedEvents) { event in
                    eventRow(event)
                }
            }
        }
    }

    private func eventRow(_ event: PuppyEvent) -> some View {
        HStack(spacing: 12) {
            Image(systemName: event.type.icon)
                .font(.body)
                .foregroundStyle(eventColor(for: event))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.type.label)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let note = event.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Text(timeString(event.time))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusS)
                .fill(cardBackground)
        )
    }

    // MARK: - Helpers

    private var containedEvents: [PuppyEvent] {
        let ids = Set(block.containedEventIds)
        return events.filter { ids.contains($0.id) }
            .sorted { $0.time < $1.time }
    }

    private var blockTitle: String {
        switch block.type {
        case .sleep: return Strings.VisualTimeline.sleepBlock
        case .walk: return Strings.VisualTimeline.walkBlock
        case .potty(let outdoor): return outdoor ? Strings.VisualTimeline.pottyOutdoor : Strings.VisualTimeline.pottyIndoor
        case .meal: return Strings.VisualTimeline.mealBlock
        case .awake: return Strings.VisualTimeline.awakeBlock
        }
    }

    private var blockColor: Color {
        switch block.type {
        case .sleep: return .ollieSleep
        case .walk: return .ollieSuccess
        case .potty(let outdoor): return outdoor ? .ollieSuccess : .ollieDanger
        case .meal: return .ollieAccent
        case .awake: return .ollieMuted
        }
    }

    private func eventColor(for event: PuppyEvent) -> Color {
        switch event.type {
        case .slapen, .bench: return .ollieSleep
        case .ontwaken: return .ollieAccent
        case .uitlaten: return .ollieSuccess
        case .plassen, .poepen:
            return event.location == .buiten ? .ollieSuccess : .ollieDanger
        case .eten, .drinken: return .ollieAccent
        default: return .ollieMuted
        }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color.ollieCardDark : Color.ollieCardLight
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let now = Date()
    let sleepStart = calendar.date(byAdding: .hour, value: -3, to: now)!
    let sleepEnd = calendar.date(byAdding: .hour, value: -1, to: now)!

    let sleepEvent = PuppyEvent(
        id: UUID(),
        time: sleepStart,
        type: .slapen,
        note: "Fell asleep on the couch"
    )

    let wakeEvent = PuppyEvent(
        id: UUID(),
        time: sleepEnd,
        type: .ontwaken
    )

    let block = ActivityBlock(
        type: .sleep,
        startTime: sleepStart,
        endTime: sleepEnd,
        containedEventIds: [sleepEvent.id, wakeEvent.id]
    )

    return TimelineBlockDetailView(
        block: block,
        events: [sleepEvent, wakeEvent]
    )
}
