//
//  FullTimelineSheet.swift
//  Otis-app
//
//  Sheet containing the full timeline with day navigation
//  Opened from the RecentActivityPreview on the Today tab

import SwiftUI
import OtisShared

/// Full timeline sheet with day navigation
struct FullTimelineSheet: View {
    @Bindable var viewModel: TimelineViewModel
    let onEditEvent: (PuppyEvent) -> Void
    let onDeleteEvent: (PuppyEvent) -> Void
    var onPhotoTap: ((PuppyEvent) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Day navigation header
                dayNavigationHeader
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                Divider()

                // Full timeline content
                ScrollView {
                    VerticalTimelineView(
                        viewModel: viewModel,
                        onEditEvent: onEditEvent,
                        onDeleteEvent: onDeleteEvent,
                        onPhotoTap: onPhotoTap
                    )
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(Strings.RecentActivity.fullTimelineTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.RecentActivity.done) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        // Swipe gestures for day navigation
        .dayNavigation(
            canGoForward: viewModel.canGoForward,
            onPreviousDay: viewModel.goToPreviousDay,
            onNextDay: viewModel.goToNextDay
        )
    }

    // MARK: - Day Navigation Header

    @ViewBuilder
    private var dayNavigationHeader: some View {
        HStack(spacing: 12) {
            // Compact day navigation group
            HStack(spacing: 0) {
                // Previous day button
                Button {
                    HapticFeedback.selection()
                    viewModel.goToPreviousDay()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 40, height: 36)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Strings.Timeline.previousDay)

                // Next day button
                Button {
                    HapticFeedback.selection()
                    viewModel.goToNextDay()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 40, height: 36)
                        .contentShape(Rectangle())
                }
                .opacity(viewModel.canGoForward ? 1 : 0.3)
                .disabled(!viewModel.canGoForward)
                .accessibilityLabel(Strings.Timeline.nextDay)
            }
            .background(
                Capsule()
                    .fill(Color(.tertiarySystemFill))
            )

            // Date title
            Text(viewModel.dateTitle)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            // "Today" pill button - only show when viewing past days
            if !viewModel.isShowingToday {
                Button {
                    HapticFeedback.selection()
                    viewModel.goToToday()
                } label: {
                    Text(Strings.Common.today)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                        )
                }
                .accessibilityLabel(Strings.Common.today)
                .accessibilityHint(Strings.Timeline.goToTodayHint)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)

    FullTimelineSheet(
        viewModel: viewModel,
        onEditEvent: { _ in },
        onDeleteEvent: { _ in }
    )
}
