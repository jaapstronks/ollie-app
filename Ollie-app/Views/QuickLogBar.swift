//
//  QuickLogBar.swift
//  Ollie-app
//

import SwiftUI

/// Bottom bar with quick-log buttons for common events
struct QuickLogBar: View {
    let onQuickLog: (EventType) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Constants.quickLogTypes) { type in
                QuickLogButton(type: type, action: { onQuickLog(type) })
            }
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

struct QuickLogButton: View {
    let type: EventType
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.medium()
            action()
        } label: {
            VStack(spacing: 4) {
                Text(type.emoji)
                    .font(.title2)
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
        QuickLogBar(onQuickLog: { type in
            print("Quick log: \(type)")
        })
    }
}
