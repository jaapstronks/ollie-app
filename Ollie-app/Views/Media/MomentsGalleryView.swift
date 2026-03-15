//
//  MomentsGalleryView.swift
//  Otis-app
//

import SwiftUI
import OtisShared
import UIKit

/// Grid gallery view of all photo moments
struct MomentsGalleryView: View {
    var viewModel: MomentsViewModel
    var onSettingsTap: (() -> Void)? = nil
    var onAddMoment: (() -> Void)? = nil
    @State private var selectedEvent: PuppyEvent?
    @Namespace private var heroNamespace
    @AppStorage("momentsViewMode") private var viewMode: MomentsViewMode = .gallery

    // First-visit tip tracking
    @AppStorage("hasSeenMomentsGalleryTip") private var hasSeenMomentsGalleryTip = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Adaptive grid columns - 3 fixed on iPhone, adaptive on iPad
    private var columns: [GridItem] {
        if horizontalSizeClass == .regular {
            // iPad: adaptive columns based on available width
            return [GridItem(.adaptive(minimum: iPadLayout.adaptiveGridMinWidth), spacing: 2)]
        } else {
            // iPhone: fixed 3 columns
            return [
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2)
            ]
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    // Skeleton loading grid - single shimmer on container only (no per-item animations)
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(0..<12, id: \.self) { _ in
                                SkeletonRect(height: 120, cornerRadius: 0)
                                    .aspectRatio(1, contentMode: .fill)
                            }
                        }
                        .padding(.top)
                    }
                    .skeleton(isLoading: true)
                } else if viewModel.events.isEmpty {
                    EmptyMomentsView(onAddMoment: onAddMoment)
                } else {
                    switch viewMode {
                    case .gallery:
                        galleryContent
                    case .diary:
                        diaryContent
                    }
                }
            }
            .navigationTitle(Strings.MomentsGallery.title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    MomentsViewModeToggle(mode: $viewMode)
                        .frame(width: 140)
                }
                if let onSettingsTap = onSettingsTap {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            onSettingsTap()
                        } label: {
                            Image(systemName: "gear")
                        }
                        .accessibilityLabel(Strings.Tabs.settings)
                    }
                }
            }
            .fullScreenCover(item: $selectedEvent) { event in
                MediaPreviewView(
                    event: event,
                    onDelete: {
                        viewModel.deleteEvent(event)
                        selectedEvent = nil
                    }
                )
            }
            .onAppear {
                viewModel.loadEventsWithMedia()
            }
            .refreshable {
                viewModel.loadEventsWithMedia()
            }
        }
    }

    // MARK: - Gallery View Content

    private var galleryContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // First-visit tip (only when there are photos)
                if !hasSeenMomentsGalleryTip {
                    FeatureTipCard(
                        tip: .momentsGallery,
                        onDismiss: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                hasSeenMomentsGalleryTip = true
                            }
                        }
                    )
                    .padding(.horizontal)
                }

                ForEach(Array(viewModel.eventsByMonth.enumerated()), id: \.element.month) { sectionIndex, section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.month)
                            .font(.headline)
                            .padding(.horizontal)
                            .animatedAppear(delay: StaggeredAnimation.delay(for: sectionIndex))

                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(Array(section.events.enumerated()), id: \.element.id) { eventIndex, event in
                                GalleryThumbnail(event: event)
                                    .aspectRatio(1, contentMode: .fill)
                                    .zoomTransitionSource(id: event.id, in: heroNamespace)
                                    .onTapGesture {
                                        selectedEvent = event
                                    }
                                    .animatedAppear(delay: StaggeredAnimation.delay(for: eventIndex, baseDelay: 0.03, maxDelay: 0.2))
                                    .onAppear {
                                        // Trigger infinite scroll when near the end
                                        viewModel.loadMoreIfNeeded(currentEvent: event)
                                    }
                            }
                        }
                    }
                }

                // Loading indicator at bottom when loading more
                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Diary View Content

    private var diaryContent: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(Array(viewModel.events.enumerated()), id: \.element.id) { index, event in
                    DiaryCardView(event: event)
                        .zoomTransitionSource(id: event.id, in: heroNamespace)
                        .onTapGesture {
                            selectedEvent = event
                        }
                        .animatedAppear(delay: StaggeredAnimation.delay(for: index, baseDelay: 0.05, maxDelay: 0.3))
                        .onAppear {
                            // Trigger infinite scroll when near the end
                            viewModel.loadMoreIfNeeded(currentEvent: event)
                        }
                }

                // Loading indicator at bottom when loading more
                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                }
            }
            .padding()
        }
    }
}

/// Single thumbnail in the gallery grid
/// Uses EventThumbnailView for CloudKit download fallback
struct GalleryThumbnail: View {
    let event: PuppyEvent

    var body: some View {
        GeometryReader { geometry in
            EventThumbnailView(event: event)
                .frame(width: geometry.size.width, height: geometry.size.width)
                .clipped()
        }
    }
}

/// Enhanced empty state for moments gallery with animation
struct EmptyMomentsView: View {
    var onAddMoment: (() -> Void)? = nil
    @State private var isAnimating = false
    @State private var shouldAnimate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Animated photo stack
            ZStack {
                // Background photo (rotated)
                Image(systemName: "photo.fill")
                    .font(.system(size: 45))
                    .foregroundStyle(Color.otisAccent.opacity(0.2))
                    .offset(x: -20, y: 10)
                    .rotationEffect(.degrees(-12))

                // Middle photo
                Image(systemName: "photo.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.otisAccent.opacity(0.4))
                    .offset(x: 15, y: -5)
                    .rotationEffect(.degrees(8))

                // Front photo with animation
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 65))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.otisAccent, Color.otisAccent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.92)
                    .opacity(isAnimating ? 1.0 : 0.8)
                    .animation(
                        shouldAnimate
                            ? .easeInOut(duration: 1.8).repeatForever(autoreverses: true)
                            : .default,
                        value: isAnimating
                    )
            }
            .onAppear {
                guard !reduceMotion else {
                    isAnimating = true
                    return
                }
                shouldAnimate = true
                isAnimating = true
            }
            .onDisappear {
                // Stop animation when view disappears
                shouldAnimate = false
                isAnimating = false
            }

            VStack(spacing: 8) {
                Text(Strings.MomentsGallery.noPhotos)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(Strings.MomentsGallery.makePhotosHint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Add first moment button (when callback provided)
            if let onAddMoment = onAddMoment {
                Button {
                    HapticFeedback.medium()
                    onAddMoment()
                } label: {
                    Label(Strings.MomentsGallery.addFirstMoment, systemImage: "camera.fill")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.otisAccent)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.MomentsGallery.noPhotos)
    }
}

#Preview {
    MomentsGalleryView(viewModel: MomentsViewModel(eventStore: EventStore()))
}
