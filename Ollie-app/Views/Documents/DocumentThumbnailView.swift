//
//  DocumentThumbnailView.swift
//  Ollie-app
//
//  Displays a document thumbnail with async loading from DocumentStore

import SwiftUI
import OllieShared

/// Async thumbnail view for documents
struct DocumentThumbnailView: View {
    let document: Document
    let size: CGFloat
    @ObservedObject var documentStore: DocumentStore

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(alignment: .bottomTrailing) {
                        // Show PDF badge for PDF documents
                        if document.hasPDF {
                            Text("PDF")
                                .font(.system(size: max(8, size * 0.15)))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(.red, in: RoundedRectangle(cornerRadius: 3))
                                .padding(4)
                        }
                    }
            } else {
                // Placeholder with document type icon
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: document.type.icon)
                            .font(.system(size: size * 0.4))
                            .foregroundColor(.secondary)
                    }
            }
        }
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard document.hasAttachment else { return }
        self.image = documentStore.loadThumbnail(for: document)
    }
}

#Preview {
    HStack(spacing: 16) {
        DocumentThumbnailView(
            document: Document(type: .passport),
            size: 60,
            documentStore: DocumentStore()
        )
        DocumentThumbnailView(
            document: Document(type: .vaccination),
            size: 60,
            documentStore: DocumentStore()
        )
        DocumentThumbnailView(
            document: Document(type: .insurance),
            size: 60,
            documentStore: DocumentStore()
        )
    }
    .padding()
}
