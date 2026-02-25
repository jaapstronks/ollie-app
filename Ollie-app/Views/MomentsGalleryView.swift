//
//  MomentsGalleryView.swift
//  Ollie-app
//

import SwiftUI
import OllieShared
import UIKit

/// Grid gallery view of all photo moments
struct MomentsGalleryView: View {
    @ObservedObject var viewModel: MomentsViewModel
    var onSettingsTap: (() -> Void)? = nil
    @State private var selectedEvent: PuppyEvent?
    @Namespace private var heroNamespace

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    // Skeleton loading grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(0..<12, id: \.self) { index in
                                SkeletonRect(height: 120, cornerRadius: 0)
                                    .aspectRatio(1, contentMode: .fill)
                                    .animatedAppear(delay: StaggeredAnimation.delay(for: index))
                            }
                        }
                        .padding(.top)
                    }
                    .skeleton(isLoading: true)
                } else if viewModel.events.isEmpty {
                    EmptyMomentsView()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
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
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle(Strings.MomentsGallery.title)
            .toolbar {
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
}

/// Single thumbnail in the gallery grid
struct GalleryThumbnail: View {
    let event: PuppyEvent
    @State private var image: UIImage?

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        }
                }
            }
        }
        .task {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        // Try thumbnail first, fall back to full photo
        let path = event.thumbnailPath ?? event.photo
        guard let path = path else { return }

        let url = documentsURL.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url),
              let loaded = UIImage(data: data) else { return }
        image = loaded
    }
}

/// Enhanced empty state for moments gallery with animation
struct EmptyMomentsView: View {
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Animated photo stack
            ZStack {
                // Background photo (rotated)
                Image(systemName: "photo.fill")
                    .font(.system(size: 45))
                    .foregroundStyle(Color.ollieAccent.opacity(0.2))
                    .offset(x: -20, y: 10)
                    .rotationEffect(.degrees(-12))

                // Middle photo
                Image(systemName: "photo.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.ollieAccent.opacity(0.4))
                    .offset(x: 15, y: -5)
                    .rotationEffect(.degrees(8))

                // Front photo with animation
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 65))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.ollieAccent, Color.ollieAccent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.92)
                    .opacity(isAnimating ? 1.0 : 0.8)
            }
            .onAppear {
                guard !reduceMotion else {
                    isAnimating = true
                    return
                }
                withAnimation(
                    .easeInOut(duration: 1.8)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
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
