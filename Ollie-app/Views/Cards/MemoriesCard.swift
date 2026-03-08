//
//  MemoriesCard.swift
//  Otis-app
//
//  "On This Day" memories card for Today view

import SwiftUI
import OtisShared

/// Photo-forward card showing memories from 1 week / 1 month / 1 year ago
struct MemoriesCard: View {
    @ObservedObject var viewModel: MemoriesViewModel

    /// Callback when a memory event is tapped - navigates to that date
    var onMemoryTap: ((PuppyEvent) -> Void)?

    /// Key for storing dismissal state per day
    @AppStorage("memoriesCardDismissedDate") private var dismissedDateString: String = ""

    @State private var selectedEvent: PuppyEvent?
    @State private var isVisible: Bool = true
    @Environment(\.colorScheme) private var colorScheme

    /// Whether the card was dismissed today
    private var isDismissedToday: Bool {
        guard !dismissedDateString.isEmpty else { return false }
        let today = Calendar.current.startOfDay(for: Date())
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let dismissedDate = formatter.date(from: dismissedDateString) else { return false }
        return Calendar.current.isDate(dismissedDate, inSameDayAs: today)
    }

    /// Whether the primary memory has a photo
    private var hasPhoto: Bool {
        viewModel.memoryItem?.event.photo != nil
    }

    var body: some View {
        if viewModel.shouldShowCard && !isDismissedToday && isVisible {
            Group {
                if hasPhoto {
                    photoForwardLayout
                } else {
                    compactLayout
                }
            }
            .transition(.asymmetric(
                insertion: .opacity,
                removal: .opacity.combined(with: .scale(scale: 0.95))
            ))
            .fullScreenCover(item: $selectedEvent) { event in
                MediaPreviewView(
                    event: event,
                    onDelete: {
                        // Don't allow deletion from memory card
                        selectedEvent = nil
                    }
                )
            }
            .onAppear {
                Analytics.track(.memoriesCardViewed)
            }
        }
    }

    // MARK: - Photo-Forward Layout

    @ViewBuilder
    private var photoForwardLayout: some View {
        if let memory = viewModel.memoryItem {
            VStack(alignment: .leading, spacing: 0) {
                // Photo with overlay
                ZStack(alignment: .topLeading) {
                    // Photo
                    EventThumbnailView(event: memory.event, showErrorPlaceholder: false)
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .clipped()

                    // Gradient overlay for text readability
                    LinearGradient(
                        colors: [.black.opacity(0.5), .clear, .clear, .black.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Top bar with time label and dismiss
                    HStack {
                        // Time frame badge
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption2)
                            Text(viewModel.timeFrame.label)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial.opacity(0.8))
                        .clipShape(Capsule())

                        Spacer()

                        // Dismiss button
                        Button {
                            dismissCard()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(.ultraThinMaterial.opacity(0.8))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticFeedback.selection()
                    selectedEvent = memory.event
                }

                // Caption bar
                HStack(spacing: 8) {
                    // Event type icon
                    Image(systemName: memory.event.type.icon)
                        .font(.caption)
                        .foregroundStyle(Color.otisAccent)

                    // Caption text
                    VStack(alignment: .leading, spacing: 1) {
                        Text(eventSummary(for: memory.event))
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        if let note = memory.event.note, !note.isEmpty {
                            Text(note)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // More indicator if there are additional events
                    if viewModel.additionalEventCount > 0 {
                        Text(Strings.Memories.moreEvents(viewModel.additionalEventCount))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground).opacity(0.6))
            }
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - Compact Layout (no photo)

    @ViewBuilder
    private var compactLayout: some View {
        if let memory = viewModel.memoryItem {
            HStack(spacing: 12) {
                // Event icon
                Image(systemName: memory.event.type.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.otisAccent)
                    .frame(width: 36, height: 36)
                    .background(Color.otisAccent.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .clipShape(Circle())

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(viewModel.timeFrame.label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }

                    Text(eventSummary(for: memory.event))
                        .font(.subheadline)
                        .lineLimit(1)

                    if let note = memory.event.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Dismiss button
                Button {
                    dismissCard()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                HapticFeedback.selection()
                onMemoryTap?(memory.event)
            }
        }
    }

    // MARK: - Actions

    private func dismissCard() {
        HapticFeedback.light()

        // Animate out first
        withAnimation(.easeOut(duration: 0.2)) {
            isVisible = false
        }

        // Then persist to storage (so it stays hidden on scroll/rerender)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            dismissedDateString = formatter.string(from: Date())
        }
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
