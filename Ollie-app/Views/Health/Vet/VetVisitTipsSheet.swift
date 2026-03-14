//
//  VetVisitTipsSheet.swift
//  Ollie-app
//
//  Full sheet displaying all vet visit tips organized by category.
//  Includes option to generate visit summary.
//

import SwiftUI
import OtisShared

/// Sheet showing all tips for an upcoming vet visit
struct VetVisitTipsSheet: View {
    let appointment: DogAppointment
    let tips: [VetVisitTip]
    let onPrepareSummary: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var expandedCategories: Set<VetVisitTip.TipCategory> = []

    private var groupedTips: [(category: VetVisitTip.TipCategory, tips: [VetVisitTip])] {
        tips.groupedByCategory()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Appointment header
                    appointmentHeader

                    // Tips by category
                    ForEach(groupedTips, id: \.category) { group in
                        tipCategorySection(category: group.category, tips: group.tips)
                    }

                    // Prepare summary button
                    if !tips.isEmpty {
                        Button(action: onPrepareSummary) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text(Strings.VetVisit.prepareSummary)
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.otisAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Strings.VetVisit.visitTips)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Components

    private var appointmentHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "cross.case.fill")
                    .font(.title2)
                    .foregroundStyle(Color.otisAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(appointment.title)
                        .font(.headline)

                    Text(appointment.dateString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }

    private func tipCategorySection(category: VetVisitTip.TipCategory, tips: [VetVisitTip]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedCategories.contains(category) {
                        expandedCategories.remove(category)
                    } else {
                        expandedCategories.insert(category)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: category.icon)
                        .font(.title3)
                        .foregroundStyle(categoryColor(for: category))
                        .frame(width: 28)

                    Text(categoryTitle(for: category))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    // High priority badge
                    let highPriorityCount = tips.filter { $0.priority == .high }.count
                    if highPriorityCount > 0 {
                        CapsuleBadge("\(highPriorityCount)", color: .otisDanger, style: .filled)
                    }

                    Image(systemName: expandedCategories.contains(category) ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            // Tips (expanded)
            if expandedCategories.contains(category) || tips.contains(where: { $0.priority == .high }) {
                ForEach(tips) { tip in
                    tipRow(tip)
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            // Auto-expand categories with high priority tips
            if tips.contains(where: { $0.priority == .high }) {
                expandedCategories.insert(category)
            }
        }
    }

    private func tipRow(_ tip: VetVisitTip) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Priority indicator
            Circle()
                .fill(priorityColor(for: tip.priority))
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Text(tip.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Source
                Text(tip.source.description)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }

            Spacer()
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func categoryTitle(for category: VetVisitTip.TipCategory) -> String {
        switch category {
        case .breedRisk: return Strings.VetVisit.BreedRisks.awareness
        case .ageRelated: return Strings.VetVisit.Milestones.ageBasedScreenings
        case .conditionRelated: return Strings.VetVisit.Summary.conditionsSection
        case .recentSymptom: return Strings.VetVisit.Summary.recentSymptomsSection
        case .preventive: return Strings.VetVisit.Tips.preventiveCare
        }
    }

    private func categoryColor(for category: VetVisitTip.TipCategory) -> Color {
        switch category {
        case .breedRisk: return Color.otisWarning
        case .ageRelated: return Color.otisInfo
        case .conditionRelated: return Color.otisDanger
        case .recentSymptom: return .purple
        case .preventive: return .otisSuccess
        }
    }

    private func priorityColor(for priority: VetVisitTip.TipPriority) -> Color {
        switch priority {
        case .high: return Color.otisDanger
        case .medium: return Color.otisWarning
        case .low: return Color.otisInfo
        }
    }
}

// MARK: - Preview

#Preview {
    VetVisitTipsSheet(
        appointment: DogAppointment(
            title: "Annual Checkup",
            appointmentType: .vetCheckup,
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600)
        ),
        tips: [
            VetVisitTip(
                category: .breedRisk,
                title: "Hip dysplasia screening due",
                description: "Golden Retrievers are at higher risk. This is a good time to discuss screening.",
                source: .breed("Golden Retriever"),
                priority: .high
            ),
            VetVisitTip(
                category: .ageRelated,
                title: "Senior bloodwork panel",
                description: "Regular bloodwork helps catch age-related issues early.",
                source: .age(months: 96),
                priority: .high
            ),
            VetVisitTip(
                category: .recentSymptom,
                title: "Recurring limping",
                description: "Logged 3 times in the last 30 days. Discuss potential causes.",
                source: .symptom(.limping, count: 3),
                priority: .medium
            ),
            VetVisitTip(
                category: .preventive,
                title: "Dental health check",
                description: "Regular dental exams prevent periodontal disease.",
                source: .preventive("Annual care"),
                priority: .low
            )
        ],
        onPrepareSummary: {}
    )
}
