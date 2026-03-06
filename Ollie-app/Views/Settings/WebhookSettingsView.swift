//
//  WebhookSettingsView.swift
//  Otis-app
//
//  Settings screen for configuring webhooks

import SwiftUI
import OtisShared

struct WebhookSettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    @StateObject private var webhookService = WebhookService.shared

    @State private var isEnabled: Bool = false
    @State private var webhookURL: String = ""
    @State private var includeDetails: Bool = true
    @State private var includePuppyName: Bool = true
    @State private var selectedEventTypes: Set<EventType> = []
    @State private var useAllEvents: Bool = true

    @State private var isTesting = false
    @State private var testResult: TestResult?
    @State private var showingTestResult = false

    private var urlValidation: WebhookURLValidation {
        webhookService.validateURL(webhookURL)
    }

    private var canSave: Bool {
        !isEnabled || urlValidation.isValid
    }

    var body: some View {
        Form {
            // Enable toggle
            Section {
                Toggle(Strings.Webhook.enabled, isOn: $isEnabled)
            } footer: {
                Text(Strings.Webhook.description)
            }

            if isEnabled {
                // URL configuration
                urlSection

                // Event types
                eventTypesSection

                // Options
                optionsSection

                // Test section
                testSection
            }
        }
        .navigationTitle(Strings.Webhook.title)
        .onAppear(perform: loadConfig)
        .onChange(of: isEnabled) { _, _ in saveConfig() }
        .onChange(of: webhookURL) { _, _ in saveConfig() }
        .onChange(of: includeDetails) { _, _ in saveConfig() }
        .onChange(of: includePuppyName) { _, _ in saveConfig() }
        .onChange(of: selectedEventTypes) { _, _ in saveConfig() }
        .onChange(of: useAllEvents) { _, _ in saveConfig() }
        .alert(
            testResult?.isSuccess == true ? Strings.Webhook.testSuccess : Strings.Webhook.testFailed,
            isPresented: $showingTestResult
        ) {
            Button(Strings.Common.ok) {}
        } message: {
            if let result = testResult {
                Text(result.message)
            }
        }
    }

    // MARK: - Sections

    private var urlSection: some View {
        Section {
            TextField(Strings.Webhook.webhookURLPlaceholder, text: $webhookURL)
                .textContentType(.URL)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .keyboardType(.URL)

            if let message = urlValidation.message {
                HStack {
                    Image(systemName: urlValidation.isValid ? "exclamationmark.triangle.fill" : "xmark.circle.fill")
                        .foregroundStyle(urlValidation.isValid ? .orange : .red)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(urlValidation.isValid ? .orange : .red)
                }
            }
        } header: {
            Text(Strings.Webhook.webhookURL)
        }
    }

    private var eventTypesSection: some View {
        Section {
            Toggle(Strings.Webhook.allEvents, isOn: $useAllEvents)

            if !useAllEvents {
                ForEach(EventType.allCases.filter { $0 != .coverageGap }, id: \.self) { eventType in
                    HStack {
                        Image(systemName: eventType.icon)
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        Text(eventType.label)
                        Spacer()
                        if selectedEventTypes.contains(eventType) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.accent)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedEventTypes.contains(eventType) {
                            selectedEventTypes.remove(eventType)
                        } else {
                            selectedEventTypes.insert(eventType)
                        }
                    }
                }
            }
        } header: {
            Text(Strings.Webhook.eventTypes)
        } footer: {
            if !useAllEvents {
                Text(Strings.Webhook.eventTypesDescription)
            }
        }
    }

    private var optionsSection: some View {
        Section {
            Toggle(isOn: $includeDetails) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Webhook.includeDetails)
                    Text(Strings.Webhook.includeDetailsDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(Strings.Webhook.includePuppyName, isOn: $includePuppyName)
        } header: {
            Text(Strings.Webhook.options)
        }
    }

    private var testSection: some View {
        Section {
            Button {
                testWebhook()
            } label: {
                HStack {
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(Strings.Webhook.testing)
                    } else {
                        Label(Strings.Webhook.testWebhook, systemImage: "paperplane")
                    }
                }
            }
            .disabled(isTesting || !urlValidation.isValid)

            if let lastSent = webhookService.lastSentTime {
                Text(Strings.Webhook.lastSent(lastSent.formatted(date: .abbreviated, time: .shortened)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(Strings.Webhook.test)
        } footer: {
            Text(Strings.Webhook.footer)
        }
    }

    // MARK: - Actions

    private func loadConfig() {
        guard let config = profileStore.profile?.webhookConfig else { return }

        isEnabled = config.isEnabled
        webhookURL = config.webhookURL ?? ""
        includeDetails = config.includeEventDetails
        includePuppyName = config.includePuppyName

        if let types = config.enabledEventTypes, !types.isEmpty {
            selectedEventTypes = types
            useAllEvents = false
        } else {
            selectedEventTypes = []
            useAllEvents = true
        }
    }

    private func saveConfig() {
        let config = WebhookConfig(
            isEnabled: isEnabled,
            webhookURL: webhookURL.nilIfBlank,
            enabledEventTypes: useAllEvents ? nil : (selectedEventTypes.isEmpty ? nil : selectedEventTypes),
            includeEventDetails: includeDetails,
            includePuppyName: includePuppyName
        )

        profileStore.updateWebhookConfig(config)
    }

    private func testWebhook() {
        isTesting = true

        let config = WebhookConfig(
            isEnabled: true,
            webhookURL: webhookURL,
            enabledEventTypes: nil,
            includeEventDetails: includeDetails,
            includePuppyName: includePuppyName
        )

        Task {
            let result = await webhookService.testWebhook(
                config: config,
                puppyName: profileStore.profile?.name
            )

            await MainActor.run {
                isTesting = false

                switch result {
                case .success(let code):
                    testResult = TestResult(isSuccess: true, message: Strings.Webhook.testSuccessWithCode(code))
                case .failure(let error):
                    testResult = TestResult(isSuccess: false, message: error.localizedDescription)
                }

                showingTestResult = true
            }
        }
    }
}

// MARK: - Test Result

private struct TestResult {
    let isSuccess: Bool
    let message: String
}

#Preview {
    NavigationStack {
        WebhookSettingsView(profileStore: ProfileStore())
    }
}
