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
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var eventStore: EventStore

    // Celebration debug settings
    @AppStorage(UserPreferences.Key.forceCelebrateEveryLog.rawValue) private var forceCelebrateEveryLog = false

    var body: some View {
        Form {
            // Subscription override (uses existing DebugSubscriptionSection)
            DebugSubscriptionSection()

            // Celebration testing
            celebrationDebugSection

            // AI broker configuration
            DebugAIBrokerSection()

            // AI surface testing
            DebugAISurfaceTestingSection()

            // Data management (import from web app, reset)
            DebugDataSection()

            // Build info
            buildInfoSection
        }
        .navigationTitle("Developer Tools")
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
            .environmentObject(ProfileStore())
            .environmentObject(EventStore())
    }
}

#endif
