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
    let puppyName: String
    let onStartNow: (Date, NapLocation?) -> Void
    let onLogCompleted: () -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// For naps: tracks whether we're showing the time picker step
    @State private var showingTimePicker = false
    @State private var selectedTime = Date()
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var selectedNapLocation: NapLocation?

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

                if showingTimePicker && activityType == .nap {
                    // Time picker step for naps
                    napTimePickerContent
                } else {
                    // Initial options
                    initialOptionsContent
                }

                Spacer()
            }
            .navigationTitle(Strings.Activity.startActivity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        if showingTimePicker {
                            showingTimePicker = false
                        } else {
                            onCancel()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Initial Options Content

    @ViewBuilder
    private var initialOptionsContent: some View {
        VStack(spacing: 16) {
            // Start now option
            Button {
                HapticFeedback.medium()
                if activityType == .nap {
                    // For naps, show time picker step
                    selectedTime = Date()
                    selectedDate = Date()
                    showingTimePicker = true
                } else {
                    // For walks, start immediately
                    onStartNow(Date(), nil)
                }
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
    }

    // MARK: - Nap Time Picker Content

    @ViewBuilder
    private var napTimePickerContent: some View {
        VStack(spacing: 20) {
            Text(Strings.Activity.sinceWhen)
                .font(.headline)

            // Location picker
            VStack(spacing: 8) {
                Text(Strings.NapLocation.wherePrompt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    ForEach(NapLocation.allCases, id: \.self) { location in
                        NapLocationButton(
                            location: location,
                            isSelected: selectedNapLocation == location,
                            colorScheme: colorScheme
                        ) {
                            HapticFeedback.selection()
                            if selectedNapLocation == location {
                                selectedNapLocation = nil
                            } else {
                                selectedNapLocation = location
                            }
                        }
                    }
                }
            }

            // Quick options
            VStack(spacing: 12) {
                // "Now" button
                Button {
                    HapticFeedback.medium()
                    onStartNow(Date(), selectedNapLocation)
                } label: {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.title3)
                        Text(Strings.Activity.now)
                            .font(.headline)
                        Spacer()
                        Text(Date().formatted(date: .omitted, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(glassBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(glassOverlay)
                }
                .buttonStyle(.plain)

                // Time picker for earlier today
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title3)
                        Text(Strings.Activity.earlier)
                            .font(.headline)
                        Spacer()

                        // Date toggle for yesterday
                        if !showingDatePicker {
                            Button {
                                showingDatePicker = true
                                // Default to yesterday at the same time
                                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                            } label: {
                                Text(Strings.Activity.yesterday)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    if showingDatePicker {
                        // Show date picker when yesterday is selected
                        HStack {
                            DatePicker(
                                "",
                                selection: $selectedDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()

                            Button {
                                showingDatePicker = false
                                selectedDate = Date()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }

                    DatePicker(
                        "",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 120)

                    Button {
                        HapticFeedback.medium()
                        // Combine selected date and time
                        let calendar = Calendar.current
                        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
                        var dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                        dateComponents.hour = timeComponents.hour
                        dateComponents.minute = timeComponents.minute
                        let combinedDate = calendar.date(from: dateComponents) ?? selectedTime
                        onStartNow(combinedDate, selectedNapLocation)
                    } label: {
                        Text(Strings.Activity.isSleepingNow(name: puppyName))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(iconColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                .background(glassBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(glassOverlay)
            }
        }
        .padding(.horizontal)
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
        case .nap: return Strings.Activity.isSleepingNow(name: puppyName)
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

// MARK: - Nap Location Button

/// Button for selecting nap location (crate, dog bed, other)
private struct NapLocationButton: View {
    let location: NapLocation
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: location.icon)
                    .font(.system(size: 20))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.ollieSleep : Color.ollieSleep.opacity(0.1))
                    )
                    .foregroundStyle(isSelected ? .white : Color.ollieSleep)

                Text(location.label)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.ollieSleep : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.ollieSleep.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.ollieSleep : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Walk") {
    StartActivitySheet(
        activityType: .walk,
        puppyName: "Luna",
        onStartNow: { time, location in print("Start now at \(time), location: \(String(describing: location))") },
        onLogCompleted: { print("Log completed") },
        onCancel: { print("Cancel") }
    )
}

#Preview("Nap") {
    StartActivitySheet(
        activityType: .nap,
        puppyName: "Luna",
        onStartNow: { time, location in print("Start now at \(time), location: \(String(describing: location))") },
        onLogCompleted: { print("Log completed") },
        onCancel: { print("Cancel") }
    )
}
