//
//  MemoriesCard.swift
//  Ollie-app
//
//  "On This Day" memories card for Today view

import SwiftUI
import OllieShared

/// Compact card showing memories from 1 week / 1 month / 1 year ago
struct MemoriesCard: View {
    @ObservedObject var viewModel: MemoriesViewModel

    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if viewModel.shouldShowCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header with time frame
                header

                // Primary memory
                if let memory = viewModel.memoryItem {
                    memoryRow(event: memory.event, isHighlighted: true)
                }

                // Expanded: show additional memories
                if isExpanded && viewModel.allMemoriesForDay.count > 1 {
                    ForEach(viewModel.allMemoriesForDay.dropFirst()) { event in
                        Divider()
                            .opacity(0.5)
                        memoryRow(event: event, isHighlighted: false)
                    }
                }

                // Expand/collapse button
                if viewModel.additionalEventCount > 0 {
                    expandCollapseButton
                }
            }
            .padding()
            .glassCard(tint: .accent)
            .onAppear {
                Analytics.track(.memoriesCardViewed)
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.timeFrame.icon)
                .foregroundStyle(Color.ollieAccent)

            Text(viewModel.timeFrame.label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Spacer()
        }
    }

    // MARK: - Memory Row

    @ViewBuilder
    private func memoryRow(event: PuppyEvent, isHighlighted: Bool) -> some View {
        HStack(spacing: 12) {
            // Event type icon
            Image(systemName: event.type.icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.ollieAccent)
                .frame(width: 28, height: 28)
                .background(Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.1))
                .clipShape(Circle())

            // Event content
            VStack(alignment: .leading, spacing: 2) {
                Text(eventSummary(for: event))
                    .font(.subheadline)
                    .lineLimit(1)

                if let note = event.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(isHighlighted ? 2 : 1)
                }
            }

            Spacer()

            // Thumbnail (if photo exists)
            if event.photo != nil {
                EventThumbnailView(event: event, showErrorPlaceholder: false)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Expand/Collapse Button

    @ViewBuilder
    private var expandCollapseButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
            HapticFeedback.selection()
        } label: {
            HStack {
                Spacer()

                if isExpanded {
                    Text(Strings.Socialization.showLess)
                        .font(.caption)
                        .foregroundStyle(Color.ollieAccent)

                    Image(systemName: "chevron.up")
                        .font(.caption)
                        .foregroundStyle(Color.ollieAccent)
                } else {
                    Text(Strings.Memories.moreEvents(viewModel.additionalEventCount))
                        .font(.caption)
                        .foregroundStyle(Color.ollieAccent)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.ollieAccent)
                }

                Spacer()
            }
            .padding(.top, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    /// Generate a summary text for the event
    private func eventSummary(for event: PuppyEvent) -> String {
        switch event.type {
        case .sociaal:
            if let who = event.who, !who.isEmpty {
                return Strings.Socialization.metName(who)
            }
            return event.type.label

        case .training:
            if let exercise = event.exercise, !exercise.isEmpty {
                return "\(event.type.label): \(exercise)"
            }
            return event.type.label

        case .uitlaten:
            if let duration = event.durationMin, duration > 0 {
                return "\(event.type.label) (\(duration) min)"
            }
            if let spotName = event.spotName, !spotName.isEmpty {
                return "\(event.type.label) - \(spotName)"
            }
            return event.type.label

        case .gewicht:
            if let weight = event.weightKg, weight > 0 {
                return String(format: "%.1f kg", weight)
            }
            return event.type.label

        case .milestone, .moment:
            return event.type.label

        default:
            return event.type.label
        }
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()

    return VStack {
        MemoriesCard(viewModel: MemoriesViewModel(eventStore: eventStore))
    }
    .padding()
}
