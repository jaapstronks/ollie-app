//
//  EventRow.swift
//  Ollie-app
//

import SwiftUI

/// Single event row in the timeline
struct EventRow: View {
    let event: PuppyEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time
            Text(event.time.timeString)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 44, alignment: .trailing)

            // Emoji
            Text(event.type.emoji)
                .font(.title2)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(event.type.label)
                        .font(.body)
                        .fontWeight(.medium)

                    if let location = event.location {
                        Text("(\(location.label.lowercased()))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                if let note = event.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                if let who = event.who, !who.isEmpty {
                    Label(who, systemImage: "person")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let exercise = event.exercise {
                    Label(exercise, systemImage: "figure.walk")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let result = event.result {
                    Label(result, systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                }

                if let duration = event.durationMin {
                    Label("\(duration) min", systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Media indicator
            if event.photo != nil || event.video != nil {
                Image(systemName: event.video != nil ? "video" : "photo")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts = [event.time.timeString, event.type.label]
        if let location = event.location {
            parts.append(location.label)
        }
        if let note = event.note, !note.isEmpty {
            parts.append(note)
        }
        if let who = event.who, !who.isEmpty {
            parts.append("met \(who)")
        }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    VStack {
        EventRow(event: PuppyEvent(
            time: Date(),
            type: .plassen,
            location: .buiten,
            note: "Na het ontbijt"
        ))

        Divider()

        EventRow(event: PuppyEvent(
            time: Date(),
            type: .training,
            exercise: "Zit",
            result: "Goed gedaan!"
        ))

        Divider()

        EventRow(event: PuppyEvent(
            time: Date(),
            type: .sociaal,
            who: "Buurhond Sasha"
        ))
    }
}
