//
//  TodayView.swift
//  Ollie-app
//
//  The "Vandaag" (Today) tab - the daily hub showing everything needed right now
//  Combines the web app's "home" and "dag" views into a single scrollable view

import SwiftUI
import TipKit

/// Main "Today" tab showing the daily hub
struct TodayView: View {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var weatherService: WeatherService
    let onSettingsTap: () -> Void

    @State private var dragOffset: CGFloat = 0
    @StateObject private var mediaCaptureViewModel = MediaCaptureViewModel(mediaStore: MediaStore())
    @State private var selectedPhotoEvent: PuppyEvent?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // Nav bar with date and settings gear
            todayNavBar

            // Trial banner (show during last 7 days of free period)
            if viewModel.shouldShowTrialBanner {
                TrialBanner(
                    daysRemaining: viewModel.freeDaysRemaining,
                    onTap: { viewModel.sheetCoordinator.presentSheet(.upgradePrompt) }
                )
            }

            ScrollView {
                VStack(spacing: 16) {
                    // Weather section (only show for today)
                    if Calendar.current.isDateInToday(viewModel.currentDate) {
                        WeatherSection(
                            forecasts: weatherService.upcomingForecasts(hours: 6),
                            alert: weatherService.smartAlert(predictedPottyTime: viewModel.predictedNextPlasTime),
                            isLoading: weatherService.isLoading
                        )
                        .padding(.vertical, 8)
                    }

                    // Status cards section (only for today)
                    if viewModel.isShowingToday {
                        statusCardsSection
                    }

                    // Daily digest
                    DigestCard(
                        digest: viewModel.dailyDigest,
                        puppyName: viewModel.puppyName
                    )

                    // Streak card
                    StreakCard(streakInfo: viewModel.streakInfo)

                    // Timeline section
                    timelineSection
                }
                .padding(.horizontal)
                .padding(.bottom, 100) // Space for FAB
            }
            .refreshable {
                viewModel.loadEvents()
            }
        }
        // Swipe gestures for day navigation
        .gesture(dayNavigationGesture)
        // All sheets from TimelineView
        .sheet(isPresented: viewModel.sheetCoordinator.isShowingPotty) {
            PottyQuickLogSheet(
                onSave: viewModel.logPottyEvent,
                onCancel: viewModel.cancelPottySheet
            )
            .presentationDetents([.height(580)])
        }
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
        .fullScreenCover(item: $selectedPhotoEvent) { event in
            MediaPreviewView(
                event: event,
                onDelete: {
                    viewModel.deleteEvent(event)
                    selectedPhotoEvent = nil
                }
            )
        }
        .sheet(isPresented: viewModel.sheetCoordinator.isShowingUpgradePrompt) {
            UpgradePromptView(
                puppyName: viewModel.puppyName,
                onPurchase: {
                    Task { await handlePurchase() }
                },
                onRestore: {
                    Task { await StoreKitManager.shared.restorePurchases() }
                },
                onDismiss: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: viewModel.sheetCoordinator.isShowingPurchaseSuccess) {
            PurchaseSuccessView(
                puppyName: viewModel.puppyName,
                onDismiss: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .presentationDetents([.medium])
        }
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
        .overlay(alignment: .bottom) {
            if viewModel.showingUndoBanner {
                UndoBanner(
                    message: Strings.Timeline.eventDeleted,
                    onUndo: viewModel.undoDelete,
                    onDismiss: viewModel.dismissUndoBanner
                )
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 100)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.showingUndoBanner)
        .task {
            await weatherService.fetchForecasts()
        }
    }

    // MARK: - Nav Bar

    @ViewBuilder
    private var todayNavBar: some View {
        HStack {
            // Previous day button
            Button {
                HapticFeedback.selection()
                viewModel.goToPreviousDay()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(Strings.Timeline.previousDay)

            Spacer()

            // Date title (tappable to go to today)
            Button {
                viewModel.goToToday()
            } label: {
                Text(viewModel.dateTitle)
                    .font(.headline)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Strings.Timeline.dateLabel(date: viewModel.dateTitle))
            .accessibilityHint(Strings.Timeline.goToTodayHint)
            .accessibilityAddTraits(.isHeader)

            Spacer()

            // Settings gear (when showing today) or next day button
            if viewModel.isShowingToday {
                Button {
                    onSettingsTap()
                } label: {
                    Image(systemName: "gear")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Strings.Tabs.settings)
                .accessibilityIdentifier("settings_button")
            } else {
                Button {
                    HapticFeedback.selection()
                    viewModel.goToNextDay()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .opacity(viewModel.canGoForward ? 1 : 0.3)
                .disabled(!viewModel.canGoForward)
                .accessibilityLabel(Strings.Timeline.nextDay)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Status Cards Section

    @ViewBuilder
    private var statusCardsSection: some View {
        VStack(spacing: 12) {
            // Potty status hero card
            PottyStatusCard(
                prediction: viewModel.pottyPrediction,
                puppyName: viewModel.puppyName
            )

            // Poop slot tracker
            PoopStatusCard(status: viewModel.poopSlotStatus)

            // Sleep status card
            SleepStatusCard(sleepState: viewModel.currentSleepState)

            // Upcoming events (meals & walks)
            UpcomingEventsCard(
                items: viewModel.upcomingItems(forecasts: weatherService.forecasts),
                isToday: viewModel.isShowingToday,
                onLogEvent: { eventType in
                    viewModel.quickLog(type: eventType)
                }
            )
        }
    }

    // MARK: - Timeline Section

    @ViewBuilder
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Text("Timeline")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            if viewModel.events.isEmpty {
                EmptyTimelineCard()
            } else {
                // Event cards in timeline
                ForEach(viewModel.events) { event in
                    EventRow(event: event)
                        .onTapGesture {
                            if event.photo != nil {
                                selectedPhotoEvent = event
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticFeedback.warning()
                                viewModel.deleteEvent(event)
                            } label: {
                                Label(Strings.Common.delete, systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    // MARK: - Gestures

    private var dayNavigationGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let threshold: CGFloat = 50
                if value.translation.width > threshold {
                    HapticFeedback.selection()
                    if reduceMotion {
                        viewModel.goToPreviousDay()
                    } else {
                        withAnimation {
                            viewModel.goToPreviousDay()
                        }
                    }
                } else if value.translation.width < -threshold && viewModel.canGoForward {
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
    }

    // MARK: - Purchase Handling

    private func handlePurchase() async {
        guard let profileID = viewModel.profileStore.profile?.id else { return }

        do {
            try await StoreKitManager.shared.purchase(for: profileID)
            viewModel.profileStore.unlockPremium()
            viewModel.sheetCoordinator.presentSheet(.purchaseSuccess)
            HapticFeedback.success()
        } catch StoreKitError.userCancelled {
            // User cancelled, do nothing
        } catch {
            HapticFeedback.error()
        }
    }
}

// MARK: - Empty Timeline Card

struct EmptyTimelineCard: View {
    private let quickLogBarTip = QuickLogBarTip()

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text(Strings.Timeline.noEvents)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(Strings.Timeline.tapToLog)
                .font(.subheadline)
                .foregroundColor(.secondary)

            TipView(quickLogBarTip)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    let weatherService = WeatherService()

    return TodayView(
        viewModel: viewModel,
        weatherService: weatherService,
        onSettingsTap: { print("Settings tapped") }
    )
}
