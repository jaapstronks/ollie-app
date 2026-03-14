//
//  ShareOptionsSheet.swift
//  Otis-app
//
//  Share options UI with format selection and platform quick actions
//

import SwiftUI
import UIKit
import OtisShared

/// Sheet for sharing content with format and platform options
struct ShareOptionsSheet<Card: ShareableCard>: View {
    let card: Card

    @State private var shareService = ShareService()
    @State private var selectedFormat: ShareFormat = .portrait
    @State private var renderedImage: UIImage?
    @State private var isRendering = true
    @State private var showingError = false
    @State private var errorMessage: String?
    @State private var showingSavedConfirmation = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Preview
                cardPreview

                // Format picker
                formatPicker

                // Quick share buttons
                quickShareButtons

                Spacer()
            }
            .padding()
            .navigationTitle(Strings.Sharing.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
            }
            .task {
                ShareAnalytics.trackShareSheetOpened(cardType: card.type)
                await renderCard()
            }
            .onChange(of: selectedFormat) { _, newFormat in
                ShareAnalytics.trackFormatSelected(format: newFormat, cardType: card.type)
                Task { await renderCard() }
            }
            .alert(Strings.Common.error, isPresented: $showingError) {
                Button(Strings.Common.ok) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .overlay {
                if showingSavedConfirmation {
                    savedConfirmationOverlay
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isRendering)
        .onDisappear {
            if !showingSavedConfirmation {
                ShareAnalytics.trackShareSheetDismissed(cardType: card.type)
            }
        }
    }

    // MARK: - Card Preview

    @ViewBuilder
    private var cardPreview: some View {
        Group {
            if let image = renderedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 350)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(height: 350)
                    .overlay {
                        ProgressView(Strings.Sharing.generating)
                    }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: renderedImage != nil)
    }

    // MARK: - Format Picker

    private var formatPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Sharing.format)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker(Strings.Sharing.format, selection: $selectedFormat) {
                Text(Strings.Sharing.formatStory).tag(ShareFormat.story)
                Text(Strings.Sharing.formatSquare).tag(ShareFormat.squarePost)
                Text(Strings.Sharing.formatPortrait).tag(ShareFormat.portrait)
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Quick Share Buttons

    private var quickShareButtons: some View {
        VStack(spacing: 16) {
            Text(Strings.Sharing.shareTo)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 24) {
                // Instagram Stories
                if shareService.isInstagramAvailable {
                    shareButton(
                        platform: .instagram,
                        label: Strings.Sharing.instagramStory,
                        action: shareToInstagram
                    )
                }

                // Facebook Stories
                if shareService.isFacebookAvailable {
                    shareButton(
                        platform: .facebook,
                        label: Strings.Sharing.facebookStory,
                        action: shareToFacebook
                    )
                }

                // Save to Photos
                shareButton(
                    icon: "square.and.arrow.down",
                    label: Strings.Sharing.save,
                    color: .green,
                    action: saveToPhotos
                )

                // More (share sheet)
                shareButton(
                    platform: .general,
                    label: Strings.Sharing.more,
                    action: showShareSheet
                )
            }
        }
    }

    private func shareButton(
        platform: SharePlatform,
        label: String,
        action: @escaping () async -> Void
    ) -> some View {
        shareButton(
            icon: platform.icon,
            label: label,
            color: platform.color,
            action: action
        )
    }

    private func shareButton(
        icon: String,
        label: String,
        color: Color,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .foregroundStyle(.white)
                    .clipShape(Circle())

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .disabled(renderedImage == nil)
    }

    // MARK: - Saved Confirmation

    private var savedConfirmationOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text(Strings.Sharing.savedToPhotos)
                .font(.headline)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Actions

    @MainActor
    private func renderCard() async {
        isRendering = true
        renderedImage = CardRenderer.shared.render(
            card.cardView(for: selectedFormat),
            for: selectedFormat
        )
        isRendering = false
    }

    private func shareToInstagram() async {
        guard let image = renderedImage else { return }
        ShareAnalytics.trackShareAttempt(cardType: card.type, platform: .instagram, format: selectedFormat)

        let success = await shareService.shareToInstagramStories(backgroundImage: image)
        if success {
            ShareAnalytics.trackShareCompleted(cardType: card.type, platform: .instagram, format: selectedFormat)
            dismiss()
        } else {
            ShareAnalytics.trackShareError(cardType: card.type, platform: .instagram, error: .platformNotAvailable)
            errorMessage = ShareError.platformNotAvailable.errorDescription
            showingError = true
        }
    }

    private func shareToFacebook() async {
        guard let image = renderedImage else { return }
        ShareAnalytics.trackShareAttempt(cardType: card.type, platform: .facebook, format: selectedFormat)

        let success = await shareService.shareToFacebookStories(backgroundImage: image)
        if success {
            ShareAnalytics.trackShareCompleted(cardType: card.type, platform: .facebook, format: selectedFormat)
            dismiss()
        } else {
            ShareAnalytics.trackShareError(cardType: card.type, platform: .facebook, error: .platformNotAvailable)
            errorMessage = ShareError.platformNotAvailable.errorDescription
            showingError = true
        }
    }

    private func saveToPhotos() async {
        guard let image = renderedImage else { return }
        ShareAnalytics.trackShareAttempt(cardType: card.type, platform: .general, format: selectedFormat)

        do {
            try await shareService.saveToPhotos(image)
            ShareAnalytics.trackSaveToPhotos(cardType: card.type, format: selectedFormat)

            withAnimation {
                showingSavedConfirmation = true
            }

            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
        } catch let error as ShareError {
            ShareAnalytics.trackShareError(cardType: card.type, platform: nil, error: error)
            errorMessage = error.errorDescription
            showingError = true
        } catch {
            let shareError = ShareError.unknown(error)
            ShareAnalytics.trackShareError(cardType: card.type, platform: nil, error: shareError)
            errorMessage = shareError.errorDescription
            showingError = true
        }
    }

    @MainActor
    private func showShareSheet() async {
        guard let image = renderedImage,
              let viewController = getRootViewController() else { return }

        ShareAnalytics.trackShareAttempt(cardType: card.type, platform: .general, format: selectedFormat)

        let caption = CaptionGenerator().generate(for: card, platform: .general)
        shareService.share(image: image, caption: caption, from: viewController)

        // We can't know if user completed the share, so just track attempt
        ShareAnalytics.trackShareCompleted(cardType: card.type, platform: .general, format: selectedFormat)
    }

    @MainActor
    private func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController.presentedViewController ?? rootViewController
    }
}

// MARK: - Simple Share Sheet

/// Simple share sheet for direct image sharing without format options
struct SimpleShareSheet: View {
    let image: UIImage
    let caption: String?

    @State private var shareService = ShareService()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 8)

                HStack(spacing: 24) {
                    if shareService.isInstagramAvailable {
                        quickButton(
                            icon: "camera.fill",
                            label: "IG Story",
                            color: .purple
                        ) {
                            Task {
                                if await shareService.shareToInstagramStories(backgroundImage: image) {
                                    dismiss()
                                }
                            }
                        }
                    }

                    quickButton(
                        icon: "square.and.arrow.down",
                        label: Strings.Sharing.save,
                        color: .green
                    ) {
                        Task {
                            try? await shareService.saveToPhotos(image)
                            dismiss()
                        }
                    }

                    quickButton(
                        icon: "square.and.arrow.up",
                        label: Strings.Sharing.more,
                        color: .secondary
                    ) {
                        if let vc = getRootViewController() {
                            shareService.share(image: image, caption: caption, from: vc)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle(Strings.Sharing.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func quickButton(
        icon: String,
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .foregroundStyle(.white)
                    .clipShape(Circle())

                Text(label)
                    .font(.caption)
            }
        }
    }

    @MainActor
    private func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController.presentedViewController ?? rootViewController
    }
}
