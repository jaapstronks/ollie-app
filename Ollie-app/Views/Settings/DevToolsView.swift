//
//  DevToolsView.swift
//  Otis-app
//
//  Developer tools - separate from user-facing app settings
//  Only available in DEBUG builds

#if DEBUG

import SwiftUI
import OtisShared

/// Developer tools screen with debug settings, AI testing, and data management
struct DevToolsView: View {
    @Environment(ProfileStore.self) var profileStore
    @Environment(EventStore.self) var eventStore
    @Environment(SkillProgressStore.self) var skillProgressStore
    @Environment(SocializationStore.self) var socializationStore
    @Environment(MilestoneStore.self) var milestoneStore

    // Celebration debug settings
    @AppStorage(UserPreferences.Key.forceCelebrateEveryLog.rawValue) private var forceCelebrateEveryLog = false

    // Fog of war settings
    @AppStorage("fogOfWarEnabled") private var fogOfWarEnabled = true

    var body: some View {
        Form {
            // Subscription override (uses existing DebugSubscriptionSection)
            DebugSubscriptionSection()

            // Fog of war
            fogOfWarSection

            // Celebration testing
            celebrationDebugSection

            // AI broker configuration
            DebugAIBrokerSection()

            // AI surface testing
            DebugAISurfaceTestingSection()

            // Data management (import from web app, reset)
            DebugDataSection()

            // Progress reset (training, socialization, milestones)
            DebugProgressResetSection()

            // Sync testing with predictable test data
            if #available(iOS 17.0, *) {
                SyncTestSection()
            }

            // Build info
            buildInfoSection
        }
        .navigationTitle("Developer Tools")
    }

    // MARK: - Fog of War Section

    private var fogOfWarSection: some View {
        Section {
            Toggle(isOn: $fogOfWarEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Exploration.fogOverlayToggle)
                    Text(Strings.Exploration.fogOverlayDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label(Strings.Exploration.sectionTitle, systemImage: "map.fill")
        }
    }

    // MARK: - Celebration Debug Section

    private var celebrationDebugSection: some View {
        Section {
            Toggle(isOn: $forceCelebrateEveryLog) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Celebrate Every Log")
                    Text("Show celebration animation for every event logged")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("Celebrations", systemImage: "party.popper")
        }
    }

    // MARK: - Build Info Section

    private var buildInfoSection: some View {
        Section {
            LabeledContent("Version") {
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-")
            }
            LabeledContent("Build") {
                Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-")
            }
            LabeledContent("Environment") {
                Text(AppEnvironment.current.displayName)
            }
        } header: {
            Label("Build Info", systemImage: "info.circle")
        }
    }
}

#Preview {
    NavigationStack {
        DevToolsView()
            .environment(ProfileStore())
            .environment(EventStore())
            .environment(SkillProgressStore())
            .environment(SocializationStore())
            .environment(MilestoneStore())
    }
}

#endif
