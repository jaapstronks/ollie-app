//
//  RecentMomentsCarousel.swift
//  Ollie-app
//
//  Compact horizontal carousel showing recent photos from the last 7 days
//

import SwiftUI
import OtisShared

/// Horizontal carousel displaying recent photo moments
struct RecentMomentsCarousel: View {
    let photoEvents: [PuppyEvent]
    var onPhotoTap: (PuppyEvent, Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Label(Strings.Sharing.recentMoments, systemImage: "camera.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(photoEvents.count)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)

            // Horizontal carousel
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(Array(photoEvents.enumerated()), id: \.element.id) { index, event in
                        MomentThumbnail(event: event)
                            .onTapGesture {
                                HapticFeedback.light()
                                onPhotoTap(event, index)
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM))
    }
}

// MARK: - Moment Thumbnail

private struct MomentThumbnail: View {
    let event: PuppyEvent

    var body: some View {
        EventThumbnailView(event: event)
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .bottomTrailing) {
                if event.hasLikes {
                    LikeBadgeSmall()
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        var parts = [Strings.Sharing.momentCard]
        parts.append(event.time.formatted(date: .abbreviated, time: .shortened))
        if let note = event.note, !note.isEmpty {
            parts.append(note)
        }
        if event.hasLikes {
            parts.append(Strings.Likes.multipleLikes(event.likeCount))
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Small Like Badge

private struct LikeBadgeSmall: View {
    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 8))
            .foregroundStyle(.white)
            .padding(4)
            .background(Color.red)
            .clipShape(Circle())
            .offset(x: 4, y: 4)
    }
}

// MARK: - Preview

#Preview("Recent Moments Carousel") {
    VStack {
        RecentMomentsCarousel(
            photoEvents: [
                PuppyEvent(
                    type: .moment,
                    note: "First moment",
                    photo: "test/photo1.jpg"
                ),
                PuppyEvent(
                    type: .moment,
                    note: "Second moment",
                    photo: "test/photo2.jpg",
                    likes: [EventLike(likedBy: "user-1")]
                ),
                PuppyEvent(
                    type: .moment,
                    note: "Third moment",
                    photo: "test/photo3.jpg"
                ),
                PuppyEvent(
                    type: .uitlaten,
                    note: "Walk photo",
                    photo: "test/photo4.jpg"
                )
            ],
            onPhotoTap: { event, index in
                print("Tapped photo at index \(index): \(event.id)")
            }
        )
        .padding()

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty Carousel") {
    RecentMomentsCarousel(
        photoEvents: [],
        onPhotoTap: { _, _ in }
    )
    .padding()
}
