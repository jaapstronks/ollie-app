//
//  DebugSection.swift
//  Ollie-app
//
//  Debug settings section - only included in DEBUG builds
//

#if DEBUG

import SwiftUI
import CoreData
import OllieShared

/// Debug section for testing features like subscription states
struct DebugSection: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showResetConfirm = false
    @State private var showImportConfirm = false
    @State private var isResetting = false
    @State private var isImporting = false
    @State private var importResult: String?

    /// Available debug subscription states
    private enum DebugSubscriptionState: String, CaseIterable, Identifiable {
        case useActual = "Use Actual"
        case free = "Free"
        case trial = "Trial"
        case active = "Active"
        case expired = "Expired"
        case legacy = "Legacy"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .useActual: return "gear"
            case .free: return "person"
            case .trial: return "clock"
            case .active: return "checkmark.seal.fill"
            case .expired: return "xmark.circle"
            case .legacy: return "star.fill"
            }
        }

        func toOlliePlusStatus() -> OlliePlusStatus? {
            switch self {
            case .useActual: return nil
            case .free: return .free
            case .trial: return .trial(until: Date().addingTimeInterval(7 * 24 * 60 * 60)) // 7 days
            case .active: return .active(until: Date().addingTimeInterval(365 * 24 * 60 * 60)) // 1 year
            case .expired: return .expired
            case .legacy: return .legacy
            }
        }

        static func from(_ status: OlliePlusStatus?) -> DebugSubscriptionState {
            guard let status = status else { return .useActual }
            switch status {
            case .free: return .free
            case .trial: return .trial
            case .active: return .active
            case .expired: return .expired
            case .legacy: return .legacy
            }
        }
    }

    var body: some View {
        Section {
            Picker(selection: Binding(
                get: { DebugSubscriptionState.from(subscriptionManager.debugOverrideStatus) },
                set: { subscriptionManager.debugOverrideStatus = $0.toOlliePlusStatus() }
            )) {
                ForEach(DebugSubscriptionState.allCases) { state in
                    Label(state.rawValue, systemImage: state.icon)
                        .tag(state)
                }
            } label: {
                Label("Subscription Override", systemImage: "ladybug")
            }

            // Show current effective state
            HStack {
                Text("Effective Status")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(subscriptionManager.effectiveStatus.displayLabel)
                    .foregroundStyle(subscriptionManager.effectiveStatus.hasOlliePlus ? Color.ollieSuccess : Color.ollieWarning)
            }
            .font(.caption)
        } header: {
            Label("Debug", systemImage: "hammer.fill")
        } footer: {
            Text("Debug overrides are only available in development builds and persist across app launches.")
        }

        // Data Management Section
        Section {
            // Import from local web app data
            Button {
                showImportConfirm = true
            } label: {
                HStack {
                    Label("Import from Web App", systemImage: "square.and.arrow.down")
                    if isImporting {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isImporting || isResetting)

            if let result = importResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(result.contains("Error") ? .red : .green)
            }

            // Nuclear reset option
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                HStack {
                    Label("Reset All Data", systemImage: "trash.fill")
                    if isResetting {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isResetting || isImporting)
        } header: {
            Label("Data Management", systemImage: "externaldrive.fill")
        } footer: {
            Text("Import loads JSONL files from ~/Github NW/Ollie/data. Reset deletes all Core Data and starts fresh.")
        }
        .alert("Reset All Data?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Everything", role: .destructive) {
                Task { await performReset() }
            }
        } message: {
            Text("This will delete all events, profile, and sync data. The app will restart fresh. This cannot be undone.")
        }
        .alert("Import Web App Data?", isPresented: $showImportConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Import") {
                Task { await performImport() }
            }
        } message: {
            Text("This will import all JSONL files from the local Ollie web app directory into Core Data.")
        }
    }

    // MARK: - Reset Action

    private func performReset() async {
        isResetting = true
        importResult = nil

        do {
            try await PersistenceController.shared.resetAllData()

            // Clear migration flag so it doesn't try to migrate archived data
            UserDefaults.standard.removeObject(forKey: "CoreDataMigrationCompleted_v1")

            // Clear widget data
            if let sharedDefaults = UserDefaults(suiteName: Constants.appGroupIdentifier) {
                sharedDefaults.removeObject(forKey: "widgetData")
            }

            importResult = "✓ Reset complete. Restart the app."
        } catch {
            importResult = "Error: \(error.localizedDescription)"
        }

        isResetting = false
    }

    // MARK: - Import Action

    private func performImport() async {
        isImporting = true
        importResult = nil

        let webAppDataPath = NSString("~/Github NW/Ollie/data").expandingTildeInPath
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: webAppDataPath) else {
            importResult = "Error: Web app data not found at \(webAppDataPath)"
            isImporting = false
            return
        }

        do {
            let files = try fileManager.contentsOfDirectory(atPath: webAppDataPath)
            let jsonlFiles = files.filter { $0.hasSuffix(".jsonl") }.sorted()

            var totalEvents = 0
            var totalFiles = 0
            let context = PersistenceController.shared.viewContext
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let string = try container.decode(String.self)
                if let date = Date.fromISO8601(string) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date")
            }

            for fileName in jsonlFiles {
                let filePath = (webAppDataPath as NSString).appendingPathComponent(fileName)
                let content = try String(contentsOfFile: filePath, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

                for line in lines {
                    guard let data = line.data(using: .utf8),
                          let event = try? decoder.decode(PuppyEvent.self, from: data) else {
                        continue
                    }

                    // Check if event already exists
                    let existing = CDPuppyEvent.fetch(byId: event.id, in: context)
                    if existing == nil {
                        _ = CDPuppyEvent.create(from: event, in: context)
                        totalEvents += 1
                    }
                }

                totalFiles += 1

                // Save in batches
                if totalEvents % 100 == 0 && context.hasChanges {
                    try context.save()
                }
            }

            // Final save
            if context.hasChanges {
                try context.save()
            }

            importResult = "✓ Imported \(totalEvents) events from \(totalFiles) files"
        } catch {
            importResult = "Error: \(error.localizedDescription)"
        }

        isImporting = false
    }
}

#Preview {
    Form {
        DebugSection()
    }
}

#endif
