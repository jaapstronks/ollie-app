//
//  ExportDataView.swift
//  Ollie-app
//
//  UI for exporting puppy data with options and progress
//

import SwiftUI
import OllieShared

/// View for exporting puppy data with configurable options
struct ExportDataView: View {
    @ObservedObject var profileStore: ProfileStore
    @StateObject private var exportService = ExportService()

    @Environment(\.dismiss) private var dismiss

    // Export options
    @State private var includeEvents = true
    @State private var includeDocuments = true
    @State private var includeContacts = true
    @State private var includeAppointments = true
    @State private var includeMilestones = true
    @State private var includeSocialization = true
    @State private var includeWalkSpots = true
    @State private var includeProfilePhoto = true
    @State private var includeMedia = false

    // State
    @State private var exportResult: ExportResult?
    @State private var showingShareSheet = false
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            Form {
                if exportService.isExporting {
                    progressSection
                } else if let result = exportResult {
                    resultSection(result)
                } else {
                    optionsSection
                    exportButtonSection
                }
            }
            .navigationTitle(Strings.Export.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                    .disabled(exportService.isExporting)
                }
            }
            .alert(Strings.Common.error, isPresented: $showingError) {
                Button(Strings.Common.ok) {}
            } message: {
                if let error = exportService.exportError {
                    Text(error.localizedDescription)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let result = exportResult {
                    ShareSheet(activityItems: [result.exportURL])
                        .onDisappear {
                            // Clean up after sharing
                            exportService.cleanupExportFolder(result.exportURL)
                        }
                }
            }
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        Section {
            Toggle(Strings.Export.includeEvents, isOn: $includeEvents)
            Toggle(Strings.Export.includeDocuments, isOn: $includeDocuments)
            Toggle(Strings.Export.includeContacts, isOn: $includeContacts)
            Toggle(Strings.Export.includeAppointments, isOn: $includeAppointments)
            Toggle(Strings.Export.includeMilestones, isOn: $includeMilestones)
            Toggle(Strings.Export.includeSocialization, isOn: $includeSocialization)
            Toggle(Strings.Export.includeWalkSpots, isOn: $includeWalkSpots)
            Toggle(Strings.Export.includeProfilePhoto, isOn: $includeProfilePhoto)

            VStack(alignment: .leading, spacing: 4) {
                Toggle(Strings.Export.includeMedia, isOn: $includeMedia)
                Text(Strings.Export.includeMediaDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(Strings.Export.optionsSection)
        } footer: {
            Text(Strings.Export.exportDescription)
        }
    }

    // MARK: - Export Button Section

    private var exportButtonSection: some View {
        Section {
            Button {
                startExport()
            } label: {
                HStack {
                    Spacer()
                    Label(Strings.Export.exportButton, systemImage: "arrow.up.circle.fill")
                        .font(.headline)
                    Spacer()
                }
            }
            .disabled(profileStore.profile == nil)
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        Section {
            VStack(spacing: 16) {
                ProgressView(value: exportService.progress)
                    .progressViewStyle(.linear)

                Text(exportService.currentStep.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(Int(exportService.progress * 100))%")
                    .font(.title2.monospacedDigit())
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Result Section

    private func resultSection(_ result: ExportResult) -> some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.ollieSuccess)

                Text(Strings.Export.exportComplete)
                    .font(.headline)

                Text(Strings.Export.exportSummary(items: result.itemCount, size: result.formattedSize))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(Strings.Export.readyToShare)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            Button {
                showingShareSheet = true
            } label: {
                HStack {
                    Spacer()
                    Label(Strings.Export.share, systemImage: "square.and.arrow.up")
                        .font(.headline)
                    Spacer()
                }
            }

            Button {
                // Reset to start over
                exportResult = nil
            } label: {
                HStack {
                    Spacer()
                    Text(Strings.Common.done)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Actions

    private func startExport() {
        guard let profile = profileStore.profile else { return }

        let options = ExportOptions(
            includeEvents: includeEvents,
            includeDocuments: includeDocuments,
            includeContacts: includeContacts,
            includeAppointments: includeAppointments,
            includeMilestones: includeMilestones,
            includeSocialization: includeSocialization,
            includeWalkSpots: includeWalkSpots,
            includeMedia: includeMedia,
            includeProfilePhoto: includeProfilePhoto
        )

        Task {
            do {
                HapticFeedback.light()
                let result = try await exportService.exportData(options: options, profile: profile)
                exportResult = result
                HapticFeedback.success()
            } catch {
                showingError = true
                HapticFeedback.error()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ExportDataView(profileStore: ProfileStore())
}
