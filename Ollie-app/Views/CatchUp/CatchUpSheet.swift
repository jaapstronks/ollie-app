//
//  CatchUpSheet.swift
//  Ollie-app
//
//  Quick catch-up sheet shown after a 3-10 hour logging gap
//  Helps user quickly establish current state for accurate predictions
//

import SwiftUI
import OllieShared

/// Sheet for quickly catching up after a logging gap
struct CatchUpSheet: View {
    let puppyName: String
    let hoursSinceLastEvent: Int
    let context: CatchUpContext
    let onComplete: (CatchUpResult) -> Void
    let onSkip: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    // State
    @State private var isSleeping: Bool? = nil
    @State private var sleepAwakeSinceTime: Date
    @State private var lastPottyOption: PottyOption = .unknown
    @State private var hasEatenSinceLast: Bool? = nil
    @State private var hasPoopedToday: Bool? = nil

    init(
        puppyName: String,
        hoursSinceLastEvent: Int,
        context: CatchUpContext,
        onComplete: @escaping (CatchUpResult) -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.puppyName = puppyName
        self.hoursSinceLastEvent = hoursSinceLastEvent
        self.context = context
        self.onComplete = onComplete
        self.onSkip = onSkip

        // Initialize state with context defaults
        _sleepAwakeSinceTime = State(initialValue: context.defaultSinceTime)
        _hasPoopedToday = State(initialValue: context.hasPoopedToday ? true : nil)
        _isSleeping = State(initialValue: context.suggestedSleepState)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    Divider()
                        .padding(.horizontal)

                    // Sleep/Awake state
                    sleepStateSection

                    Divider()
                        .padding(.horizontal)

                    // Last potty
                    pottySection

                    Divider()
                        .padding(.horizontal)

                    // Meal question (if relevant)
                    if context.lastMealDescription != nil {
                        mealSection
                        Divider()
                            .padding(.horizontal)
                    }

                    // Poop question
                    poopSection

                    Spacer(minLength: 20)

                    // Complete button
                    completeButton

                    // Skip option
                    Button {
                        onSkip()
                    } label: {
                        Text(Strings.CatchUp.skipForNow)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.top)
            }
            .navigationTitle(Strings.CatchUp.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        onSkip()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.blue)

            Text(Strings.CatchUp.greeting)
                .font(.title3)
                .fontWeight(.semibold)

            Text(Strings.CatchUp.lastLogged(hours: hoursSinceLastEvent))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    // MARK: - Sleep State Section

    private var sleepStateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Strings.CatchUp.currentState(name: puppyName))
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal)

            // Sleep/Awake toggle buttons
            HStack(spacing: 12) {
                StateButton(
                    icon: "moon.zzz.fill",
                    label: Strings.CatchUp.sleeping,
                    isSelected: isSleeping == true,
                    color: .purple
                ) {
                    isSleeping = true
                    HapticFeedback.selection()
                }

                StateButton(
                    icon: "sun.max.fill",
                    label: Strings.CatchUp.awake,
                    isSelected: isSleeping == false,
                    color: .orange
                ) {
                    isSleeping = false
                    HapticFeedback.selection()
                }
            }
            .padding(.horizontal)

            // Time slider (only show when state is selected)
            if isSleeping != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.CatchUp.since)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    TimeSlider(
                        value: $sleepAwakeSinceTime,
                        range: context.lastEventTime...Date(),
                        defaultValue: context.defaultSinceTime
                    )
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Potty Section

    private var pottySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.CatchUp.lastPotty)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal)

            HStack(spacing: 8) {
                ForEach(PottyOption.allCases, id: \.self) { option in
                    PottyOptionButton(
                        option: option,
                        isSelected: lastPottyOption == option
                    ) {
                        lastPottyOption = option
                        HapticFeedback.selection()
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Meal Section

    private var mealSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.CatchUp.eatenSince(time: context.lastMealDescription ?? ""))
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal)

            HStack(spacing: 12) {
                YesNoButton(
                    label: Strings.Common.yes,
                    isSelected: hasEatenSinceLast == true
                ) {
                    hasEatenSinceLast = true
                    HapticFeedback.selection()
                }

                YesNoButton(
                    label: Strings.Common.no,
                    isSelected: hasEatenSinceLast == false
                ) {
                    hasEatenSinceLast = false
                    HapticFeedback.selection()
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Poop Section

    private var poopSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.CatchUp.poopedToday)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal)

            HStack(spacing: 12) {
                YesNoButton(
                    label: Strings.Common.yes,
                    isSelected: hasPoopedToday == true
                ) {
                    hasPoopedToday = true
                    HapticFeedback.selection()
                }

                YesNoButton(
                    label: Strings.Common.no,
                    isSelected: hasPoopedToday == false
                ) {
                    hasPoopedToday = false
                    HapticFeedback.selection()
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Complete Button

    private var completeButton: some View {
        Button {
            HapticFeedback.success()
            let result = CatchUpResult(
                isSleeping: isSleeping,
                sleepAwakeSinceTime: isSleeping != nil ? sleepAwakeSinceTime : nil,
                lastPottyOption: lastPottyOption,
                hasEatenSinceLast: hasEatenSinceLast,
                hasPoopedToday: hasPoopedToday
            )
            onComplete(result)
        } label: {
            Text(Strings.CatchUp.allCaughtUp)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canComplete ? Color.blue : Color.gray.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(!canComplete)
        .padding(.horizontal)
    }

    private var canComplete: Bool {
        // At minimum, need sleep state to be useful
        isSleeping != nil
    }
}

// MARK: - Result

/// Result of the catch-up flow
struct CatchUpResult {
    let isSleeping: Bool?
    let sleepAwakeSinceTime: Date?
    let lastPottyOption: PottyOption
    let hasEatenSinceLast: Bool?
    let hasPoopedToday: Bool?
}

/// Options for last potty time
enum PottyOption: CaseIterable {
    case justNow
    case oneHour
    case twoHours
    case unknown

    var label: String {
        switch self {
        case .justNow: return Strings.CatchUp.pottyJustNow
        case .oneHour: return Strings.CatchUp.pottyOneHour
        case .twoHours: return Strings.CatchUp.pottyTwoHours
        case .unknown: return "?"
        }
    }

    /// Minutes ago for this option
    var minutesAgo: Int? {
        switch self {
        case .justNow: return 10
        case .oneHour: return 60
        case .twoHours: return 120
        case .unknown: return nil
        }
    }
}

// MARK: - Supporting Views

private struct StateButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : color)

                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? color : GlassButtonHelpers.glassColor(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected ? color : Color.primary.opacity(0.1),
                        lineWidth: isSelected ? 2 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PottyOptionButton: View {
    let option: PottyOption
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(option.label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? Color.blue : GlassButtonHelpers.glassColor(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.blue : Color.primary.opacity(0.1),
                            lineWidth: isSelected ? 2 : 0.5
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

private struct YesNoButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? Color.blue : GlassButtonHelpers.glassColor(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.blue : Color.primary.opacity(0.1),
                            lineWidth: isSelected ? 2 : 0.5
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

/// Horizontal time slider for selecting approximate time
private struct TimeSlider: View {
    @Binding var value: Date
    let range: ClosedRange<Date>
    let defaultValue: Date

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            // Time display
            Text(value.timeString)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()

            // Slider
            Slider(
                value: Binding(
                    get: { value.timeIntervalSince(range.lowerBound) },
                    set: { value = range.lowerBound.addingTimeInterval($0) }
                ),
                in: 0...range.upperBound.timeIntervalSince(range.lowerBound)
            )
            .tint(.blue)

            // Labels
            HStack {
                Text(formatTimeAgo(range.lowerBound))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Strings.CatchUp.now)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        )
    }

    private func formatTimeAgo(_ date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        let hours = minutes / 60
        if hours > 0 {
            return "\(hours)h ago"
        } else {
            return "\(minutes)m ago"
        }
    }
}

#Preview {
    CatchUpSheet(
        puppyName: "Ollie",
        hoursSinceLastEvent: 5,
        context: CatchUpContext(
            lastEventTime: Date().addingTimeInterval(-5 * 3600),
            lastPottyTime: Date().addingTimeInterval(-6 * 3600),
            lastMealTime: Date().addingTimeInterval(-4 * 3600),
            lastMealDescription: "12:30",
            hasPoopedToday: false,
            suggestedSleepState: nil,
            defaultSinceTime: Date().addingTimeInterval(-2 * 3600),
            isTypicalNapTime: false
        ),
        onComplete: { result in print("Complete: \(result)") },
        onSkip: { print("Skip") }
    )
}
