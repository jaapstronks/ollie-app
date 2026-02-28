//
//  ImageCropView.swift
//  Ollie-app
//
//  Circular image crop view with pan and zoom gestures

import SwiftUI
import UIKit

/// A view that allows users to pan and zoom an image within a circular crop area
struct ImageCropView: View {
    let image: UIImage
    let onConfirm: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let cropSize: CGFloat = 280
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 4.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(Strings.Common.cancel) {
                            onCancel()
                        }
                        .foregroundStyle(.white)

                        Spacer()

                        Text(Strings.Profile.adjustPhoto)
                            .font(.headline)
                            .foregroundStyle(.white)

                        Spacer()

                        Button(Strings.Common.done) {
                            let croppedImage = cropImage(in: geometry)
                            onConfirm(croppedImage)
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    }
                    .padding()

                    Spacer()

                    // Crop area
                    ZStack {
                        // Image with gestures
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: imageDisplaySize.width, height: imageDisplaySize.height)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let newScale = lastScale * value
                                            scale = min(max(newScale, minScale), maxScale)
                                        }
                                        .onEnded { _ in
                                            lastScale = scale
                                            constrainOffset()
                                        },
                                    DragGesture()
                                        .onChanged { value in
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                            constrainOffset()
                                        }
                                )
                            )

                        // Overlay with circular cutout
                        CropOverlay(cropSize: cropSize)
                            .allowsHitTesting(false)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .clipped()

                    Spacer()

                    // Hint text
                    Text(Strings.Profile.cropHint)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            // Initialize scale to fill the crop area
            initializeScale()
        }
    }

    /// The size to display the image at before any transformations
    private var imageDisplaySize: CGSize {
        let imageAspect = image.size.width / image.size.height

        // Calculate size that will cover the crop area
        if imageAspect > 1 {
            // Landscape: height matches crop, width extends
            return CGSize(width: cropSize * imageAspect, height: cropSize)
        } else {
            // Portrait or square: width matches crop, height extends
            return CGSize(width: cropSize, height: cropSize / imageAspect)
        }
    }

    /// Initialize scale so the image fills the crop circle
    private func initializeScale() {
        let imageAspect = image.size.width / image.size.height

        // Ensure the smaller dimension fills the crop area
        if imageAspect > 1 {
            // Landscape image: height is the smaller dimension
            scale = 1.0
        } else {
            // Portrait image: width is the smaller dimension
            scale = 1.0
        }
        lastScale = scale
    }

    /// Constrain offset to keep image covering the crop area
    private func constrainOffset() {
        let scaledWidth = imageDisplaySize.width * scale
        let scaledHeight = imageDisplaySize.height * scale

        let maxOffsetX = max(0, (scaledWidth - cropSize) / 2)
        let maxOffsetY = max(0, (scaledHeight - cropSize) / 2)

        withAnimation(.easeOut(duration: 0.2)) {
            offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
            offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)
            lastOffset = offset
        }
    }

    /// Crop the image based on current scale and offset
    private func cropImage(in geometry: GeometryProxy) -> UIImage {
        let imageSize = image.size
        let displaySize = imageDisplaySize

        // Calculate the scale factor from display to actual image
        let displayToImageScale = imageSize.width / displaySize.width

        // Calculate the visible crop area in display coordinates
        // The crop area is centered in the view
        let cropCenterInDisplay = CGPoint(x: 0, y: 0)

        // Adjust for current offset and scale
        // When offset is positive, the image moved right/down, so crop area is left/up in image
        let adjustedCenterX = (cropCenterInDisplay.x - offset.width) / scale
        let adjustedCenterY = (cropCenterInDisplay.y - offset.height) / scale

        // Calculate the crop rect in display coordinates
        let cropSizeInDisplay = cropSize / scale
        let cropRectInDisplay = CGRect(
            x: (displaySize.width / 2) + adjustedCenterX - (cropSizeInDisplay / 2),
            y: (displaySize.height / 2) + adjustedCenterY - (cropSizeInDisplay / 2),
            width: cropSizeInDisplay,
            height: cropSizeInDisplay
        )

        // Convert to image coordinates
        let cropRectInImage = CGRect(
            x: cropRectInDisplay.origin.x * displayToImageScale,
            y: cropRectInDisplay.origin.y * displayToImageScale,
            width: cropRectInDisplay.width * displayToImageScale,
            height: cropRectInDisplay.height * displayToImageScale
        )

        // Perform the crop
        guard let cgImage = image.cgImage?.cropping(to: cropRectInImage) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

/// Overlay with a circular transparent cutout
private struct CropOverlay: View {
    let cropSize: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent overlay
                Rectangle()
                    .fill(Color.black.opacity(0.6))

                // Circular cutout
                Circle()
                    .frame(width: cropSize, height: cropSize)
                    .blendMode(.destinationOut)

                // Circle border
                Circle()
                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
                    .frame(width: cropSize, height: cropSize)
            }
            .compositingGroup()
        }
    }
}

#Preview {
    ImageCropView(
        image: UIImage(systemName: "photo")!,
        onConfirm: { _ in },
        onCancel: {}
    )
}
