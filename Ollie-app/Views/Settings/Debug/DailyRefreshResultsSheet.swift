//
//  DailyRefreshResultsSheet.swift
//  Ollie-app
//
//  Sheet for displaying daily AI refresh simulation results
//

#if DEBUG

import SwiftUI

/// Sheet displaying results from daily AI refresh simulation
struct DailyRefreshResultsSheet: View {
    let results: [AIOrchestrator.NewAITestResult]
    @Binding var selectedResult: AIOrchestrator.NewAITestResult?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Summary header
                    SummaryHeaderView(results: results)

                    // Results list
                    ForEach(results, id: \.surface) { result in
                        ResultRowButton(result: result) {
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(50))
                                selectedResult = result
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("AI Refresh Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(item: $selectedResult) { result in
                NewAITestResultSheet(result: result)
            }
        }
    }
}

// MARK: - Subviews

private struct SummaryHeaderView: View {
    let results: [AIOrchestrator.NewAITestResult]

    private var successCount: Int {
        results.filter(\.isSuccess).count
    }

    private var totalLatency: Int {
        results.reduce(0) { $0 + $1.latencyMs }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily AI Refresh")
                    .font(.headline)
                Text("\(successCount)/\(results.count) surfaces succeeded")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(totalLatency)ms total")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct ResultRowButton: View {
    let result: AIOrchestrator.NewAITestResult
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(result.isSuccess ? .green : .red)

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.surface.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    if result.isSuccess {
                        Text(responsePreview(result))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text(result.error ?? "Unknown error")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Spacer()

                Text("\(result.latencyMs)ms")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func responsePreview(_ result: AIOrchestrator.NewAITestResult) -> String {
        guard let response = result.response as? [String: Any] else {
            return "No response data"
        }

        switch result.surface {
        case .insightBundle:
            if let daily = response["dailyStatus"] as? [String: Any],
               let headline = daily["headline"] as? String {
                return headline
            }
        case .trainingGuidance:
            if let skill = response["suggestedSkill"] as? String {
                return "Focus: \(skill)"
            }
            if let advice = response["sessionAdvice"] as? String {
                return advice
            }
        case .pottyAnalysis:
            if let assessment = response["progressAssessment"] as? String {
                return assessment
            }
        case .socializationGuidance:
            if let assessment = response["assessment"] as? String {
                return assessment
            }
        case .healthInsights:
            if let assessment = response["wellnessAssessment"] as? String {
                return assessment
            }
        case .notificationPolicy:
            if let suppress = response["suppressPotty"] as? Bool {
                return suppress ? "Suppress potty reminders" : "Keep reminders active"
            }
        }

        if let confidence = response["confidence"] as? Double {
            return String(format: "Confidence: %.0f%%", confidence * 100)
        }

        return "Tap to view details"
    }
}

#Preview {
    DailyRefreshResultsSheet(
        results: [
            AIOrchestrator.NewAITestResult(
                surface: .insightBundle,
                timestamp: Date(),
                latencyMs: 342,
                provider: "anthropic",
                model: "claude-haiku",
                reasoningTags: [],
                response: nil,
                rawResponse: nil,
                error: nil
            ),
            AIOrchestrator.NewAITestResult(
                surface: .trainingGuidance,
                timestamp: Date(),
                latencyMs: 256,
                provider: "anthropic",
                model: "claude-haiku",
                reasoningTags: [],
                response: nil,
                rawResponse: nil,
                error: "Test error"
            )
        ],
        selectedResult: .constant(nil)
    )
}

#endif
