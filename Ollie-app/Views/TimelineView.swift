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

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            Button("Ongedaan maken") {
                onUndo()
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(Color.ollieAccent)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(colorScheme == .dark ? 0.1 : 0.08))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(glassOverlay)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.12), radius: 12, y: 6)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            if colorScheme == .dark {
                Color.white.opacity(0.1)
            } else {
                Color.white.opacity(0.85)
            }

            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.2 : 0.5),
                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }
}

// MARK: - Subviews

struct DateHeader: View {
    let title: String
    let canGoForward: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            // Previous day button
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(glassButtonBackground)
                    .clipShape(Circle())
                    .overlay(glassButtonOverlay)
            }
            .buttonStyle(GlassNavButtonStyle())

            Spacer()

            // Date title - tappable to go to today
            Button(action: onToday) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.plain)

            Spacer()

            // Next day button
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(glassButtonBackground)
                    .clipShape(Circle())
                    .overlay(glassButtonOverlay)
            }
            .buttonStyle(GlassNavButtonStyle())
            .opacity(canGoForward ? 1 : 0.3)
            .disabled(!canGoForward)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var glassButtonBackground: some View {
        ZStack {
            if colorScheme == .dark {
                Color.white.opacity(0.08)
            } else {
                Color.white.opacity(0.6)
            }
        }
        .background(.thinMaterial)
    }

    @ViewBuilder
    private var glassButtonOverlay: some View {
        Circle()
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                        Color.white.opacity(colorScheme == .dark ? 0.03 : 0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }
}

/// Interactive button style for navigation buttons
struct GlassNavButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
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
