//
//  TimelineView.swift
//  Ollie-app
//

import SwiftUI

/// Main timeline view showing today's events
struct TimelineView: View {
    @ObservedObject var viewModel: TimelineViewModel
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Date navigation header
            DateHeader(
                title: viewModel.dateTitle,
                canGoForward: viewModel.canGoForward,
                onPrevious: {
                    HapticFeedback.selection()
                    viewModel.goToPreviousDay()
                },
                onNext: {
                    HapticFeedback.selection()
                    viewModel.goToNextDay()
                },
                onToday: viewModel.goToToday
            )

            // Daily digest summary
            DigestCard(
                digest: viewModel.dailyDigest,
                puppyName: viewModel.puppyName
            )

            // V3: Potty status hero card with smart predictions
            PottyStatusCard(
                prediction: viewModel.pottyPrediction,
                puppyName: viewModel.puppyName
            )

            // Sleep status card
            SleepStatusCard(sleepState: viewModel.currentSleepState)

            // Streak card (outdoor potty streak)
            StreakCard(streakInfo: viewModel.streakInfo)

            // Event list with pull-to-refresh
            if viewModel.events.isEmpty {
                ScrollView {
                    EmptyTimelineView()
                }
                .refreshable {
                    viewModel.loadEvents()
                }
            } else {
                EventList(
                    events: viewModel.events,
                    onDelete: viewModel.deleteEvent,
                    onRefresh: viewModel.loadEvents
                )
            }

            Spacer()

            // Quick log bar (V2: with "+" button)
            QuickLogBar(
                onQuickLog: viewModel.quickLog,
                onShowAllEvents: viewModel.showAllEvents
            )
        }
        // Swipe gestures for day navigation
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width > threshold {
                        // Swipe right -> previous day
                        HapticFeedback.selection()
                        withAnimation {
                            viewModel.goToPreviousDay()
                        }
                    } else if value.translation.width < -threshold && viewModel.canGoForward {
                        // Swipe left -> next day
                        HapticFeedback.selection()
                        withAnimation {
                            viewModel.goToNextDay()
                        }
                    }
                    dragOffset = 0
                }
        )
        // V2: QuickLogSheet with time adjustment for all events
        .sheet(isPresented: $viewModel.showingQuickLogSheet) {
            if let type = viewModel.pendingEventType {
                QuickLogSheet(
                    eventType: type,
                    onSave: viewModel.logFromQuickSheet,
                    onCancel: viewModel.cancelQuickLogSheet
                )
                .presentationDetents([type.requiresLocation ? .height(480) : .height(380)])
            }
        }
        // Legacy: kept for backwards compatibility
        .sheet(isPresented: $viewModel.showingLocationPicker) {
            LocationPickerSheet(
                eventType: viewModel.pendingPottyType ?? .plassen,
                onSelect: viewModel.logWithLocation,
                onCancel: viewModel.cancelLocationPicker
            )
            .presentationDetents([.height(200)])
        }
        .sheet(isPresented: $viewModel.showingLogSheet) {
            if let type = viewModel.selectedEventType {
                LogEventSheet(eventType: type) { note, who, exercise, result, durationMin in
                    viewModel.logEvent(
                        type: type,
                        note: note,
                        who: who,
                        exercise: exercise,
                        result: result,
                        durationMin: durationMin
                    )
                    viewModel.showingLogSheet = false
                }
            }
        }
        // V2: All events sheet
        .sheet(isPresented: $viewModel.showingAllEventsSheet) {
            AllEventsSheet(
                onSelect: { type in
                    viewModel.showingAllEventsSheet = false
                    // Small delay to let sheet dismiss before showing new one
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.quickLog(type: type)
                    }
                },
                onCancel: {
                    viewModel.showingAllEventsSheet = false
                }
            )
            .presentationDetents([.medium, .large])
        }
        // Delete confirmation dialog
        .confirmationDialog(
            "Verwijderen?",
            isPresented: $viewModel.showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Verwijder", role: .destructive) {
                viewModel.confirmDeleteEvent()
            }
            Button("Annuleren", role: .cancel) {
                viewModel.cancelDeleteEvent()
            }
        } message: {
            if let event = viewModel.eventToDelete {
                Text("Weet je zeker dat je '\(event.type.label)' van \(event.time.timeString) wilt verwijderen?")
            }
        }
        // Undo banner overlay
        .overlay(alignment: .bottom) {
            if viewModel.showingUndoBanner {
                UndoBanner(
                    message: "Event verwijderd",
                    onUndo: viewModel.undoDelete,
                    onDismiss: viewModel.dismissUndoBanner
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 100) // Above quick log bar
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.showingUndoBanner)
    }
}

// MARK: - Undo Banner

struct UndoBanner: View {
    let message: String
    let onUndo: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Text(message)
                .foregroundColor(.white)

            Spacer()

            Button("Ongedaan maken") {
                onUndo()
            }
            .fontWeight(.semibold)
            .foregroundColor(.yellow)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Color.black.opacity(0.85))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Subviews

struct DateHeader: View {
    let title: String
    let canGoForward: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }

            Spacer()

            Button(action: onToday) {
                Text(title)
                    .font(.headline)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title2)
            }
            .opacity(canGoForward ? 1 : 0.3)
            .disabled(!canGoForward)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct StatsBar: View {
    let timeSinceLastPlas: String

    var body: some View {
        HStack {
            Label(timeSinceLastPlas, systemImage: "clock")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }
}

struct EventList: View {
    let events: [PuppyEvent]
    let onDelete: (PuppyEvent) -> Void
    let onRefresh: () -> Void

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(events) { event in
                    EventRow(event: event)
                        .id(event.id)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        HapticFeedback.warning()
                        onDelete(events[index])
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                onRefresh()
            }
            .onChange(of: events.count) { _, _ in
                // Scroll to latest event
                if let lastEvent = events.last {
                    withAnimation {
                        proxy.scrollTo(lastEvent.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct EmptyTimelineView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "pawprint")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Nog geen gebeurtenissen")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Tik hieronder om de eerste te loggen")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    return TimelineView(viewModel: viewModel)
}
