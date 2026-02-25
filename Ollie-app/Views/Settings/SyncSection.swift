//
//  SyncSection.swift
//  Ollie-app
//
//  iCloud sync section for SettingsView

import SwiftUI
import OllieShared

/// iCloud sync status and controls section
struct SyncSection: View {
    @ObservedObject var eventStore: EventStore
    @ObservedObject var cloudKit: CloudKitService

    var body: some View {
        Section {
            // Sync status
            HStack {
                if eventStore.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(Strings.Settings.syncing)
                        .foregroundStyle(.secondary)
                } else if cloudKit.isCloudAvailable {
                    Image(systemName: "checkmark.icloud")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Settings.iCloudActive)
                        Text("Sync is automatic")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Image(systemName: "xmark.icloud")
                        .foregroundStyle(.orange)
                    Text(Strings.Settings.iCloudUnavailable)
                }
                Spacer()
            }

            // Manual sync button
            if cloudKit.isCloudAvailable && !eventStore.isSyncing {
                Button {
                    Task {
                        await eventStore.forceSync()
                    }
                } label: {
                    Label(Strings.Settings.syncNow, systemImage: "arrow.triangle.2.circlepath")
                }
            }
        } header: {
            Text(Strings.Settings.sync)
        } footer: {
            Text(Strings.Settings.syncFooter)
        }
    }
}
