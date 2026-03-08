//
//  VisitSummaryView.swift
//  Ollie-app
//
//  Displays and allows sharing of vet visit summary.
//  Supports PDF and text export formats.
//

import SwiftUI
import OtisShared

/// View for displaying and sharing vet visit summary
struct VisitSummaryView: View {
    @EnvironmentObject private var profileStore: ProfileStore

    @Environment(\.dismiss) private var dismiss

    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showCopiedToast = false

    private let summaryGenerator = VisitSummaryGenerator()
    private let symptomStore = HealthSymptomStore.shared
    private let checkInStore = HealthCheckInStore.shared

    private var profile: PuppyProfile? {
        profileStore.activeProfile
    }

    private var conditions: [HealthCondition] {
        profile?.healthConditions ?? []
    }

    private var medications: [Medication] {
        profile?.medicationSchedule.medications.filter { $0.isActive } ?? []
    }

    private var recentSymptoms: [HealthSymptomLog] {
        symptomStore.recentSymptoms()
    }

    private var recentCheckIns: [HealthCheckIn] {
        Array(checkInStore.checkIns.values)
    }

    private var allergies: [Allergy] {
        profile?.allergies ?? []
    }

    private var recentWeights: [WeightMeasurement] {
        // WeightStore might not be available, return empty array as fallback
        []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile section
                    profileSection

                    // Allergies (if critical)
                    if !allergies.filter({ $0.severity == .severe || $0.severity == .lifeThreatening }).isEmpty {
                        allergiesSection
                    }

                    // Conditions
                    conditionsSection

                    // Medications
                    medicationsSection

                    // Recent symptoms
                    symptomsSection

                    // Health assessments
                    if !recentCheckIns.isEmpty {
                        assessmentsSection
                    }

                    // Weight trend
                    if recentWeights.count >= 2 {
                        weightSection
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Strings.VetVisit.Summary.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(Strings.Common.close) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            shareAsPDF()
                        } label: {
                            Label(Strings.VetVisit.shareAsPDF, systemImage: "doc.fill")
                        }

                        Button {
                            shareAsText()
                        } label: {
                            Label(Strings.VetVisit.shareAsText, systemImage: "doc.text")
                        }

                        Divider()

                        Button {
                            copyToClipboard()
                        } label: {
                            Label(Strings.VetVisit.copyToClipboard, systemImage: "doc.on.clipboard")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: shareItems)
            }
            .overlay {
                if showCopiedToast {
                    toastOverlay
                }
            }
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.VetVisit.Summary.profileSection, icon: "pawprint.fill")

            VStack(alignment: .leading, spacing: 8) {
                if let profile = profile {
                    profileRow(label: Strings.VetVisit.Summary.name, value: profile.name)
                    if let breed = profile.breed {
                        profileRow(label: Strings.VetVisit.Summary.breed, value: breed)
                    }
                    profileRow(label: Strings.VetVisit.Summary.age, value: formatAge(months: profile.ageInMonths))
                    profileRow(label: Strings.VetVisit.Summary.size, value: profile.sizeCategory.label)
                    profileRow(label: Strings.VetVisit.Summary.gender, value: profile.gender.label)
                    if let weight = recentWeights.first {
                        profileRow(label: Strings.VetVisit.Summary.weight, value: String(format: "%.1f kg", weight.weightKg))
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var allergiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.VetVisit.Summary.allergiesSection, icon: "exclamationmark.triangle.fill", color: Color.otisDanger)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(allergies.filter { $0.severity == .severe || $0.severity == .lifeThreatening }, id: \.id) { allergy in
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.otisDanger)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(allergy.allergen)
                                .font(.subheadline.weight(.medium))

                            Text(allergy.severity.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color.otisDanger.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var conditionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.VetVisit.Summary.conditionsSection, icon: "heart.text.square.fill")

            VStack(alignment: .leading, spacing: 8) {
                let activeConditions = conditions.filter { $0.status == .active || $0.status == .monitoring }

                if activeConditions.isEmpty {
                    Text(Strings.VetVisit.Summary.noConditions)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(activeConditions, id: \.id) { condition in
                        conditionRow(condition)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var medicationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.VetVisit.Summary.medicationsSection, icon: "pills.fill")

            VStack(alignment: .leading, spacing: 8) {
                if medications.isEmpty {
                    Text(Strings.VetVisit.Summary.noMedications)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(medications, id: \.id) { med in
                        medicationRow(med)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var symptomsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.VetVisit.Summary.recentSymptomsSection, icon: "waveform.path.ecg")

            VStack(alignment: .leading, spacing: 8) {
                if recentSymptoms.isEmpty {
                    Text(Strings.VetVisit.Summary.noRecentSymptoms)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    let grouped = Dictionary(grouping: recentSymptoms) { $0.symptomType.label }
                    let sortedKeys = grouped.keys.sorted { (grouped[$0]?.count ?? 0) > (grouped[$1]?.count ?? 0) }
                    ForEach(sortedKeys.prefix(5).map { $0 }, id: \.self) { symptomName in
                        if let occurrences = grouped[symptomName] {
                            symptomRow(name: symptomName, count: occurrences.count)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var assessmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.VetVisit.Summary.assessmentsSection, icon: "chart.bar.fill")

            VStack(alignment: .leading, spacing: 8) {
                let grouped = Dictionary(grouping: recentCheckIns) { $0.category }
                ForEach(Array(grouped.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { category in
                    if let checkIns = grouped[category],
                       let latest = checkIns.max(by: { $0.createdAt < $1.createdAt }) {
                        assessmentRow(category: category, score: latest.score)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.VetVisit.Summary.weightTrendSection, icon: "scalemass.fill")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(recentWeights.prefix(5)), id: \.id) { weight in
                    HStack {
                        Text(String(format: "%.1f kg", weight.weightKg))
                            .font(.subheadline.weight(.medium))

                        Spacer()

                        Text(weight.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Row Components

    private func sectionHeader(_ title: String, icon: String, color: Color = Color.otisAccent) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)

            Text(title)
                .font(.headline)

            Spacer()
        }
    }

    private func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }

    private func conditionRow(_ condition: HealthCondition) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: condition.type.icon)
                    .foregroundStyle(Color.otisWarning)

                Text(condition.displayName)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text(condition.severity.label)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(condition.severity.colorName).opacity(0.2))
                    .clipShape(Capsule())
            }

            if let notes = condition.vetRecommendations, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func medicationRow(_ med: Medication) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(med.name)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text(med.recurrence.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let dosage = med.instructions {
                Text(dosage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func symptomRow(name: String, count: Int) -> some View {
        HStack {
            Text(name)
                .font(.subheadline)

            Spacer()

            Text("\(count)x")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private func assessmentRow(category: HealthCheckInCategory, score: Int) -> some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundStyle(Color.otisAccent)

            Text(category.label)
                .font(.subheadline)

            Spacer()

            // Score dots
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { i in
                    Circle()
                        .fill(i <= score ? Color.otisAccent : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }

    private var toastOverlay: some View {
        VStack {
            Spacer()

            Text(Strings.VetVisit.copiedToClipboard)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.8))
                .clipShape(Capsule())
                .padding(.bottom, 60)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: showCopiedToast)
    }

    // MARK: - Actions

    private func shareAsPDF() {
        guard let profile = profile else { return }
        Task { @MainActor in
            let pdfData = summaryGenerator.generatePDF(
                for: profile,
                conditions: conditions,
                medications: medications,
                recentSymptoms: recentSymptoms,
                recentCheckIns: recentCheckIns,
                allergies: allergies,
                recentWeights: recentWeights
            )

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(profile.name)_VetVisitSummary.pdf")

            do {
                try pdfData.write(to: tempURL)
                shareItems = [tempURL]
                showShareSheet = true
            } catch {
                print("Failed to write PDF: \(error)")
            }
        }
    }

    private func shareAsText() {
        guard let profile = profile else { return }
        let text = summaryGenerator.generateText(
            for: profile,
            conditions: conditions,
            medications: medications,
            recentSymptoms: recentSymptoms,
            recentCheckIns: recentCheckIns,
            allergies: allergies,
            recentWeights: recentWeights
        )

        shareItems = [text]
        showShareSheet = true
    }

    private func copyToClipboard() {
        guard let profile = profile else { return }
        let text = summaryGenerator.generateText(
            for: profile,
            conditions: conditions,
            medications: medications,
            recentSymptoms: recentSymptoms,
            recentCheckIns: recentCheckIns,
            allergies: allergies,
            recentWeights: recentWeights
        )

        UIPasteboard.general.string = text

        withAnimation {
            showCopiedToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedToast = false
            }
        }
    }

    // MARK: - Helpers

    private func formatAge(months: Int) -> String {
        let years = months / 12
        let remainingMonths = months % 12

        if years > 0 && remainingMonths > 0 {
            return "\(years) year\(years == 1 ? "" : "s"), \(remainingMonths) month\(remainingMonths == 1 ? "" : "s")"
        } else if years > 0 {
            return "\(years) year\(years == 1 ? "" : "s")"
        } else {
            return "\(months) month\(months == 1 ? "" : "s")"
        }
    }
}
