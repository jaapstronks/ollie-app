//
//  DebugSection.swift
//  Otis-app
//
//  Debug settings section - only included in DEBUG builds
//

#if DEBUG

import SwiftUI
import CoreData
import OtisShared

/// Debug section for testing features like subscription states
struct DebugSection: View {
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var eventStore: EventStore
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showResetConfirm = false
    @State private var showImportConfirm = false
    @State private var isResetting = false
    @State private var isImporting = false
    @State private var importResult: String?
    @State private var isTestingBroker = false
    @State private var brokerTestResult: String?
    // AI surface testing state
    @State private var isTestingInsight = false
    @State private var isTestingNotification = false
    @State private var isTestingTraining = false
    @State private var isTestingPotty = false
    @State private var isTestingSocialization = false
    @State private var isTestingHealth = false
    @State private var aiTestResult: AIOrchestrator.NewAITestResult?
    @State private var showTestResultSheet = false

    private var isAnyTestRunning: Bool {
        isTestingInsight || isTestingNotification || isTestingTraining ||
        isTestingPotty || isTestingSocialization || isTestingHealth
    }

    // AI broker debug config (stored in UserDefaults via AINudgeRollout keys)
    @AppStorage("ai.nudges.brokerBaseURL") private var aiBrokerBaseURL = "https://ai.otis.pet"
    @AppStorage("ai.nudges.brokerApiKey") private var aiBrokerApiKey = ""
    @AppStorage("ai.nudges.rolloutPercentage") private var aiRolloutPercentage = 100
    @AppStorage("ai.nudges.shadowMode") private var aiShadowMode = true
    @AppStorage("ai.nudges.enabled") private var aiEnabled = true

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

        func toOtisPlusStatus() -> OtisPlusStatus? {
            switch self {
            case .useActual: return nil
            case .free: return .free
            case .trial: return .trial(until: Date().addingTimeInterval(7 * 24 * 60 * 60)) // 7 days
            case .active: return .active(until: Date().addingTimeInterval(365 * 24 * 60 * 60)) // 1 year
            case .expired: return .expired
            case .legacy: return .legacy
            }
        }

        static func from(_ status: OtisPlusStatus?) -> DebugSubscriptionState {
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
                get: { DebugSubscriptionState.from(subscriptionManager.betaOverrideStatus) },
                set: { subscriptionManager.betaOverrideStatus = $0.toOtisPlusStatus() }
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
                    .foregroundStyle(subscriptionManager.effectiveStatus.hasOtisPlus ? Color.otisSuccess : Color.otisWarning)
            }
            .font(.caption)
        } header: {
            Label("Debug", systemImage: "hammer.fill")
        } footer: {
            Text("Debug overrides are only available in development builds and persist across app launches.")
        }

        // AI Broker Section
        Section {
            Toggle("AI Nudges Enabled", isOn: $aiEnabled)
            Toggle("AI Shadow Mode", isOn: $aiShadowMode)

            HStack {
                Text("Rollout %")
                Spacer()
                Stepper(
                    value: $aiRolloutPercentage,
                    in: 0...100,
                    step: 5
                ) {
                    Text("\(aiRolloutPercentage)%")
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Broker Base URL")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("https://ai.otis.pet", text: $aiBrokerBaseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Broker API Key")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("Broker key", text: $aiBrokerApiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
            }

            Button {
                Task { await testBrokerHealth() }
            } label: {
                HStack {
                    Label("Test Broker /health", systemImage: "network")
                    if isTestingBroker {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isTestingBroker || aiBrokerBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if let brokerTestResult {
                Text(brokerTestResult)
                    .font(.caption)
                    .foregroundStyle(brokerTestResult.hasPrefix("✓") ? .green : .red)
            }
        } header: {
            Label("AI Broker", systemImage: "cpu")
        } footer: {
            Text("Configure broker URL/key and rollout locally for debug testing. Production should use remote config and HTTPS.")
        }

        // AI Surface Testing Section
        Section {
            Button {
                Task { await testInsightBundle() }
            } label: {
                HStack {
                    Label("Insight Bundle", systemImage: "sparkles")
                    Spacer()
                    if isTestingInsight {
                        ProgressView()
                    } else {
                        Image(systemName: "play.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isAnyTestRunning || aiBrokerApiKey.isEmpty)

            Button {
                Task { await testNotificationPolicy() }
            } label: {
                HStack {
                    Label("Notification Policy", systemImage: "bell.badge")
                    Spacer()
                    if isTestingNotification {
                        ProgressView()
                    } else {
                        Image(systemName: "play.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isAnyTestRunning || aiBrokerApiKey.isEmpty)

            Button {
                Task { await testTrainingGuidance() }
            } label: {
                HStack {
                    Label("Training Guidance", systemImage: "figure.walk")
                    Spacer()
                    if isTestingTraining {
                        ProgressView()
                    } else {
                        Image(systemName: "play.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isAnyTestRunning || aiBrokerApiKey.isEmpty)

            Button {
                Task { await testPottyAnalysis() }
            } label: {
                HStack {
                    Label("Potty Analysis", systemImage: "leaf.fill")
                    Spacer()
                    if isTestingPotty {
                        ProgressView()
                    } else {
                        Image(systemName: "play.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isAnyTestRunning || aiBrokerApiKey.isEmpty)

            Button {
                Task { await testSocializationGuidance() }
            } label: {
                HStack {
                    Label("Socialization Guidance", systemImage: "person.3.fill")
                    Spacer()
                    if isTestingSocialization {
                        ProgressView()
                    } else {
                        Image(systemName: "play.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isAnyTestRunning || aiBrokerApiKey.isEmpty)

            Button {
                Task { await testHealthInsights() }
            } label: {
                HStack {
                    Label("Health Insights", systemImage: "heart.fill")
                    Spacer()
                    if isTestingHealth {
                        ProgressView()
                    } else {
                        Image(systemName: "play.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isAnyTestRunning || aiBrokerApiKey.isEmpty)

            Button {
                AINudgeOrchestrator.shared.clearCache()
                brokerTestResult = "✓ AI cache cleared"
            } label: {
                Label("Clear AI Cache", systemImage: "arrow.clockwise")
            }

            if let result = aiTestResult {
                Button {
                    showTestResultSheet = true
                } label: {
                    HStack {
                        Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(result.isSuccess ? .green : .red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.surface.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.subheadline)
                            Text("\(result.latencyMs)ms • \(result.provider ?? "error")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Label("AI Surface Testing", systemImage: "sparkles.rectangle.stack")
        } footer: {
            Text("Test AI surfaces. All surfaces use the modular context system.")
        }
        .sheet(isPresented: $showTestResultSheet) {
            if let result = aiTestResult {
                NewAITestResultSheet(result: result)
            }
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
            Text("Import loads JSONL files from ~/Github NW/Otis/data. Reset deletes all Core Data and starts fresh.")
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
            Text("This will import all JSONL files from the local Otis web app directory into Core Data.")
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

        let webAppDataPath = NSString("~/Github NW/Otis/data").expandingTildeInPath
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

    // MARK: - AI Surface Tests

    private func testInsightBundle() async {
        isTestingInsight = true
        aiTestResult = nil
        defer { isTestingInsight = false }

        guard let profile = profileStore.profile else {
            aiTestResult = AIOrchestrator.NewAITestResult(
                surface: .insightBundle,
                timestamp: Date(),
                latencyMs: 0,
                provider: nil,
                model: nil,
                reasoningTags: [],
                response: nil,
                rawResponse: nil,
                error: "No profile found"
            )
            return
        }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEvents = eventStore.getEvents(from: sevenDaysAgo, to: Date())
        aiTestResult = await AIOrchestrator.shared.testInsightBundle(
            profile: profile,
            recentEvents: recentEvents
        )
        showTestResultSheet = true
    }

    private func testNotificationPolicy() async {
        isTestingNotification = true
        aiTestResult = nil
        defer { isTestingNotification = false }

        guard let profile = profileStore.profile else {
            aiTestResult = AIOrchestrator.NewAITestResult(
                surface: .notificationPolicy,
                timestamp: Date(),
                latencyMs: 0,
                provider: nil,
                model: nil,
                reasoningTags: [],
                response: nil,
                rawResponse: nil,
                error: "No profile found"
            )
            return
        }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEvents = eventStore.getEvents(from: sevenDaysAgo, to: Date())
        aiTestResult = await AIOrchestrator.shared.testNotificationPolicy(
            profile: profile,
            recentEvents: recentEvents
        )
        showTestResultSheet = true
    }

    private func testTrainingGuidance() async {
        isTestingTraining = true
        aiTestResult = nil
        defer { isTestingTraining = false }

        guard let profile = profileStore.profile else {
            aiTestResult = AIOrchestrator.NewAITestResult(
                surface: .trainingGuidance,
                timestamp: Date(),
                latencyMs: 0,
                provider: nil,
                model: nil,
                reasoningTags: [],
                response: nil,
                rawResponse: nil,
                error: "No profile found"
            )
            return
        }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEvents = eventStore.getEvents(from: sevenDaysAgo, to: Date())
        aiTestResult = await AIOrchestrator.shared.testTrainingGuidance(
            profile: profile,
            recentEvents: recentEvents
        )
        showTestResultSheet = true
    }

    private func testPottyAnalysis() async {
        isTestingPotty = true
        aiTestResult = nil
        defer { isTestingPotty = false }

        guard let profile = profileStore.profile else {
            aiTestResult = AIOrchestrator.NewAITestResult(
                surface: .pottyAnalysis,
                timestamp: Date(),
                latencyMs: 0,
                provider: nil,
                model: nil,
                reasoningTags: [],
                response: nil,
                rawResponse: nil,
                error: "No profile found"
            )
            return
        }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEvents = eventStore.getEvents(from: sevenDaysAgo, to: Date())
        aiTestResult = await AIOrchestrator.shared.testPottyAnalysis(
            profile: profile,
            recentEvents: recentEvents
        )
        showTestResultSheet = true
    }

    private func testSocializationGuidance() async {
        isTestingSocialization = true
        aiTestResult = nil
        defer { isTestingSocialization = false }

        guard let profile = profileStore.profile else {
            aiTestResult = AIOrchestrator.NewAITestResult(
                surface: .socializationGuidance,
                timestamp: Date(),
                latencyMs: 0,
                provider: nil,
                model: nil,
                reasoningTags: [],
                response: nil,
                rawResponse: nil,
                error: "No profile found"
            )
            return
        }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEvents = eventStore.getEvents(from: sevenDaysAgo, to: Date())
        aiTestResult = await AIOrchestrator.shared.testSocializationGuidance(
            profile: profile,
            recentEvents: recentEvents
        )
        showTestResultSheet = true
    }

    private func testHealthInsights() async {
        isTestingHealth = true
        aiTestResult = nil
        defer { isTestingHealth = false }

        guard let profile = profileStore.profile else {
            aiTestResult = AIOrchestrator.NewAITestResult(
                surface: .healthInsights,
                timestamp: Date(),
                latencyMs: 0,
                provider: nil,
                model: nil,
                reasoningTags: [],
                response: nil,
                rawResponse: nil,
                error: "No profile found"
            )
            return
        }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEvents = eventStore.getEvents(from: sevenDaysAgo, to: Date())
        aiTestResult = await AIOrchestrator.shared.testHealthInsights(
            profile: profile,
            recentEvents: recentEvents
        )
        showTestResultSheet = true
    }

    // MARK: - AI Broker Test

    private func testBrokerHealth() async {
        isTestingBroker = true
        brokerTestResult = nil
        defer { isTestingBroker = false }

        let raw = aiBrokerBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var url = URL(string: raw) else {
            brokerTestResult = "X Invalid broker URL"
            return
        }

        url.append(path: "health")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                brokerTestResult = "X Invalid response"
                return
            }

            if (200...299).contains(http.statusCode) {
                let body = String(data: data, encoding: .utf8) ?? ""
                brokerTestResult = "✓ Broker reachable: \(body)"
            } else {
                brokerTestResult = "X Broker returned \(http.statusCode)"
            }
        } catch {
            brokerTestResult = "X \(error.localizedDescription)"
        }
    }
}

// MARK: - AI Test Result Sheet

struct AITestResultSheet: View {
    let result: AITestResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(result.isSuccess ? .green : .red)
                        VStack(alignment: .leading) {
                            Text(result.surface == .insightBundle ? "Insight Bundle" : "Notification Policy")
                                .font(.headline)
                            Text(result.timestamp.formatted(date: .abbreviated, time: .standard))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Metadata
                    if result.isSuccess {
                        VStack(alignment: .leading, spacing: 8) {
                            MetadataRow(label: "Provider", value: result.provider ?? "unknown")
                            MetadataRow(label: "Model", value: result.model ?? "unknown")
                            MetadataRow(label: "Latency", value: "\(result.latencyMs)ms")
                            if !result.reasoningTags.isEmpty {
                                MetadataRow(label: "Tags", value: result.reasoningTags.joined(separator: ", "))
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }

                    // Full Response
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Response")
                            .font(.headline)

                        Text(result.summaryText)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(8)
                    }

                    // Copy button
                    Button {
                        UIPasteboard.general.string = result.summaryText
                    } label: {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("AI Test Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
        }
    }
}

// MARK: - New AI Test Result Sheet

struct NewAITestResultSheet: View {
    let result: AIOrchestrator.NewAITestResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(result.isSuccess ? .green : .red)
                        VStack(alignment: .leading) {
                            Text(result.surface.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.headline)
                            Text(result.timestamp.formatted(date: .abbreviated, time: .standard))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Metadata
                    if result.isSuccess {
                        VStack(alignment: .leading, spacing: 8) {
                            MetadataRow(label: "Provider", value: result.provider ?? "unknown")
                            MetadataRow(label: "Model", value: result.model ?? "unknown")
                            MetadataRow(label: "Latency", value: "\(result.latencyMs)ms")
                            if !result.reasoningTags.isEmpty {
                                MetadataRow(label: "Tags", value: result.reasoningTags.joined(separator: ", "))
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }

                    // Full Response
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Response")
                            .font(.headline)

                        Text(result.summaryText)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(8)
                    }

                    // Copy button
                    Button {
                        UIPasteboard.general.string = result.summaryText
                    } label: {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("AI Test Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    Form {
        DebugSection()
    }
    .environmentObject(ProfileStore())
    .environmentObject(EventStore())
}

#Preview("Test Result Sheet") {
    AITestResultSheet(result: AITestResult(
        surface: .insightBundle,
        timestamp: Date(),
        latencyMs: 342,
        provider: "anthropic",
        model: "claude-haiku-4-5-20251001",
        reasoningTags: ["insight_bundle", "schema_validated"],
        rawResponse: AINudgeBrokerResponse(
            providerUsed: "anthropic",
            modelUsed: "claude-haiku-4-5-20251001",
            reasoningTags: ["insight_bundle", "schema_validated"],
            insightBundleDecision: AIInsightBundleDecision(
                confidence: 0.85,
                dailyStatusDecision: AIDailyStatusDecision(
                    headline: "Great morning routine!",
                    subtitle: "3 potty breaks logged before 10am",
                    confidence: 0.9
                ),
                walkOrderingDecision: nil,
                trainingProgressText: nil,
                socializationProgressText: nil,
                loggingRecommendations: []
            ),
            notificationPolicyDecision: nil
        ),
        error: nil
    ))
}

#endif
