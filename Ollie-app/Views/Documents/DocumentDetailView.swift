//
//  DocumentDetailView.swift
//  Ollie-app
//
//  Detail view for viewing and editing a document

import SwiftUI
import OllieShared

/// Detail view for a document
struct DocumentDetailView: View {
    let document: Document
    @ObservedObject var documentStore: DocumentStore

    @Environment(\.dismiss) private var dismiss

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingFullImage = false
    @State private var fullImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image section
                imageSection

                // Details card
                detailsCard

                // Notes section
                if let note = document.note, !note.isEmpty {
                    notesCard(note)
                }
            }
            .padding()
        }
        .navigationTitle(document.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label(Strings.Common.edit, systemImage: "pencil")
                    }

                    if document.hasImage, let image = fullImage {
                        ShareLink(
                            item: Image(uiImage: image),
                            preview: SharePreview(document.displayTitle, image: Image(uiImage: image))
                        ) {
                            Label(Strings.Documents.share, systemImage: "square.and.arrow.up")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label(Strings.Common.delete, systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddDocumentSheet(
                documentStore: documentStore,
                existingDocument: document
            )
        }
        .fullScreenCover(isPresented: $showingFullImage) {
            fullImageView
        }
        .alert(
            Strings.Documents.deleteConfirmTitle,
            isPresented: $showingDeleteConfirmation
        ) {
            Button(Strings.Common.cancel, role: .cancel) {}
            Button(Strings.Common.delete, role: .destructive) {
                documentStore.deleteDocument(document)
                dismiss()
            }
        } message: {
            Text(Strings.Documents.deleteConfirmMessage)
        }
        .task {
            // Load full image on appear for share functionality
            await loadFullImage()
        }
    }

    // MARK: - Image Section

    @ViewBuilder
    private var imageSection: some View {
        if document.hasImage {
            AsyncDocumentImageLoader(
                document: document,
                documentStore: documentStore
            )
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
            .onTapGesture {
                showingFullImage = true
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showingFullImage = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .padding(8)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(12)
            }
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(height: 200)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: document.type.icon)
                            .font(.system(size: 48))
                        Text(Strings.Documents.photo)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
        }
    }

    // MARK: - Details Card

    @ViewBuilder
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Document type
            detailRow(
                icon: document.type.icon,
                title: Strings.Documents.documentType,
                value: document.type.displayName
            )

            if let date = document.documentDate {
                Divider()
                detailRow(
                    icon: "calendar",
                    title: Strings.Documents.documentDate,
                    value: date.formatted(date: .long, time: .omitted)
                )
            }

            if let expiry = document.expiryDate {
                Divider()
                expiryRow(expiry: expiry)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    @ViewBuilder
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.ollieAccent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
        }
    }

    @ViewBuilder
    private func expiryRow(expiry: Date) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.exclamationmark")
                .foregroundColor(expiryColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Documents.expiryDate)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text(expiry.formatted(date: .long, time: .omitted))
                        .font(.body)

                    if document.isExpired {
                        Text(Strings.Documents.expired)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.red, in: Capsule())
                    } else if document.expiresSoon {
                        Text(Strings.Documents.expiresSoon)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.orange, in: Capsule())
                    }
                }
            }
        }
    }

    private var expiryColor: Color {
        if document.isExpired {
            return .red
        } else if document.expiresSoon {
            return .orange
        }
        return .ollieAccent
    }

    // MARK: - Notes Card

    @ViewBuilder
    private func notesCard(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(Strings.Documents.notes, systemImage: "note.text")
                .font(.headline)

            Text(note)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Full Image View

    @ViewBuilder
    private var fullImageView: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let image = fullImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        showingFullImage = false
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func loadFullImage() async {
        guard document.hasImage else { return }
        self.fullImage = documentStore.loadImage(for: document)
    }
}

// MARK: - Async Document Image Loader

private struct AsyncDocumentImageLoader: View {
    let document: Document
    @ObservedObject var documentStore: DocumentStore

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .task {
            image = documentStore.loadImage(for: document)
        }
    }
}

#Preview {
    NavigationStack {
        DocumentDetailView(
            document: Document(
                type: .passport,
                title: "EU Pet Passport",
                note: "This is the official EU pet passport with all vaccination records.",
                hasImage: true,
                documentDate: Date(),
                expiryDate: Calendar.current.date(byAdding: .day, value: 25, to: Date())
            ),
            documentStore: DocumentStore()
        )
    }
}
