//
//  TimelineView.swift
//  Ollie-app
//

import SwiftUI
import TipKit

/// Main timeline view showing today's events
struct TimelineView: View {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var weatherService: WeatherService
    @State private var dragOffset: CGFloat = 0
    @StateObject private var mediaCaptureViewModel = MediaCaptureViewModel(mediaStore: MediaStore())
    @State private var selectedPhotoEvent: PuppyEvent?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

            // Trial banner (show during last 7 days of free period)
            if viewModel.shouldShowTrialBanner {
                TrialBanner(
                    daysRemaining: viewModel.freeDaysRemaining,
                    onTap: { viewModel.sheetCoordinator.presentSheet(.upgradePrompt) }
                )
            }

            // Weather section (only show for today)
            if Calendar.current.isDateInToday(viewModel.currentDate) {
                WeatherSection(
                    forecasts: weatherService.upcomingForecasts(hours: 6),
                    alert: weatherService.smartAlert(predictedPottyTime: viewModel.predictedNextPlasTime),
                    isLoading: weatherService.isLoading
                )
                .padding(.vertical, 8)
            }

            // Daily digest summary
            DigestCard(
                digest: viewModel.dailyDigest,
                puppyName: viewModel.puppyName
            )

            // Upcoming events (meals & walks) - only for today
            UpcomingEventsCard(
                items: viewModel.upcomingItems(forecasts: weatherService.forecasts),
                isToday: viewModel.isShowingToday,
                onLogEvent: { eventType in
                    viewModel.quickLog(type: eventType)
                }
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
                    onRefresh: viewModel.loadEvents,
                    onTapPhoto: { event in
                        selectedPhotoEvent = event
                    }
                )
            }

            Spacer()

            // Quick log bar (V3: smart contextual icons)
            QuickLogBar(
                context: viewModel.quickLogContext,
                canLogEvents: viewModel.canLogEvents,
                onPottyTap: viewModel.showPottySheet,
                onQuickLog: viewModel.quickLog,
                onShowAllEvents: viewModel.showAllEvents,
                onCameraTap: viewModel.openCamera
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
                        if reduceMotion {
                            viewModel.goToPreviousDay()
                        } else {
                            withAnimation {
                                viewModel.goToPreviousDay()
                            }
                        }
                    } else if value.translation.width < -threshold && viewModel.canGoForward {
                        // Swipe left -> next day
                        HapticFeedback.selection()
                        if reduceMotion {
                            viewModel.goToNextDay()
                        } else {
                            withAnimation {
                                viewModel.goToNextDay()
                            }
                        }
                    }
                    dragOffset = 0
                }
        )
        // V3: PottyQuickLogSheet for combined plassen/poepen
        .sheet(isPresented: viewModel.sheetCoordinator.isShowingPotty) {
            PottyQuickLogSheet(
                onSave: viewModel.logPottyEvent,
                onCancel: viewModel.cancelPottySheet
            )
            .presentationDetents([.height(580)])
        }
        // V2: QuickLogSheet with time adjustment for all events
        .sheet(isPresented: viewModel.sheetCoordinator.isShowingQuickLog) {
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
        .sheet(isPresented: viewModel.sheetCoordinator.isShowingLocationPicker) {
            LocationPickerSheet(
                eventType: viewModel.pendingEventType ?? .plassen,
                onSelect: viewModel.logWithLocation,
                onCancel: viewModel.cancelLocationPicker
            )
            .presentationDetents([.height(200)])
        }
        .sheet(isPresented: viewModel.sheetCoordinator.isShowingLogSheet) {
            if let type = viewModel.pendingEventType {
                LogEventSheet(eventType: type) { note, who, exercise, result, durationMin in
                    viewModel.logEvent(
                        type: type,
                        note: note,
                        who: who,
                        exercise: exercise,
                        result: result,
                        durationMin: durationMin
                    )
                    viewModel.sheetCoordinator.dismissSheet()
                }
            }
        }
        // V2: All events sheet - uses transitionToSheet for clean flow
        .sheet(isPresented: viewModel.sheetCoordinator.isShowingAllEvents) {
            AllEventsSheet(
                onSelect: { type in
                    viewModel.sheetCoordinator.transitionToSheet(.quickLog(type))
                },
                onCancel: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .presentationDetents([.medium, .large])
        }
        // Media picker for photo moments
        .fullScreenCover(isPresented: viewModel.sheetCoordinator.isShowingMediaPicker) {
            MediaPicker(
                source: viewModel.mediaPickerSource,
                onImageSelected: { image, data in
                    mediaCaptureViewModel.processImage(image, originalData: data)
                    viewModel.dismissMediaPicker()
                    viewModel.showLogMomentSheet()
                },
                onCancel: {
                    viewModel.dismissMediaPicker()
                }
            )
        }
        // Log moment sheet
        .sheet(isPresented: viewModel.sheetCoordinator.isShowingLogMoment) {
            LogMomentSheet(
                viewModel: mediaCaptureViewModel,
                onSave: { event in
                    viewModel.addEvent(event)
                    viewModel.dismissLogMomentSheet()
                    mediaCaptureViewModel.reset()
                    HapticFeedback.success()
                },
                onCancel: {
                    viewModel.dismissLogMomentSheet()
                    mediaCaptureViewModel.reset()
                }
            )
        }
        // Photo preview for tapped events
        .fullScreenCover(item: $selectedPhotoEvent) { event in
            MediaPreviewView(
                event: event,
                onDelete: {
                    viewModel.deleteEvent(event)
                    selectedPhotoEvent = nil
                }
            )
        }
        // Upgrade prompt sheet
        .sheet(isPresented: viewModel.sheetCoordinator.isShowingUpgradePrompt) {
            UpgradePromptView(
                puppyName: viewModel.puppyName,
                onPurchase: {
                    Task {
                        await handlePurchase()
                    }
                },
                onRestore: {
                    Task {
                        await StoreKitManager.shared.restorePurchases()
                    }
                },
                onDismiss: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .presentationDetents([.large])
        }
        // Purchase success sheet
        .sheet(isPresented: viewModel.sheetCoordinator.isShowingPurchaseSuccess) {
            PurchaseSuccessView(
                puppyName: viewModel.puppyName,
                onDismiss: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .presentationDetents([.medium])
        }
        // Delete confirmation dialog
        .confirmationDialog(
            Strings.Timeline.deleteConfirmTitle,
            isPresented: viewModel.showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(Strings.Common.delete, role: .destructive) {
                viewModel.confirmDeleteEvent()
            }
            Button(Strings.Common.cancel, role: .cancel) {
                viewModel.cancelDeleteEvent()
            }
        } message: {
            if let event = viewModel.eventToDelete {
                Text(Strings.Timeline.deleteConfirmMessage(event: event.type.label, time: event.time.timeString))
            }
        }
        // Undo banner overlay
        .overlay(alignment: .bottom) {
            if viewModel.showingUndoBanner {
                UndoBanner(
                    message: Strings.Timeline.eventDeleted,
                    onUndo: viewModel.undoDelete,
                    onDismiss: viewModel.dismissUndoBanner
                )
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 100) // Above quick log bar
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.showingUndoBanner)
        .task {
            // Fetch weather on appear
            await weatherService.fetchForecasts()
        }
    }

    // MARK: - Purchase Handling

    private func handlePurchase() async {
        guard let profileID = viewModel.profileStore.profile?.id else { return }

        do {
            try await StoreKitManager.shared.purchase(for: profileID)
            // Update profile to reflect premium status
            viewModel.profileStore.unlockPremium()
            viewModel.sheetCoordinator.presentSheet(.purchaseSuccess)
            HapticFeedback.success()
        } catch StoreKitError.userCancelled {
            // User cancelled, do nothing
        } catch {
            // Show error (StoreKitManager already sets purchaseError)
            HapticFeedback.error()
        }
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

            Button(Strings.Common.undo) {
                onUndo()
            }
            .fontWeight(.semibold)
            .foregroundColor(.yellow)
            .frame(minWidth: 44, minHeight: 44)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding()
        .background(Color.black.opacity(0.85))
        .cornerRadius(12)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Timeline.eventDeleted)
        .accessibilityHint(Strings.Timeline.undoAccessibility)
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
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(Strings.Timeline.previousDay)

            Spacer()

            Button(action: onToday) {
                Text(title)
                    .font(.headline)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Strings.Timeline.dateLabel(date: title))
            .accessibilityHint(Strings.Timeline.goToTodayHint)
            .accessibilityAddTraits(.isHeader)

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .opacity(canGoForward ? 1 : 0.3)
            .disabled(!canGoForward)
            .accessibilityLabel(Strings.Timeline.nextDay)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct EventList: View {
    let events: [PuppyEvent]
    let onDelete: (PuppyEvent) -> Void
    let onRefresh: () -> Void
    let onTapPhoto: (PuppyEvent) -> Void

    private let swipeToDeleteTip = SwipeToDeleteTip()

    var body: some View {
        ScrollViewReader { proxy in
            List {
                // Tip for swipe-to-delete (shown once at top of list)
                TipView(swipeToDeleteTip)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                ForEach(events) { event in
                    EventRow(event: event)
                        .id(event.id)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            if event.photo != nil {
                                onTapPhoto(event)
                            }
                        }
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
    private let quickLogBarTip = QuickLogBarTip()

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "pawprint")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text(Strings.Timeline.noEvents)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(Strings.Timeline.tapToLog)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Tip for using the quick log bar
            TipView(quickLogBarTip)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    let weatherService = WeatherService()
    return TimelineView(viewModel: viewModel, weatherService: weatherService)
}
