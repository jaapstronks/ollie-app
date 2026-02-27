//
//  EndCoverageGapSheet.swift
//  Ollie-app
//
//  Sheet for ending an active coverage gap
//

import SwiftUI
import OllieShared

/// Sheet for ending an active coverage gap
struct EndCoverageGapSheet: View {
    let gap: PuppyEvent
    let onEnd: (Date, String?) -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var endTime = Date()
    @State private var note = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Gap summary
                VStack(spacing: 16) {
                    Image(systemName: gap.gapType?.icon ?? "person.badge.clock.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.ollieWarning)

                    VStack(spacing: 4) {
                        Text(gap.gapType?.label ?? Strings.CoverageGap.eventLabel)
                            .font(.title2)
                            .fontWeight(.semibold)

                        if let location = gap.gapLocation {
                            Text(location)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Duration so far
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text(Strings.CoverageGap.since(time: gap.time.timeString))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("(\(durationSoFar))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.ollieWarning.opacity(0.1))
                    )
                }
                .padding(.top, 24)

                Divider()
                    .padding(.horizontal)

                // End time picker
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.CoverageGap.endTime)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    DatePicker(
                        "",
                        selection: $endTime,
                        in: gap.time...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(.horizontal)
                }

                // Optional note
                VStack(alignment: .leading, spacing: 8) {
                    TextField(Strings.CoverageGap.notePlaceholder, text: $note)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }

                Spacer()

                // End button
                Button {
                    HapticFeedback.medium()
                    onEnd(endTime, note.isEmpty ? nil : note)
                } label: {
                    Text(Strings.CoverageGap.endButton)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.ollieWarning)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle(Strings.CoverageGap.endTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        onCancel()
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var durationSoFar: String {
        let minutes = Int(endTime.timeIntervalSince(gap.time) / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return Strings.CoverageGap.duration(hours: hours, minutes: remainingMinutes)
    }
}

#Preview {
    EndCoverageGapSheet(
        gap: PuppyEvent.coverageGap(
            startTime: Date().addingTimeInterval(-3600),
            gapType: .daycare,
            location: "Happy Paws Daycare"
        ),
        onEnd: { time, note in
            print("End gap at \(time), note: \(note ?? "")")
        },
        onCancel: { print("Cancel") }
    )
}
