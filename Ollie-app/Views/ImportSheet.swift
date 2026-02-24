//
//  ImportSheet.swift
//  Ollie-app
//
//  Multi-stage import sheet with preview, progress, and completion states

import SwiftUI
import OllieShared

/// Import stages
enum ImportStage {
    case preview
    case importing
    case done
    case error
}

/// Sheet for importing data from GitHub with preview and progress
struct ImportSheet: View {
    @ObservedObject var dataImporter: DataImporter
    let onDismiss: () -> Void
    let onComplete: () -> Void

    @State private var stage: ImportStage = .preview
    @State private var overwriteExisting: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                switch stage {
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
            .navigationTitle("Importeren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if stage != .importing {
                        Button("Annuleren") {
                            onDismiss()
                        }
                    }
                }
            }
        }
        .task {
            await loadPreview()
        }
    }

    // MARK: - Preview Stage

    private var previewStage: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding(.top, 20)

            if dataImporter.isFetchingPreview {
                ProgressView("Gegevens ophalen...")
            } else if let preview = dataImporter.lastPreview {
                previewContent(preview)
            } else {
                Text("Kon preview niet laden")
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private func previewContent(_ preview: ImportPreview) -> some View {
        VStack(spacing: 16) {
            // Summary stats
            VStack(spacing: 8) {
                Text("Gevonden: \(preview.totalDays) dagen")
                    .font(.headline)

                if let range = preview.dateRange {
                    Text("\(formatDate(range.start)) tot \(formatDate(range.end))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Breakdown
            VStack(spacing: 8) {
                HStack {
                    Text("Lokaal aanwezig:")
                    Spacer()
                    Text("\(preview.localDays) dagen")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Nieuw te importeren:")
                    Spacer()
                    Text("\(preview.newDays) dagen")
                        .fontWeight(.semibold)
                        .foregroundColor(preview.newDays > 0 ? .green : .secondary)
                }
            }
            .font(.subheadline)

            Divider()

            // Overwrite toggle
            Toggle(isOn: $overwriteExisting) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Overschrijf bestaande data")
                    Text("Vervangt lokale bestanden met GitHub versie")
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
                    Text("Importeren")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(LayoutConstants.cornerRadiusM)
            }
            .disabled(preview.newDays == 0 && !overwriteExisting)
        }
    }

    // MARK: - Progress Stage

    private var progressStage: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated icon
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .symbolEffect(.pulse.wholeSymbol, options: .repeating)

            Text("Importeren...")
                .font(.headline)

            if let progress = dataImporter.importProgress {
                VStack(spacing: 12) {
                    // Progress bar
                    ProgressView(value: Double(progress.currentFile), total: Double(progress.totalFiles))
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(x: 1, y: 2, anchor: .center)

                    // Progress text
                    Text("\(progress.currentFile)/\(progress.totalFiles)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(progress.currentFileName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if progress.eventsImportedSoFar > 0 {
                        Text("\(progress.eventsImportedSoFar) events geimporteerd")
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
                .foregroundColor(.green)

            Text("Import voltooid!")
                .font(.headline)

            if let result = dataImporter.lastResult {
                VStack(spacing: 8) {
                    Text("\(result.filesImported) dagen geimporteerd")
                        .font(.title3)

                    Text("\(result.eventsImported) events totaal")
                        .foregroundColor(.secondary)

                    if result.skipped > 0 {
                        Text("\(result.skipped) overgeslagen (bestonden al)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !result.errors.isEmpty {
                        Text("\(result.errors.count) fouten")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            // Done button
            Button {
                onComplete()
            } label: {
                Text("Klaar")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
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
                .foregroundColor(.orange)

            Text("Import mislukt")
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
                    Task {
                        await loadPreview()
                    }
                } label: {
                    Text("Opnieuw proberen")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(LayoutConstants.cornerRadiusM)
                }

                Button {
                    onDismiss()
                } label: {
                    Text("Annuleren")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 20)
        }
        .padding()
    }

    // MARK: - Actions

    private func loadPreview() async {
        stage = .preview
        do {
            _ = try await dataImporter.fetchPreview()
        } catch {
            errorMessage = error.localizedDescription
            stage = .error
        }
    }

    private func startImport() {
        stage = .importing
        Task {
            do {
                _ = try await dataImporter.importFromGitHub(overwriteExisting: overwriteExisting)
                stage = .done
            } catch {
                errorMessage = error.localizedDescription
                stage = .error
            }
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter.string(from: date)
    }
}

#Preview {
    ImportSheet(
        dataImporter: DataImporter(),
        onDismiss: {},
        onComplete: {}
    )
}
