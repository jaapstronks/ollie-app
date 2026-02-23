//
//  PlanTabView.swift
//  Ollie-app
//
//  Plan tab showing puppy age, milestones, and moments preview

import SwiftUI

/// Plan tab - milestones, appointments, moments
struct PlanTabView: View {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var momentsViewModel: MomentsViewModel
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var socializationStore: SocializationStore

    @State private var milestones: [HealthMilestone] = []
    @State private var showMomentsGallery = false

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Properties

    private var profile: PuppyProfile? {
        profileStore.profile
    }

    private var upcomingMilestones: [HealthMilestone] {
        milestones.filter { $0.status == .nextUp || $0.status == .overdue }
    }

    private var futureMilestones: [HealthMilestone] {
        milestones.filter { $0.status == .future }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Puppy age header
                    ageHeaderSection

                    // Socialization checklist
                    socializationSection

                    // Upcoming milestones (next up + overdue)
                    if !upcomingMilestones.isEmpty {
                        upcomingMilestonesSection
                    }

                    // Moments preview
                    momentsPreviewSection

                    // Full milestone timeline
                    milestoneTimelineSection
                }
                .padding()
                .padding(.bottom, 84) // Space for FAB
            }
            .navigationTitle(Strings.PlanTab.title)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showMomentsGallery) {
                MomentsGalleryView(viewModel: momentsViewModel)
            }
            .onAppear {
                loadMilestones()
            }
        }
    }

    // MARK: - Age Header Section

    @ViewBuilder
    private var ageHeaderSection: some View {
        if let profile = profile {
            VStack(spacing: 8) {
                // Puppy name
                Text(profile.name)
                    .font(.title)
                    .fontWeight(.bold)

                // Age display
                HStack(spacing: 16) {
                    // Weeks old
                    VStack(spacing: 2) {
                        Text("\(profile.ageInWeeks)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.ollieAccent)
                        Text(Strings.Common.weeks)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Divider
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 1, height: 40)

                    // Days home
                    VStack(spacing: 2) {
                        Text("\(profile.daysHome)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.ollieSuccess)
                        Text(Strings.Common.days)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)

                // Readable age text
                Text(ageDescription(for: profile))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .glassCard(tint: .accent)
        }
    }

    private func ageDescription(for profile: PuppyProfile) -> String {
        let months = profile.ageInWeeks / 4
        if months >= 2 {
            return Strings.PlanTab.monthsOld(months)
        } else {
            return Strings.PlanTab.weeksOld(profile.ageInWeeks)
        }
    }

    // MARK: - Socialization Section

    @ViewBuilder
    private var socializationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Progress card
            SocializationProgressCard()

            // Category list
            VStack(spacing: 0) {
                ForEach(socializationStore.categories) { category in
                    NavigationLink {
                        SocializationCategoryDetailView(category: category)
                    } label: {
                        SocializationCategoryRow(category: category)
                    }
                    .buttonStyle(.plain)

                    if category.id != socializationStore.categories.last?.id {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .glassCard(tint: .accent)
        }
    }

    // MARK: - Upcoming Milestones Section

    @ViewBuilder
    private var upcomingMilestonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: Strings.PlanTab.upcomingMilestones,
                icon: "exclamationmark.circle.fill",
                tint: .ollieWarning
            )

            VStack(spacing: 12) {
                ForEach(upcomingMilestones) { milestone in
                    upcomingMilestoneCard(milestone)
                }
            }
        }
    }

    @ViewBuilder
    private func upcomingMilestoneCard(_ milestone: HealthMilestone) -> some View {
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(milestone.status == .overdue ? Color.ollieWarning : Color.ollieAccent)
                    .frame(width: 36, height: 36)

                Image(systemName: milestone.status == .overdue ? "exclamationmark" : "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.label)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let period = milestone.period {
                    Text(period)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Status badge
            HStack(spacing: 4) {
                Image(systemName: milestone.status == .overdue ? "exclamationmark.triangle.fill" : "arrow.right.circle.fill")
                    .font(.system(size: 10))
                Text(milestone.status == .overdue ? Strings.PlanTab.overdue : Strings.PlanTab.nextUp)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(milestone.status == .overdue ? Color.ollieWarning : Color.ollieAccent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                (milestone.status == .overdue ? Color.ollieWarning : Color.ollieAccent)
                    .opacity(colorScheme == .dark ? 0.2 : 0.1)
            )
            .clipShape(Capsule())
        }
        .padding()
        .glassCard(tint: milestone.status == .overdue ? .warning : .accent)
        .onTapGesture {
            toggleMilestone(milestone)
        }
    }

    // MARK: - Moments Preview Section

    @ViewBuilder
    private var momentsPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(
                    title: Strings.PlanTab.moments,
                    icon: "photo.on.rectangle.angled",
                    tint: .ollieInfo
                )

                Spacer()

                // See all button
                if momentsViewModel.events.count > 4 {
                    Button {
                        showMomentsGallery = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(Strings.PlanTab.seeAllMoments)
                            Image(systemName: "chevron.right")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.ollieAccent)
                    }
                }
            }

            if momentsViewModel.events.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text(Strings.MomentsGallery.noPhotos)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .glassCard(tint: .info)
            } else {
                // Horizontal scroll of recent moments
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(momentsViewModel.events.prefix(6))) { event in
                            EventThumbnailView(event: event)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .onTapGesture {
                                    showMomentsGallery = true
                                }
                        }
                    }
                }
            }
        }
        .onAppear {
            momentsViewModel.loadEventsWithMedia()
        }
    }

    // MARK: - Milestone Timeline Section

    @ViewBuilder
    private var milestoneTimelineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: Strings.Health.milestones,
                icon: "heart.fill",
                tint: .ollieDanger
            )

            if milestones.isEmpty {
                Text(Strings.PlanTab.noUpcomingMilestones)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .glassCard(tint: .danger)
            } else {
                HealthTimelineView(milestones: milestones) { milestone in
                    toggleMilestone(milestone)
                }
                .padding()
                .glassCard(tint: .danger)
            }
        }
    }

    // MARK: - Actions

    private func loadMilestones() {
        guard let birthDate = profile?.birthDate else { return }
        milestones = DefaultMilestones.create(birthDate: birthDate)
    }

    private func toggleMilestone(_ milestone: HealthMilestone) {
        if let index = milestones.firstIndex(where: { $0.id == milestone.id }) {
            milestones[index].isDone.toggle()
            HapticFeedback.light()
        }
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let socializationStore = SocializationStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    let momentsViewModel = MomentsViewModel(eventStore: eventStore)

    return PlanTabView(
        viewModel: viewModel,
        momentsViewModel: momentsViewModel
    )
    .environmentObject(profileStore)
    .environmentObject(socializationStore)
}
