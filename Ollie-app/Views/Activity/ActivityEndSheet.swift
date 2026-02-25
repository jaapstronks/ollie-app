//
//  ActivityEndSheet.swift
//  Ollie-app
//
//  Sheet for ending an in-progress activity with time adjustment options

import SwiftUI
import OllieShared

/// Sheet shown when ending an in-progress walk or nap
struct ActivityEndSheet: View {
    let activity: InProgressActivity
    let onEnd: (Int, String?) -> Void  // (minutesAgo, note)
    let onCancel: () -> Void
    let onDiscard: () -> Void

    @State private var selectedMinutesAgo: Int = 0
    @State private var note: String = ""
    @Environment(\.colorScheme) private var colorScheme

    private let presetMinutes = [0, 5, 10, 15, 30]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Activity summary
                    activitySummaryCard

                    // When did it end?
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When did it end?")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        // Preset time buttons
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 8) {
                            ForEach(presetMinutes, id: \.self) { minutes in
                                Button {
                                    HapticFeedback.selection()
                                    selectedMinutesAgo = minutes
                                } label: {
                                    Text(minutes == 0 ? Strings.Activity.endNow : Strings.Activity.minutesAgo(minutes))
                                        .font(.subheadline)
                                        .fontWeight(selectedMinutesAgo == minutes ? .semibold : .regular)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(selectedMinutesAgo == minutes ? Color.accentColor : Color(.secondarySystemBackground))
                                        .foregroundStyle(selectedMinutesAgo == minutes ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Optional note
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.QuickLogSheet.noteOptional)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        TextField(Strings.QuickLogSheet.notePlaceholder, text: $note, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .lineLimit(2...4)
                    }
                    .padding(.horizontal)

                    // Main action button
                    Button {
                        HapticFeedback.success()
                        onEnd(selectedMinutesAgo, note.isEmpty ? nil : note)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(endButtonTitle)
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal)

                    // Discard option
                    Button(role: .destructive) {
                        onDiscard()
                    } label: {
                        Text(Strings.Activity.discardActivity)
                            .font(.subheadline)
                    }
                    .padding(.bottom)
                }
                .padding(.vertical)
            }
            .navigationTitle(Strings.Activity.endActivity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        onCancel()
                    }
                }
            }
        }
    }

    // MARK: - Activity Summary Card

    @ViewBuilder
    private var activitySummaryCard: some View {
        HStack(spacing: 16) {
            // Icon with pulsing animation
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: activity.type.icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(activityTitle)
                    .font(.headline)

                Text(Strings.Activity.elapsed(activity.elapsedTimeFormatted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let spotName = activity.spotName {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption)
                        Text(spotName)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(glassOverlay)
        .padding(.horizontal)
    }

    // MARK: - Computed Properties

    private var activityTitle: String {
        switch activity.type {
        case .walk: return Strings.Activity.walkInProgress
        case .nap: return Strings.Activity.napInProgress
        }
    }

    private var endButtonTitle: String {
        switch activity.type {
        case .walk: return Strings.Activity.endWalk
        case .nap: return Strings.Activity.wakeUp
        }
    }

    private var iconColor: Color {
        switch activity.type {
        case .walk: return .green
        case .nap: return .purple
        }
    }

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            if colorScheme == .dark {
                Color.white.opacity(0.05)
            } else {
                Color.white.opacity(0.6)
            }
        }
        .background(.thinMaterial)
    }

    @ViewBuilder
    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
                Color.primary.opacity(colorScheme == .dark ? 0.1 : 0.15),
                lineWidth: 0.5
            )
    }
}

#Preview {
    ActivityEndSheet(
        activity: InProgressActivity(
            type: .walk,
            startTime: Date().addingTimeInterval(-25 * 60),
            spotName: "Park"
        ),
        onEnd: { minutes, note in
            print("End \(minutes) min ago, note: \(note ?? "none")")
        },
        onCancel: { print("Cancel") },
        onDiscard: { print("Discard") }
    )
}
