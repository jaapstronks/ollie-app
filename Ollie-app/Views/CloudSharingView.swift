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
            // Use preparationHandler for inviting - creates share when user chooses how to send
            let capturedContainer = container!
            let capturedZoneID = zoneID!

            sharingController = UICloudSharingController { [weak self] (controller, preparationCompletionHandler) in
                Task {
                    do {
                        let newShare = CKShare(recordZoneID: capturedZoneID)
                        newShare[CKShare.SystemFieldKey.title] = "Ollie - Puppy Events"
                        newShare.publicPermission = .none

                        // Save the share to CloudKit
                        _ = try await capturedContainer.privateCloudDatabase.save(newShare)

                        logger.info("Share created and saved successfully")

                        await MainActor.run {
                            preparationCompletionHandler(newShare, capturedContainer, nil)
                        }
                    } catch {
                        logger.error("Failed to create share: \(error.localizedDescription)")
                        await MainActor.run {
                            preparationCompletionHandler(nil, nil, error)
                        }
                    }
                }
            }

        case .manage:
            guard let existingShare = share else {
                logger.error("Share is required for .manage mode")
                dismissAndNotify()
                return
            }
            sharingController = UICloudSharingController(share: existingShare, container: container)
        }

        guard let sharingController = sharingController else { return }

        sharingController.availablePermissions = [.allowReadWrite]
        sharingController.delegate = coordinator
        sharingController.presentationController?.delegate = self

        // Present the sharing controller
        present(sharingController, animated: true) {
            logger.info("Sharing controller presented")
        }
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
