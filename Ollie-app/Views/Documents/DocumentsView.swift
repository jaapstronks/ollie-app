//
//  DocumentsView.swift
//  Ollie-app
//
//  Main view for managing dog documents

import SwiftUI
import OllieShared

/// Main view for listing and managing documents
struct DocumentsView: View {
    @ObservedObject var documentStore: DocumentStore

    @State private var showingAddSheet = false
    @State private var documentToDelete: Document?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Group {
            if documentStore.documents.isEmpty {
                emptyState
            } else {
                documentList
            }
        }
        .navigationTitle(Strings.Documents.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddDocumentSheet(documentStore: documentStore)
        }
        .alert(
            Strings.Documents.deleteConfirmTitle,
            isPresented: $showingDeleteConfirmation,
            presenting: documentToDelete
        ) { document in
            Button(Strings.Common.cancel, role: .cancel) {
                documentToDelete = nil
            }
            Button(Strings.Common.delete, role: .destructive) {
                documentStore.deleteDocument(document)
                documentToDelete = nil
            }
        } message: { _ in
            Text(Strings.Documents.deleteConfirmMessage)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        ContentUnavailableView {
            Label(Strings.Documents.noDocuments, systemImage: "doc.text")
        } description: {
            Text(Strings.Documents.noDocumentsHint)
        } actions: {
            Button {
                showingAddSheet = true
            } label: {
                Text(Strings.Documents.addDocument)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Document List

    @ViewBuilder
    private var documentList: some View {
        List {
            // Group by document type
            ForEach(groupedDocumentTypes, id: \.self) { type in
                Section(type.displayName) {
                    ForEach(documentsForType(type)) { document in
                        NavigationLink {
                            DocumentDetailView(
                                document: document,
                                documentStore: documentStore
                            )
                        } label: {
                            DocumentRow(
                                document: document,
                                documentStore: documentStore
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                documentToDelete = document
                                showingDeleteConfirmation = true
                            } label: {
                                Label(Strings.Common.delete, systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Helpers

    /// Document types that have at least one document, sorted by display name
    private var groupedDocumentTypes: [DocumentType] {
        let typesWithDocuments = Set(documentStore.documents.map { $0.type })
        return DocumentType.allCases.filter { typesWithDocuments.contains($0) }
    }

    /// Documents for a specific type, sorted by creation date
    private func documentsForType(_ type: DocumentType) -> [Document] {
        documentStore.documents
            .filter { $0.type == type }
            .sorted { $0.createdAt > $1.createdAt }
    }
}

#Preview {
    NavigationStack {
        DocumentsView(documentStore: DocumentStore())
    }
}
