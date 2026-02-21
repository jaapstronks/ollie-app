//
//  FABButton.swift
//  Ollie-app
//
//  Floating Action Button for quick event logging
//  Tap: Opens full LogEventSheet
//  Long press: Shows radial quick menu for one-tap logging

import SwiftUI

/// Quick action item for the FAB menu
struct FABQuickAction: Identifiable {
    let id = UUID()
    let type: EventType
    let label: String
    let icon: String
    let color: Color
    let location: EventLocation?

    static var defaultActions: [FABQuickAction] {
        [
            FABQuickAction(type: .plassen, label: Strings.FAB.peeOutside, icon: "drop.fill", color: .ollieInfo, location: .buiten),
            FABQuickAction(type: .poepen, label: Strings.FAB.poopOutside, icon: "circle.inset.filled", color: .ollieWarning, location: .buiten),
            FABQuickAction(type: .eten, label: Strings.FAB.eat, icon: "fork.knife", color: .ollieAccent, location: nil),
            FABQuickAction(type: .slapen, label: Strings.FAB.sleep, icon: "moon.zzz.fill", color: .ollieSleep, location: nil),
            FABQuickAction(type: .ontwaken, label: Strings.FAB.wakeUp, icon: "sun.max.fill", color: .ollieAccent, location: nil),
            FABQuickAction(type: .uitlaten, label: Strings.FAB.walk, icon: "figure.walk", color: .ollieSuccess, location: nil),
            FABQuickAction(type: .training, label: Strings.FAB.training, icon: "graduationcap.fill", color: .ollieMuted, location: nil),
        ]
    }
}

/// Floating Action Button with long-press quick menu
struct FABButton: View {
    let sleepState: SleepState
    let onTap: () -> Void
    let onQuickAction: (EventType, EventLocation?) -> Void

    @State private var isShowingMenu = false
    @State private var isPressed = false
    @State private var didLongPress = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let fabSize: CGFloat = 56
    private let menuItemSize: CGFloat = 48

    /// Filtered actions based on sleep state
    private var availableActions: [FABQuickAction] {
        FABQuickAction.defaultActions.filter { action in
            switch sleepState {
            case .sleeping:
                // When sleeping, show wake up instead of sleep
                return action.type != .slapen
            case .awake, .unknown:
                // When awake, show sleep instead of wake up
                return action.type != .ontwaken
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Dimmed backdrop when menu is open
            if isShowingMenu {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissMenu()
                    }
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }

            // Quick action menu - positioned above the FAB
            if isShowingMenu {
                quickActionMenu
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            }

            // Main FAB button - stays in bottom-right corner
            // Shows + when closed, X when menu is open
            fabButton
        }
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: isShowingMenu)
    }

    // MARK: - FAB Button

    @ViewBuilder
    private var fabButton: some View {
        Button {
            // Skip if this tap is from releasing a long press
            guard !didLongPress else {
                didLongPress = false
                return
            }

            // Handle tap - open full log sheet or dismiss menu
            if isShowingMenu {
                dismissMenu()
            } else {
                HapticFeedback.medium()
                onTap()
            }
        } label: {
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.ollieAccent)
                    .frame(width: fabSize, height: fabSize)
                    .shadow(color: Color.ollieAccent.opacity(0.4), radius: 8, y: 4)

                // Icon - changes to X when menu is open
                Image(systemName: isShowingMenu ? "xmark" : "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(isShowingMenu ? 45 : 0))
            }
        }
        .buttonStyle(FABMainButtonStyle(isPressed: $isPressed, reduceMotion: reduceMotion))
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4)
                .onEnded { _ in
                    didLongPress = true
                    HapticFeedback.medium()
                    withAnimation {
                        isShowingMenu = true
                    }
                }
        )
        .accessibilityLabel(Strings.FAB.accessibilityLabel)
        .accessibilityHint(Strings.FAB.accessibilityHint)
        .accessibilityIdentifier("FAB_BUTTON")
        .accessibilityAction(named: Strings.FAB.showQuickMenu) {
            HapticFeedback.medium()
            withAnimation {
                isShowingMenu = true
            }
        }
    }

    // MARK: - Quick Action Menu

    @ViewBuilder
    private var quickActionMenu: some View {
        VStack(spacing: 8) {
            Spacer()

            // Glass card container for menu items
            VStack(spacing: 4) {
                ForEach(availableActions) { action in
                    quickActionButton(action)
                }
            }
            .padding(12)
            .glassBackground(.menu)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.5 : 0.15), radius: 20, y: 10)

            // Spacer for FAB position
            Spacer()
                .frame(height: fabSize + 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func quickActionButton(_ action: FABQuickAction) -> some View {
        Button {
            HapticFeedback.success()
            dismissMenu()
            onQuickAction(action.type, action.location)
        } label: {
            HStack(spacing: 12) {
                CircleIconView(
                    icon: .system(action.icon),
                    color: action.color,
                    size: menuItemSize,
                    iconScale: 0.42
                )

                Text(action.label)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(QuickActionButtonStyle())
        .accessibilityLabel(action.label)
        .accessibilityHint(Strings.FAB.quickActionHint(action.label))
        .accessibilityIdentifier("FAB_QUICK_ACTION_\(action.type.rawValue)")
    }

    // MARK: - Helpers

    private func dismissMenu() {
        withAnimation {
            isShowingMenu = false
        }
    }
}

// MARK: - Button Styles

struct QuickActionButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(configuration.isPressed ? Color.primary.opacity(0.08) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Button style for main FAB button with press animation
struct FABMainButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()

        VStack {
            Spacer()

            HStack {
                Spacer()

                FABButton(
                    sleepState: .awake(since: Date(), durationMin: 30),
                    onTap: { print("FAB tapped") },
                    onQuickAction: { type, location in
                        print("Quick action: \(type), location: \(String(describing: location))")
                    }
                )
                .padding(.trailing, 16)
                .padding(.bottom, 80) // Above tab bar
            }
        }
    }
}
