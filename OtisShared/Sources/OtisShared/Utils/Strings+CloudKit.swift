//
//  Strings+CloudKit.swift
//  OtisShared
//
//  CloudKit sharing and sync strings.
//

import Foundation

extension Strings {
    // MARK: - Cloud Sharing
    public enum CloudSharing {
        public static var iCloudUnavailable: String { String(localized: "iCloud unavailable", bundle: Strings.bundle) }
        public static var sharedData: String { String(localized: "Shared data", bundle: Strings.bundle) }
        public static var viewingOthersData: String { String(localized: "You're viewing someone else's data", bundle: Strings.bundle) }
        public static var shared: String { String(localized: "Shared", bundle: Strings.bundle) }
        public static var noParticipants: String { String(localized: "No participants yet", bundle: Strings.bundle) }
        public static var manageSharing: String { String(localized: "Manage sharing", bundle: Strings.bundle) }
        public static var stopSharing: String { String(localized: "Stop sharing", bundle: Strings.bundle) }
        public static var shareWithPartner: String { String(localized: "Share with partner", bundle: Strings.bundle) }
        public static var inviteAnother: String { String(localized: "Invite another person", bundle: Strings.bundle) }
        public static var sharing: String { String(localized: "Sharing", bundle: Strings.bundle) }
        public static func sharingDescription(name: String) -> String {
            String(localized: "Share \(name)'s data with your partner so you can both track and log events.", bundle: Strings.bundle)
        }
        /// Legacy static version
        public static var sharingDescription: String { String(localized: "Share data with your partner so you can both track and log events.", bundle: Strings.bundle) }
        public static var stopSharingConfirm: String { String(localized: "Are you sure you want to stop sharing? The other person will lose access.", bundle: Strings.bundle) }
        public static func lastSynced(time: String) -> String {
            String(localized: "Synced \(time)", bundle: Strings.bundle)
        }

        // iCloud status messages
        public static var iCloudStatusUnknown: String { String(localized: "iCloud status unknown", bundle: Strings.bundle) }
        public static var noICloudAccount: String { String(localized: "No iCloud account configured", bundle: Strings.bundle) }
        public static var iCloudRestricted: String { String(localized: "iCloud is restricted", bundle: Strings.bundle) }
        public static var iCloudTemporarilyUnavailable: String { String(localized: "iCloud temporarily unavailable", bundle: Strings.bundle) }
        public static var iCloudNotAvailable: String { String(localized: "iCloud not available", bundle: Strings.bundle) }
        public static var couldNotCheckICloudStatus: String { String(localized: "Could not check iCloud status", bundle: Strings.bundle) }
        public static var saveFailed: String { String(localized: "Save failed", bundle: Strings.bundle) }
        public static var deleteFailed: String { String(localized: "Delete failed", bundle: Strings.bundle) }

        // Participant status
        public static var statusPending: String { String(localized: "Invited", bundle: Strings.bundle) }
        public static var statusAccepted: String { String(localized: "Active", bundle: Strings.bundle) }
        public static var statusRemoved: String { String(localized: "Removed", bundle: Strings.bundle) }

        // Error messages
        public static var cloudKitNotAvailable: String { String(localized: "CloudKit is not available", bundle: Strings.bundle) }
        public static func saveFailedMessage(_ message: String) -> String {
            String(localized: "Save failed: \(message)", bundle: Strings.bundle)
        }
        public static func deleteFailedMessage(_ message: String) -> String {
            String(localized: "Delete failed: \(message)", bundle: Strings.bundle)
        }
        public static func syncFailedMessage(_ message: String) -> String {
            String(localized: "Sync failed: \(message)", bundle: Strings.bundle)
        }
        public static func migrationFailedMessage(_ message: String) -> String {
            String(localized: "Migration failed: \(message)", bundle: Strings.bundle)
        }
        public static var cannotShareAsParticipant: String { String(localized: "You cannot share as a participant", bundle: Strings.bundle) }
        public static var couldNotLoadShare: String { String(localized: "Could not load share", bundle: Strings.bundle) }
    }
}
