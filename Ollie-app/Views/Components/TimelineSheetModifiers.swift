//
//  TimelineSheetModifiers.swift
//  Ollie-app
//
//  ViewModifier that applies all shared sheet handling to timeline views
//

import SwiftUI

/// ViewModifier that applies all timeline sheet handling
struct TimelineSheetModifiers: ViewModifier {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var mediaCaptureViewModel: MediaCaptureViewModel
    @Binding var selectedPhotoEvent: PuppyEvent?
    let reduceMotion: Bool
    var spotStore: SpotStore
    var locationManager: LocationManager

    /// Direct observation of SheetCoordinator to ensure sheet state changes trigger view updates
    @ObservedObject private var sheetCoordinator: SheetCoordinator

    init(
        viewModel: TimelineViewModel,
        mediaCaptureViewModel: MediaCaptureViewModel,
        selectedPhotoEvent: Binding<PuppyEvent?>,
        reduceMotion: Bool,
        spotStore: SpotStore,
        locationManager: LocationManager
    ) {
        self.viewModel = viewModel
        self.mediaCaptureViewModel = mediaCaptureViewModel
        self._selectedPhotoEvent = selectedPhotoEvent
        self.reduceMotion = reduceMotion
        self.spotStore = spotStore
        self.locationManager = locationManager
        self.sheetCoordinator = viewModel.sheetCoordinator
    }

    func body(content: Content) -> some View {
        content
            // Single sheet presentation using item-based approach
            // Directly bind to sheetCoordinator.activeSheet since we're observing it
            .sheet(item: $sheetCoordinator.activeSheet) { sheet in
                sheetContent(for: sheet)
            }
            // Media picker uses fullScreenCover (separate from sheets)
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.sheetCoordinator.isShowingMediaPicker },
                set: { if !$0 { viewModel.dismissMediaPicker() } }
            )) {
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
            // Media preview (item-based fullScreenCover)
            .fullScreenCover(item: $selectedPhotoEvent) { event in
                MediaPreviewView(
                    event: event,
                    onDelete: {
                        viewModel.deleteEvent(event)
                        selectedPhotoEvent = nil
                    }
                )
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
                    .padding(.bottom, 100)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.showingUndoBanner)
    }

    // MARK: - Sheet Content Builder

    @ViewBuilder
    private func sheetContent(for sheet: SheetCoordinator.ActiveSheet) -> some View {
        switch sheet {
        case .potty:
            PottyQuickLogSheet(
                onSave: viewModel.logPottyEvent,
                onCancel: viewModel.cancelPottySheet
            )
            .presentationDetents([.height(580)])

        case .allEvents:
            AllEventsSheet(
                onSelect: { type in
                    // Moment events need special handling - go to LogMomentSheet
                    if type == .moment {
                        viewModel.sheetCoordinator.transitionToSheet(.logMoment)
                    } else if type == .uitlaten {
                        // Walk: check if activity in progress, otherwise show start/log choice
                        if viewModel.isWalkInProgress {
                            viewModel.sheetCoordinator.transitionToSheet(.endActivity)
                        } else {
                            viewModel.sheetCoordinator.transitionToSheet(.startActivity(.walk))
                        }
                    } else if type == .slapen {
                        // Nap: check if nap in progress, otherwise show start/log choice
                        if viewModel.isNapInProgress {
                            viewModel.sheetCoordinator.transitionToSheet(.endActivity)
                        } else {
                            viewModel.sheetCoordinator.transitionToSheet(.startActivity(.nap))
                        }
                    } else {
                        viewModel.sheetCoordinator.transitionToSheet(.quickLog(type))
                    }
                },
                onCancel: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .presentationDetents([.medium, .large])

        case .quickLog(let type):
            QuickLogSheet(
                eventType: type,
                onSave: viewModel.logFromQuickSheet,
                onCancel: viewModel.cancelQuickLogSheet,
                spotStore: type == .uitlaten ? spotStore : nil,
                locationManager: type == .uitlaten ? locationManager : nil,
                onSaveWalk: type == .uitlaten ? { time, spot, lat, lon, note in
                    viewModel.logWalkEvent(time: time, spot: spot, latitude: lat, longitude: lon, note: note)
                    viewModel.sheetCoordinator.dismissSheet()
                } : nil
            )
            .presentationDetents([type == .uitlaten ? .height(550) : (type.requiresLocation ? .height(480) : .height(380))])

        case .logEvent(let type):
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

        case .locationPicker(let type):
            LocationPickerSheet(
                eventType: type,
                onSelect: viewModel.logWithLocation,
                onCancel: viewModel.cancelLocationPicker
            )
            .presentationDetents([.height(200)])

        case .mediaPicker:
            // Handled by fullScreenCover above, this case shouldn't be reached
            EmptyView()

        case .logMoment:
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

        case .upgradePrompt:
            UpgradePromptView(
                puppyName: viewModel.puppyName,
                onPurchase: {
                    Task { await handlePurchase(viewModel: viewModel) }
                },
                onRestore: {
                    Task { await StoreKitManager.shared.restorePurchases() }
                },
                onDismiss: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .presentationDetents([.large])

        case .purchaseSuccess:
            PurchaseSuccessView(
                puppyName: viewModel.puppyName,
                onDismiss: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .presentationDetents([.medium])

        case .editEvent(let event):
            EditEventSheet(event: event) { updatedEvent in
                viewModel.updateEvent(updatedEvent)
                viewModel.sheetCoordinator.dismissSheet()
            }
            .presentationDetents([.medium, .large])

        case .endSleep(let startTime):
            EndSleepSheet(
                sleepStartTime: startTime,
                onSave: { wakeUpTime in
                    viewModel.logWakeUp(time: wakeUpTime)
                },
                onCancel: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .presentationDetents([.height(420)])

        case .startActivity(let activityType):
            StartActivitySheet(
                activityType: activityType,
                onStartNow: {
                    viewModel.startActivity(type: activityType)
                },
                onLogCompleted: {
                    // Transition to regular quickLog sheet for retrospective logging
                    let eventType: EventType = activityType == .walk ? .uitlaten : .slapen
                    viewModel.sheetCoordinator.transitionToSheet(.quickLog(eventType))
                },
                onCancel: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .presentationDetents([.height(350)])

        case .endActivity:
            if let activity = viewModel.currentActivity {
                ActivityEndSheet(
                    activity: activity,
                    onEnd: { minutesAgo, note in
                        viewModel.endActivity(minutesAgo: minutesAgo, note: note)
                    },
                    onCancel: {
                        viewModel.sheetCoordinator.dismissSheet()
                    },
                    onDiscard: {
                        viewModel.cancelActivity()
                    }
                )
                .presentationDetents([.height(480)])
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - Purchase Handling

private func handlePurchase(viewModel: TimelineViewModel) async {
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

// MARK: - View Extension

extension View {
    /// Applies all timeline sheet handling modifiers
    func timelineSheetHandling(
        viewModel: TimelineViewModel,
        mediaCaptureViewModel: MediaCaptureViewModel,
        selectedPhotoEvent: Binding<PuppyEvent?>,
        reduceMotion: Bool,
        spotStore: SpotStore,
        locationManager: LocationManager
    ) -> some View {
        modifier(TimelineSheetModifiers(
            viewModel: viewModel,
            mediaCaptureViewModel: mediaCaptureViewModel,
            selectedPhotoEvent: selectedPhotoEvent,
            reduceMotion: reduceMotion,
            spotStore: spotStore,
            locationManager: locationManager
        ))
    }
}
