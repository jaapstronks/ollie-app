//
//  AddDocumentSheet.swift
//  Ollie-app
//
//  Sheet for adding or editing a document

import SwiftUI
import OllieShared
import UniformTypeIdentifiers
import PDFKit

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
    @State private var insuranceAgency: String = ""
    @State private var selectedImage: UIImage?
    @State private var selectedPDFData: Data?
    @State private var attachmentType: AttachmentType = .none
    @State private var attachmentWasChanged: Bool = false
    @State private var attachmentWasRemoved: Bool = false

    @State private var isSaving = false

    private var isEditing: Bool {
        existingDocument != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                // Attachment section (photo or PDF)
                Section(Strings.Documents.attachment) {
                    if attachmentType == .pdf, let pdfData = selectedPDFData {
                        // Show PDF preview with remove option
                        HStack {
                            PDFThumbnailPreview(pdfData: pdfData)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(Strings.Documents.pdfDocument)
                                    .font(.subheadline)
                                if let pageCount = PDFDocument(data: pdfData)?.pageCount {
                                    Text(Strings.Documents.pageCount(pageCount))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Button {
                                withAnimation {
                                    selectedPDFData = nil
                                    attachmentType = .none
                                    attachmentWasRemoved = true
                                    attachmentWasChanged = true
                                }
                            } label: {
                                Label(Strings.MediaAttachment.remove, systemImage: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        MediaAttachmentButton(
                            selectedImage: $selectedImage,
                            onImageSelected: { image, _ in
                                selectedImage = image
                                selectedPDFData = nil
                                attachmentType = .image
                                attachmentWasChanged = true
                                attachmentWasRemoved = false
                            },
                            onFileSelected: { data, fileType in
                                if fileType == .pdf {
                                    selectedPDFData = data
                                    selectedImage = nil
                                    attachmentType = .pdf
                                    attachmentWasChanged = true
                                    attachmentWasRemoved = false
                                }
                            },
                            showFilesOption: true,
                            buttonLabel: Strings.Documents.addAttachment,
                            buttonIcon: "paperclip",
                            dialogTitle: Strings.Documents.addAttachmentTitle
                        )
                        .onChange(of: selectedImage) { oldValue, newValue in
                            // Track if image was removed (had image, now nil)
                            if oldValue != nil && newValue == nil && attachmentType == .image {
                                attachmentWasRemoved = true
                                attachmentWasChanged = true
                                attachmentType = .none
                            }
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

                // Insurance-specific field
                if documentType == .insurance {
                    Section(Strings.Documents.insuranceAgency) {
                        TextField(Strings.Documents.insuranceAgencyPlaceholder, text: $insuranceAgency)
                    }
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
        insuranceAgency = document.insuranceAgency ?? ""
        attachmentType = document.attachmentType

        // Load existing attachment from DocumentStore
        switch document.attachmentType {
        case .image:
            selectedImage = documentStore.loadImage(for: document)
        case .pdf:
            selectedPDFData = documentStore.loadPDFData(for: document)
        case .none:
            break
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
            insuranceAgency: insuranceAgency.isEmpty ? nil : insuranceAgency,
            attachmentType: attachmentType,
            documentDate: hasDocumentDate ? documentDate : nil,
            expiryDate: hasExpiry ? expiryDate : nil,
            createdAt: existingDocument?.createdAt ?? Date(),
            modifiedAt: Date()
        )

        if isEditing {
            // Update existing document
            if attachmentWasRemoved {
                // Attachment was explicitly removed
                documentStore.updateDocument(document, image: nil, removeAttachment: true)
            } else if attachmentWasChanged {
                // New attachment was selected
                switch attachmentType {
                case .image:
                    documentStore.updateDocument(document, image: selectedImage)
                case .pdf:
                    documentStore.updateDocument(document, pdfData: selectedPDFData)
                case .none:
                    documentStore.updateDocument(document, image: nil, removeAttachment: true)
                }
            } else {
                // Just metadata update, keep existing attachment
                documentStore.updateDocument(document)
            }
        } else {
            // New document
            switch attachmentType {
            case .image:
                documentStore.addDocument(document, image: selectedImage)
            case .pdf:
                documentStore.addDocument(document, pdfData: selectedPDFData)
            case .none:
                documentStore.addDocument(document)
            }
        }

        dismiss()
    }
}

// MARK: - PDF Thumbnail Preview

private struct PDFThumbnailPreview: View {
    let pdfData: Data

    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay {
                        Image(systemName: "doc.fill")
                            .foregroundColor(.secondary)
                    }
            }
        }
        .task {
            thumbnail = generateThumbnail()
        }
    }

    private func generateThumbnail() -> UIImage? {
        guard let pdfDocument = PDFDocument(data: pdfData),
              let page = pdfDocument.page(at: 0) else {
            return nil
        }

        let pageRect = page.bounds(for: .mediaBox)
        let scale: CGFloat = 200 / max(pageRect.width, pageRect.height)
        let scaledSize = CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: scaledSize))

            context.cgContext.translateBy(x: 0, y: scaledSize.height)
            context.cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: context.cgContext)
        }
    }
}

#Preview {
    AddDocumentSheet(documentStore: DocumentStore())
}
