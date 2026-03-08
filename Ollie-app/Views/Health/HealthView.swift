//
//  HealthView.swift
//  Otis-app
//
//  Health tracking view: weight chart and health milestones timeline

import SwiftUI
import OtisShared

/// Main health view showing weight tracking and health milestones
struct HealthView: View {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var milestoneStore: MilestoneStore

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var weightStore: WeightStore
    @EnvironmentObject var routineStore: RoutineStore

    @State private var showWeightSheet = false
    @State private var showAddMilestoneSheet = false
    @State private var showSymptomLogSheet = false
    @AppStorage(UserPreferences.Key.weightUnit.rawValue) private var weightUnitRaw = WeightUnit.kg.rawValue

    @StateObject private var symptomStore = HealthSymptomStore.shared
    @StateObject private var checkInStore = HealthCheckInStore.shared
    @StateObject private var seniorWellnessStore = SeniorWellnessStore.shared

    @State private var showMobilitySheet = false
    @State private var showCognitiveSheet = false
    @State private var showQoLSheet = false
    @State private var showRRRSheet = false

    @Environment(\.colorScheme) private var colorScheme

    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? .kg
    }

    // MARK: - Computed Properties

    private var profile: PuppyProfile? {
        viewModel.profileStore.profile
    }

    private var chartPoints: [WeightChartPoint] {
        guard let birthDate = profile?.birthDate else { return [] }
        return weightStore.chartPoints(birthDate: birthDate)
    }

    private var latestWeight: (weight: Double, date: Date)? {
        weightStore.latestWeight
    }

    private var weightDelta: (delta: Double, previousDate: Date)? {
        weightStore.weightDelta
    }

    private var referenceCurve: [GrowthReference] {
        guard let size = profile?.sizeCategory else {
            return GrowthCurves.goldenRetrieverFemale
        }
        return GrowthCurves.curve(for: size)
    }

    // Vet visit state
    @State private var showVetTipsSheet = false
    @State private var showVisitSummary = false
    @State private var showHealthCalendar = false
    @State private var showAppointmentForm = false
    @State private var appointmentPrefill: (conditionType: HealthConditionType, title: String)?

    @EnvironmentObject private var appointmentStore: AppointmentStore

    // Vet tip generator
    private let tipGenerator = VetVisitTipGenerator()

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Senior wellness section (for senior dogs)
                if isSenior {
                    seniorWellnessSection
                }

                // Adult wellness section (for adult dogs)
                if isAdult && !isSenior {
                    adultWellnessSection
                }

                // Symptoms section (for dogs with conditions)
                if hasActiveConditions {
                    symptomsSection
                }

                // Breed risk awareness section
                if let profile = profile {
                    breedRiskSection(for: profile)
                }

                // Follow-up reminders section
                if hasActiveConditions, let profile = profile {
                    followUpRemindersSection(for: profile)
                }

                // Health calendar navigation
                healthCalendarSection

                // Weight section
                weightSection

                // Milestones section
                milestonesSection
            }
            .padding()
        }
        .navigationTitle(Strings.Health.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Analytics.track(.healthTimelineViewed)
        }
        .sheet(isPresented: $showWeightSheet) {
            WeightLogSheet(isPresented: $showWeightSheet)
        }
        .sheet(isPresented: $showSymptomLogSheet) {
            SymptomLogSheet(
                onSave: { symptom in
                    symptomStore.log(symptom)
                    showSymptomLogSheet = false
                },
                onCancel: {
                    showSymptomLogSheet = false
                }
            )
            .environmentObject(viewModel.profileStore)
        }
        .sheet(isPresented: $showMobilitySheet) {
            MobilityAssessmentSheet(onSave: { assessment in
                seniorWellnessStore.recordMobility(
                    score: assessment.score,
                    observations: assessment.observations,
                    note: assessment.note
                )
            })
            .environmentObject(viewModel.profileStore)
        }
        .sheet(isPresented: $showCognitiveSheet) {
            CognitiveAssessmentSheet(onSave: { assessment in
                seniorWellnessStore.recordCognitive(
                    symptoms: assessment.symptoms,
                    note: assessment.note
                )
            })
            .environmentObject(viewModel.profileStore)
        }
        .sheet(isPresented: $showQoLSheet) {
            QualityOfLifeSheet(onSave: { assessment in
                seniorWellnessStore.recordQoL(
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
            .environmentObject(viewModel.profileStore)
        }
        .sheet(isPresented: $showRRRSheet) {
            RespiratoryRateSheet(onSave: { reading in
                seniorWellnessStore.recordRRR(
                    breathsPerMinute: reading.breathsPerMinute,
                    wasResting: reading.wasResting,
                    note: reading.note
                )
            })
            .environmentObject(viewModel.profileStore)
        }
    }

    private var hasActiveConditions: Bool {
        guard let profile = profile else { return false }
        return !profile.healthConditions.filter { $0.status == .active }.isEmpty ||
               profile.lifecyclePhase == .senior
    }

    private var isSenior: Bool {
        profile?.lifecyclePhase == .senior || seniorWellnessStore.shouldShowSeniorFeatures(for: profile)
    }

    private var isAdult: Bool {
        guard let phase = profile?.lifecyclePhase else { return false }
        return phase == .adult || phase == .youngAdult
    }

    // MARK: - Adult Wellness Section

    @ViewBuilder
    private var adultWellnessSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            SectionHeader(title: Strings.Routine.wellness, icon: "figure.walk.motion", tint: .green) {
                NavigationLink(destination: RoutineView().environmentObject(routineStore)) {
                    Text(Strings.Common.seeAll)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }

            // Adult wellness content
            VStack(spacing: 12) {
                // Grooming due card (if any due)
                let dueGrooming = routineStore.dueGroomingActivities
                if !dueGrooming.isEmpty {
                    GroomingCard(
                        activities: routineStore.groomingActivities,
                        onMarkComplete: { activity in
                            routineStore.markGroomingCompleted(activity)
                        },
                        onTap: {}
                    )
                }

                // Enrichment suggestion
                if let suggestion = routineStore.enrichmentSuggestion {
                    EnrichmentCard(
                        activities: routineStore.enrichmentActivities,
                        suggestion: suggestion,
                        onLogActivity: {
                            routineStore.addEnrichment(type: suggestion)
                        },
                        onTap: {}
                    )
                }

                // Weight goal progress (if active goal exists)
                if let goal = routineStore.weightGoal {
                    WeightGoalCard(
                        goal: goal,
                        currentWeight: weightStore.latestWeight?.weight,
                        onTap: {}
                    )
                }
            }
        }
    }

    // MARK: - Senior Wellness Section

    @ViewBuilder
    private var seniorWellnessSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            SectionHeader(title: Strings.SeniorWellness.title, icon: "heart.circle.fill", tint: .pink) {
                NavigationLink(destination: SeniorWellnessView().environmentObject(viewModel.profileStore)) {
                    Text(Strings.Common.seeAll)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }

            // Senior wellness card
            VStack(spacing: 16) {
                // Quick mobility check
                MobilityTrendCard(
                    onLogTap: { showMobilitySheet = true },
                    onViewHistoryTap: {
                        // Navigate to history
                    }
                )
                .environmentObject(viewModel.profileStore)

                // Additional assessments reminder
                if seniorWellnessStore.cognitiveAssessmentDue || seniorWellnessStore.qolAssessmentDue {
                    VStack(spacing: 8) {
                        if seniorWellnessStore.cognitiveAssessmentDue {
                            AssessmentDueCard(
                                title: Strings.SeniorWellness.cognitiveAssessment,
                                icon: "brain.head.profile",
                                iconColor: .purple,
                                lastDate: seniorWellnessStore.latestCognitive?.createdAt,
                                action: { showCognitiveSheet = true }
                            )
                        }

                        if seniorWellnessStore.qolAssessmentDue {
                            AssessmentDueCard(
                                title: Strings.SeniorWellness.qualityOfLife,
                                icon: "heart.circle.fill",
                                iconColor: .pink,
                                lastDate: seniorWellnessStore.latestQoL?.createdAt,
                                action: { showQoLSheet = true }
                            )
                        }
                    }
                }

                // RRR tracking (for heart conditions)
                let activeConditions = profile?.healthConditions.filter { $0.status == .active } ?? []
                if seniorWellnessStore.shouldShowRRRTracking(activeConditions: activeConditions) {
                    RRRQuickCard(
                        latestReading: seniorWellnessStore.latestRRR,
                        onLogTap: { showRRRSheet = true }
                    )
                }
            }
        }
    }

    // MARK: - Symptoms Section

    @ViewBuilder
    private var symptomsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            SectionHeader(title: Strings.HealthLogging.symptomTrends, icon: "stethoscope", tint: .teal) {
                Button {
                    showSymptomLogSheet = true
                } label: {
                    Label(Strings.HealthLogging.logSymptom, systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Symptoms content
            VStack(spacing: 16) {
                // Recent symptoms summary
                let recentSymptoms = symptomStore.recentSymptoms()
                if recentSymptoms.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.green)
                        Text(Strings.HealthLogging.noRecentSymptoms)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    // Show recent symptoms grouped by type
                    ForEach(recentSymptomsSummary, id: \.type) { summary in
                        HStack {
                            Image(systemName: summary.type.icon)
                                .foregroundStyle(.teal)
                            Text(summary.type.label)
                                .font(.subheadline)
                            Spacer()
                            Text(Strings.HealthLogging.episodes(summary.count))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Quick log cards for active conditions
                if let profile = profile {
                    let activeConditions = profile.healthConditions.filter { $0.status == .active }
                    if !activeConditions.isEmpty {
                        ForEach(activeConditions) { condition in
                            ConditionQuickLogCard(
                                condition: condition,
                                onLogSymptom: { symptomType in
                                    let log = HealthSymptomLog(
                                        symptomType: symptomType,
                                        relatedConditionId: condition.id
                                    )
                                    symptomStore.log(log)
                                },
                                onLogGoodDay: {
                                    // Could track "good days" for trends
                                },
                                onViewDetails: {
                                    // Could navigate to condition detail
                                }
                            )
                        }
                    }
                }
            }
            .padding()
            .glassCard(tint: .info)
        }
    }

    private var recentSymptomsSummary: [(type: SymptomType, count: Int)] {
        let symptoms = symptomStore.recentSymptoms()
        let grouped = Dictionary(grouping: symptoms) { $0.symptomType }
        return grouped
            .map { (type: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(3)
            .map { $0 }
    }

    // MARK: - Weight Section

    @ViewBuilder
    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            SectionHeader(title: Strings.Health.weight, icon: "scalemass.fill", tint: .otisAccent) {
                Button {
                    showWeightSheet = true
                } label: {
                    Label(Strings.Health.logWeight, systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Weight card
            VStack(spacing: 16) {
                // Current weight hero (if available)
                if let latest = latestWeight {
                    weightHeroCard(weight: latest.weight, date: latest.date)
                }

                // Growth curve chart
                if chartPoints.isEmpty {
                    WeightChartEmptyView(referenceCurve: referenceCurve)
                } else {
                    WeightChartView(
                        measurements: chartPoints,
                        referenceCurve: referenceCurve,
                        puppyName: profile?.name ?? "Puppy"
                    )
                }
            }
            .padding()
            .glassCard(tint: .accent)
        }
    }

    @ViewBuilder
    private func weightHeroCard(weight: Double, date: Date) -> some View {
        VStack(spacing: 8) {
            // Big weight number
            Text(weightUnit.format(weight))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            // Date
            Text(date.formattedMedium())
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Delta since last (if available)
            if let delta = weightDelta {
                HStack(spacing: 4) {
                    Image(systemName: delta.delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    Text(Strings.Health.sinceLast(weightUnit.formatDelta(delta.delta)))
                        .font(.caption)
                }
                .foregroundStyle(delta.delta >= 0 ? Color.otisSuccess : Color.otisWarning)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    (delta.delta >= 0 ? Color.otisSuccess : Color.otisWarning)
                        .opacity(colorScheme == .dark ? 0.2 : 0.1)
                )
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Milestones Section

    @ViewBuilder
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            SectionHeader(title: Strings.Health.milestones, icon: "heart.fill", tint: .otisDanger) {
                // Add button (premium)
                if subscriptionManager.hasAccess(to: .customMilestones) {
                    Button {
                        showAddMilestoneSheet = true
                    } label: {
                        Label(Strings.Health.addMilestone, systemImage: "plus.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }

            // Timeline
            HealthTimelineView(
                milestones: milestoneStore.milestones,
                birthDate: profile?.birthDate ?? Date(),
                onToggle: { milestone in
                    milestoneStore.toggleMilestoneCompletion(milestone)
                }
            )
            .padding()
            .glassCard(tint: .danger)
        }
        .sheet(isPresented: $showAddMilestoneSheet) {
            AddMilestoneSheet(isPresented: $showAddMilestoneSheet) { milestone in
                milestoneStore.toggleMilestoneCompletion(milestone)
            }
        }
    }

    // MARK: - Breed Risk Section

    @ViewBuilder
    private func breedRiskSection(for profile: PuppyProfile) -> some View {
        let breedRisks = BreedHealthRisk.risks(for: profile.breed)
        let sizeRisks = BreedHealthRisk.sizeBasedRisks(for: profile.sizeCategory)

        if breedRisks != nil || !sizeRisks.isEmpty {
            BreedRiskCard(
                breedRisks: breedRisks,
                sizeRisks: sizeRisks,
                existingConditions: profile.healthConditions,
                ageMonths: profile.ageInMonths,
                onScheduleScreening: { risk in
                    appointmentPrefill = (risk.conditionType, "\(risk.conditionType.label) Screening")
                    showAppointmentForm = true
                }
            )
        }
    }

    // MARK: - Follow-up Reminders Section

    @ViewBuilder
    private func followUpRemindersSection(for profile: PuppyProfile) -> some View {
        let activeConditions = profile.healthConditions.filter { $0.status == .active || $0.status == .monitoring }

        if !activeConditions.isEmpty {
            FollowUpRemindersCard(
                conditions: activeConditions,
                onScheduleFollowUp: { followUp in
                    appointmentPrefill = (followUp.conditionType, "\(followUp.followUpType.rawValue.capitalized) for \(followUp.conditionType.label)")
                    showAppointmentForm = true
                }
            )
        }
    }

    // MARK: - Health Calendar Section

    @ViewBuilder
    private var healthCalendarSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            SectionHeader(title: Strings.VetVisit.Calendar.title, icon: "calendar", tint: .otisAccent) {
                NavigationLink {
                    HealthCalendarView()
                        .environmentObject(appointmentStore)
                        .environmentObject(milestoneStore)
                        .environmentObject(viewModel.profileStore)
                } label: {
                    HStack(spacing: 4) {
                        Text(Strings.Common.seeAll)
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
            }

            // Quick preview of upcoming events
            upcomingAppointmentsSection
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .sheet(isPresented: $showHealthCalendar) {
            NavigationStack {
                HealthCalendarView()
                    .environmentObject(appointmentStore)
                    .environmentObject(milestoneStore)
                    .environmentObject(viewModel.profileStore)
            }
        }
    }

    // MARK: - Upcoming Appointments Section

    @ViewBuilder
    private var upcomingAppointmentsSection: some View {
        let appointments = Array(appointmentStore.upcomingAppointments.prefix(2))
        VStack(spacing: 12) {
            if appointments.isEmpty {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(.secondary)
                    Text(Strings.VetVisit.Calendar.noEvents)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
            } else {
                ForEach(appointments, id: \.id) { appointment in
                    HStack(spacing: 12) {
                        Image(systemName: appointment.appointmentType.icon)
                            .foregroundStyle(appointment.appointmentType.isHealthRelated ? Color.otisHealth : Color.otisAccent)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(appointment.title)
                                .font(.subheadline.weight(.medium))

                            Text(appointment.dateString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if appointment.isToday {
                            Text(Strings.VetVisit.visitToday)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.otisDanger)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding()
            }
        }
    }

}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let milestoneStore = MilestoneStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)

    NavigationStack {
        HealthView(viewModel: viewModel, milestoneStore: milestoneStore)
    }
    .environmentObject(SubscriptionManager.shared)
    .environmentObject(WeightStore())
    .environmentObject(RoutineStore())
}
