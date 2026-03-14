//
//  SeniorWellnessView.swift
//  Ollie-app
//
//  Main dashboard view for senior dog wellness features
//  Part of Brief 05: Senior Wellness
//

import SwiftUI
import OtisShared

struct SeniorWellnessView: View {
    @Environment(ProfileStore.self) private var profileStore
    @StateObject private var wellnessStore = SeniorWellnessStore.shared

    @State private var showMobilitySheet = false
    @State private var showCognitiveSheet = false
    @State private var showQoLSheet = false
    @State private var showRRRSheet = false

    private var puppyName: String {
        profileStore.activeProfile?.name ?? "Your dog"
    }

    private var activeConditions: [HealthCondition] {
        profileStore.activeProfile?.healthConditions.filter { $0.status == .active } ?? []
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Daily Check-Ins Section
                dailyCheckInsSection

                // Quick Assessments
                quickAssessmentsSection

                // Recent Activity
                if hasRecentData {
                    recentActivitySection
                }

                // Full History Button
                NavigationLink(destination: SeniorWellnessHistoryView()) {
                    HStack {
                        Text(Strings.SeniorWellness.fullHealthHistory)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Quality of Life Assessment
                qolSection
            }
            .padding()
        }
        .navigationTitle(Strings.SeniorWellness.title)
        .sheet(isPresented: $showMobilitySheet) {
            MobilityAssessmentSheet(onSave: { assessment in
                wellnessStore.recordMobility(
                    score: assessment.score,
                    observations: assessment.observations,
                    note: assessment.note
                )
            })
        }
        .sheet(isPresented: $showCognitiveSheet) {
            CognitiveAssessmentSheet(onSave: { assessment in
                wellnessStore.recordCognitive(
                    symptoms: assessment.symptoms,
                    note: assessment.note
                )
            })
        }
        .sheet(isPresented: $showQoLSheet) {
            QualityOfLifeSheet(onSave: { assessment in
                wellnessStore.recordQoL(
                    hurt: assessment.hurt,
                    hunger: assessment.hunger,
                    hydration: assessment.hydration,
                    hygiene: assessment.hygiene,
                    happiness: assessment.happiness,
                    mobility: assessment.mobility,
                    moreDays: assessment.moreDays,
                    note: assessment.note
                )
            })
        }
        .sheet(isPresented: $showRRRSheet) {
            RespiratoryRateSheet(onSave: { reading in
                wellnessStore.recordRRR(
                    breathsPerMinute: reading.breathsPerMinute,
                    wasResting: reading.wasResting,
                    note: reading.note
                )
            })
        }
    }

    // MARK: - Daily Check-Ins Section

    @ViewBuilder
    private var dailyCheckInsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.SeniorWellness.dailyCheckIns)
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Mobility
                WellnessStatusCard(
                    title: Strings.SeniorWellness.mobilityCard,
                    icon: "figure.walk",
                    score: wellnessStore.latestMobility?.score,
                    maxScore: 5,
                    status: wellnessStore.latestMobility?.scoreDescription,
                    trend: wellnessStore.mobilityState.trend?.label,
                    trendIcon: wellnessStore.mobilityState.trend?.icon,
                    trendColor: wellnessStore.mobilityState.trend.map { Color($0.colorName) }
                ) {
                    showMobilitySheet = true
                }

                // Breathing (if heart condition)
                if wellnessStore.shouldShowRRRTracking(activeConditions: activeConditions) {
                    let rrrState = wellnessStore.rrrState(activeConditions: activeConditions)
                    WellnessStatusCard(
                        title: Strings.SeniorWellness.rrrCard,
                        icon: "lungs.fill",
                        score: wellnessStore.latestRRR?.breathsPerMinute,
                        maxScore: nil,
                        status: wellnessStore.latestRRR?.status.label,
                        statusColor: wellnessStore.latestRRR.map { Color($0.status.colorName) },
                        trend: rrrState.trend?.label,
                        trendIcon: rrrState.trend?.icon,
                        trendColor: rrrState.trend.map { Color($0.colorName) }
                    ) {
                        showRRRSheet = true
                    }
                }
            }
        }
    }

    // MARK: - Quick Assessments Section

    @ViewBuilder
    private var quickAssessmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clipboard.fill")
                Text("Assessments")
            }
            .font(.headline)

            VStack(spacing: 8) {
                // Cognitive Assessment
                AssessmentRow(
                    title: Strings.SeniorWellness.cognitiveAssessment,
                    icon: "brain.head.profile",
                    lastDate: wellnessStore.latestCognitive?.createdAt,
                    status: wellnessStore.latestCognitive?.severity.label,
                    statusColor: wellnessStore.latestCognitive.map { Color($0.severity.colorName) },
                    isDue: wellnessStore.cognitiveAssessmentDue
                ) {
                    showCognitiveSheet = true
                }

                Divider()

                // Quality of Life
                AssessmentRow(
                    title: Strings.SeniorWellness.qualityOfLife,
                    icon: "heart.circle.fill",
                    lastDate: wellnessStore.latestQoL?.createdAt,
                    status: wellnessStore.latestQoL?.interpretation.label,
                    statusColor: wellnessStore.latestQoL.map { Color($0.interpretation.colorName) },
                    isDue: wellnessStore.qolAssessmentDue
                ) {
                    showQoLSheet = true
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Recent Activity Section

    private var hasRecentData: Bool {
        wellnessStore.mobilityAssessmentsThisWeek().count > 0 ||
        wellnessStore.rrrReadingsThisWeek().count > 0
    }

    @ViewBuilder
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.SeniorWellness.recent)
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                // Mobility trend
                if let trend = wellnessStore.mobilityState.trend {
                    HStack(spacing: 6) {
                        Image(systemName: trend.icon)
                            .foregroundStyle(Color(trend.colorName))
                        Text(Strings.SeniorWellness.mobilityImproved(name: puppyName))
                            .font(.subheadline)
                    }
                }

                // Stiff mornings
                let stiffCount = wellnessStore.mobilityState.stiffMorningsThisWeek
                if stiffCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "bed.double.fill")
                            .foregroundStyle(.orange)
                        Text(Strings.SeniorWellness.stiffMorningsCount(stiffCount))
                            .font(.subheadline)
                    }
                }

                // RRR readings
                let elevatedCount = wellnessStore.rrrState(activeConditions: activeConditions).elevatedReadingsThisWeek
                if elevatedCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text("\(elevatedCount) elevated breathing reading(s)")
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Quality of Life Section

    @ViewBuilder
    private var qolSection: some View {
        if let qol = wellnessStore.latestQoL, qol.isCurrent {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: qol.interpretation.icon)
                        .foregroundStyle(Color(qol.interpretation.colorName))
                    Text(Strings.SeniorWellness.qolTitle)
                        .font(.headline)
                    Spacer()
                    Text(Strings.SeniorWellness.qolScore(qol.totalScore, maxScore: QualityOfLifeAssessment.maxScore))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(qol.interpretation.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !qol.concerningCategories.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(qol.concerningCategories.prefix(3), id: \.self) { category in
                            CapsuleBadge(category.label, icon: category.icon, color: .orange, style: .tinted)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Supporting Views

private struct WellnessStatusCard: View {
    let title: String
    let icon: String
    let score: Int?
    let maxScore: Int?
    let status: String?
    var statusColor: Color? = nil
    let trend: String?
    let trendIcon: String?
    let trendColor: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(.blue)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                if let score = score {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(score)")
                            .font(.title)
                            .fontWeight(.bold)
                        if let max = maxScore {
                            Text("/\(max)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("bpm")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("--")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }

                if let status = status {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(statusColor ?? .secondary)
                }

                if let trend = trend, let trendIcon = trendIcon {
                    HStack(spacing: 4) {
                        Image(systemName: trendIcon)
                            .font(.caption2)
                        Text(trend)
                            .font(.caption2)
                    }
                    .foregroundStyle(trendColor ?? .secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct AssessmentRow: View {
    let title: String
    let icon: String
    let lastDate: Date?
    let status: String?
    let statusColor: Color?
    let isDue: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let date = lastDate {
                        Text(date, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not yet completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let status = status {
                    CapsuleBadge(status, color: statusColor ?? .gray, style: .tinted)
                }

                if isDue {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.orange)
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - History View (Placeholder)

struct SeniorWellnessHistoryView: View {
    var body: some View {
        Text("Full health history")
            .navigationTitle("Health History")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SeniorWellnessView()
            .environment(ProfileStore.shared)
    }
}
