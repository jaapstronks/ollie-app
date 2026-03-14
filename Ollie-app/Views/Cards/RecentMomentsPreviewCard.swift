//
//  RecentMomentsPreviewCard.swift
//  Ollie-app
//
//  Shows the 3 most recent photo moments as a compact preview card
//

import SwiftUI
import OtisShared

/// Card showing the 3 most recent photos with larger thumbnails
struct RecentMomentsPreviewCard: View {
    let photoEvents: [PuppyEvent]
    var onPhotoTap: (PuppyEvent, Int) -> Void
    var onViewAll: (() -> Void)?
    var onLikeToggle: ((PuppyEvent) -> Void)?

    @State private var localEvents: [PuppyEvent]?

    /// Check if household sharing is active (other family members exist)
    private var isSharingActive: Bool {
        !ParticipantResolver.shared.resolvedParticipants.isEmpty ||
        !UserIdentityStore.shared.fetchFamilyMemberIdentities().isEmpty
    }

    /// Use localEvents if available (for optimistic like updates), otherwise use photoEvents
    private var displayEvents: [PuppyEvent] {
        localEvents ?? photoEvents
    }

    private var recentThree: [PuppyEvent] {
        Array(displayEvents.prefix(3))
    }

    var body: some View {
        if !recentThree.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Label(Strings.Sharing.recentMoments, systemImage: "photo.on.rectangle.angled")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    if photoEvents.count > 3, let onViewAll {
                        Button {
                            onViewAll()
                        } label: {
                            Text(Strings.Common.seeAll)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.accent)
                        }
                    }
                }

                // Photo thumbnails row
                HStack(spacing: 10) {
                    ForEach(Array(recentThree.enumerated()), id: \.element.id) { index, event in
                        MomentPreviewThumbnail(
                            event: event,
                            showAttribution: isSharingActive,
                            onLikeTap: {
                                handleLikeTap(for: event)
                            }
                        )
                        .onTapGesture {
                            HapticFeedback.light()
                            onPhotoTap(event, index)
                        }
                    }

                    // Placeholder slots for empty spaces
                    ForEach(0..<(3 - recentThree.count), id: \.self) { _ in
                        EmptyThumbnailSlot()
                    }
                }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM))
            .onChange(of: photoEvents) { _, newEvents in
                localEvents = newEvents
            }
        }
    }

    private func handleLikeTap(for event: PuppyEvent) {
        HapticFeedback.light()

        // Update local state immediately for responsiveness
        if let currentUserID = UserIdentityStore.shared.currentUserRecordID {
            // Initialize localEvents from photoEvents if not yet set
            var events = localEvents ?? photoEvents
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    events[index] = event.withLikeToggled(by: currentUserID)
                    localEvents = events
                }
            }
        }

        // Notify parent to persist the change
        onLikeToggle?(event)
    }
}

// MARK: - Moment Preview Thumbnail

private struct MomentPreviewThumbnail: View {
    let event: PuppyEvent
    var showAttribution: Bool = false
    var onLikeTap: (() -> Void)?

    @State private var isLikeAnimating = false

    /// Check if current user has liked this event
    private var isLikedByCurrentUser: Bool {
        guard let currentUserID = UserIdentityStore.shared.currentUserRecordID else { return false }
        return event.isLikedBy(currentUserID)
    }

    /// Get the display name of who logged this moment
    private var loggedByName: String? {
        guard let loggedBy = event.loggedBy else { return nil }
        // Don't show attribution if it's the current user
        if UserIdentityStore.shared.isCurrentUser(loggedBy) { return nil }
        return ParticipantResolver.shared.displayName(for: loggedBy)
    }

    /// Format the date as a relative string (Today, Yesterday, 2 days ago, etc.)
    private var relativeDateText: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(event.time) {
            return Strings.Common.today
        } else if calendar.isDateInYesterday(event.time) {
            return Strings.Common.yesterday
        } else {
            // Show relative date for recent days, otherwise show abbreviated date
            let daysDiff = calendar.dateComponents([.day], from: event.time, to: now).day ?? 0
            if daysDiff <= 6 {
                return event.time.formatted(.relative(presentation: .named))
            } else {
                // For older photos, show short date like "Mar 5"
                return event.time.formatted(.dateTime.month(.abbreviated).day())
            }
        }
    }

    var body: some View {
        EventThumbnailView(event: event)
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            // Top-left: User attribution (when sharing is active and someone else logged it)
            .overlay(alignment: .topLeading) {
                if showAttribution, let name = loggedByName {
                    UserAttributionBadge(
                        cloudKitRecordID: event.loggedBy,
                        displayName: name
                    )
                    .padding(6)
                }
            }
            // Bottom-right: Like button with count
            .overlay(alignment: .bottomTrailing) {
                CompactLikeButton(
                    isLiked: isLikedByCurrentUser,
                    likeCount: event.likeCount,
                    isAnimating: isLikeAnimating,
                    onTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            isLikeAnimating = true
                        }
                        onLikeTap?()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isLikeAnimating = false
                        }
                    }
                )
                .padding(6)
            }
            // Bottom-left: Relative date
            .overlay(alignment: .bottomLeading) {
                Text(relativeDateText)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(6)
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        var parts = [Strings.Sharing.momentCard]
        parts.append(relativeDateText)
        if let name = loggedByName {
            parts.append(Strings.Sharing.capturedBy(name))
        }
        if let note = event.note, !note.isEmpty {
            parts.append(note)
        }
        if event.hasLikes {
            parts.append(Strings.Likes.multipleLikes(event.likeCount))
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - User Attribution Badge

private struct UserAttributionBadge: View {
    let cloudKitRecordID: String?
    let displayName: String

    var body: some View {
        HStack(spacing: 4) {
            UserAvatarFromRecordID(cloudKitRecordID: cloudKitRecordID, size: 14)

            // Show first name only to save space
            Text(displayName.components(separatedBy: " ").first ?? displayName)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Compact Like Button

private struct CompactLikeButton: View {
    let isLiked: Bool
    let likeCount: Int
    let isAnimating: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 3) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isLiked ? .red : .white)
                    .scaleEffect(isAnimating ? 1.3 : 1.0)

                if likeCount > 0 {
                    Text("\(likeCount)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, likeCount > 0 ? 6 : 5)
            .padding(.vertical, 4)
            .background {
                if isLiked {
                    Capsule()
                        .fill(Color.red.opacity(0.4))
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isLiked ? Strings.Likes.youLiked : Strings.Likes.tapToToggle)
    }
}

// MARK: - Empty Thumbnail Slot

private struct EmptyThumbnailSlot: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.tertiarySystemFill))
            .frame(width: 100, height: 100)
            .overlay {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.quaternary)
            }
    }
}

// MARK: - Preview

#Preview("Recent Moments Preview Card") {
    VStack {
        RecentMomentsPreviewCard(
            photoEvents: [
                PuppyEvent(
                    time: Date().addingTimeInterval(-86400), // Yesterday
                    type: .moment,
                    note: "Playing in the park",
                    photo: "test/photo1.jpg",
                    loggedBy: "partner-user-id"
                ),
                PuppyEvent(
                    time: Date().addingTimeInterval(-172800), // 2 days ago
                    type: .moment,
                    note: "Morning cuddles",
                    photo: "test/photo2.jpg",
                    likes: [
                        EventLike(likedBy: "user-1"),
                        EventLike(likedBy: "user-2")
                    ]
                ),
                PuppyEvent(
                    time: Date(), // Today
                    type: .uitlaten,
                    note: "Evening walk",
                    photo: "test/photo3.jpg"
                )
            ],
            onPhotoTap: { event, index in
                print("Tapped photo at index \(index): \(event.id)")
            },
            onViewAll: {
                print("View all tapped")
            },
            onLikeToggle: { event in
                print("Like toggled for: \(event.id)")
            }
        )
        .padding()

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Single Photo - Today") {
    RecentMomentsPreviewCard(
        photoEvents: [
            PuppyEvent(
                time: Date(),
                type: .moment,
                note: "Just one photo",
                photo: "test/photo1.jpg"
            )
        ],
        onPhotoTap: { _, _ in },
        onLikeToggle: { _ in }
    )
    .padding()
}

#Preview("With Likes") {
    RecentMomentsPreviewCard(
        photoEvents: [
            PuppyEvent(
                time: Date().addingTimeInterval(-86400),
                type: .moment,
                note: "Loved by everyone",
                photo: "test/photo1.jpg",
                likes: [
                    EventLike(likedBy: "user-1"),
                    EventLike(likedBy: "user-2"),
                    EventLike(likedBy: "user-3")
                ]
            )
        ],
        onPhotoTap: { _, _ in },
        onLikeToggle: { _ in }
    )
    .padding()
}

#Preview("Empty") {
    RecentMomentsPreviewCard(
        photoEvents: [],
        onPhotoTap: { _, _ in }
    )
    .padding()
}
