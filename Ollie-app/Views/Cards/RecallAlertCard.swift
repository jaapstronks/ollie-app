//
//  RecallAlertCard.swift
//  Otis-app
//
//  Alert card displayed on Today view when food recalls match user's brands

import SwiftUI

/// Card displayed on Today view when there are unacknowledged food recalls
struct RecallAlertCard: View {
    var foodRecallService: FoodRecallService
    @State private var showingRecalls = false

    private var unacknowledgedRecalls: [FoodRecall] {
        foodRecallService.unacknowledgedRecalls
    }

    var body: some View {
        if !unacknowledgedRecalls.isEmpty {
            Button {
                showingRecalls = true
            } label: {
                HStack(spacing: 12) {
                    // Warning icon
                    ZStack {
                        Circle()
                            .fill(backgroundColor)
                            .frame(width: 40, height: 40)
                        Image(systemName: highestSeverity.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(iconColor)
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.FoodRecall.alertTitle)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(alertMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(borderColor, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingRecalls) {
                RecallAlertSheet(
                    recalls: unacknowledgedRecalls,
                    foodRecallService: foodRecallService
                )
            }
        }
    }

    private var highestSeverity: FoodRecall.Severity {
        unacknowledgedRecalls.map(\.severity).max(by: { severityOrder($0) < severityOrder($1) }) ?? .low
    }

    private func severityOrder(_ severity: FoodRecall.Severity) -> Int {
        switch severity {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .critical: return 3
        }
    }

    private var backgroundColor: Color {
        switch highestSeverity {
        case .low: return .blue.opacity(0.1)
        case .medium: return .yellow.opacity(0.1)
        case .high: return .orange.opacity(0.1)
        case .critical: return .red.opacity(0.1)
        }
    }

    private var iconColor: Color {
        switch highestSeverity {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }

    private var borderColor: Color {
        switch highestSeverity {
        case .low: return .blue.opacity(0.3)
        case .medium: return .yellow.opacity(0.3)
        case .high: return .orange.opacity(0.3)
        case .critical: return .red.opacity(0.3)
        }
    }

    private var alertMessage: String {
        let count = unacknowledgedRecalls.count
        if count == 1 {
            return Strings.FoodRecall.alertMessageSingle(brand: unacknowledgedRecalls[0].brand)
        } else {
            return Strings.FoodRecall.alertMessageMultiple(count: count)
        }
    }
}

// MARK: - Recall Alert Sheet

private struct RecallAlertSheet: View {
    let recalls: [FoodRecall]
    var foodRecallService: FoodRecallService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(recalls) { recall in
                    RecallAlertRow(recall: recall, foodRecallService: foodRecallService)
                }
            }
            .navigationTitle(Strings.FoodRecall.recallAlerts)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Recall Alert Row

private struct RecallAlertRow: View {
    let recall: FoodRecall
    var foodRecallService: FoodRecallService
    @State private var showingDetail = false

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: recall.severity.icon)
                            .foregroundStyle(severityColor)
                        Text(recall.brand)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }

                    Text(recall.reason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text(recall.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showingDetail) {
            RecallDetailView(recall: recall, foodRecallService: foodRecallService)
        }
    }

    private var severityColor: Color {
        switch recall.severity {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Recall Detail View

private struct RecallDetailView: View {
    let recall: FoodRecall
    var foodRecallService: FoodRecallService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Severity header
                    HStack {
                        Image(systemName: recall.severity.icon)
                            .font(.title)
                            .foregroundStyle(severityColor)
                        Text(recall.severity.label)
                            .font(.title2.bold())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(severityColor.opacity(0.1))
                    .cornerRadius(12)

                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: Strings.FoodRecall.brand, value: recall.brand)
                        DetailRow(label: Strings.FoodRecall.product, value: recall.product)
                        DetailRow(label: Strings.FoodRecall.date, value: recall.date.formatted(date: .long, time: .omitted))
                    }

                    // Reason
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.FoodRecall.reason)
                            .font(.headline)
                        Text(recall.reason)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    // Actions
                    VStack(spacing: 12) {
                        if let url = recall.sourceURL {
                            Link(destination: url) {
                                HStack {
                                    Image(systemName: "link")
                                    Text(Strings.FoodRecall.viewSource)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                            }
                        }

                        Button {
                            foodRecallService.acknowledgeRecall(recall)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text(Strings.FoodRecall.acknowledge)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .foregroundStyle(.green)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(Strings.FoodRecall.recallDetails)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var severityColor: Color {
        switch recall.severity {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Detail Row

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        RecallAlertCard(foodRecallService: FoodRecallService())
    }
    .padding()
}
