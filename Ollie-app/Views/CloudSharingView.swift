//
//  CloudSharingView.swift
//  Ollie-app
//
//  UIKit wrapper for CloudKit sharing controller
//

import SwiftUI
import OllieShared
import CloudKit
import os

private let logger = Logger.ollie(category: "CloudSharingView")

/// Mode for the sharing controller
enum SharingMode {
    case invite  // Creating a new share and inviting people
    case manage  // Managing an existing share
}

/// SwiftUI wrapper for UICloudSharingController
/// Use .invite mode when first sharing (to show the share sheet with Messages, AirDrop, etc.)
/// Use .manage mode when managing an existing share (to view/remove participants)
struct CloudSharingView: UIViewControllerRepresentable {
    let mode: SharingMode
    let share: CKShare?  // Only needed for .manage mode
    let container: CKContainer
    let zoneID: CKRecordZone.ID
    let onDismiss: () -> Void

    init(mode: SharingMode, share: CKShare? = nil, container: CKContainer, zoneID: CKRecordZone.ID, onDismiss: @escaping () -> Void = {}) {
        self.mode = mode
        self.share = share
        self.container = container
        self.zoneID = zoneID
        self.onDismiss = onDismiss
    }

    func makeUIViewController(context: Context) -> CloudSharingHostController {
        let hostController = CloudSharingHostController()
        hostController.mode = mode
        hostController.share = share
        hostController.container = container
        hostController.zoneID = zoneID
        hostController.coordinator = context.coordinator
        return hostController
    }

    func updateUIViewController(_ uiViewController: CloudSharingHostController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            logger.error("CloudKit sharing failed: \(error.localizedDescription)")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            "Ollie - Puppy Events"
        }

        func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
            // Could return app icon data here
            nil
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            logger.info("Share saved successfully")
            Task { @MainActor in
                await CloudKitService.shared.updateShareState()
            }
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            logger.info("Sharing stopped")
            Task { @MainActor in
                await CloudKitService.shared.updateShareState()
            }
        }
    }
}

/// Host controller that presents UICloudSharingController modally
/// This is needed because UICloudSharingController requires specific presentation handling
class CloudSharingHostController: UIViewController, UIAdaptivePresentationControllerDelegate {
    var mode: SharingMode = .invite
    var share: CKShare?
    var container: CKContainer!
    var zoneID: CKRecordZone.ID!
    weak var coordinator: CloudSharingView.Coordinator?

    private var hasPresented = false
    private var sharingController: UICloudSharingController?
    private var isPreparingShare = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Only present once
        guard !hasPresented else { return }
        hasPresented = true

        presentSharingController()
    }

    private func presentSharingController() {
        switch mode {
        case .invite:
            // Create the share first, then present the controller
            prepareAndPresentInviteController()

        case .manage:
            guard let existingShare = share else {
                logger.error("Share is required for .manage mode")
                dismissAndNotify()
                return
            }
            presentController(with: existingShare)
        }
    }

    /// Creates a new share and presents the sharing controller (iOS 17+ approach)
    private func prepareAndPresentInviteController() {
        guard !isPreparingShare else { return }
        isPreparingShare = true

        // Show loading indicator
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.center = view.center
        spinner.startAnimating()
        view.addSubview(spinner)

        Task {
            do {
                // Create and save the share first
                let newShare = CKShare(recordZoneID: zoneID)
                newShare[CKShare.SystemFieldKey.title] = "Ollie - Puppy Events"
                newShare.publicPermission = .none

                _ = try await container.privateCloudDatabase.save(newShare)
                logger.info("Share created and saved successfully")

                await MainActor.run {
                    spinner.removeFromSuperview()
                    self.presentController(with: newShare)
                }
            } catch {
                logger.error("Failed to create share: \(error.localizedDescription)")
                await MainActor.run {
                    spinner.removeFromSuperview()
                    self.showError(error)
                }
            }
        }
    }

    /// Presents the UICloudSharingController with an existing share
    private func presentController(with share: CKShare) {
        sharingController = UICloudSharingController(share: share, container: container)

        guard let sharingController = sharingController else { return }

        sharingController.availablePermissions = [.allowReadWrite]
        sharingController.delegate = coordinator
        sharingController.presentationController?.delegate = self

        present(sharingController, animated: true) {
            logger.info("Sharing controller presented")
        }
    }

    /// Shows an error alert and dismisses
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: Strings.Common.error,
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Strings.Common.ok, style: .default) { [weak self] _ in
            self?.dismissAndNotify()
        })
        present(alert, animated: true)
    }

    // Called when user dismisses the sharing controller by swiping down or tapping outside
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        logger.info("Sharing controller dismissed by user")
        dismissAndNotify()
    }

    private func dismissAndNotify() {
        // If we're still presenting something, dismiss it first
        if presentedViewController != nil {
            dismiss(animated: false) { [weak self] in
                self?.coordinator?.onDismiss()
            }
        } else {
            coordinator?.onDismiss()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Notify when this host controller is being dismissed
        if isBeingDismissed || isMovingFromParent {
            coordinator?.onDismiss()
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
