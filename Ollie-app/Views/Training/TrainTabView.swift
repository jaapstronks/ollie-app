//
//  TrainTabView.swift
//  Ollie-app
//
//  Combined training tab with Potty Progress, Socialization, and Skills sections

import OllieShared
import SwiftUI

/// Train tab - unified view with potty progress, socialization checklist, and skills tracker
struct TrainTabView: View {
    @ObservedObject var viewModel: TimelineViewModel
    let onSettingsTap: () -> Void

    @EnvironmentObject var eventStore: EventStore
    @EnvironmentObject var socializationStore: SocializationStore
    @EnvironmentObject var profileStore: ProfileStore

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Properties

    /// Calculate outdoor percentage for the past 7 days
    private var outdoorPercentage: Int {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEvents = eventStore.getEvents(from: sevenDaysAgo, to: Date())
        let peeEvents = recentEvents.pee()

        let outdoorCount = peeEvents.filter { $0.location == .buiten }.count
        let totalCount = peeEvents.count

        guard totalCount > 0 else { return 0 }
        return (outdoorCount * 100) / totalCount
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Section 1: Potty Progress
                    pottyProgressSection
                        .animatedAppear(delay: 0)

                    // Section 2: Skills
                    skillsSection
                        .animatedAppear(delay: 0.08)

                    // Section 3: Socialization
                    socializationSection
                        .animatedAppear(delay: 0.16)
                }
                .padding()
                .padding(.bottom, 84) // Space for FAB
            }
            .navigationTitle(Strings.Tabs.train)
            .navigationBarTitleDisplayMode(.large)
            .profileToolbar(profile: profileStore.profile, action: onSettingsTap)
        }
    }

    // MARK: - Potty Progress Section

    @ViewBuilder
    private var pottyProgressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PottyProgressCard(
                streakInfo: viewModel.streakInfo,
                patternAnalysis: viewModel.patternAnalysis,
                outdoorPercentage: outdoorPercentage
            )
        }
    }

    // MARK: - Socialization Section

    /// Categories that need attention (incomplete, sorted by least progress)
    private var priorityCategories: [SocializationCategory] {
        socializationStore.categories
            .filter { category in
                let progress = socializationStore.categoryProgress(for: category.id)
                return progress.completed < progress.total
            }
            .sorted { cat1, cat2 in
                let p1 = socializationStore.categoryProgress(for: cat1.id)
                let p2 = socializationStore.categoryProgress(for: cat2.id)
                let ratio1 = p1.total > 0 ? Double(p1.completed) / Double(p1.total) : 0
                let ratio2 = p2.total > 0 ? Double(p2.completed) / Double(p2.total) : 0
                return ratio1 < ratio2
            }
            .prefix(3)
            .map { $0 }
    }

    @ViewBuilder
    private var socializationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Compact progress card with inline "See all" link
            NavigationLink {
                SocializationFullListView()
            } label: {
                SocializationProgressCard()
            }
            .buttonStyle(.plain)

            // Show only top 3 priority categories (least complete)
            if !priorityCategories.isEmpty {
                VStack(spacing: 0) {
                    ForEach(priorityCategories) { category in
                        NavigationLink {
                            SocializationCategoryDetailView(category: category)
                        } label: {
                            SocializationCategoryRow(category: category)
                        }
                        .buttonStyle(.plain)

                        if category.id != priorityCategories.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }

                    // "See all categories" row
                    Divider()
                        .padding(.leading, 52)

                    NavigationLink {
                        SocializationFullListView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "list.bullet")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color.secondary.opacity(colorScheme == .dark ? 0.2 : 0.1))
                                )

                            Text(Strings.Train.allCategories)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.ollieAccent)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .glassCard(tint: .accent)
            }
        }
    }

    // MARK: - Skills Section

    @ViewBuilder
    private var skillsSection: some View {
        SkillsPreviewCard(eventStore: eventStore)
    }
}

// MARK: - Skills Preview Card

/// Compact preview of current week's training focus
private struct SkillsPreviewCard: View {
    @ObservedObject var eventStore: EventStore
    @StateObject private var trainingStore = TrainingPlanStore()

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header (matching Potty Progress and Socialization style)
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundStyle(Color.ollieAccent)
                Text(Strings.Train.skills)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            if let weekPlan = trainingStore.currentWeekPlan {
                // Week info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.Training.weekNumber(trainingStore.currentWeek))
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(weekPlan.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Progress ring
                    ZStack {
                        let progress = trainingStore.weekProgress
                        let progressFraction = progress.total > 0 ? CGFloat(progress.started) / CGFloat(progress.total) : 0

                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: progressFraction)
                            .stroke(Color.ollieAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(progressFraction * 100))%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 44, height: 44)
                }

                // Focus skills chips
                if !trainingStore.currentFocusSkills.isEmpty {
                    Divider()

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(trainingStore.currentFocusSkills) { skill in
                                skillChip(skill)
                            }
                        }
                    }
                }

                // "See all" link at the bottom (matching "All Categories" style)
                Divider()

                NavigationLink {
                    TrainingView(eventStore: eventStore)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.secondary.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            )

                        Text(Strings.Common.seeAll)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.ollieAccent)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            } else {
                // Loading or no plan
                Text(Strings.Common.loading)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .glassCard(tint: .accent)
        .onAppear {
            trainingStore.setEventStore(eventStore)
        }
    }

    @ViewBuilder
    private func skillChip(_ skill: Skill) -> some View {
        let status = trainingStore.status(for: skill.id)

        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(for: status))
                .frame(width: 6, height: 6)

            Text(skill.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(statusColor(for: status).opacity(colorScheme == .dark ? 0.2 : 0.1))
        )
    }

    private func statusColor(for status: SkillStatus) -> Color {
        switch status {
        case .notStarted: return .secondary
        case .started: return .ollieAccent
        case .practicing: return .orange
        case .mastered: return .ollieSuccess
        }
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)

    return TrainTabView(
        viewModel: viewModel,
        onSettingsTap: { print("Settings tapped") }
    )
    .environmentObject(eventStore)
    .environmentObject(SocializationStore())
    .environmentObject(profileStore)
}
