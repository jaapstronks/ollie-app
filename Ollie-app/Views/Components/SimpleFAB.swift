//
//  SimpleFAB.swift
//  Otis-app
//
//  Simple floating action button for consistent FAB styling across the app.
//  Use FABButton for the full radial quick menu on the Today tab.

import SwiftUI
import OtisShared

/// Standard FAB positioning constants
enum FABLayout {
    /// Right padding from screen edge
    static let trailingPadding: CGFloat = 16
    /// Bottom padding above tab bar (matches Today FAB)
    static let bottomPadding: CGFloat = 60
    /// FAB button size
    static let size: CGFloat = 56
    /// Icon font size
    static let iconSize: CGFloat = 24
    /// Shadow radius
    static let shadowRadius: CGFloat = 8
    /// Shadow Y offset
    static let shadowY: CGFloat = 4
    /// Shadow opacity
    static let shadowOpacity: CGFloat = 0.4
}

/// Simple floating action button with consistent styling
/// For use in views like Schedule, Places, etc. where the full radial menu isn't needed
struct SimpleFAB<Content: View>: View {
    let accessibilityLabel: String
    @ViewBuilder let content: () -> Content

    init(
        accessibilityLabel: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.content = content
    }

    var body: some View {
        content()
            .modifier(FABPositionModifier())
            .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - FAB Label (the visual circle button)

/// Standard FAB visual appearance - a circle with plus icon
struct FABLabel: View {
    var icon: String = "plus"

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.otisAccent)
                .frame(width: FABLayout.size, height: FABLayout.size)
                .shadow(
                    color: Color.otisAccent.opacity(FABLayout.shadowOpacity),
                    radius: FABLayout.shadowRadius,
                    y: FABLayout.shadowY
                )

            Image(systemName: icon)
                .font(.system(size: FABLayout.iconSize, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Position Modifier

/// Modifier that positions content as a FAB in the bottom-right corner
struct FABPositionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.trailing, FABLayout.trailingPadding)
            .padding(.bottom, FABLayout.bottomPadding)
    }
}

extension View {
    /// Applies standard FAB positioning (bottom-right, above tab bar)
    func fabPosition() -> some View {
        modifier(FABPositionModifier())
    }
}

// MARK: - Convenience Initializers

extension SimpleFAB where Content == Button<FABLabel> {
    /// Creates a simple button FAB with the standard plus icon
    init(accessibilityLabel: String, action: @escaping () -> Void) {
        self.accessibilityLabel = accessibilityLabel
        self.content = {
            Button(action: action) {
                FABLabel()
            }
        }
    }
}

extension SimpleFAB where Content == Menu<FABLabel, TupleView<(Button<Label<Text, Image>>, Button<Label<Text, Image>>)>> {
    /// Creates a menu FAB with two options
    init(
        accessibilityLabel: String,
        option1Label: String,
        option1Icon: String,
        option1Action: @escaping () -> Void,
        option2Label: String,
        option2Icon: String,
        option2Action: @escaping () -> Void
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.content = {
            Menu {
                Button(action: option1Action) {
                    Label(option1Label, systemImage: option1Icon)
                }
                Button(action: option2Action) {
                    Label(option2Label, systemImage: option2Icon)
                }
            } label: {
                FABLabel()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack(alignment: .bottomTrailing) {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()

        SimpleFAB(accessibilityLabel: "Add item") {
            print("Tapped!")
        }
    }
}
