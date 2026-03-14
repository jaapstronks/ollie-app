//
//  DataSection.swift
//  Otis-app
//
//  Data import/export section for SettingsView

import SwiftUI
import OtisShared

/// Data import and management section
struct DataSection: View {
    var dataImporter: DataImporter
    var eventStore: EventStore
    @Binding var showingImportSheet: Bool

    var body: some View {
        Section(Strings.Settings.data) {
            if dataImporter.isImporting {
                HStack {
                    ProgressView()
                    Text(dataImporter.progress)
                        .foregroundColor(.secondary)
                }
            } else {
                Button {
                    showingImportSheet = true
                } label: {
                    Label(Strings.Settings.importData, systemImage: "square.and.arrow.down")
                }

                if let result = dataImporter.lastResult {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.DataImport.lastImportResult)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(Strings.DataImport.importSummary(
                            components: result.componentsImported,
                            items: result.itemsImported
                        ))
                            .font(.caption)
                    }
                }
            }
        }
    }
}

/// Danger zone section for destructive actions
struct DangerSection: View {
    var profileStore: ProfileStore

    var body: some View {
        Section {
            Button(role: .destructive) {
                HapticFeedback.warning()
                profileStore.resetProfile()
            } label: {
                Label(Strings.Settings.resetProfile, systemImage: "trash")
            }
        }
    }
}
