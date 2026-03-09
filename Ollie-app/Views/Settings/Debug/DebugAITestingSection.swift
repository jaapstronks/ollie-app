//
//  DebugAITestingSection.swift
//  Otis-app
//
//  Debug section for AI broker configuration and surface testing

#if DEBUG

import SwiftUI
import OtisShared

/// Debug section for AI broker configuration and testing
struct DebugAIBrokerSection: View {
    // AI broker debug config (stored in UserDefaults via AINudgeRollout keys)
    @AppStorage("ai.nudges.brokerBaseURL") private var aiBrokerBaseURL = "https://ai.otis.pet"
    @AppStorage("ai.nudges.brokerApiKey") private var aiBrokerApiKey = ""
    @AppStorage("ai.nudges.rolloutPercentage") private var aiRolloutPercentage = 100
    @AppStorage("ai.nudges.shadowMode") private var aiShadowMode = true
    @AppStorage("ai.nudges.enabled") private var aiEnabled = true

    @State private var isTestingBroker = false
    @State private var brokerTestResult: String?

    var body: some View {
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
    }

    // MARK: - Broker Health Test

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

/// Debug section for testing AI surfaces
struct DebugAISurfaceTestingSection: View {
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var eventStore: EventStore

    @AppStorage("ai.nudges.brokerApiKey") private var aiBrokerApiKey = ""

    // View state: loading indicators only
    @State private var isTestingInsight = false
    @State private var isTestingNotification = false
    @State private var isTestingTraining = false
    @State private var isTestingPotty = false
    @State private var isTestingSocialization = false
    @State private var isTestingHealth = false

    // Last test result - use NavigationLink instead of sheet to avoid nested sheet issues
    // (Settings itself is a sheet, so presenting another sheet from here causes auto-dismiss)
    @State private var lastTestResult: AIOrchestrator.NewAITestResult?
    @State private var showCacheCleared = false

    private var isAnyTestRunning: Bool {
        isTestingInsight || isTestingNotification || isTestingTraining ||
        isTestingPotty || isTestingSocialization || isTestingHealth
    }

    var body: some View {
        Section {
            testButton(
                label: "Insight Bundle",
                icon: "sparkles",
                isRunning: isTestingInsight
            ) {
                await testInsightBundle()
            }

            testButton(
                label: "Notification Policy",
                icon: "bell.badge",
                isRunning: isTestingNotification
            ) {
                await testNotificationPolicy()
            }

            testButton(
                label: "Training Guidance",
                icon: "figure.walk",
                isRunning: isTestingTraining
            ) {
                await testTrainingGuidance()
            }

            testButton(
                label: "Potty Analysis",
                icon: "leaf.fill",
                isRunning: isTestingPotty
            ) {
                await testPottyAnalysis()
            }

            testButton(
                label: "Socialization Guidance",
                icon: "person.3.fill",
                isRunning: isTestingSocialization
            ) {
                await testSocializationGuidance()
            }

            testButton(
                label: "Health Insights",
                icon: "heart.fill",
                isRunning: isTestingHealth
            ) {
                await testHealthInsights()
            }

            Button {
                AINudgeOrchestrator.shared.clearCache()
                AINudgeOrchestrator.shared.resetBudget()
                AIOrchestrator.shared.clearCache()
                showCacheCleared = true
                // Auto-hide after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showCacheCleared = false
                }
            } label: {
                HStack {
                    Label("Clear AI Cache & Budget", systemImage: "arrow.clockwise")
                    Spacer()
                    if showCacheCleared {
                        Text("Cleared!")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            // Last result - uses NavigationLink to avoid nested sheet issues
            // (Settings is already a sheet, so presenting a sheet from here causes auto-dismiss)
            if let result = lastTestResult {
                NavigationLink {
                    AITestResultView(result: result)
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
                        ChevronIcon(color: .secondary)
                    }
                }
            }
        } header: {
            Label("AI Surface Testing", systemImage: "sparkles.rectangle.stack")
        } footer: {
            Text("Test AI surfaces. All surfaces use the modular context system.")
        }
    }

    // MARK: - Test Button Builder

    @ViewBuilder
    private func testButton(
        label: String,
        icon: String,
        isRunning: Bool,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                Label(label, systemImage: icon)
                Spacer()
                if isRunning {
                    ProgressView()
                } else {
                    Image(systemName: "play.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .disabled(isAnyTestRunning || aiBrokerApiKey.isEmpty)
    }

    // MARK: - Test Functions

    private func getRecentEvents() -> [PuppyEvent] {
        eventStore.getEvents(from: Date.daysAgo(7), to: Date())
    }

    private func makeErrorResult(surface: AISurface) -> AIOrchestrator.NewAITestResult {
        AIOrchestrator.NewAITestResult(
            surface: surface,
            timestamp: Date(),
            latencyMs: 0,
            provider: nil,
            model: nil,
            reasoningTags: [],
            response: nil,
            rawResponse: nil,
            error: "No profile found"
        )
    }

    @MainActor
    private func testInsightBundle() async {
        isTestingInsight = true
        guard let profile = profileStore.profile else {
            lastTestResult = makeErrorResult(surface: .insightBundle)
            isTestingInsight = false
            return
        }

        let result = await AIOrchestrator.shared.testInsightBundle(
            profile: profile,
            recentEvents: getRecentEvents()
        )
        lastTestResult = result
        isTestingInsight = false
    }

    @MainActor
    private func testNotificationPolicy() async {
        isTestingNotification = true
        guard let profile = profileStore.profile else {
            lastTestResult = makeErrorResult(surface: .notificationPolicy)
            isTestingNotification = false
            return
        }

        let result = await AIOrchestrator.shared.testNotificationPolicy(
            profile: profile,
            recentEvents: getRecentEvents()
        )
        lastTestResult = result
        isTestingNotification = false
    }

    @MainActor
    private func testTrainingGuidance() async {
        isTestingTraining = true
        guard let profile = profileStore.profile else {
            lastTestResult = makeErrorResult(surface: .trainingGuidance)
            isTestingTraining = false
            return
        }

        let result = await AIOrchestrator.shared.testTrainingGuidance(
            profile: profile,
            recentEvents: getRecentEvents()
        )
        lastTestResult = result
        isTestingTraining = false
    }

    @MainActor
    private func testPottyAnalysis() async {
        isTestingPotty = true
        guard let profile = profileStore.profile else {
            lastTestResult = makeErrorResult(surface: .pottyAnalysis)
            isTestingPotty = false
            return
        }

        let result = await AIOrchestrator.shared.testPottyAnalysis(
            profile: profile,
            recentEvents: getRecentEvents()
        )
        lastTestResult = result
        isTestingPotty = false
    }

    @MainActor
    private func testSocializationGuidance() async {
        isTestingSocialization = true
        guard let profile = profileStore.profile else {
            lastTestResult = makeErrorResult(surface: .socializationGuidance)
            isTestingSocialization = false
            return
        }

        let result = await AIOrchestrator.shared.testSocializationGuidance(
            profile: profile,
            recentEvents: getRecentEvents()
        )
        lastTestResult = result
        isTestingSocialization = false
    }

    @MainActor
    private func testHealthInsights() async {
        isTestingHealth = true
        guard let profile = profileStore.profile else {
            lastTestResult = makeErrorResult(surface: .healthInsights)
            isTestingHealth = false
            return
        }

        let result = await AIOrchestrator.shared.testHealthInsights(
            profile: profile,
            recentEvents: getRecentEvents()
        )
        lastTestResult = result
        isTestingHealth = false
    }
}

#Preview("AI Broker") {
    Form {
        DebugAIBrokerSection()
    }
}

#Preview("AI Surface Testing") {
    Form {
        DebugAISurfaceTestingSection()
    }
    .environmentObject(ProfileStore())
    .environmentObject(EventStore())
}

// MARK: - AISurface Display Extensions

extension AISurface {
    var displayName: String {
        rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var icon: String {
        switch self {
        case .insightBundle: return "sparkles"
        case .notificationPolicy: return "bell.badge"
        case .trainingGuidance: return "figure.walk"
        case .pottyAnalysis: return "leaf.fill"
        case .socializationGuidance: return "person.3.fill"
        case .healthInsights: return "heart.fill"
        case .morningBriefing: return "sun.max.fill"
        }
    }
}

#endif
