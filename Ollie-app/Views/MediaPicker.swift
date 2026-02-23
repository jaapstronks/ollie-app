//
//  MediaPicker.swift
//  Ollie-app
//

import SwiftUI
import PhotosUI
import UIKit

enum MediaPickerSource {
    case camera
    case library
}

/// SwiftUI wrapper for camera and photo library picker
struct MediaPicker: UIViewControllerRepresentable {
    let source: MediaPickerSource
    let onImageSelected: (UIImage, Data?) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        switch source {
        case .camera:
            return makeCameraController(context: context)
        case .library:
            return makeLibraryController(context: context)
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected, onCancel: onCancel)
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

    // MARK: - Coordinator

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
        let onImageSelected: (UIImage, Data?) -> Void
        let onCancel: () -> Void

        init(onImageSelected: @escaping (UIImage, Data?) -> Void, onCancel: @escaping () -> Void) {
            self.onImageSelected = onImageSelected
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

            // Try to get original data for EXIF extraction
            result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, error in
                DispatchQueue.main.async {
                    if let data = data, let image = UIImage(data: data) {
                        self?.onImageSelected(image, data)
                    } else {
                        // Fallback: load as UIImage without data
                        result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                            DispatchQueue.main.async {
                                if let image = object as? UIImage {
                                    self?.onImageSelected(image, nil)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    Text("Media Picker")
}
