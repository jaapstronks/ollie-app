//
//  ImportSheet.swift
//  Otis-app
//
//  Multi-stage import sheet with file picker, preview, progress, and completion states

import SwiftUI
import UniformTypeIdentifiers
import OtisShared

/// Import stages
enum ImportStage {
    case selectFile
    case preview
    case importing
    case done
    case error
}

/// Sheet for importing data from exported JSON folder
struct ImportSheet: View {
    var dataImporter: DataImporter
    let onDismiss: () -> Void
    let onComplete: () -> Void

    @State private var stage: ImportStage = .selectFile
    @State private var overwriteExisting: Bool = false
    @State private var errorMessage: String?
    @State private var showingFilePicker: Bool = false
    @State private var selectedFolderURL: URL?

    var body: some View {
        NavigationStack {
            Group {
                switch stage {
                case .selectFile:
                    selectFileStage
                case .preview:
                    previewStage
                case .importing:
                    progressStage
                case .done:
                    doneStage
                case .error:
                    errorStage
                }
            }
            .navigationTitle(Strings.DataImport.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if stage != .importing {
                        Button(Strings.Common.cancel) {
                            onDismiss()
                        }
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.folder, .json],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }

    // MARK: - Select File Stage

    private var selectFileStage: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.otisInfo)

            VStack(spacing: 8) {
                Text(Strings.DataImport.selectFolder)
                    .font(.headline)

                Text(Strings.DataImport.selectFolderDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Select folder button
            Button {
                showingFilePicker = true
            } label: {
                HStack {
                    Image(systemName: "folder")
                    Text(Strings.DataImport.chooseFolder)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.otisInfo)
                .cornerRadius(LayoutConstants.cornerRadiusM)
            }
            .padding(.bottom, 20)
        }
        .padding()
    }

    // MARK: - Preview Stage

    private var previewStage: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.otisInfo)
                .padding(.top, 20)

            if let preview = dataImporter.lastPreview {
                previewContent(preview)
            } else {
                Text(Strings.DataImport.couldNotLoadPreview)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private func previewContent(_ preview: ImportPreview) -> some View {
        VStack(spacing: 16) {
            // Summary
            VStack(spacing: 8) {
                if let name = preview.puppyName {
                    Text(Strings.DataImport.dataFor(name: name))
                        .font(.headline)
                }

                if let date = preview.exportDate {
                    Text(Strings.DataImport.exportedOn(date: formatDate(date)))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Components breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.DataImport.componentsToImport)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(preview.components, id: \.self) { component in
                    HStack {
                        Image(systemName: iconForComponent(component))
                            .frame(width: 24)
                            .foregroundColor(.otisInfo)
                        Text(localizedComponentName(component))
                        Spacer()
                        if let count = preview.itemCounts[component], count > 0 {
                            Text("\(count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.subheadline)
                }
            }

            Divider()

            // Overwrite toggle
            Toggle(isOn: $overwriteExisting) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Settings.overwriteExisting)
                    Text(Strings.DataImport.overwriteDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Import button
            Button {
                startImport()
            } label: {
                HStack {
                    Text(Strings.Settings.importAction)
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.otisInfo)
                .cornerRadius(LayoutConstants.cornerRadiusM)
            }
            .disabled(preview.components.isEmpty)
        }
    }

    // MARK: - Progress Stage

    private var progressStage: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated icon
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 60))
                .foregroundColor(.otisInfo)
                .symbolEffect(.pulse.wholeSymbol, options: .repeating)

            Text(Strings.DataImport.importing)
                .font(.headline)

            if let progress = dataImporter.importProgress {
                VStack(spacing: 12) {
                    // Progress bar
                    ProgressView(value: Double(progress.currentIndex), total: Double(progress.totalComponents))
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(x: 1, y: 2, anchor: .center)

                    // Progress text
                    Text("\(progress.currentIndex)/\(progress.totalComponents)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(localizedComponentName(progress.currentComponent))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if progress.itemsImportedSoFar > 0 {
                        Text(Strings.DataImport.itemsImported(progress.itemsImportedSoFar))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 40)
            } else {
                ProgressView()
            }

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Done Stage

    private var doneStage: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.otisSuccess)

            Text(Strings.DataImport.importComplete)
                .font(.headline)

            if let result = dataImporter.lastResult {
                VStack(spacing: 8) {
                    Text(Strings.DataImport.componentsImported(result.componentsImported))
                        .font(.title3)

                    Text(Strings.DataImport.totalItems(result.itemsImported))
                        .foregroundColor(.secondary)

                    if !result.errors.isEmpty {
                        Text(Strings.DataImport.errors(result.errors.count))
                            .font(.caption)
                            .foregroundColor(.otisWarning)
                    }
                }
            }

            Spacer()

            // Done button
            Button {
                onComplete()
            } label: {
                Text(Strings.Common.done)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.otisSuccess)
                    .cornerRadius(LayoutConstants.cornerRadiusM)
            }
            .padding(.bottom, 20)
        }
        .padding()
    }

    // MARK: - Error Stage

    private var errorStage: some View {
        VStack(spacing: 24) {
            Spacer()

            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.otisWarning)

            Text(Strings.DataImport.importFailed)
                .font(.headline)

            if let error = errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Retry button
            VStack(spacing: 12) {
                Button {
                    stage = .selectFile
                    dataImporter.reset()
                } label: {
                    Text(Strings.Common.tryAgain)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.otisInfo)
                        .cornerRadius(LayoutConstants.cornerRadiusM)
                }

                Button {
                    onDismiss()
                } label: {
                    Text(Strings.Common.cancel)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 20)
        }
        .padding()
    }

    // MARK: - Actions

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let folderURL = urls.first else { return }

            // Start security-scoped access
            guard folderURL.startAccessingSecurityScopedResource() else {
                errorMessage = Strings.DataImport.accessDenied
                stage = .error
                return
            }

            selectedFolderURL = folderURL

            Task {
                do {
                    _ = try await dataImporter.previewImport(from: folderURL)
                    stage = .preview
                } catch {
                    errorMessage = error.localizedDescription
                    stage = .error
                    folderURL.stopAccessingSecurityScopedResource()
                }
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
            stage = .error
        }
    }

    private func startImport() {
        guard let folderURL = selectedFolderURL else { return }

        stage = .importing
        Task {
            do {
                _ = try await dataImporter.importFromFolder(folderURL, overwriteExisting: overwriteExisting)
                stage = .done
            } catch {
                errorMessage = error.localizedDescription
                stage = .error
            }

            // Stop security-scoped access when done
            folderURL.stopAccessingSecurityScopedResource()
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func iconForComponent(_ component: String) -> String {
        switch component {
        case "profile": return "person.circle"
        case "events": return "list.bullet"
        case "documents": return "doc"
        case "contacts": return "person.2"
        case "appointments": return "calendar"
        case "milestones": return "flag"
        case "exposures": return "sparkles"
        case "walkSpots": return "mappin"
        case "media": return "photo"
        case "profilePhoto": return "camera"
        default: return "doc"
        }
    }

    private func localizedComponentName(_ component: String) -> String {
        switch component {
        case "profile": return Strings.Export.includeProfile
        case "events": return Strings.Export.includeEvents
        case "documents": return Strings.Export.includeDocuments
        case "contacts": return Strings.Export.includeContacts
        case "appointments": return Strings.Export.includeAppointments
        case "milestones": return Strings.Export.includeMilestones
        case "exposures": return Strings.Export.includeSocialization
        case "walkSpots": return Strings.Export.includeWalkSpots
        case "media": return Strings.Export.includeMedia
        case "profilePhoto": return Strings.Export.includeProfilePhoto
        default: return component
        }
    }
}

#Preview {
    ImportSheet(
        dataImporter: DataImporter(),
        onDismiss: {},
        onComplete: {}
    )
}
