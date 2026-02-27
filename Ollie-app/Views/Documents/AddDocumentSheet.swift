//
//  AddDocumentSheet.swift
//  Ollie-app
//
//  Sheet for adding or editing a document

import SwiftUI
import OllieShared

/// Sheet for adding or editing a document
struct AddDocumentSheet: View {
    @ObservedObject var documentStore: DocumentStore
    var existingDocument: Document?

    @Environment(\.dismiss) private var dismiss

    @State private var documentType: DocumentType = .other
    @State private var customTitle: String = ""
    @State private var documentDate: Date = Date()
    @State private var hasDocumentDate: Bool = false
    @State private var hasExpiry: Bool = false
    @State private var expiryDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var notes: String = ""
    @State private var selectedImage: UIImage?
    @State private var imageWasChanged: Bool = false
    @State private var imageWasRemoved: Bool = false

    @State private var isSaving = false

    private var isEditing: Bool {
        existingDocument != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                // Photo section
                Section(Strings.Documents.photo) {
                    MediaAttachmentButton(
                        selectedImage: $selectedImage,
                        onImageSelected: { image, _ in
                            selectedImage = image
                            imageWasChanged = true
                            imageWasRemoved = false
                        }
                    )
                    .onChange(of: selectedImage) { oldValue, newValue in
                        // Track if image was removed (had image, now nil)
                        if oldValue != nil && newValue == nil {
                            imageWasRemoved = true
                            imageWasChanged = true
                        }
                    }
                }

                // Type section
                Section(Strings.Documents.documentType) {
                    Picker(Strings.Documents.documentType, selection: $documentType) {
                        ForEach(DocumentType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                // Details section
                Section {
                    TextField(Strings.Documents.customTitlePlaceholder, text: $customTitle)
                } header: {
                    Text(Strings.Documents.customTitle)
                } footer: {
                    Text(Strings.Documents.titleHint)
                }

                // Dates section
                Section {
                    Toggle(isOn: $hasDocumentDate.animation()) {
                        Text(Strings.Documents.documentDate)
                    }

                    if hasDocumentDate {
                        DatePicker(
                            Strings.Documents.documentDate,
                            selection: $documentDate,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
                }

                Section {
                    Toggle(isOn: $hasExpiry.animation()) {
                        Text(Strings.Documents.hasExpiry)
                    }

                    if hasExpiry {
                        DatePicker(
                            Strings.Documents.expiryDate,
                            selection: $expiryDate,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
                }

                // Notes section
                Section(Strings.Documents.notes) {
                    TextField(Strings.Documents.notesPlaceholder, text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? Strings.Documents.editDocument : Strings.Documents.addDocument)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        saveDocument()
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear {
                loadExistingDocument()
            }
        }
    }

    // MARK: - Load Existing Document

    private func loadExistingDocument() {
        guard let document = existingDocument else { return }

        documentType = document.type
        customTitle = document.title ?? ""
        hasDocumentDate = document.documentDate != nil
        if let date = document.documentDate {
            documentDate = date
        }
        hasExpiry = document.expiryDate != nil
        if let expiry = document.expiryDate {
            expiryDate = expiry
        }
        notes = document.note ?? ""

        // Load existing image from DocumentStore
        if document.hasImage {
            selectedImage = documentStore.loadImage(for: document)
        }
    }

    // MARK: - Save

    private func saveDocument() {
        isSaving = true

        let document = Document(
            id: existingDocument?.id ?? UUID(),
            type: documentType,
            title: customTitle.isEmpty ? nil : customTitle,
            note: notes.isEmpty ? nil : notes,
            hasImage: selectedImage != nil,
            documentDate: hasDocumentDate ? documentDate : nil,
            expiryDate: hasExpiry ? expiryDate : nil,
            createdAt: existingDocument?.createdAt ?? Date(),
            modifiedAt: Date()
        )

        if isEditing {
            // Update existing document
            if imageWasRemoved {
                // Image was explicitly removed
                documentStore.updateDocument(document, image: nil, removeImage: true)
            } else if imageWasChanged, let image = selectedImage {
                // New image was selected
                documentStore.updateDocument(document, image: image)
            } else {
                // Just metadata update, keep existing image
                documentStore.updateDocument(document)
            }
        } else {
            // New document
            documentStore.addDocument(document, image: selectedImage)
        }

        dismiss()
    }
}

#Preview {
    AddDocumentSheet(documentStore: DocumentStore())
}
