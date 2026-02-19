//
//  QuickLogBar.swift
//  Ollie-app
//

import SwiftUI

/// Bottom bar with quick-log buttons for common events
struct QuickLogBar: View {
    let onQuickLog: (EventType) -> Void
    let onShowAllEvents: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Constants.quickLogTypes) { type in
                QuickLogButton(type: type, action: { onQuickLog(type) })
            }

            // V2: "+" button to show all event types
            MoreEventsButton(action: onShowAllEvents)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
}

/// Button to open the all-events sheet
struct MoreEventsButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.medium()
            action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Meer")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Meer event types")
        .accessibilityHint("Dubbeltik om alle event types te zien")
    }
}

struct QuickLogButton: View {
    let type: EventType
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.medium()
            action()
        } label: {
            VStack(spacing: 4) {
                EventIcon(type: type, size: 28)
                Text(type.label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(type.label) loggen")
        .accessibilityHint("Dubbeltik om \(type.label.lowercased()) te registreren")
    }
}

#Preview {
    VStack {
        Spacer()
        QuickLogBar(
            onQuickLog: { type in
                print("Quick log: \(type)")
            },
            onShowAllEvents: {
                print("Show all events")
            }
        )
    }
}
