//
//  LogMomentSheet.swift
//  Ollie-app
//

import SwiftUI

/// Photo-first logging sheet: shows preview + extracted date/location + optional note
struct LogMomentSheet: View {
    @ObservedObject var viewModel: MediaCaptureViewModel
    let onSave: (PuppyEvent) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNoteFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo preview
                    if let image = viewModel.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 4)
                    }

                    // Extracted metadata
                    VStack(spacing: 12) {
                        // Date
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                            if let date = viewModel.extractedDate {
                                VStack(alignment: .leading) {
                                    Text(Strings.LogMoment.dateFromPhoto)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(date.formatted(date: .long, time: .shortened))
                                        .font(.body)
                                }
                            } else {
                                VStack(alignment: .leading) {
                                    Text(Strings.LogMoment.date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(Date().formatted(date: .long, time: .shortened))
                                        .font(.body)
                                    Text(Strings.LogMoment.nowNoDateInPhoto)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        // Location (if available)
                        if let lat = viewModel.extractedLatitude,
                           let lon = viewModel.extractedLongitude {
                            HStack {
                                Image(systemName: "location")
                                    .foregroundColor(.secondary)
                                VStack(alignment: .leading) {
                                    Text(Strings.LogMoment.locationFromPhoto)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.4f, %.4f", lat, lon))
                                        .font(.body)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }

                    // Note input
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.LogMoment.note)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField(Strings.LogMoment.whatHappened, text: $viewModel.note, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                            .focused($isNoteFocused)
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle(Strings.LogMoment.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        saveEvent()
                    }
                    .disabled(viewModel.capturedImage == nil || viewModel.isProcessing)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(Strings.Common.done) {
                        isNoteFocused = false
                    }
                }
            }
        }
    }

    private func saveEvent() {
        guard let event = viewModel.createEvent() else { return }
        onSave(event)
        dismiss()
    }
}

#Preview {
    LogMomentSheet(
        viewModel: MediaCaptureViewModel(mediaStore: MediaStore()),
        onSave: { _ in },
        onCancel: { }
    )
}
