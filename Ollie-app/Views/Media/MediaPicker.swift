//
//  MediaPicker.swift
//  Otis-app
//

import SwiftUI
import OtisShared
@preconcurrency import PhotosUI
import UIKit
import UniformTypeIdentifiers

enum MediaPickerSource {
    case camera
    case library
    case files
}

/// SwiftUI wrapper for camera, photo library, and document picker
struct MediaPicker: UIViewControllerRepresentable {
    let source: MediaPickerSource
    let onImageSelected: (UIImage, Data?) -> Void
    let onFileSelected: ((Data, UTType) -> Void)?
    let onCancel: () -> Void

    init(
        source: MediaPickerSource,
        onImageSelected: @escaping (UIImage, Data?) -> Void,
        onFileSelected: ((Data, UTType) -> Void)? = nil,
        onCancel: @escaping () -> Void
    ) {
        self.source = source
        self.onImageSelected = onImageSelected
        self.onFileSelected = onFileSelected
        self.onCancel = onCancel
    }

    func makeUIViewController(context: Context) -> UIViewController {
        switch source {
        case .camera:
            return makeCameraController(context: context)
        case .library:
            return makeLibraryController(context: context)
        case .files:
            return makeDocumentController(context: context)
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected, onFileSelected: onFileSelected, onCancel: onCancel)
    }

    // MARK: - Camera

    private func makeCameraController(context: Context) -> UIViewController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    // MARK: - Library

    private func makeLibraryController(context: Context) -> UIViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    // MARK: - Document Picker (Files)

    private func makeDocumentController(context: Context) -> UIViewController {
        let supportedTypes: [UTType] = [.pdf, .jpeg, .png, .heic]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate, UIDocumentPickerDelegate {
        let onImageSelected: (UIImage, Data?) -> Void
        let onFileSelected: ((Data, UTType) -> Void)?
        let onCancel: () -> Void

        /// Maximum file size: 50 MB
        private let maxFileSize = 50 * 1024 * 1024

        init(
            onImageSelected: @escaping (UIImage, Data?) -> Void,
            onFileSelected: ((Data, UTType) -> Void)?,
            onCancel: @escaping () -> Void
        ) {
            self.onImageSelected = onImageSelected
            self.onFileSelected = onFileSelected
            self.onCancel = onCancel
        }

        // UIImagePickerController delegate (camera)
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                // Camera doesn't provide original data, so pass nil
                onImageSelected(image, nil)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }

        // PHPickerViewController delegate (library)
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                onCancel()
                return
            }

            let itemProvider = result.itemProvider

            Task { @MainActor [weak self] in
                guard let self = self else { return }

                // Try to get original data for EXIF extraction
                if let data = try? await self.loadData(from: itemProvider),
                   let image = UIImage(data: data) {
                    self.onImageSelected(image, data)
                    return
                }

                // Fallback: load as UIImage without data
                if let image = try? await self.loadImage(from: itemProvider) {
                    self.onImageSelected(image, nil)
                }
            }
        }

        // Bridge completion handler APIs to async/await
        private nonisolated func loadData(from itemProvider: NSItemProvider) async throws -> Data {
            try await withCheckedThrowingContinuation { continuation in
                itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let data = data {
                        continuation.resume(returning: data)
                    } else {
                        continuation.resume(throwing: NSError(domain: "MediaPicker", code: -1))
                    }
                }
            }
        }

        private nonisolated func loadImage(from itemProvider: NSItemProvider) async throws -> UIImage {
            try await withCheckedThrowingContinuation { continuation in
                itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let image = object as? UIImage {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: NSError(domain: "MediaPicker", code: -1))
                    }
                }
            }
        }

        // UIDocumentPickerDelegate (files)
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                onCancel()
                return
            }

            // Security-scoped access for files from other apps
            guard url.startAccessingSecurityScopedResource() else {
                onCancel()
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)

                // Check file size
                guard data.count <= maxFileSize else {
                    // File too large - cancel silently (UI will show error)
                    onCancel()
                    return
                }

                // Determine file type
                let fileType: UTType
                if let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
                   let utType = UTType(typeIdentifier) {
                    fileType = utType
                } else if url.pathExtension.lowercased() == "pdf" {
                    fileType = .pdf
                } else {
                    fileType = .data
                }

                // Handle based on file type
                if fileType.conforms(to: .pdf) {
                    onFileSelected?(data, .pdf)
                } else if fileType.conforms(to: .image), let image = UIImage(data: data) {
                    onImageSelected(image, data)
                } else {
                    onCancel()
                }
            } catch {
                onCancel()
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }
    }
}

#Preview {
    Text("Media Picker")
}
