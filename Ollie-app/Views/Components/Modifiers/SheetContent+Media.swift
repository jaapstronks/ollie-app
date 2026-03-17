//
//  SheetContent+Media.swift
//  Otis-app
//
//  Sheet content builders for media-related sheets (photos, moments)
//

import SwiftUI
import OtisShared

extension SheetCoordinator.ActiveSheet {

    // MARK: - Media Sheets

    @MainActor @ViewBuilder
    func buildMediaContent(context: SheetContentContext) -> some View {
        switch self {
        case .mediaPicker:
            // Handled by fullScreenCover in TimelineSheetModifiers, not as a sheet
            EmptyView()

        case .momentSourcePicker:
            MomentSourcePickerSheet(
                onCamera: {
                    context.viewModel.openCamera()
                },
                onLibrary: {
                    context.viewModel.openPhotoLibrary()
                },
                onCancel: {
                    context.sheetCoordinator.dismissSheet()
                }
            )

        case .logMoment:
            LogMomentSheet(
                viewModel: context.mediaCaptureViewModel,
                onSave: { event in
                    context.viewModel.addEvent(event)
                    context.viewModel.dismissLogMomentSheet()
                    context.mediaCaptureViewModel.reset()
                    HapticFeedback.success()
                },
                onCancel: {
                    context.viewModel.dismissLogMomentSheet()
                    context.mediaCaptureViewModel.reset()
                }
            )

        default:
            EmptyView()
        }
    }
}
