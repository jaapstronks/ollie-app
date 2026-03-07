//
//  TimelineSheetModifiers.swift
//  Otis-app
//
//  ViewModifier that applies all shared sheet handling to timeline views.
//  Sheet content is built by domain-specific extensions in SheetContent+*.swift files.
//

import SwiftUI
import OtisShared

/// ViewModifier that applies all timeline sheet handling
struct TimelineSheetModifiers: ViewModifier {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var mediaCaptureViewModel: MediaCaptureViewModel
    @Binding var selectedPhotoEvent: PuppyEvent?
    let reduceMotion: Bool
    var spotStore: SpotStore
    var locationManager: LocationManager

    @ObservedObject private var sheetCoordinator: SheetCoordinator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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

    // MARK: - Context

    private var context: SheetContentContext {
        SheetContentContext(
            viewModel: viewModel,
            mediaCaptureViewModel: mediaCaptureViewModel,
            spotStore: spotStore,
            locationManager: locationManager,
            selectedPhotoEvent: $selectedPhotoEvent
        )
    }

    // MARK: - Sheet Binding

    /// Binding that excludes mediaPicker from sheet presentation (handled by fullScreenCover)
    private var sheetBinding: Binding<SheetCoordinator.ActiveSheet?> {
        Binding(
            get: {
                if case .mediaPicker = sheetCoordinator.activeSheet {
                    return nil
                }
                return sheetCoordinator.activeSheet
            },
            set: { sheetCoordinator.activeSheet = $0 }
        )
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .sheetPresentation(binding: sheetBinding, context: context, sizeClass: horizontalSizeClass)
            .mediaPickerPresentation(viewModel: viewModel, mediaCaptureViewModel: mediaCaptureViewModel)
            .mediaPreviewPresentation(selectedPhotoEvent: $selectedPhotoEvent, viewModel: viewModel)
            .deleteConfirmation(viewModel: viewModel)
            .undoBannerOverlay(viewModel: viewModel, reduceMotion: reduceMotion)
            .celebrationBannerOverlay(viewModel: viewModel, reduceMotion: reduceMotion)
    }
}

// MARK: - Sheet Presentation Modifier

private extension View {

    func sheetPresentation(
        binding: Binding<SheetCoordinator.ActiveSheet?>,
        context: SheetContentContext,
        sizeClass: UserInterfaceSizeClass?
    ) -> some View {
        sheet(item: binding) { sheet in
            sheet.buildContentWithDetents(context: context, horizontalSizeClass: sizeClass)
        }
    }
}

// MARK: - Media Picker Presentation

private extension View {

    func mediaPickerPresentation(
        viewModel: TimelineViewModel,
        mediaCaptureViewModel: MediaCaptureViewModel
    ) -> some View {
        fullScreenCover(isPresented: Binding(
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
    }
}

// MARK: - Media Preview Presentation

private extension View {

    func mediaPreviewPresentation(
        selectedPhotoEvent: Binding<PuppyEvent?>,
        viewModel: TimelineViewModel
    ) -> some View {
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
}

// MARK: - Delete Confirmation

private extension View {

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
}

// MARK: - Undo Banner Overlay

private extension View {

    func undoBannerOverlay(viewModel: TimelineViewModel, reduceMotion: Bool) -> some View {
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

// MARK: - Celebration Banner Overlay

private extension View {

    func celebrationBannerOverlay(viewModel: TimelineViewModel, reduceMotion: Bool) -> some View {
        overlay(alignment: .top) {
            if viewModel.showingCelebrationBanner {
                CelebrationBanner(
                    message: viewModel.celebrationMessage,
                    onDismiss: viewModel.dismissCelebrationBanner
                )
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                .padding(.top, 60)
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showingCelebrationBanner)
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
