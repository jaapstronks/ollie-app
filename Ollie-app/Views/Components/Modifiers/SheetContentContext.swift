//
//  SheetContentContext.swift
//  Otis-app
//
//  Context object containing all dependencies needed to build sheet content
//

import SwiftUI
import OtisShared

/// Context containing all dependencies needed to build sheet content
/// This eliminates the need to pass many parameters through the sheet builder
@MainActor
struct SheetContentContext {
    let viewModel: TimelineViewModel
    let mediaCaptureViewModel: MediaCaptureViewModel
    let spotStore: SpotStore
    let locationManager: LocationManager
    let routineStore: RoutineStore
    var selectedPhotoEvent: Binding<PuppyEvent?>

    // MARK: - Convenience Accessors

    var sheetCoordinator: SheetCoordinator {
        viewModel.sheetCoordinator
    }

    var profileStore: ProfileStore {
        viewModel.profileStore
    }

    var eventStore: EventStore {
        viewModel.eventStore
    }

    var puppyName: String {
        viewModel.puppyName
    }

    var profile: PuppyProfile? {
        profileStore.profile
    }
}
