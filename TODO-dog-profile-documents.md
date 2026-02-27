# TODO: Dog Profile Documents

## Overview

Add a **Documents** feature to the existing dog profile, allowing users to store scans/photos of important dog documents: passport, chip registration, insurance policy, pedigree papers, vaccination records, etc.

The dog profile (`PuppyProfile` / `CDPuppyProfile`) already exists. This feature adds a new `CDDocument` Core Data entity with a one-to-many relationship from the profile, plus views for capturing, viewing, and managing documents.

## Architecture

### Data Layer

#### New Core Data Entity: `CDDocument`

Add to `Ollie-app/Ollie.xcdatamodeld`:

```xml
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

public enum DocumentType: String, CaseIterable, Codable, Identifiable, Sendable {
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

public struct DogDocument: Identifiable, Codable, Hashable, Sendable {
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

**Store images locally in the app's documents directory.** The existing `MediaPicker` and event photo handling patterns should be reused.

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

    func fullPath(for filename: String) -> URL {
        documentsDirectory.appendingPathComponent(filename)
    }

    enum DocumentError: Error {
        case imageConversionFailed
    }
}
```

### CloudKit Sync

The Core Data model uses `usedWithCloudKit="YES"`, so `CDDocument` will sync automatically via `NSPersistentCloudKitContainer`. Images stored as filenames will need the `DogDocuments/` directory included in iCloud container, or use Core Data's "Allows External Storage" for the image data.

### ViewModel

```swift
// DocumentStore.swift
import Foundation
import CoreData
import SwiftUI

@MainActor
final class DocumentStore: ObservableObject {
    @Published var documents: [DogDocument] = []

    let context: NSManagedObjectContext
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
            documents = results.compactMap { $0.toDogDocument() }
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
  ├── Empty state (ContentUnavailableView)
  ├── Toolbar: + button → AddDocumentSheet
  └── Swipe to delete

AddDocumentSheet
  ├── Image selection (reuse MediaAttachmentButton pattern)
  │     ├── PhotosPicker / Camera via existing MediaPicker
  │     └── Image preview
  ├── TextField: title
  ├── Picker: DocumentType
  ├── Toggle + DatePicker: expiration (optional)
  ├── TextEditor: notes (optional)
  └── Save button

DocumentDetailView
  ├── Full-size zoomable image (reuse MediaPreviewView pattern)
  ├── Document metadata
  ├── Edit button → edit mode
  ├── Share button (ShareLink)
  └── Delete button
```

### Reuse Existing Components

The app already has these components that should be reused:

| Component | Location | Use For |
|-----------|----------|---------|
| `MediaAttachmentButton` | `Ollie-app/Views/MediaAttachmentButton.swift` | Photo selection UI pattern |
| `MediaPicker` | `Ollie-app/Views/MediaPicker.swift` | Camera/library picker |
| `MediaPickerSource` | `Ollie-app/Views/MediaPicker.swift` | `.camera` / `.library` enum |
| `MediaPreviewView` | `Ollie-app/Views/MediaPreviewView.swift` | Full-screen image viewer with zoom |

### Key View: DocumentsView

```swift
// DocumentsView.swift
import SwiftUI
import OllieShared

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
                    Strings.Documents.emptyTitle,
                    systemImage: "doc.text.magnifyingglass",
                    description: Text(Strings.Documents.emptyDescription)
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

## File List

### New Files

| File | Location |
|------|----------|
| `DocumentType.swift` | `OllieShared/Sources/OllieShared/Models/` |
| `DogDocument.swift` | `OllieShared/Sources/OllieShared/Models/` |
| `DocumentStore.swift` | `Ollie-app/ViewModels/` |
| `DocumentImageStore.swift` | `Ollie-app/Services/` |
| `DocumentsView.swift` | `Ollie-app/Views/Documents/` |
| `AddDocumentSheet.swift` | `Ollie-app/Views/Documents/` |
| `DocumentDetailView.swift` | `Ollie-app/Views/Documents/` |
| `DocumentRow.swift` | `Ollie-app/Views/Documents/` |

### Modified Files

| File | Change |
|------|--------|
| `Ollie-app/Ollie.xcdatamodeld` | Add `CDDocument` entity + relationship on `CDPuppyProfile` |
| `Ollie-app/Views/Settings/DogProfileSettingsView.swift` | Add "Documents" section with NavigationLink |
| `OllieShared/Sources/OllieShared/Utils/Strings.swift` | Add `Strings.Documents.*` constants |
| `Ollie-app/Localizable.xcstrings` | Add all document-related keys (en + nl) |

## Localization Keys

Add to `Strings.swift`:

```swift
public enum Documents {
    public static let title = String(localized: "documents.title")
    public static let emptyTitle = String(localized: "documents.empty.title")
    public static let emptyDescription = String(localized: "documents.empty.description")
    public static let addTitle = String(localized: "documents.add.title")
    public static let addTitleNav = String(localized: "documents.add.title.nav")
    public static let type = String(localized: "documents.add.type")
    public static let hasExpiration = String(localized: "documents.add.hasExpiration")
    public static let expirationDate = String(localized: "documents.add.expirationDate")
    public static let notes = String(localized: "documents.add.notes")
    public static let expiring = String(localized: "document.expiring")
    public static let expired = String(localized: "document.expired")
}
```

Translations (en / nl):

```
documents.title = "Documents" / "Documenten"
documents.empty.title = "No Documents" / "Geen documenten"
documents.empty.description = "Add your dog's important documents like passport, insurance, and vaccination records." / "Voeg belangrijke documenten toe zoals paspoort, verzekering en vaccinatiegegevens."
documents.add.title.nav = "Add Document" / "Document toevoegen"
documents.add.title = "Title" / "Titel"
documents.add.type = "Type" / "Type"
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

1. **Core Data model** - Add `CDDocument` entity and relationship to `CDPuppyProfile`
2. **OllieShared models** - `DocumentType` enum + `DogDocument` struct
3. **DocumentImageStore** - File storage service
4. **DocumentStore** - ViewModel with CRUD operations
5. **DocumentRow** - List row component
6. **DocumentsView** - Main list view with empty state
7. **AddDocumentSheet** - Creation form (reuse MediaPicker patterns)
8. **DocumentDetailView** - Full view with zoom (reuse MediaPreviewView) + share
9. **Integration** - Add section to `DogProfileSettingsView`
10. **Localization** - Add all string keys to Strings.swift and xcstrings

## Future Considerations

- **VisionKit integration** - Use `VNDocumentCameraViewController` for proper document scanning (auto-crop, perspective correction)
- **OCR** - Extract text from scanned documents using Vision framework
- **Quick Look** - Support PDF documents via `QLPreviewController`
- **Expiration notifications** - Local notifications for expiring documents
- **Widgets** - Show expiring documents in widget
