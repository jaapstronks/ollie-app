//
//  DataSection.swift
//  Ollie-app
//
//  Data import/export section for SettingsView

import SwiftUI

/// Data import and management section
struct DataSection: View {
    @ObservedObject var dataImporter: DataImporter
    @ObservedObject var eventStore: EventStore
    @Binding var showingImportConfirm: Bool
    @Binding var overwriteExisting: Bool

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
                    showingImportConfirm = true
                } label: {
                    Label(Strings.Settings.importFromGitHub, systemImage: "arrow.down.circle")
                }

                if let result = dataImporter.lastResult {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.Settings.lastImport(date: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(Strings.Settings.importStats(days: result.filesImported, events: result.eventsImported))
                            .font(.caption)
                        if result.skipped > 0 {
                            Text(Strings.Settings.skippedExisting(result.skipped))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle(Strings.Settings.overwriteExisting, isOn: $overwriteExisting)
            }
        }
    }
}

/// Danger zone section for destructive actions
struct DangerSection: View {
    @ObservedObject var profileStore: ProfileStore

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
