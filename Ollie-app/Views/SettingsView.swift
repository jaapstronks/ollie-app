//
//  SettingsView.swift
//  Ollie-app
//

import SwiftUI

/// Settings screen with profile editing and data import
struct SettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var dataImporter: DataImporter
    @ObservedObject var eventStore: EventStore

    @State private var showingImportConfirm = false
    @State private var importError: String?
    @State private var showingError = false
    @State private var overwriteExisting = false

    var body: some View {
        NavigationStack {
            Form {
                if let profile = profileStore.profile {
                    profileSection(profile)
                    statsSection(profile)
                    mealSection(profile)
                }

                dataSection
                dangerSection
            }
            .navigationTitle("Instellingen")
        }
        .alert("Importeren", isPresented: $showingImportConfirm) {
            Button("Importeren") {
                startImport()
            }
            Button("Annuleren", role: .cancel) {}
        } message: {
            Text("Wil je data importeren van GitHub? Dit haalt alle beschikbare dagen op.")
        }
        .alert("Fout", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(importError ?? "Onbekende fout")
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func profileSection(_ profile: PuppyProfile) -> some View {
        Section("Profiel") {
            HStack {
                Text("Naam")
                Spacer()
                Text(profile.name)
                    .foregroundColor(.secondary)
            }

            if let breed = profile.breed {
                HStack {
                    Text("Ras")
                    Spacer()
                    Text(breed)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Text("Grootte")
                Spacer()
                Text(profile.sizeCategory.label)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func statsSection(_ profile: PuppyProfile) -> some View {
        Section("Stats") {
            HStack {
                Text("Leeftijd")
                Spacer()
                Text("\(profile.ageInWeeks) weken")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Dagen thuis")
                Spacer()
                Text("\(profile.daysHome) dagen")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Max beweging")
                Spacer()
                Text("\(profile.maxExerciseMinutes) min/wandeling")
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func mealSection(_ profile: PuppyProfile) -> some View {
        Section("Maaltijden (\(profile.mealSchedule.mealsPerDay)x per dag)") {
            ForEach(profile.mealSchedule.portions) { portion in
                HStack {
                    Text(portion.label)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(portion.amount)
                            .foregroundColor(.secondary)
                        if let time = portion.targetTime {
                            Text(time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
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
                    Label("Importeer van GitHub", systemImage: "arrow.down.circle")
                }

                if let result = dataImporter.lastResult {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Laatste import:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(result.filesImported) dagen, \(result.eventsImported) events")
                            .font(.caption)
                        if result.skipped > 0 {
                            Text("\(result.skipped) overgeslagen (bestonden al)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Toggle("Overschrijf bestaande data", isOn: $overwriteExisting)
            }
        }
    }

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                profileStore.resetProfile()
            } label: {
                Label("Reset profiel", systemImage: "trash")
            }
        }
    }

    // MARK: - Actions

    private func startImport() {
        Task {
            do {
                _ = try await dataImporter.importFromGitHub(overwriteExisting: overwriteExisting)
                // Refresh events after import
                eventStore.loadEvents(for: Date())
            } catch {
                importError = error.localizedDescription
                showingError = true
            }
        }
    }
}

#Preview {
    SettingsView(
        profileStore: ProfileStore(),
        dataImporter: DataImporter(),
        eventStore: EventStore()
    )
}
