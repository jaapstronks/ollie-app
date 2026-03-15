//
//  MomentsLightbox.swift
//  Ollie-app
//
//  Full-screen photo gallery using ScrollView + scrollTargetBehavior (iOS 17+)
//

import SwiftUI
import OtisShared

/// Full-screen lightbox with swipe navigation between photos
struct MomentsLightbox: View {
    let photoEvents: [PuppyEvent]
    @Binding var selectedIndex: Int
    var onDismiss: () -> Void
    var onDelete: (PuppyEvent) -> Void

    @Environment(EventStore.self) private var eventStore
    @Environment(ProfileStore.self) private var profileStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var localEvents: [PuppyEvent]
    @State private var currentEventID: UUID?
    @State private var showShareSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showLikersSheet = false
    @State private var loadedImages: [UUID: UIImage] = [:]

    init(
        photoEvents: [PuppyEvent],
        selectedIndex: Binding<Int>,
        onDismiss: @escaping () -> Void,
        onDelete: @escaping (PuppyEvent) -> Void
    ) {
        self.photoEvents = photoEvents
        self._selectedIndex = selectedIndex
        self.onDismiss = onDismiss
        self.onDelete = onDelete
        self._localEvents = State(initialValue: photoEvents)
        // Initialize currentEventID - always set to a valid value
        let validIndex = min(max(0, selectedIndex.wrappedValue), max(0, photoEvents.count - 1))
        if !photoEvents.isEmpty {
            self._currentEventID = State(initialValue: photoEvents[validIndex].id)
        }
    }

    private var currentEvent: PuppyEvent {
        localEvents.first { $0.id == currentEventID } ?? localEvents.first ?? PuppyEvent(type: .moment)
    }

    private var currentIndex: Int {
        localEvents.firstIndex { $0.id == currentEventID } ?? 0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black

                // Ambient glow from current image
                if let image = loadedImages[currentEvent.id] {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 80)
                        .opacity(0.2)
                        .scaleEffect(1.5)
                }

                // Main carousel using ScrollView + scrollTargetBehavior
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(localEvents) { event in
                            MomentPageView(
                                event: event,
                                loadedImage: loadedImages[event.id],
                                safeAreaTop: geometry.safeAreaInsets.top,
                                safeAreaBottom: geometry.safeAreaInsets.bottom
                            )
                            .containerRelativeFrame(.horizontal)
                            .id(event.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $currentEventID)
                .scrollIndicators(.hidden)

                // Fixed overlay controls
                VStack(spacing: 0) {
                    // Top bar
                    topNavigationBar
                        .padding(.horizontal, 16)
                        .padding(.top, geometry.safeAreaInsets.top + 8)

                    Spacer()

                    // Bottom info card
                    bottomInfoCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                    // Page indicator dots
                    if localEvents.count > 1 {
                        pageIndicator
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                    } else {
                        Spacer().frame(height: geometry.safeAreaInsets.bottom + 16)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onChange(of: currentEventID) { _, newID in
            // Sync selectedIndex when scroll position changes
            if let newID, let index = localEvents.firstIndex(where: { $0.id == newID }) {
                selectedIndex = index
            }
        }
        .confirmationDialog(
            Strings.MediaPreview.deleteTitle,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(Strings.MediaPreview.deletePhoto, role: .destructive) {
                deleteCurrentPhoto()
            }
            Button(Strings.Common.cancel, role: .cancel) {}
        } message: {
            Text(Strings.MediaPreview.deleteConfirmMessage)
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = loadedImages[currentEvent.id],
               let profile = profileStore.activeProfile {
                ShareOptionsSheet(card: MomentShareCard(
                    event: currentEvent,
                    profile: profile,
                    momentImage: image
                ))
            }
        }
        .sheet(isPresented: $showLikersSheet) {
            LikersSheet(event: currentEvent)
        }
        .task {
            await preloadImages()
        }
        // Accessibility: adjustable trait for carousel navigation
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                if currentIndex + 1 < localEvents.count {
                    currentEventID = localEvents[currentIndex + 1].id
                }
            case .decrement:
                if currentIndex - 1 >= 0 {
                    currentEventID = localEvents[currentIndex - 1].id
                }
            @unknown default: break
            }
        }
    }

    // MARK: - Top Navigation Bar

    private var topNavigationBar: some View {
        HStack(spacing: 12) {
            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel(Strings.Common.close)
            .accessibilityHint("Returns to the previous screen")

            Spacer()

            // Photo counter
            if localEvents.count > 1 {
                Text("\(currentIndex + 1) / \(localEvents.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                Button {
                    HapticFeedback.light()
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel(Strings.Sharing.shareThisMoment)

                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.red)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel(Strings.Common.delete)
            }
        }
    }

    // MARK: - Bottom Info Card

    private var bottomInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentEvent.time.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(currentEvent.time.formatted(.dateTime.hour().minute()))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                // Like button
                LikeButton(
                    event: currentEvent,
                    onToggle: { toggleLike(for: currentEvent) },
                    onShowLikers: { showLikersSheet = true }
                )
            }

            // Caption if present
            if let note = currentEvent.note, !note.isEmpty {
                Text(note)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(3)
            }

            // Liker avatars if multiple likes
            if currentEvent.likeCount > 1 {
                HStack(spacing: 8) {
                    LikerAvatarsRow(likerRecordIDs: currentEvent.likes?.map { $0.likedBy } ?? [])

                    Text(Strings.Likes.multipleLikes(currentEvent.likeCount))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .onTapGesture { showLikersSheet = true }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(Array(localEvents.enumerated()), id: \.element.id) { index, _ in
                Circle()
                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.3))
                    .frame(width: index == currentIndex ? 8 : 6, height: index == currentIndex ? 8 : 6)
            }
        }
        .animation(.spring(response: 0.3), value: currentIndex)
    }

    // MARK: - Actions

    private func toggleLike(for event: PuppyEvent) {
        HapticFeedback.light()
        if let updated = eventStore.toggleLike(on: event) {
            withAnimation(.spring(response: 0.3)) {
                if let index = localEvents.firstIndex(where: { $0.id == event.id }) {
                    localEvents[index] = updated
                }
            }
        }
    }

    private func deleteCurrentPhoto() {
        HapticFeedback.warning()
        let eventToDelete = currentEvent
        let deletedIndex = currentIndex

        localEvents.removeAll { $0.id == eventToDelete.id }
        onDelete(eventToDelete)

        if localEvents.isEmpty {
            onDismiss()
        } else {
            // Move to next photo, or previous if we deleted the last one
            let newIndex = min(deletedIndex, localEvents.count - 1)
            currentEventID = localEvents[newIndex].id
            selectedIndex = newIndex
        }
    }

    private func preloadImages() async {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        for event in localEvents {
            guard let photoPath = event.photo ?? event.thumbnailPath else { continue }
            let imageURL = documentsURL.appendingPathComponent(photoPath)
            guard let data = try? Data(contentsOf: imageURL),
                  let image = UIImage(data: data) else { continue }
            await MainActor.run {
                loadedImages[event.id] = image
            }
        }
    }
}

// MARK: - Moment Page View

private struct MomentPageView: View {
    let event: PuppyEvent
    let loadedImage: UIImage?
    let safeAreaTop: CGFloat
    let safeAreaBottom: CGFloat

    // Space needed for overlay controls
    private var topControlsHeight: CGFloat { 56 + safeAreaTop }
    private var bottomControlsHeight: CGFloat { 180 + safeAreaBottom }

    var body: some View {
        VStack(spacing: 0) {
            // Top spacing for controls
            Spacer()
                .frame(height: topControlsHeight)

            // Photo
            if let uiImage = loadedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                    .padding(.horizontal, 20)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .aspectRatio(3/4, contentMode: .fit)
                    .overlay(ProgressView().tint(.white))
                    .padding(.horizontal, 20)
            }

            // Bottom spacing for controls
            Spacer()
                .frame(height: bottomControlsHeight)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.MediaPreview.photoOf(event.type.label))
        .accessibilityHint("Swipe left or right to browse moments")
        .accessibilityAddTraits(.isImage)
    }
}

// MARK: - Liker Avatars Row

private struct LikerAvatarsRow: View {
    let likerRecordIDs: [String]

    var body: some View {
        HStack(spacing: -8) {
            ForEach(Array(likerRecordIDs.prefix(4).enumerated()), id: \.element) { index, recordID in
                UserAvatarFromRecordID(cloudKitRecordID: recordID, size: 28)
                    .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: 2))
                    .zIndex(Double(4 - index))
            }
            if likerRecordIDs.count > 4 {
                Text("+\(likerRecordIDs.count - 4)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
    }
}

// MARK: - Wrapper

/// Wrapper that manages selectedIndex state internally
struct MomentsLightboxWrapper: View {
    let events: [PuppyEvent]
    let startIndex: Int
    let onDismiss: () -> Void
    let onDelete: (PuppyEvent) -> Void

    @State private var selectedIndex: Int

    init(
        events: [PuppyEvent],
        startIndex: Int,
        onDismiss: @escaping () -> Void,
        onDelete: @escaping (PuppyEvent) -> Void
    ) {
        self.events = events
        self.startIndex = startIndex
        self.onDismiss = onDismiss
        self.onDelete = onDelete
        self._selectedIndex = State(initialValue: startIndex)
    }

    var body: some View {
        MomentsLightbox(
            photoEvents: events,
            selectedIndex: $selectedIndex,
            onDismiss: onDismiss,
            onDelete: onDelete
        )
    }
}

// MARK: - Preview

#Preview("Moments Lightbox") {
    struct PreviewWrapper: View {
        @State private var selectedIndex = 0

        var body: some View {
            MomentsLightbox(
                photoEvents: [
                    PuppyEvent(type: .moment, note: "Playing in the park"),
                    PuppyEvent(type: .moment, note: "Morning cuddles"),
                    PuppyEvent(type: .moment)
                ],
                selectedIndex: $selectedIndex,
                onDismiss: { print("Dismiss") },
                onDelete: { event in print("Delete \(event.id)") }
            )
            .environment(EventStore())
            .environment(ProfileStore.shared)
        }
    }

    return PreviewWrapper()
}
