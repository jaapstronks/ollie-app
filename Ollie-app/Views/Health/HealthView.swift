//
//  HealthView.swift
//  Otis-app
//
//  Health tracking view: weight chart and health milestones timeline.
//  Section views are in HealthView+WellnessSections.swift, HealthView+HealthSections.swift,
//  and HealthView+CalendarSections.swift.
//

import SwiftUI
import OtisShared

/// Main health view showing weight tracking and health milestones
struct HealthView: View {
    @Bindable var viewModel: TimelineViewModel
    var milestoneStore: MilestoneStore

    @Environment(SubscriptionManager.self) var subscriptionManager
    @Environment(WeightStore.self) var weightStore
    @Environment(RoutineStore.self) var routineStore

    @State var showWeightSheet = false
    @State var showAddMilestoneSheet = false
    @State var showSymptomLogSheet = false

    @Environment(UnitPreferences.self) var unitPreferences

    @State var symptomStore = HealthSymptomStore.shared
    @State var checkInStore = HealthCheckInStore.shared
    @State var seniorWellnessStore = SeniorWellnessStore.shared

    @State var showMobilitySheet = false
    @State var showCognitiveSheet = false
    @State var showQoLSheet = false
    @State var showRRRSheet = false

    @Environment(\.colorScheme) var colorScheme

    var weightUnit: WeightUnit {
        unitPreferences.weightUnit
    }

    // MARK: - Computed Properties

    var profile: PuppyProfile? {
        viewModel.profileStore.profile
    }

    var chartPoints: [WeightChartPoint] {
        guard let birthDate = profile?.birthDate else { return [] }
        return weightStore.chartPoints(birthDate: birthDate)
    }

    var latestWeight: (weight: Double, date: Date)? {
        weightStore.latestWeight
    }

    var weightDelta: (delta: Double, previousDate: Date)? {
        weightStore.weightDelta
    }

    var referenceCurve: [GrowthReference] {
        guard let size = profile?.sizeCategory else {
            return GrowthCurves.goldenRetrieverFemale
        }
        return GrowthCurves.curve(for: size)
    }

    // Vet visit state
    @State var showVetTipsSheet = false
    @State var showVisitSummary = false
    @State var showHealthCalendar = false
    @State var showAppointmentForm = false
    @State var appointmentPrefill: (conditionType: HealthConditionType, title: String)?

    @Environment(AppointmentStore.self) var appointmentStore

    // Vet tip generator
    let tipGenerator = VetVisitTipGenerator()

    // MARK: - Lifecycle Helpers

    var hasActiveConditions: Bool {
        guard let profile = profile else { return false }
        return profile.healthConditions.contains { $0.status == .active } ||
               profile.lifecyclePhase == .senior
    }

    var isSenior: Bool {
        profile?.lifecyclePhase == .senior || seniorWellnessStore.shouldShowSeniorFeatures(for: profile)
    }

    var isAdult: Bool {
        guard let phase = profile?.lifecyclePhase else { return false }
        return phase == .adult
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical) {
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
            .environment(viewModel.profileStore)
        }
        .sheet(isPresented: $showMobilitySheet) {
            MobilityAssessmentSheet(onSave: { assessment in
                seniorWellnessStore.recordMobility(
                    score: assessment.score,
                    observations: assessment.observations,
                    note: assessment.note
                )
            })
            .environment(viewModel.profileStore)
        }
        .sheet(isPresented: $showCognitiveSheet) {
            CognitiveAssessmentSheet(onSave: { assessment in
                seniorWellnessStore.recordCognitive(
                    symptoms: assessment.symptoms,
                    note: assessment.note
                )
            })
            .environment(viewModel.profileStore)
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
            .environment(viewModel.profileStore)
        }
        .sheet(isPresented: $showRRRSheet) {
            RespiratoryRateSheet(onSave: { reading in
                seniorWellnessStore.recordRRR(
                    breathsPerMinute: reading.breathsPerMinute,
                    wasResting: reading.wasResting,
                    note: reading.note
                )
            })
            .environment(viewModel.profileStore)
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
    .environment(SubscriptionManager.shared)
    .environment(WeightStore())
    .environment(RoutineStore())
}
