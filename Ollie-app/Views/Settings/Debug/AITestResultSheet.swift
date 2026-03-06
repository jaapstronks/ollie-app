//
//  AITestResultSheet.swift
//  Otis-app
//
//  Sheets for displaying AI test results

#if DEBUG

import SwiftUI
import OtisShared

// MARK: - Metadata Row

struct MetadataRow: View {
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

// MARK: - AI Test Result Sheet (Legacy)

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
                    .cornerRadius(LayoutConstants.cornerRadiusM)

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
                        .cornerRadius(LayoutConstants.cornerRadiusM)
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
                            .cornerRadius(LayoutConstants.cornerRadiusS)
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

// MARK: - New AI Test Result Sheet

struct NewAITestResultSheet: View {
    let result: AIOrchestrator.NewAITestResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AITestResultContent(result: result)
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

// MARK: - AI Test Result View (Navigation-based)

/// Navigation-push version of test result display.
/// Use this instead of sheet when already inside another sheet (e.g., Settings).
struct AITestResultView: View {
    let result: AIOrchestrator.NewAITestResult

    var body: some View {
        AITestResultContent(result: result)
    }
}

// MARK: - Shared Content

/// Shared content view used by both sheet and navigation presentations
private struct AITestResultContent: View {
    let result: AIOrchestrator.NewAITestResult

    var body: some View {
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
                .cornerRadius(LayoutConstants.cornerRadiusM)

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
                    .cornerRadius(LayoutConstants.cornerRadiusM)
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
                        .cornerRadius(LayoutConstants.cornerRadiusS)
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
    }
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
