//
//  DogSharingSettingsView.swift
//  Otis-app
//
//  Dog-specific sharing settings view wrapping SharingSection
//

import CloudKit
import SwiftUI
import OtisShared

/// Wrapper view for sharing settings, accessible from dog-specific settings
struct DogSharingSettingsView: View {
    var cloudKit: CloudKitService

    @State private var activeShareSheet: ShareSheetItem?

    var body: some View {
        Form {
            SharingSection(
                cloudKit: cloudKit,
                showHeader: false,
                activeShareSheet: $activeShareSheet
            )
        }
        .navigationTitle(Strings.CloudSharing.sharing)
        .navigationDestination(item: $activeShareSheet) { item in
            CloudSharingView(
                share: item.share,
                container: CKContainer(identifier: "iCloud.nl.jaapstronks.Otis"),
                onDismiss: {
                    activeShareSheet = nil
                    Task { await cloudKit.updateShareState() }
                }
            )
            .navigationTitle(Strings.CloudSharing.manageSharing)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("With header") {
    @Previewable @State var activeShareSheet: ShareSheetItem?
    NavigationStack {
        Form {
            SharingSection(
                cloudKit: CloudKitService.shared,
                showHeader: true,
                activeShareSheet: $activeShareSheet
            )
        }
        .environment(SubscriptionManager.shared)
    }
}

#Preview("Standalone") {
    NavigationStack {
        DogSharingSettingsView(cloudKit: CloudKitService.shared)
            .environment(SubscriptionManager.shared)
    }
}
