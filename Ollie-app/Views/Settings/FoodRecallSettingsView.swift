//
//  FoodRecallSettingsView.swift
//  Otis-app
//
//  Settings view for configuring food recall alerts

import SwiftUI

/// Settings view for food recall alerts configuration
struct FoodRecallSettingsView: View {
    @ObservedObject var foodRecallService: FoodRecallService
    @State private var showingBrandPicker = false
    @State private var customBrand = ""
    @FocusState private var isCustomBrandFocused: Bool

    var body: some View {
        List {
            // Enable/disable section
            Section {
                Toggle(isOn: $foodRecallService.settings.enabled) {
                    Label {
                        Text(Strings.FoodRecall.enableAlerts)
                    } icon: {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.orange)
                    }
                }
                .onChange(of: foodRecallService.settings.enabled) { _, enabled in
                    if enabled {
                        Task {
                            await foodRecallService.checkForRecalls()
                        }
                    }
                }
            } footer: {
                Text(Strings.FoodRecall.enableAlertsFooter)
            }

            // Saved brands section
            if foodRecallService.settings.enabled {
                Section {
                    // List of saved brands
                    ForEach(foodRecallService.settings.savedBrands, id: \.self) { brand in
                        HStack {
                            Text(brand)
                            Spacer()
                        }
                    }
                    .onDelete(perform: deleteBrands)

                    // Add brand button
                    Button {
                        showingBrandPicker = true
                    } label: {
                        Label(Strings.FoodRecall.addBrand, systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text(Strings.FoodRecall.savedBrands)
                } footer: {
                    if foodRecallService.settings.savedBrands.isEmpty {
                        Text(Strings.FoodRecall.noBrandsHint)
                    }
                }

                // Check frequency section
                Section {
                    Picker(Strings.FoodRecall.checkFrequency, selection: $foodRecallService.settings.checkFrequency) {
                        ForEach(FoodAlertSettings.CheckFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.label).tag(frequency)
                        }
                    }
                } header: {
                    Text(Strings.FoodRecall.checkFrequency)
                }

                // Status section
                Section {
                    if foodRecallService.isLoading {
                        HStack {
                            ProgressView()
                            Text(Strings.FoodRecall.checking)
                                .foregroundColor(.secondary)
                        }
                    } else if let lastChecked = foodRecallService.lastChecked {
                        HStack {
                            Text(Strings.FoodRecall.lastChecked)
                            Spacer()
                            Text(lastChecked, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let error = foodRecallService.lastError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error.localizedDescription)
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }

                    // Matching recalls count
                    if !foodRecallService.matchingRecalls.isEmpty {
                        NavigationLink {
                            RecallListView(recalls: foodRecallService.matchingRecalls, foodRecallService: foodRecallService)
                        } label: {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(Strings.FoodRecall.matchingRecalls(count: foodRecallService.matchingRecalls.count))
                            }
                        }
                    }

                    // Manual refresh button
                    Button {
                        Task {
                            await foodRecallService.refresh()
                        }
                    } label: {
                        Label(Strings.FoodRecall.checkNow, systemImage: "arrow.clockwise")
                    }
                    .disabled(foodRecallService.isLoading)
                } header: {
                    Text(Strings.FoodRecall.status)
                }
            }
        }
        .navigationTitle(Strings.FoodRecall.title)
        .sheet(isPresented: $showingBrandPicker) {
            BrandPickerSheet(
                selectedBrands: $foodRecallService.settings.savedBrands,
                isPresented: $showingBrandPicker
            )
        }
    }

    private func deleteBrands(at offsets: IndexSet) {
        foodRecallService.settings.savedBrands.remove(atOffsets: offsets)
    }
}

// MARK: - Brand Picker Sheet

private struct BrandPickerSheet: View {
    @Binding var selectedBrands: [String]
    @Binding var isPresented: Bool
    @State private var customBrand = ""
    @FocusState private var isCustomBrandFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                // Custom brand entry
                Section {
                    HStack {
                        TextField(Strings.FoodRecall.customBrandPlaceholder, text: $customBrand)
                            .focused($isCustomBrandFocused)
                            .submitLabel(.done)
                            .onSubmit(addCustomBrand)

                        if !customBrand.isEmpty {
                            Button(action: addCustomBrand) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                } header: {
                    Text(Strings.FoodRecall.customBrand)
                }

                // Common brands
                Section {
                    ForEach(FoodRecallService.commonBrands, id: \.self) { brand in
                        Button {
                            toggleBrand(brand)
                        } label: {
                            HStack {
                                Text(brand)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedBrands.contains(brand) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text(Strings.FoodRecall.popularBrands)
                }
            }
            .navigationTitle(Strings.FoodRecall.selectBrands)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func toggleBrand(_ brand: String) {
        if let index = selectedBrands.firstIndex(of: brand) {
            selectedBrands.remove(at: index)
        } else {
            selectedBrands.append(brand)
        }
    }

    private func addCustomBrand() {
        let trimmed = customBrand.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !selectedBrands.contains(trimmed) else { return }
        selectedBrands.append(trimmed)
        customBrand = ""
        isCustomBrandFocused = false
    }
}

// MARK: - Recall List View

private struct RecallListView: View {
    let recalls: [FoodRecall]
    @ObservedObject var foodRecallService: FoodRecallService

    var body: some View {
        List {
            ForEach(recalls) { recall in
                RecallRowView(recall: recall, foodRecallService: foodRecallService)
            }
        }
        .navigationTitle(Strings.FoodRecall.recallAlerts)
    }
}

// MARK: - Recall Row View

private struct RecallRowView: View {
    let recall: FoodRecall
    @ObservedObject var foodRecallService: FoodRecallService
    @State private var showingDetail = false

    private var isAcknowledged: Bool {
        foodRecallService.settings.acknowledgedRecallIds.contains(recall.id)
    }

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: recall.severity.icon)
                            .foregroundColor(severityColor)
                        Text(recall.brand)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Text(recall.product)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Text(recall.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isAcknowledged {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .opacity(isAcknowledged ? 0.6 : 1)
        }
        .sheet(isPresented: $showingDetail) {
            RecallDetailSheet(recall: recall, foodRecallService: foodRecallService)
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

// MARK: - Recall Detail Sheet

private struct RecallDetailSheet: View {
    let recall: FoodRecall
    @ObservedObject var foodRecallService: FoodRecallService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent(Strings.FoodRecall.brand, value: recall.brand)
                    LabeledContent(Strings.FoodRecall.product, value: recall.product)
                    LabeledContent(Strings.FoodRecall.date, value: recall.date.formatted(date: .long, time: .omitted))
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: recall.severity.icon)
                                .foregroundColor(severityColor)
                            Text(recall.severity.label)
                                .font(.headline)
                        }
                        Text(recall.reason)
                            .font(.body)
                    }
                } header: {
                    Text(Strings.FoodRecall.reason)
                }

                if let url = recall.sourceURL {
                    Section {
                        Link(destination: url) {
                            Label(Strings.FoodRecall.viewSource, systemImage: "link")
                        }
                    }
                }

                Section {
                    Button {
                        foodRecallService.acknowledgeRecall(recall)
                        dismiss()
                    } label: {
                        Label(Strings.FoodRecall.acknowledge, systemImage: "checkmark.circle")
                    }
                }
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

// MARK: - Preview

#Preview {
    NavigationStack {
        FoodRecallSettingsView(foodRecallService: FoodRecallService())
    }
}
