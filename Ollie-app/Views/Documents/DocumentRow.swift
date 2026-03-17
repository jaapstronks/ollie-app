//
//  DocumentRow.swift
//  Otis-app
//
//  Row component for displaying a document in a list

import SwiftUI
import OtisShared

/// Row view for displaying a document in a list
struct DocumentRow: View {
    let document: Document
    var documentStore: DocumentStore

    private let thumbnailSize: CGFloat = 60

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            DocumentThumbnailView(
                document: document,
                size: thumbnailSize,
                documentStore: documentStore
            )

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(document.displayTitle)
                    .font(.headline)
                    .lineLimit(1)

                // Type label (if custom title is set)
                if document.title != nil {
                    Label(document.type.displayName, systemImage: document.type.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Expiry badge
                if document.isExpired {
                    expiryBadge(text: Strings.Documents.expired, color: .red)
                } else if document.expiresSoon {
                    expiryBadge(text: Strings.Documents.expiresSoon, color: .orange)
                } else if let days = document.daysUntilExpiry, days <= 60 {
                    Text(Strings.Documents.expiresIn(days))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func expiryBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color, in: Capsule())
    }
}

#Preview {
    List {
        DocumentRow(
            document: Document(
                type: .passport,
                title: "EU Pet Passport",
                expiryDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())
            ),
            documentStore: DocumentStore()
        )

        DocumentRow(
            document: Document(
                type: .vaccination,
                expiryDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())
            ),
            documentStore: DocumentStore()
        )

        DocumentRow(
            document: Document(
                type: .insurance,
                title: "Petplan Policy"
            ),
            documentStore: DocumentStore()
        )

        DocumentRow(
            document: Document(type: .chipRegistration),
            documentStore: DocumentStore()
        )
    }
}
