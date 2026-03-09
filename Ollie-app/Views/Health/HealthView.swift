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
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var milestoneStore: MilestoneStore

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var weightStore: WeightStore
    @EnvironmentObject var routineStore: RoutineStore

    @State var showWeightSheet = false
    @State var showAddMilestoneSheet = false
    @State var showSymptomLogSheet = false

    @EnvironmentObject var unitPreferences: UnitPreferences

    @StateObject var symptomStore = HealthSymptomStore.shared
    @StateObject var checkInStore = HealthCheckInStore.shared
    @StateObject var seniorWellnessStore = SeniorWellnessStore.shared

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

    @EnvironmentObject var appointmentStore: AppointmentStore

    // Vet tip generator
    let tipGenerator = VetVisitTipGenerator()

    // MARK: - Lifecycle Helpers

    var hasActiveConditions: Bool {
        guard let profile = profile else { return false }
        return !profile.healthConditions.filter { $0.status == .active }.isEmpty ||
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
