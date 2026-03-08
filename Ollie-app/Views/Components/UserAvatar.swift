//
//  UserAvatar.swift
//  Ollie-app
//
//  Avatar display for users (CloudKit-based identity)
//  Replaces HouseholdMemberAvatar with UserIdentity support
//

import SwiftUI
import OtisShared

/// Displays a user's avatar (image or colored initial)
/// Works with both UserIdentity (new) and HouseholdMember (legacy) for backwards compatibility
struct UserAvatar: View {
    let identity: UserIdentity?
    var size: CGFloat = 20

    var body: some View {
        if let identity = identity {
            if let avatarData = identity.avatarData,
               let uiImage = UIImage(data: avatarData) {
                // Show avatar image
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                // Show colored circle with initial
                ZStack {
                    Circle()
                        .fill(Color(hex: identity.colorHex))

                    Text(identity.initial)
                        .font(.system(size: size * 0.5, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: size, height: size)
            }
        }
    }
}

/// Helper to display avatars from CloudKit record IDs
struct UserAvatarFromRecordID: View {
    let cloudKitRecordID: String?
    var size: CGFloat = 20
    @ObservedObject private var userIdentityStore = UserIdentityStore.shared
    @ObservedObject private var participantResolver = ParticipantResolver.shared

    var body: some View {
        if let recordID = cloudKitRecordID {
            if userIdentityStore.isCurrentUser(recordID),
               let identity = userIdentityStore.currentIdentity {
                // Current user - show their avatar
                UserAvatar(identity: identity, size: size)
            } else {
                // Other user - resolve via ParticipantResolver
                let resolved = participantResolver.resolve(cloudKitRecordID: recordID)
                PlaceholderAvatar(displayName: resolved.displayName, size: size)
            }
        }
    }
}

/// Placeholder avatar for users we don't have full info for
private struct PlaceholderAvatar: View {
    let displayName: String
    let size: CGFloat

    private var initial: String {
        String(displayName.prefix(1)).uppercased()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(.tint.opacity(0.3))

            Text(initial)
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundStyle(.tint)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview("With Avatar") {
    HStack(spacing: 16) {
        UserAvatar(
            identity: UserIdentity(
                name: "John",
                colorHex: "#FF6B6B",
                cloudKitUserRecordID: "test-1"
            ),
            size: 20
        )

        UserAvatar(
            identity: UserIdentity(
                name: "Sarah",
                colorHex: "#4ECDC4",
                cloudKitUserRecordID: "test-2"
            ),
            size: 28
        )

        UserAvatar(
            identity: UserIdentity(
                name: "Mike",
                colorHex: "#45B7D1",
                cloudKitUserRecordID: "test-3"
            ),
            size: 36
        )
    }
    .padding()
}

#Preview("Nil Identity") {
    UserAvatar(identity: nil, size: 20)
        .padding()
}
