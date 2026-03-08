//
//  AllEventsSheet.swift
//  Otis-app
//
//  V2: Grid showing all event types for logging
//  Uses liquid glass design for iOS 26 aesthetic

import SwiftUI
import OtisShared

/// Sheet showing all event types in a grid layout
/// Uses liquid glass button styling
struct AllEventsSheet: View {
    let onSelect: (EventType) -> Void
    let onSelectGrooming: (GroomingType) -> Void
    let onCancel: () -> Void

    @EnvironmentObject private var routineStore: RoutineStore
    @Environment(\.colorScheme) private var colorScheme

    // Event types not in quick log bar
    // Excludes:
    // - gewicht: managed in Health tab
    // - bench: deprecated in favor of napLocation on sleep events
    // - training: separate system in Train tab (skills tracking)
    // - tuin: use walks instead
    // - milestone, gedrag: not user-loggable
    private var additionalEventTypes: [EventType] {
        let excluded: Set<EventType> = [.gewicht, .bench, .training, .tuin, .milestone, .gedrag]
        return EventType.allCases.filter { type in
            !Constants.quickLogTypes.contains(type) && !excluded.contains(type)
        }
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Additional event types section
                    sectionHeader(title: Strings.AllEvents.moreEvents, icon: "square.grid.2x2")

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(additionalEventTypes) { type in
                            EventTypeButton(type: type) {
                                onSelect(type)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Glass divider
                    glassDivider

                    // Care & Grooming section
                    sectionHeader(title: Strings.AllEvents.careGrooming, icon: "comb.fill")

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(GroomingType.allCases, id: \.self) { type in
                            CareTypeButton(
                                type: type,
                                activity: routineStore.groomingActivities.first { $0.type == type }
                            ) {
                                onSelectGrooming(type)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Glass divider
                    glassDivider

                    // Quick log types also available here
                    sectionHeader(title: Strings.AllEvents.quickEvents, icon: "bolt.fill")

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Constants.quickLogTypes) { type in
                            EventTypeButton(type: type) {
                                onSelect(type)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle(Strings.AllEvents.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        onCancel()
                    }
                    .foregroundStyle(Color.otisAccent)
                }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.otisAccent)

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var glassDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.06))
            .frame(height: 1)
            .padding(.vertical, 8)
            .padding(.horizontal)
    }
}

/// Single event type button in the grid with liquid glass styling
struct EventTypeButton: View {
    let type: EventType
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            HapticFeedback.medium()
            action()
        } label: {
            VStack(spacing: 6) {
                EventIcon(type: type, size: 28)
                    .frame(width: 36, height: 36)
                    .background(iconBackground)
                    .clipShape(Circle())

                Text(type.label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background(glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(glassOverlay)
        }
        .buttonStyle(GlassEventButtonStyle())
    }

    @ViewBuilder
    private var iconBackground: some View {
        iconColor.opacity(colorScheme == .dark ? 0.15 : 0.1)
    }

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            if colorScheme == .dark {
                Color.white.opacity(0.05)
            } else {
                Color.white.opacity(0.6)
            }

            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .background(.thinMaterial)
    }

    @ViewBuilder
    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.12 : 0.35),
                        Color.white.opacity(colorScheme == .dark ? 0.03 : 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }

    private var iconColor: Color {
        switch type {
        case .plassen, .poepen: return Color.otisInfo
        case .eten, .drinken: return Color.otisAccent
        case .slapen, .ontwaken: return Color.otisSleep
        case .uitlaten: return Color.otisSuccess
        case .sociaal: return Color.otisInfo
        default: return Color.otisMuted
        }
    }
}

/// Interactive button style for event buttons
struct GlassEventButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Care/grooming type button in the grid with liquid glass styling
/// Shows status indicators for due/overdue activities
struct CareTypeButton: View {
    let type: GroomingType
    let activity: GroomingActivity?
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isOverdue: Bool {
        activity?.isOverdue ?? false
    }

    private var isDue: Bool {
        activity?.isDue ?? false
    }

    var body: some View {
        Button {
            HapticFeedback.medium()
            action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isOverdue ? .orange : .purple)
                    .frame(width: 36, height: 36)
                    .background(iconBackground)
                    .clipShape(Circle())

                Text(type.label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                // Status indicator
                if let activity = activity, activity.isEnabled {
                    if isOverdue {
                        Text(Strings.Grooming.overdue)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.orange)
                    } else if isDue {
                        Text(Strings.Grooming.due)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.purple.opacity(0.8))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background(glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(statusOverlay)
        }
        .buttonStyle(GlassEventButtonStyle())
    }

    @ViewBuilder
    private var iconBackground: some View {
        (isOverdue ? Color.orange : Color.purple)
            .opacity(colorScheme == .dark ? 0.15 : 0.1)
    }

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            if colorScheme == .dark {
                Color.white.opacity(0.05)
            } else {
                Color.white.opacity(0.6)
            }

            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .background(.thinMaterial)
    }

    @ViewBuilder
    private var statusOverlay: some View {
        if isOverdue {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.5), lineWidth: 1.5)
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.12 : 0.35),
                            Color.white.opacity(colorScheme == .dark ? 0.03 : 0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
    }
}

#Preview {
    AllEventsSheet(
        onSelect: { type in
            print("Selected event: \(type)")
        },
        onSelectGrooming: { type in
            print("Selected grooming: \(type)")
        },
        onCancel: {}
    )
    .environmentObject(RoutineStore())
}
