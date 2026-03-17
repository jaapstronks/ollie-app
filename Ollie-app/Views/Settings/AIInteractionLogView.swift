//
//  AIInteractionLogView.swift
//  Ollie-app
//
//  View for reviewing and exporting AI interaction logs.
//

import SwiftUI

/// View for reviewing AI interactions and providing feedback.
struct AIInteractionLogView: View {
    @State private var entries: [AIInteractionEntry] = []
    @State private var selectedEntry: AIInteractionEntry?
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var feedbackText = ""
    @State private var selectedRating: AIInteractionEntry.FeedbackRating?

    var body: some View {
        List {
            // Export section
            Section {
                Button {
                    exportURL = AIInteractionLogger.shared.exportToFile()
                    if exportURL != nil {
                        showingExportSheet = true
                    }
                } label: {
                    Label("Export Full Log (JSON)", systemImage: "square.and.arrow.up")
                }

                Button {
                    UIPasteboard.general.string = AIInteractionLogger.shared.exportSummary()
                    HapticFeedback.success()
                } label: {
                    Label("Copy Summary to Clipboard", systemImage: "doc.on.clipboard")
                }

                Button(role: .destructive) {
                    AIInteractionLogger.shared.clearAll()
                    loadEntries()
                } label: {
                    Label("Clear All Logs", systemImage: "trash")
                }
            } header: {
                Text("Export")
            } footer: {
                Text("Export includes: context sent, system prompts, responses, and any feedback you've added.")
            }

            // Entries section
            Section {
                if entries.isEmpty {
                    Text("No AI interactions logged yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entries) { entry in
                        Button {
                            selectedEntry = entry
                        } label: {
                            EntryRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text("Recent Interactions (\(entries.count))")
            }
        }
        .navigationTitle("AI Interaction Log")
        .onAppear {
            loadEntries()
        }
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(item: $selectedEntry) { entry in
            EntryDetailSheet(entry: entry, onFeedbackSubmitted: {
                loadEntries()
            })
        }
    }

    private func loadEntries() {
        entries = AIInteractionLogger.shared.recentEntries(limit: 100)
    }
}

// MARK: - Entry Row

private struct EntryRow: View {
    let entry: AIInteractionEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.surface)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                if let rating = entry.feedbackRating {
                    Image(systemName: ratingIcon(rating))
                        .foregroundStyle(ratingColor(rating))
                }

                Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = entry.error {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            } else {
                // Show first meaningful field from response
                if let preview = responsePreview(entry) {
                    Text(preview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            HStack(spacing: 8) {
                Text(entry.provider ?? "unknown")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if let conf = entry.confidence {
                    Text("\(Int(conf * 100))% conf")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Text("\(entry.latencyMs)ms")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private func responsePreview(_ entry: AIInteractionEntry) -> String? {
        guard let jsonString = entry.responseJSON,
              let data = jsonString.data(using: .utf8),
              let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Try common fields
        if let text = response["progressAssessment"] as? String { return text }
        if let text = response["assessment"] as? String { return text }
        if let text = response["wellnessAssessment"] as? String { return text }
        if let text = response["encouragementMessage"] as? String { return text }
        if let text = response["suggestion"] as? String { return text }
        if let text = response["keyInsight"] as? String { return text }

        return nil
    }

    private func ratingIcon(_ rating: AIInteractionEntry.FeedbackRating) -> String {
        switch rating {
        case .helpful: return "hand.thumbsup.fill"
        case .notHelpful: return "hand.thumbsdown.fill"
        case .wrong: return "xmark.circle.fill"
        case .tooWordy: return "text.badge.minus"
        case .missingContext: return "questionmark.circle.fill"
        }
    }

    private func ratingColor(_ rating: AIInteractionEntry.FeedbackRating) -> Color {
        switch rating {
        case .helpful: return .green
        case .notHelpful, .tooWordy: return .orange
        case .wrong, .missingContext: return .red
        }
    }
}

// MARK: - Entry Detail Sheet

private struct EntryDetailSheet: View {
    let entry: AIInteractionEntry
    var onFeedbackSubmitted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var feedbackText = ""
    @State private var selectedRating: AIInteractionEntry.FeedbackRating?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.surface)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(entry.timestamp.formatted())
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Label(entry.provider ?? "unknown", systemImage: "server.rack")
                            Label("\(entry.latencyMs)ms", systemImage: "clock")
                            if let conf = entry.confidence {
                                Label("\(Int(conf * 100))%", systemImage: "percent")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Response
                    sectionHeader("Response")
                    if let error = entry.error {
                        Text("Error: \(error)")
                            .foregroundStyle(.red)
                    } else if let responseJSON = entry.responseJSON {
                        codeBlock(responseJSON)
                    }

                    Divider()

                    // Context sent
                    sectionHeader("Context Sent to AI")
                    codeBlock(contextToString(entry.contextPayload))

                    Divider()

                    // System prompt
                    sectionHeader("System Prompt")
                    codeBlock(entry.systemPrompt)

                    Divider()

                    // Feedback
                    sectionHeader("Your Feedback")
                    Text("Help improve AI responses by rating and commenting")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Rating picker
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(AIInteractionEntry.FeedbackRating.allCases, id: \.self) { rating in
                            Button {
                                selectedRating = rating
                            } label: {
                                Text(ratingLabel(rating))
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedRating == rating ? Color.accentColor : Color(.secondarySystemBackground))
                                    .foregroundStyle(selectedRating == rating ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    TextField("Optional comment (e.g., 'we trained with kibble, didn't log as meal')", text: $feedbackText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)

                    if selectedRating != nil {
                        Button("Submit Feedback") {
                            AIInteractionLogger.shared.addFeedback(
                                entryId: entry.id,
                                rating: selectedRating!,
                                comment: feedbackText.isEmpty ? nil : feedbackText
                            )
                            onFeedbackSubmitted()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    // Existing feedback
                    if let existingRating = entry.feedbackRating {
                        Divider()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Previous feedback: \(ratingLabel(existingRating))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let comment = entry.userFeedback {
                                Text(comment)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Interaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: exportText()) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
    }

    @ViewBuilder
    private func codeBlock(_ text: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(text)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func contextToString(_ payload: AIContextPayload) -> String {
        // Convert the context payload to JSON
        if let data = try? JSONEncoder().encode(payload),
           let string = String(data: data, encoding: .utf8) {
            // Try to pretty-print it
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                return prettyString
            }
            return string
        }
        return "Unable to encode context"
    }

    private func ratingLabel(_ rating: AIInteractionEntry.FeedbackRating) -> String {
        switch rating {
        case .helpful: return "Helpful"
        case .notHelpful: return "Not Helpful"
        case .wrong: return "Wrong"
        case .tooWordy: return "Too Wordy"
        case .missingContext: return "Missing Context"
        }
    }

    private func exportText() -> String {
        var text = "AI Interaction: \(entry.surface)\n"
        text += "Time: \(entry.timestamp.formatted())\n"
        text += "Provider: \(entry.provider ?? "unknown")\n\n"
        text += "== Response ==\n"
        if let responseJSON = entry.responseJSON {
            text += responseJSON
        }
        text += "\n\n== Context ==\n"
        text += contextToString(entry.contextPayload)
        text += "\n\n== System Prompt ==\n"
        text += entry.systemPrompt
        return text
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AIInteractionLogView()
    }
}
