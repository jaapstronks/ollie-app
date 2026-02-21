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

    func body(content: Content) -> some View {
        content
            .pottySheet(viewModel: viewModel)
            .quickLogSheet(viewModel: viewModel, spotStore: spotStore, locationManager: locationManager)
            .locationPickerSheet(viewModel: viewModel)
            .logEventSheet(viewModel: viewModel)
            .allEventsSheet(viewModel: viewModel)
            .mediaPicker(viewModel: viewModel, mediaCaptureViewModel: mediaCaptureViewModel)
            .logMomentSheet(viewModel: viewModel, mediaCaptureViewModel: mediaCaptureViewModel)
            .mediaPreview(selectedPhotoEvent: $selectedPhotoEvent, viewModel: viewModel)
            .upgradePromptSheet(viewModel: viewModel)
            .purchaseSuccessSheet(viewModel: viewModel)
            .deleteConfirmation(viewModel: viewModel)
            .undoBanner(viewModel: viewModel, reduceMotion: reduceMotion)
    }
}

// MARK: - Individual Sheet Modifiers

private extension View {
    func pottySheet(viewModel: TimelineViewModel) -> some View {
        sheet(isPresented: viewModel.sheetCoordinator.isShowingPotty) {
            PottyQuickLogSheet(
                onSave: viewModel.logPottyEvent,
                onCancel: viewModel.cancelPottySheet
            )
            .presentationDetents([.height(580)])
        }
    }

    func quickLogSheet(viewModel: TimelineViewModel, spotStore: SpotStore, locationManager: LocationManager) -> some View {
        sheet(isPresented: viewModel.sheetCoordinator.isShowingQuickLog) {
            if let type = viewModel.pendingEventType {
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
            }
        }
    }

    func locationPickerSheet(viewModel: TimelineViewModel) -> some View {
        sheet(isPresented: viewModel.sheetCoordinator.isShowingLocationPicker) {
            LocationPickerSheet(
                eventType: viewModel.pendingEventType ?? .plassen,
                onSelect: viewModel.logWithLocation,
                onCancel: viewModel.cancelLocationPicker
            )
            .presentationDetents([.height(200)])
        }
    }

    func logEventSheet(viewModel: TimelineViewModel) -> some View {
        sheet(isPresented: viewModel.sheetCoordinator.isShowingLogSheet) {
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
    }

    func allEventsSheet(viewModel: TimelineViewModel) -> some View {
        sheet(isPresented: viewModel.sheetCoordinator.isShowingAllEvents) {
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
    }

    func mediaPicker(viewModel: TimelineViewModel, mediaCaptureViewModel: MediaCaptureViewModel) -> some View {
        fullScreenCover(isPresented: viewModel.sheetCoordinator.isShowingMediaPicker) {
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
    }

    func logMomentSheet(viewModel: TimelineViewModel, mediaCaptureViewModel: MediaCaptureViewModel) -> some View {
        sheet(isPresented: viewModel.sheetCoordinator.isShowingLogMoment) {
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
    }

    func mediaPreview(selectedPhotoEvent: Binding<PuppyEvent?>, viewModel: TimelineViewModel) -> some View {
        fullScreenCover(item: selectedPhotoEvent) { event in
            MediaPreviewView(
                event: event,
                onDelete: {
                    viewModel.deleteEvent(event)
                    selectedPhotoEvent.wrappedValue = nil
                }
            )
        }
    }

    func upgradePromptSheet(viewModel: TimelineViewModel) -> some View {
        sheet(isPresented: viewModel.sheetCoordinator.isShowingUpgradePrompt) {
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
        }
    }

    func purchaseSuccessSheet(viewModel: TimelineViewModel) -> some View {
        sheet(isPresented: viewModel.sheetCoordinator.isShowingPurchaseSuccess) {
            PurchaseSuccessView(
                puppyName: viewModel.puppyName,
                onDismiss: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .presentationDetents([.medium])
        }
    }

    func deleteConfirmation(viewModel: TimelineViewModel) -> some View {
        confirmationDialog(
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
    }

    func undoBanner(viewModel: TimelineViewModel, reduceMotion: Bool) -> some View {
        overlay(alignment: .bottom) {
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
