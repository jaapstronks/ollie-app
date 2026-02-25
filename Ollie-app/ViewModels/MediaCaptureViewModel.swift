//
//  MediaCaptureViewModel.swift
//  Ollie-app
//

import Foundation
import OllieShared
import UIKit
import Combine

/// ViewModel for handling photo capture and EXIF extraction
@MainActor
class MediaCaptureViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var extractedDate: Date?
    @Published var extractedLatitude: Double?
    @Published var extractedLongitude: Double?
    @Published var note: String = ""
    @Published var isProcessing = false

    private let mediaStore: MediaStore

    init(mediaStore: MediaStore) {
        self.mediaStore = mediaStore
    }

    /// Process a captured/selected image and extract EXIF metadata
    func processImage(_ image: UIImage, originalData: Data?) {
        capturedImage = image

        // Extract EXIF metadata if we have original data
        if let data = originalData {
            let metadata = EXIFExtractor.extractMetadata(from: data)
            extractedDate = metadata.date
            extractedLatitude = metadata.latitude
            extractedLongitude = metadata.longitude
        } else {
            // No EXIF data available (e.g., camera capture)
            extractedDate = nil
            extractedLatitude = nil
            extractedLongitude = nil
        }
    }

    /// Create a PuppyEvent from the captured photo
    func createEvent() -> PuppyEvent? {
        guard let image = capturedImage else { return nil }

        isProcessing = true
        defer { isProcessing = false }

        // Save photo and thumbnail
        guard let paths = mediaStore.savePhoto(image) else {
            return nil
        }

        let eventTime = extractedDate ?? Date()

        return PuppyEvent(
            time: eventTime,
            type: .moment,
            note: note.isEmpty ? nil : note,
            photo: paths.photoPath,
            latitude: extractedLatitude,
            longitude: extractedLongitude,
            thumbnailPath: paths.thumbnailPath
        )
    }

    /// Reset the view model for a new capture
    func reset() {
        capturedImage = nil
        extractedDate = nil
        extractedLatitude = nil
        extractedLongitude = nil
        note = ""
        isProcessing = false
    }
}
