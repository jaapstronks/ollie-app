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

/// Settings section for CloudKit sharing
struct ShareSettingsSection: View {
    @ObservedObject var cloudKit: CloudKitService

    @State private var share: CKShare?
    @State private var showShareSheet = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showStopSharingConfirm = false

    var body: some View {
        Section {
            if !cloudKit.isCloudAvailable {
                // iCloud not available
                HStack {
                    Image(systemName: "exclamationmark.icloud")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.CloudSharing.iCloudUnavailable)
                            .font(.subheadline)
                        if let error = cloudKit.syncError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else if cloudKit.isParticipant {
                // User is viewing shared data (not the owner)
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.CloudSharing.sharedData)
                            .font(.subheadline)
                        Text(Strings.CloudSharing.viewingOthersData)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(Strings.Common.loading)
                        .foregroundStyle(.secondary)
                }
            } else if cloudKit.isShared {
                // Already shared - show participants
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(Strings.CloudSharing.shared)
                            .font(.subheadline.weight(.medium))
                    }

                    if cloudKit.shareParticipants.isEmpty {
                        Text(Strings.CloudSharing.noParticipants)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(cloudKit.shareParticipants) { participant in
                            HStack {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(participant.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(participant.status.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Button {
                    showShareSheet = true
                } label: {
                    Label(Strings.CloudSharing.manageSharing, systemImage: "person.badge.plus")
                }

                Button(role: .destructive) {
                    HapticFeedback.warning()
                    showStopSharingConfirm = true
                } label: {
                    Label(Strings.CloudSharing.stopSharing, systemImage: "xmark.circle")
                }
            } else {
                // Not shared yet - show invite button
                Button {
                    Task { await createAndShowShare() }
                } label: {
                    Label(Strings.CloudSharing.shareWithPartner, systemImage: "person.badge.plus")
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text(Strings.CloudSharing.sharing)
        } footer: {
            if cloudKit.isCloudAvailable && !cloudKit.isParticipant {
                Text(Strings.CloudSharing.sharingDescription)
            }
        }
        .task {
            await loadExistingShare()
        }
        .sheet(isPresented: $showShareSheet) {
            if let share = share {
                CloudSharingView(
                    share: share,
                    container: CKContainer(identifier: "iCloud.nl.jaapstronks.Ollie")
                )
            }
        }
        .alert(Strings.CloudSharing.stopSharing, isPresented: $showStopSharingConfirm) {
            Button(Strings.Common.cancel, role: .cancel) {}
            Button(Strings.CloudSharing.stopSharing, role: .destructive) {
                Task { await stopSharing() }
            }
        } message: {
            Text(Strings.CloudSharing.stopSharingConfirm)
        }
    }

    private func loadExistingShare() async {
        isLoading = true
        errorMessage = nil

        do {
            share = try await cloudKit.fetchExistingShare()
        } catch {
            // Not a critical error if there's no share yet
        }

        isLoading = false
    }

    private func createAndShowShare() async {
        errorMessage = nil

        do {
            share = try await cloudKit.createShare()
            showShareSheet = true
        } catch {
            errorMessage = "Kon niet delen: \(error.localizedDescription)"
        }
    }

    private func stopSharing() async {
        do {
            try await cloudKit.stopSharing()
            share = nil
        } catch {
            errorMessage = "Kon delen niet stoppen: \(error.localizedDescription)"
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
    NavigationStack {
        Form {
            ShareSettingsSection(cloudKit: CloudKitService.shared)
        }
    }
}
