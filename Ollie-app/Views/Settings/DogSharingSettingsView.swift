//
//  DogSharingSettingsView.swift
//  Otis-app
//
//  Dog-specific sharing settings view wrapping SharingSection
//

import SwiftUI
import OtisShared

/// Wrapper view for sharing settings, accessible from dog-specific settings
struct DogSharingSettingsView: View {
    @ObservedObject var cloudKit: CloudKitService

    var body: some View {
        Form {
            SharingSection(cloudKit: cloudKit, showHeader: false)
        }
        .navigationTitle(Strings.CloudSharing.sharing)
    }
}

#Preview("With header") {
    NavigationStack {
        Form {
            SharingSection(cloudKit: CloudKitService.shared, showHeader: true)
        }
        .environmentObject(SubscriptionManager.shared)
    }
}

#Preview("Standalone") {
    NavigationStack {
        DogSharingSettingsView(cloudKit: CloudKitService.shared)
            .environmentObject(SubscriptionManager.shared)
    }
}
