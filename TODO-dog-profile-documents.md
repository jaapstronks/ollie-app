# TODO: Dog Profile Documents

## Overview

Add a **Documents** feature to the existing dog profile, allowing users to store scans/photos of important dog documents: passport, chip registration, insurance policy, pedigree papers, vaccination records, etc.

The dog profile (`PuppyProfile` / `CDPuppyProfile`) already exists. This feature adds a new `CDDocument` Core Data entity with a one-to-many relationship from the profile, plus views for capturing, viewing, and managing documents.

## Architecture

### Data Layer

#### New Core Data Entity: `CDDocument`

Add to `Ollie.xcdatamodeld`:

```
Entity: CDDocument
Attributes:
  - id: UUID
  - title: String
  - documentType: String          // maps to DocumentType enum
  - notes: String?
  - imageFilename: String          // relative path in app documents dir
  - thumbnailFilename: String?     // smaller version for list views
  - createdAt: Date
  - updatedAt: Date
  - expirationDate: Date?          // e.g. insurance renewal, vaccination expiry

Relationships:
  - profile: CDPuppyProfile (inverse: documents, to-one)
```

Add inverse relationship on `CDPuppyProfile`:
```
  - documents: NSSet<CDDocument> (inverse: profile, to-many, cascade delete)
```

#### OllieShared Model: `DocumentType`

Add to `OllieShared/Sources/OllieShared/Models/`:

```swift
// DocumentType.swift
import Foundation

public enum DocumentType: String, CaseIterable, Codable, Identifiable {
    case passport = "passport"
    case chipRegistration = "chip_registration"
    case insurance = "insurance"
    case pedigree = "pedigree"
    case vaccination = "vaccination"
    case medicalRecord = "medical_record"
    case registration = "registration"       // e.g. municipality/RVO
    case trainingCertificate = "training_certificate"
    case other = "other"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .passport: return String(localized: "document.type.passport")
        case .chipRegistration: return String(localized: "document.type.chipRegistration")
        case .insurance: return String(localized: "document.type.insurance")
        case .pedigree: return String(localized: "document.type.pedigree")
        case .vaccination: return String(localized: "document.type.vaccination")
        case .medicalRecord: return String(localized: "document.type.medicalRecord")
        case .registration: return String(localized: "document.type.registration")
        case .trainingCertificate: return String(localized: "document.type.trainingCertificate")
        case .other: return String(localized: "document.type.other")
        }
    }

    public var systemImage: String {
        switch self {
        case .passport: return "book.closed"
        case .chipRegistration: return "cpu"
        case .insurance: return "shield.checkered"
        case .pedigree: return "scroll"
        case .vaccination: return "syringe"
        case .medicalRecord: return "cross.case"
        case .registration: return "building.columns"
        case .trainingCertificate: return "medal"
        case .other: return "doc"
        }
    }
}
```

#### OllieShared Model: `DogDocument`

```swift
// DogDocument.swift
import Foundation

public struct DogDocument: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var documentType: DocumentType
    public var notes: String?
    public var imageFilename: String
    public var thumbnailFilename: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var expirationDate: Date?

    public var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return expiration < Date()
    }

    public var isExpiringSoon: Bool {
        guard let expiration = expirationDate else { return false }
        let thirtyDays = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        return expiration < thirtyDays && !isExpired
    }

    public init(
        id: UUID = UUID(),
        title: String,
        documentType: DocumentType,
        notes: String? = nil,
        imageFilename: String,
        thumbnailFilename: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        expirationDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.documentType = documentType
        self.notes = notes
        self.imageFilename = imageFilename
        self.thumbnailFilename = thumbnailFilename
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.expirationDate = expirationDate
    }
}
```

### Image Storage

**Do NOT use CDN or cloud storage.** Store images locally in the app's documents directory:

```swift
// DocumentImageStore.swift
import UIKit

final class DocumentImageStore {
    static let shared = DocumentImageStore()

    private let fileManager = FileManager.default
    private let documentsDirectory: URL

    private init() {
        documentsDirectory = fileManager
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DogDocuments", isDirectory: true)

        try? fileManager.createDirectory(
            at: documentsDirectory,
            withIntermediateDirectories: true
        )
    }

    func save(image: UIImage, filename: String) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw DocumentError.imageConversionFailed
        }
        let url = documentsDirectory.appendingPathComponent(filename)
        try data.write(to: url)
        return filename
    }

    func saveThumbnail(image: UIImage, filename: String, maxSize: CGFloat = 200) throws -> String {
        let thumbnailFilename = "thumb_\(filename)"
        let ratio = min(maxSize / image.size.width, maxSize / image.size.height)
        let newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return try save(image: thumbnail, filename: thumbnailFilename)
    }

    func load(filename: String) -> UIImage? {
        let url = documentsDirectory.appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }

    func delete(filename: String) throws {
        let url = documentsDirectory.appendingPathComponent(filename)
        try fileManager.removeItem(at: url)
    }

    enum DocumentError: Error {
        case imageConversionFailed
    }
}
```

### CloudKit Sync Considerations

- The `DogDocuments/` directory should be included in the app's iCloud container if CloudKit is enabled
- For image sync: consider using `NSPersistentCloudKitContainer` which auto-syncs Core Data
- Images stored as external binary data in Core Data (`Allows External Storage` checkbox) will sync via CloudKit automatically
- **Alternative approach:** Store the image data as a `Binary Data` attribute on `CDDocument` with "Allows External Storage" enabled — Core Data manages file storage and CloudKit handles sync
- Max CloudKit asset size: 50MB per record (more than enough for document scans)

### ViewModel

```swift
// DocumentStore.swift
import Foundation
import CoreData
import SwiftUI

@MainActor
final class DocumentStore: ObservableObject {
    @Published var documents: [DogDocument] = []

    private let context: NSManagedObjectContext
    private let imageStore = DocumentImageStore.shared

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchDocuments()
    }

    func fetchDocuments() {
        let request = CDDocument.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDocument.createdAt, ascending: false)]

        do {
            let results = try context.fetch(request)
            documents = results.map { $0.toDogDocument() }
        } catch {
            print("Failed to fetch documents: \(error)")
        }
    }

    func addDocument(
        title: String,
        type: DocumentType,
        image: UIImage,
        notes: String?,
        expirationDate: Date?,
        profile: CDPuppyProfile
    ) throws {
        let id = UUID()
        let filename = "\(id.uuidString).jpg"

        let savedFilename = try imageStore.save(image: image, filename: filename)
        let thumbFilename = try imageStore.saveThumbnail(image: image, filename: filename)

        let entity = CDDocument(context: context)
        entity.id = id
        entity.title = title
        entity.documentType = type.rawValue
        entity.imageFilename = savedFilename
        entity.thumbnailFilename = thumbFilename
        entity.notes = notes
        entity.expirationDate = expirationDate
        entity.createdAt = Date()
        entity.updatedAt = Date()
        entity.profile = profile

        try context.save()
        fetchDocuments()
    }

    func deleteDocument(_ document: DogDocument) throws {
        try imageStore.delete(filename: document.imageFilename)
        if let thumb = document.thumbnailFilename {
            try? imageStore.delete(filename: thumb)
        }

        let request = CDDocument.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", document.id as CVarArg)
        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try context.save()
        }
        fetchDocuments()
    }
}
```

## Views

### View Hierarchy

```
DogProfileSettingsView (existing)
  └── Section: "Documents"
        ├── NavigationLink → DocumentsView
        └── Badge: count of expiring documents

DocumentsView
  ├── List grouped by DocumentType
  │     └── DocumentRow (thumbnail, title, type, expiration badge)
  ├── Empty state illustration
  ├── Toolbar: + button → AddDocumentSheet
  └── Swipe to delete

AddDocumentSheet
  ├── PhotosPicker / Camera button
  ├── Image preview + crop
  ├── TextField: title
  ├── Picker: DocumentType
  ├── DatePicker: expiration (optional)
  ├── TextEditor: notes (optional)
  └── Save button

DocumentDetailView
  ├── Full-size zoomable image (pinch to zoom)
  ├── Document metadata
  ├── Edit button → edit mode
  ├── Share button (ShareLink)
  └── Delete button
```

### Key View: DocumentsView

```swift
// DocumentsView.swift
import SwiftUI

struct DocumentsView: View {
    @StateObject private var store: DocumentStore
    @State private var showingAddSheet = false

    init(context: NSManagedObjectContext) {
        _store = StateObject(wrappedValue: DocumentStore(context: context))
    }

    var body: some View {
        Group {
            if store.documents.isEmpty {
                ContentUnavailableView(
                    String(localized: "documents.empty.title"),
                    systemImage: "doc.text.magnifyingglass",
                    description: Text(String(localized: "documents.empty.description"))
                )
            } else {
                List {
                    ForEach(groupedDocuments, id: \.key) { type, docs in
                        Section(type.displayName) {
                            ForEach(docs) { doc in
                                NavigationLink(value: doc) {
                                    DocumentRow(document: doc)
                                }
                            }
                            .onDelete { indexSet in
                                deleteDocuments(docs: docs, at: indexSet)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "documents.title"))
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
            AddDocumentSheet(store: store)
        }
        .navigationDestination(for: DogDocument.self) { doc in
            DocumentDetailView(document: doc, store: store)
        }
    }

    private var groupedDocuments: [(key: DocumentType, value: [DogDocument])] {
        Dictionary(grouping: store.documents) { doc in
            doc.documentType
        }
        .sorted { $0.key.displayName < $1.key.displayName }
    }

    private func deleteDocuments(docs: [DogDocument], at offsets: IndexSet) {
        for index in offsets {
            try? store.deleteDocument(docs[index])
        }
    }
}
```

### Key View: AddDocumentSheet

```swift
// AddDocumentSheet.swift
import SwiftUI
import PhotosUI

struct AddDocumentSheet: View {
    @ObservedObject var store: DocumentStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var documentType: DocumentType = .passport
    @State private var notes = ""
    @State private var expirationDate: Date?
    @State private var hasExpiration = false
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                // Image selection
                Section {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    HStack {
                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images
                        ) {
                            Label(String(localized: "documents.add.photoLibrary"), systemImage: "photo.on.rectangle")
                        }

                        Button {
                            showingCamera = true
                        } label: {
                            Label(String(localized: "documents.add.camera"), systemImage: "camera")
                        }
                    }
                }

                // Metadata
                Section {
                    TextField(String(localized: "documents.add.title"), text: $title)

                    Picker(String(localized: "documents.add.type"), selection: $documentType) {
                        ForEach(DocumentType.allCases) { type in
                            Label(type.displayName, systemImage: type.systemImage)
                                .tag(type)
                        }
                    }
                }

                // Expiration
                Section {
                    Toggle(String(localized: "documents.add.hasExpiration"), isOn: $hasExpiration)
                    if hasExpiration {
                        DatePicker(
                            String(localized: "documents.add.expirationDate"),
                            selection: Binding(
                                get: { expirationDate ?? Date() },
                                set: { expirationDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                }

                // Notes
                Section(String(localized: "documents.add.notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(String(localized: "documents.add.title.nav"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "general.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "general.save")) { save() }
                        .disabled(title.isEmpty || selectedImage == nil || isSaving)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(image: $selectedImage)
            }
        }
    }

    private func save() {
        guard let image = selectedImage else { return }
        isSaving = true

        Task {
            do {
                // Get current profile from Core Data
                let context = store.context
                let request = CDPuppyProfile.fetchRequest()
                guard let profile = try context.fetch(request).first else { return }

                try store.addDocument(
                    title: title,
                    type: documentType,
                    image: image,
                    notes: notes.isEmpty ? nil : notes,
                    expirationDate: hasExpiration ? expirationDate : nil,
                    profile: profile
                )
                dismiss()
            } catch {
                isSaving = false
            }
        }
    }
}
```

### Camera Integration

```swift
// CameraView.swift
import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
```

## File List

### New Files
| File | Location |
|------|----------|
| `DocumentType.swift` | `OllieShared/Sources/OllieShared/Models/` |
| `DogDocument.swift` | `OllieShared/Sources/OllieShared/Models/` |
| `DocumentStore.swift` | `Ollie/ViewModels/` |
| `DocumentImageStore.swift` | `Ollie/Services/` |
| `DocumentsView.swift` | `Ollie/Views/Documents/` |
| `AddDocumentSheet.swift` | `Ollie/Views/Documents/` |
| `DocumentDetailView.swift` | `Ollie/Views/Documents/` |
| `DocumentRow.swift` | `Ollie/Views/Documents/` |
| `CameraView.swift` | `Ollie/Views/Documents/` |

### Modified Files
| File | Change |
|------|--------|
| `Ollie.xcdatamodeld` | Add `CDDocument` entity + relationship on `CDPuppyProfile` |
| `DogProfileSettingsView.swift` | Add "Documents" section with NavigationLink |
| `Localizable.xcstrings` | Add all `documents.*` keys (en + nl) |
| `Strings.swift` | Add document-related string constants if used |

## Localization Keys

```
documents.title = "Documents" / "Documenten"
documents.empty.title = "No Documents" / "Geen documenten"
documents.empty.description = "Add your dog's important documents like passport, insurance, and vaccination records." / "Voeg belangrijke documenten toe zoals paspoort, verzekering en vaccinatiegegevens."
documents.add.title.nav = "Add Document" / "Document toevoegen"
documents.add.title = "Title" / "Titel"
documents.add.type = "Type" / "Type"
documents.add.photoLibrary = "Photo Library" / "Fotobibliotheek"
documents.add.camera = "Camera" / "Camera"
documents.add.hasExpiration = "Has expiration date" / "Heeft vervaldatum"
documents.add.expirationDate = "Expiration Date" / "Vervaldatum"
documents.add.notes = "Notes" / "Notities"
document.type.passport = "Passport" / "Paspoort"
document.type.chipRegistration = "Chip Registration" / "Chipregistratie"
document.type.insurance = "Insurance" / "Verzekering"
document.type.pedigree = "Pedigree" / "Stamboom"
document.type.vaccination = "Vaccination Record" / "Vaccinatiebewijs"
document.type.medicalRecord = "Medical Record" / "Medisch dossier"
document.type.registration = "Registration" / "Registratie"
document.type.trainingCertificate = "Training Certificate" / "Trainingscertificaat"
document.type.other = "Other" / "Overig"
document.expiring = "Expiring soon" / "Verloopt binnenkort"
document.expired = "Expired" / "Verlopen"
```

## Implementation Order

1. **Core Data model** — Add `CDDocument` entity and relationship
2. **OllieShared models** — `DocumentType` enum + `DogDocument` struct
3. **DocumentImageStore** — File storage service
4. **DocumentStore** — ViewModel with CRUD operations
5. **DocumentRow** — List row component
6. **DocumentsView** — Main list view
7. **CameraView** — Camera UIKit bridge
8. **AddDocumentSheet** — Creation form
9. **DocumentDetailView** — Full view with zoom + share
10. **Integration** — Add section to `DogProfileSettingsView`
11. **Localization** — Add all string keys
12. **Expiration notifications** — Optional: local notifications for expiring documents

## Future Considerations

- **VisionKit integration** — Use `VNDocumentCameraViewController` for proper document scanning (auto-crop, perspective correction) instead of plain camera
- **OCR** — Extract text from scanned documents using Vision framework
- **Quick Look** — Support PDF documents via `QLPreviewController`
- **Widgets** — Show expiring documents in widget
- **Siri** — "Show my dog's passport" via App Intents
