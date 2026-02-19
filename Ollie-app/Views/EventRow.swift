//
//  EventRow.swift
//  Ollie-app
//

import SwiftUI

struct EventRow: View {
    let event: PuppyEvent

    private var emoji: String {
        Constants.eventEmoji[event.type] ?? "📌"
    }

    private var label: String {
        Constants.eventLabels[event.type] ?? event.type.rawValue
    }

    private var timeString: String {
        DateHelpers.formatTime(event.time)
    }

    private var locationBadge: String? {
        guard let location = event.location else { return nil }
        return location == .buiten ? "buiten" : "binnen"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time
            Text(timeString)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 50, alignment: .leading)

            // Emoji
            Text(emoji)
                .font(.title2)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(label)
                        .font(.body)
                        .fontWeight(.medium)

                    if let badge = locationBadge {
                        Text(badge)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(badge == "buiten" ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                            .foregroundStyle(badge == "buiten" ? .green : .orange)
                            .clipShape(Capsule())
                    }
                }

                if let note = event.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack {
        EventRow(event: PuppyEvent(type: .plassen, location: .buiten, note: "Na het wakker worden"))
        EventRow(event: PuppyEvent(type: .eten))
        EventRow(event: PuppyEvent(type: .slapen, note: "In de bench"))
    }
    .padding()
}
