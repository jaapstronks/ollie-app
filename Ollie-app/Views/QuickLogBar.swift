//
//  QuickLogBar.swift
//  Ollie-app
//

import SwiftUI

struct QuickLogBar: View {
    let onTap: (EventType) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Constants.quickLogTypes, id: \.self) { type in
                QuickLogButton(type: type) {
                    onTap(type)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

struct QuickLogButton: View {
    let type: EventType
    let action: () -> Void

    private var emoji: String {
        Constants.eventEmoji[type] ?? "📌"
    }

    private var label: String {
        Constants.eventLabels[type] ?? type.rawValue
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji)
                    .font(.title2)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        Spacer()
        QuickLogBar { type in
            print("Tapped: \(type)")
        }
    }
}
