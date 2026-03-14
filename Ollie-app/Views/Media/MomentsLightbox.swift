//
//  MomentsLightbox.swift
//  Ollie-app
//
//  Premium full-screen photo gallery with swipeable timeline navigation
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
    @State private var localEvents: [PuppyEvent]
    @State private var showShareSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showLikersSheet = false
    @State private var loadedImages: [UUID: UIImage] = [:]
    @State private var dragOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
    }

    private var currentEvent: PuppyEvent {
        guard selectedIndex >= 0, selectedIndex < localEvents.count else {
            return localEvents.first ?? PuppyEvent(type: .moment)
        }
        return localEvents[selectedIndex]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Rich gradient background
                backgroundGradient

                // Photo carousel - full width for proper swiping
                TabView(selection: $selectedIndex) {
                    ForEach(Array(localEvents.enumerated()), id: \.element.id) { index, event in
                        PhotoCard(
                            event: event,
                            loadedImage: loadedImages[event.id],
                            geometry: geometry
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Overlay controls - fixed position, not affected by swipe
                VStack(spacing: 0) {
                    // Top navigation bar
                    topNavigationBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    Spacer()

                    // Bottom info card
                    bottomInfoCard
                        .padding(.horizontal, 16)

                    // Timeline dots
                    if localEvents.count > 1 {
                        timelineDots
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                    }
                }
            }
        }
        .statusBarHidden(true)
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
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            // Base dark color
            Color(white: 0.08)

            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    Color(white: 0.12),
                    Color(white: 0.06),
                    Color(white: 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Subtle ambient glow from current image color
            if let image = loadedImages[currentEvent.id] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 100)
                    .opacity(0.15)
                    .scaleEffect(1.5)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Top Navigation

    private var topNavigationBar: some View {
        HStack(spacing: 12) {
            // Close button
            GlassButton(icon: "xmark", action: onDismiss)
                .accessibilityLabel(Strings.Common.close)

            Spacer()

            // Photo counter
            if localEvents.count > 1 {
                Text("\(selectedIndex + 1) / \(localEvents.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(Capsule())
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                GlassButton(icon: "square.and.arrow.up") {
                    HapticFeedback.light()
                    showShareSheet = true
                }
                .accessibilityLabel(Strings.Sharing.shareThisMoment)

                GlassButton(icon: "trash", tint: .red) {
                    showDeleteConfirmation = true
                }
                .accessibilityLabel(Strings.Common.delete)
            }
        }
    }

    // MARK: - Bottom Info Card

    private var bottomInfoCard: some View {
        VStack(spacing: 0) {
            // Date header
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

                // Like button with count
                LikeButtonStyled(
                    event: currentEvent,
                    onToggle: toggleLike,
                    onShowLikers: { showLikersSheet = true }
                )
            }

            // Note/caption if present
            if let note = currentEvent.note, !note.isEmpty {
                Text(note)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
                    .lineLimit(3)
            }

            // Liker avatars if multiple likes
            if currentEvent.likeCount > 1 {
                HStack(spacing: 8) {
                    LikerAvatarsStack(likerRecordIDs: currentEvent.likes?.map { $0.likedBy } ?? [])

                    Text(Strings.Likes.multipleLikes(currentEvent.likeCount))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))

                    Spacer()
                }
                .padding(.top, 10)
                .onTapGesture { showLikersSheet = true }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Timeline Dots

    private var timelineDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<localEvents.count, id: \.self) { index in
                Circle()
                    .fill(index == selectedIndex ? Color.white : Color.white.opacity(0.3))
                    .frame(width: index == selectedIndex ? 8 : 6, height: index == selectedIndex ? 8 : 6)
                    .animation(.spring(response: 0.3), value: selectedIndex)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func toggleLike() {
        HapticFeedback.light()
        if let updated = eventStore.toggleLike(on: currentEvent) {
            withAnimation(.spring(response: 0.3)) {
                localEvents[selectedIndex] = updated
            }
        }
    }

    private func deleteCurrentPhoto() {
        HapticFeedback.warning()
        let eventToDelete = currentEvent
        localEvents.removeAll { $0.id == eventToDelete.id }
        onDelete(eventToDelete)
        if selectedIndex >= localEvents.count {
            selectedIndex = max(0, localEvents.count - 1)
        }
        if localEvents.isEmpty {
            onDismiss()
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

// MARK: - Glass Button

private struct GlassButton: View {
    let icon: String
    var tint: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial.opacity(0.6))
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Photo Card

private struct PhotoCard: View {
    let event: PuppyEvent
    let loadedImage: UIImage?
    let geometry: GeometryProxy

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isZoomed: Bool { scale > 1.0 }

    // Available space for the image (accounting for top/bottom UI)
    // Top bar ~56pt, bottom card ~180pt, safe padding ~24pt
    private var availableHeight: CGFloat {
        geometry.size.height - 280
    }

    var body: some View {
        Group {
            if let uiImage = loadedImage {
                // Photo with elegant card presentation
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: geometry.size.width - 32, maxHeight: availableHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .scaleEffect(scale)
                    .offset(offset)
                    // Subtle shadow for depth
                    .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                    // Subtle border
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    // Gestures
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let newScale = lastScale * value
                                scale = min(max(newScale, 1.0), 4.0)
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale == 1.0 {
                                    resetOffset()
                                }
                            }
                    )
                    .highPriorityGesture(
                        isZoomed ?
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                        : nil
                    )
                    .onTapGesture(count: 2) {
                        toggleZoom()
                    }
                    .accessibilityLabel(Strings.MediaPreview.photoOf(event.type.label))
            } else {
                // Loading placeholder
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .frame(width: 280, height: 380)
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }

    private func resetOffset() {
        if reduceMotion {
            offset = .zero
            lastOffset = .zero
        } else {
            withAnimation(.spring(response: 0.3)) {
                offset = .zero
                lastOffset = .zero
            }
        }
    }

    private func toggleZoom() {
        let animation: Animation? = reduceMotion ? nil : .spring(response: 0.3)
        withAnimation(animation) {
            if scale > 1.0 {
                scale = 1.0
                lastScale = 1.0
                offset = .zero
                lastOffset = .zero
            } else {
                scale = 2.0
                lastScale = 2.0
            }
        }
    }
}

// MARK: - Styled Like Button

private struct LikeButtonStyled: View {
    let event: PuppyEvent
    let onToggle: () -> Void
    let onShowLikers: () -> Void

    @State private var isAnimating = false

    private var isLiked: Bool {
        guard let currentUserID = UserIdentityStore.shared.currentUserRecordID else { return false }
        return event.isLikedBy(currentUserID)
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isAnimating = true
            }
            onToggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isLiked ? .red : .white)
                    .scaleEffect(isAnimating ? 1.3 : 1.0)

                if event.likeCount > 0 {
                    Text("\(event.likeCount)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isLiked ? Color.red.opacity(0.2) : .white.opacity(0.1))
                    .overlay(
                        Capsule()
                            .strokeBorder(isLiked ? Color.red.opacity(0.4) : .white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Liker Avatars Stack

private struct LikerAvatarsStack: View {
    let likerRecordIDs: [String]

    var body: some View {
        HStack(spacing: -8) {
            ForEach(Array(likerRecordIDs.prefix(4).enumerated()), id: \.element) { index, recordID in
                UserAvatarFromRecordID(cloudKitRecordID: recordID, size: 28)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.8), lineWidth: 2)
                    )
                    .zIndex(Double(4 - index))
            }
            if likerRecordIDs.count > 4 {
                Text("+\(likerRecordIDs.count - 4)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Wrapper (for sheet presentation)

/// Wrapper that manages selectedIndex state internally
/// Used when presenting from SheetCoordinator
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
                    PuppyEvent(type: .moment, note: "Playing in the park on a sunny afternoon"),
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
