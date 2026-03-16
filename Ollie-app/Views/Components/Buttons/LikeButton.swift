//
//  LikeButton.swift
//  Ollie-app
//
//  Like button component for events.
//  Shows heart icon with like count, allows toggling likes.
//

import SwiftUI
import OtisShared

/// Like button for events - shows heart with count
struct LikeButton: View {
    let event: PuppyEvent
    let onToggle: () -> Void
    var onShowLikers: (() -> Void)? = nil

    @State private var isAnimating = false

    private var isLikedByCurrentUser: Bool {
        guard let currentUserRecordID = UserIdentityStore.shared.currentUserRecordID else {
            return false
        }
        return event.isLikedBy(currentUserRecordID)
    }

    private var likeCount: Int {
        event.likeCount
    }

    var body: some View {
        Button(action: {
            // Trigger haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()

            // Animate
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isAnimating = true
            }

            // Toggle like
            onToggle()

            // Reset animation
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.3))
                isAnimating = false
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: isLikedByCurrentUser ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isLikedByCurrentUser ? Color.red : Color.secondary)
                    .scaleEffect(isAnimating ? 1.3 : 1.0)

                if likeCount > 0 {
                    Text("\(likeCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .monospacedDigit()
                        .foregroundStyle(isLikedByCurrentUser ? Color.red : Color.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isLikedByCurrentUser ? Color.red.opacity(0.1) : Color.secondary.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(Strings.Likes.tapToToggle)
    }

    private var accessibilityLabel: String {
        if likeCount == 0 {
            return Strings.Likes.noLikes
        } else if likeCount == 1 {
            return isLikedByCurrentUser ? Strings.Likes.youLiked : Strings.Likes.oneLike
        } else {
            return Strings.Likes.multipleLikes(likeCount)
        }
    }
}

/// Compact like indicator (no button, just shows likes)
struct LikeIndicator: View {
    let event: PuppyEvent

    var body: some View {
        if event.hasLikes {
            HStack(spacing: 2) {
                Image(systemName: "heart.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.red)

                Text("\(event.likeCount)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Like badge for showing on cards/thumbnails
struct LikeBadge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            HStack(spacing: 2) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.red)
            )
        }
    }
}

// MARK: - Preview

#Preview("Like Button") {
    VStack(spacing: 20) {
        // No likes
        LikeButton(
            event: PuppyEvent(type: .moment),
            onToggle: { print("Toggle") }
        )

        // With likes
        LikeButton(
            event: PuppyEvent(
                type: .moment,
                likes: [EventLike(likedBy: "user-1")]
            ),
            onToggle: { print("Toggle") }
        )

        // Multiple likes
        LikeButton(
            event: PuppyEvent(
                type: .moment,
                likes: [
                    EventLike(likedBy: "user-1"),
                    EventLike(likedBy: "user-2"),
                    EventLike(likedBy: "user-3")
                ]
            ),
            onToggle: { print("Toggle") }
        )
    }
    .padding()
}

#Preview("Like Badge") {
    HStack(spacing: 20) {
        LikeBadge(count: 0)
        LikeBadge(count: 1)
        LikeBadge(count: 5)
        LikeBadge(count: 99)
    }
    .padding()
}
