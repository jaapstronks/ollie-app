//
//  CoverageGapRow.swift
//  Ollie-app
//
//  Timeline row for displaying coverage gap events
//

import SwiftUI
import OllieShared

/// Row displaying a coverage gap event in the timeline
/// Has a distinctive full-width card appearance to stand out from regular events
struct CoverageGapRow: View {
    let event: PuppyEvent
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon with background
                Image(systemName: event.gapType?.icon ?? "person.badge.clock.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .frame(width: 40, height: 40)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Circle())

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    // Type label
                    HStack(spacing: 6) {
                        Text(event.gapType?.label ?? Strings.CoverageGap.eventLabel)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if event.isOngoingGap {
                            Text(Strings.CoverageGap.ongoing)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                    }

                    // Time range
                    HStack(spacing: 4) {
                        Text(event.time.timeString)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let endTime = event.endTime {
                            Text("-")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(endTime.timeString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("(\(formattedDuration))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Location if provided
                    if let location = event.gapLocation, !location.isEmpty {
                        Label(location, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Note if provided
                    if let note = event.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Chevron for tappable indication
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.orange.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed Properties

    private var formattedDuration: String {
        guard let minutes = event.gapDurationMinutes else { return "" }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return Strings.CoverageGap.duration(hours: hours, minutes: remainingMinutes)
    }

    private var cardBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(Color.orange.opacity(0.08))
        }
        return AnyShapeStyle(Color.orange.opacity(0.05))
    }
}

#Preview("Coverage Gap Row") {
    VStack(spacing: 12) {
        // Ongoing gap
        CoverageGapRow(
            event: PuppyEvent.coverageGap(
                startTime: Date().addingTimeInterval(-3600),
                gapType: .daycare,
                location: "Happy Paws Daycare"
            ),
            onTap: {}
        )

        // Completed gap
        CoverageGapRow(
            event: PuppyEvent.coverageGap(
                startTime: Date().addingTimeInterval(-7200),
                endTime: Date().addingTimeInterval(-3600),
                gapType: .family,
                location: "Grandma's house",
                note: "Puppy had a great time!"
            ),
            onTap: {}
        )

        // Minimal gap
        CoverageGapRow(
            event: PuppyEvent.coverageGap(
                startTime: Date().addingTimeInterval(-3600),
                endTime: Date(),
                gapType: .sitter
            ),
            onTap: {}
        )
    }
    .padding()
}
