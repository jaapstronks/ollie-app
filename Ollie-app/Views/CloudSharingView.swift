//
//  CloudSharingView.swift
//  Ollie-app
//
//  UIKit wrapper for CloudKit sharing controller
//

import SwiftUI
import CloudKit

/// SwiftUI wrapper for UICloudSharingController
struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("Failed to save share: \(error.localizedDescription)")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            "Ollie - Puppy Events"
        }

        func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
            // Could return app icon data here
            nil
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            // Share was saved successfully
            Task { @MainActor in
                await CloudKitService.shared.refreshShareParticipants()
            }
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            // User stopped sharing
            Task { @MainActor in
                await CloudKitService.shared.refreshShareParticipants()
            }
        }
    }
}

/// Sync status indicator for the timeline or other views
struct SyncStatusView: View {
    @ObservedObject var eventStore: EventStore
    @ObservedObject var cloudKit = CloudKitService.shared

    var body: some View {
        HStack(spacing: 6) {
            if eventStore.isSyncing {
                ProgressView()
                    .scaleEffect(0.6)
                Text(Strings.Settings.syncing)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let error = eventStore.syncError {
                Image(systemName: "exclamationmark.icloud")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else if cloudKit.isCloudAvailable {
                if let lastSync = cloudKit.lastSyncDate {
                    Image(systemName: "checkmark.icloud")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text(Strings.CloudSharing.lastSynced(time: lastSync.formatted(.relative(presentation: .named))))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "icloud")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    SyncStatusView(eventStore: EventStore())
}
