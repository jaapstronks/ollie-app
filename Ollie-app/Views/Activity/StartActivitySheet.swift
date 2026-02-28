//
//  StartActivitySheet.swift
//  Ollie-app
//
//  Sheet shown when user taps Walk or Nap, offering choice between
//  "Start now" (live tracking) or "Log completed" (retrospective)

import SwiftUI
import OllieShared

/// Sheet offering choice between starting live activity or logging completed one
struct StartActivitySheet: View {
    let activityType: ActivityType
    let onStartNow: (Date) -> Void
    let onLogCompleted: () -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Activity icon and title
                VStack(spacing: 12) {
                    Image(systemName: activityType.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(iconColor)

                    Text(activityTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top, 24)

                // Options
                VStack(spacing: 16) {
                    // Start now option - immediately starts with current time
                    Button {
                        HapticFeedback.medium()
                        onStartNow(Date())
                    } label: {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(startNowTitle)
                                    .font(.headline)
                                Text(startNowDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(glassBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(glassOverlay)
                    }
                    .buttonStyle(.plain)

                    // Log completed option
                    Button {
                        HapticFeedback.medium()
                        onLogCompleted()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(logCompletedTitle)
                                    .font(.headline)
                                Text(logCompletedDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(glassBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(glassOverlay)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle(Strings.Activity.startActivity)
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

    // MARK: - Computed Properties

    private var activityTitle: String {
        switch activityType {
        case .walk: return Strings.EventType.walk
        case .nap: return Strings.EventType.sleep
        }
    }

    private var startNowTitle: String {
        switch activityType {
        case .walk: return Strings.Activity.startWalkNow
        case .nap: return Strings.Activity.startNapNow
        }
    }

    private var startNowDescription: String {
        switch activityType {
        case .walk: return "Track this walk in real-time"
        case .nap: return "Start the nap timer now"
        }
    }

    private var logCompletedTitle: String {
        switch activityType {
        case .walk: return Strings.Activity.logCompletedWalk
        case .nap: return Strings.Activity.logCompletedNap
        }
    }

    private var logCompletedDescription: String {
        switch activityType {
        case .walk: return "Log a walk that already happened"
        case .nap: return "Log a nap that already happened"
        }
    }

    private var iconColor: Color {
        switch activityType {
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
    StartActivitySheet(
        activityType: .walk,
        onStartNow: { time in print("Start now at \(time)") },
        onLogCompleted: { print("Log completed") },
        onCancel: { print("Cancel") }
    )
}
