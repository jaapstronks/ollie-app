//
//  CloudSharingView.swift
//  Ollie-app
//
//  Simple UIKit wrapper for CloudKit sharing controller (Apple's recommended pattern)
//

import SwiftUI
import OllieShared
import CloudKit
import os

private let logger = Logger.ollie(category: "CloudSharingView")

/// Simple SwiftUI wrapper for UICloudSharingController (Apple's pattern)
/// Pass an already-created CKShare - no async share creation inside the view
struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = context.coordinator
        controller.modalPresentationStyle = .formSheet
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            logger.error("Share failed: \(error.localizedDescription)")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            "Ollie - Puppy Events"
        }

        func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
            // Return app icon as thumbnail for share previews
            if let icon = UIImage(named: "AppIcon"),
               let data = icon.pngData() {
                return data
            }
            // Fallback: try to get icon from bundle
            if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
               let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
               let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
               let lastIcon = iconFiles.last,
               let icon = UIImage(named: lastIcon),
               let data = icon.pngData() {
                return data
            }
            return nil
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            logger.info("Share saved successfully")
            // Share state is managed automatically by NSPersistentCloudKitContainer
            NotificationCenter.default.post(name: .cloudKitShareAccepted, object: nil)
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            logger.info("Sharing stopped")
            // Share state is managed automatically by NSPersistentCloudKitContainer
            NotificationCenter.default.post(name: .cloudKitShareAccepted, object: nil)
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
                Image(systemName: "checkmark.icloud")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }
}

#Preview {
    SyncStatusView(eventStore: EventStore())
}
