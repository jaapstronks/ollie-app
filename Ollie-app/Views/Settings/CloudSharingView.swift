//
//  CloudSharingView.swift
//  Otis-app
//
//  Simple UIKit wrapper for CloudKit sharing controller (Apple's recommended pattern)
//

import SwiftUI
import OtisShared
import CloudKit
import UIKit
import os

private let logger = Logger.otis(category: "CloudSharingView")

/// Simple SwiftUI wrapper for UICloudSharingController (Apple's pattern)
/// Pass an already-created CKShare - no async share creation inside the view
struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> SharingHostViewController {
        let host = SharingHostViewController()
        host.onDidAppear = { [coordinator = context.coordinator] in
            coordinator.presentIfNeeded(share: share, container: container, from: host)
        }
        return host
    }

    func updateUIViewController(_ uiViewController: SharingHostViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, UICloudSharingControllerDelegate, UIAdaptivePresentationControllerDelegate {
        let onDismiss: () -> Void
        private var didPresentController = false
        private var didCallDismiss = false

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func presentIfNeeded(share: CKShare, container: CKContainer, from host: UIViewController) {
            guard !didPresentController else { return }
            didPresentController = true

            let controller = UICloudSharingController(share: share, container: container)
            controller.availablePermissions = [.allowReadWrite, .allowPrivate]
            controller.delegate = self
            controller.presentationController?.delegate = self
            host.present(controller, animated: true)
        }

        private func notifyDismissIfNeeded() {
            guard !didCallDismiss else { return }
            didCallDismiss = true
            onDismiss()
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            notifyDismissIfNeeded()
        }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            logger.error("Share failed: \(error.localizedDescription)")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            "Otis - Puppy Events"
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
            // Do not broadcast share-accepted here; that notification is only for invitation acceptance.
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            logger.info("Sharing stopped")
            // State updates are handled by the presenting SwiftUI view on dismiss.
        }
    }
}

final class SharingHostViewController: UIViewController {
    var onDidAppear: (() -> Void)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onDidAppear?()
    }
}

/// Sync status indicator for the timeline or other views
struct SyncStatusView: View {
    var eventStore: EventStore
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
                    .foregroundStyle(Color.otisWarning)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else if cloudKit.isCloudAvailable {
                Image(systemName: "checkmark.icloud")
                    .font(.caption)
                    .foregroundStyle(Color.otisSuccess)
            }
        }
    }
}

#Preview {
    SyncStatusView(eventStore: EventStore())
}
