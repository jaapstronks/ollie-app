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
            SharingSection(cloudKit: cloudKit)
        }
        .navigationTitle(Strings.CloudSharing.sharing)
    }
}

#Preview {
    NavigationStack {
        DogSharingSettingsView(cloudKit: CloudKitService.shared)
            .environmentObject(SubscriptionManager.shared)
    }
}
