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

    @State private var showingImportSheet = false
    @State private var importError: String?
    @State private var showingError = false
    @State private var showingMealEditor = false
    @State private var editableMealSchedule: MealSchedule?
    @AppStorage(UserPreferences.Key.appearanceMode.rawValue) private var appearanceMode = AppearanceMode.system.rawValue

    var body: some View {
        NavigationStack {
            Form {
                if let profile = profileStore.profile {
                    profileSection(profile)
                    statsSection(profile)
                    mealSection(profile)
                    exerciseSection(profile)
                }

                appearanceSection
                dataSection
                dangerSection
                debugSection
            }
            .navigationTitle("Instellingen")
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportSheet(
                dataImporter: dataImporter,
                onDismiss: {
                    showingImportSheet = false
                },
                onComplete: {
                    showingImportSheet = false
                    eventStore.loadEvents(for: Date())
                }
            )
            .presentationDetents([.medium, .large])
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
        Section {
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

            Button {
                editableMealSchedule = profile.mealSchedule
                showingMealEditor = true
            } label: {
                Label("Bewerk maaltijden", systemImage: "pencil")
            }
        } header: {
            Text("Maaltijden (\(profile.mealSchedule.mealsPerDay)x per dag)")
        }
        .sheet(isPresented: $showingMealEditor) {
            if let schedule = editableMealSchedule {
                MealScheduleEditorWrapper(
                    initialSchedule: schedule,
                    onSave: { updatedSchedule in
                        profileStore.updateMealSchedule(updatedSchedule)
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func exerciseSection(_ profile: PuppyProfile) -> some View {
        Section("Beweging") {
            HStack {
                Text("Max beweging")
                Spacer()
                Text("\(profile.maxExerciseMinutes) min/wandeling")
                    .foregroundColor(.secondary)
            }

            Stepper(value: Binding(
                get: { profile.exerciseConfig.minutesPerMonthOfAge },
                set: { newValue in
                    var config = profile.exerciseConfig
                    config.minutesPerMonthOfAge = newValue
                    profileStore.updateExerciseConfig(config)
                }
            ), in: 3...10) {
                HStack {
                    Text("Minuten per maand leeftijd")
                    Spacer()
                    Text("\(profile.exerciseConfig.minutesPerMonthOfAge)")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section("Weergave") {
            Picker("Thema", selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Label(mode.label, systemImage: mode.icon)
                        .tag(mode.rawValue)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button {
                dataImporter.reset()
                showingImportSheet = true
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

    // Debug section for seed data
    private var debugSection: some View {
        Section("Debug") {
            Button {
                SeedData.forceReinstallBundledData()
                eventStore.loadEvents(for: Date())
            } label: {
                Label("Herinstalleer seed data", systemImage: "arrow.clockwise")
            }

            // Show data directory status
            let dataStatus = getDataDirectoryStatus()
            Text(dataStatus)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func getDataDirectoryStatus() -> String {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataDir = docs.appendingPathComponent("data")

        guard fileManager.fileExists(atPath: dataDir.path) else {
            return "Data folder bestaat niet"
        }

        let files = (try? fileManager.contentsOfDirectory(atPath: dataDir.path)) ?? []
        let jsonlFiles = files.filter { $0.hasSuffix(".jsonl") }

        if jsonlFiles.isEmpty {
            return "Data folder is leeg"
        }

        return "Gevonden: \(jsonlFiles.count) bestanden\n\(jsonlFiles.joined(separator: ", "))"
    }

}

#Preview {
    SettingsView(
        profileStore: ProfileStore(),
        dataImporter: DataImporter(),
        eventStore: EventStore()
    )
}
