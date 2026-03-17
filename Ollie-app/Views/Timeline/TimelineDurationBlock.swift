//
//  TimelineDurationBlock.swift
//  Otis-app
//
//  Extracted duration block components from VerticalTimelineView
//  - DurationBlockView: liquid glass block for naps/walks
//  - LiveDurationText: live-updating duration for ongoing activities

import SwiftUI
import OtisShared
import Combine

// MARK: - Duration Block View

/// Compact block view for naps and walks using iOS 26 liquid glass design
/// Label positioned at top left with time next to title
struct DurationBlockView: View {
    let item: VerticalTimelineItem
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var blockColor: Color {
        switch item.type {
        case .sleepSession:
            return .otisSleep
        case .walkEvent:
            return .otisSuccess
        default:
            return .secondary
        }
    }

    private var glassTint: GlassTint {
        switch item.type {
        case .sleepSession:
            return .sleep
        case .walkEvent:
            return .success
        default:
            return .none
        }
    }

    private var blockLabel: String {
        switch item.type {
        case .sleepSession:
            return Strings.VerticalTimeline.sleep
        case .walkEvent:
            return Strings.VerticalTimeline.walk
        default:
            return ""
        }
    }

    var body: some View {
        Button(action: onTap) {
            // Label at top left with duration next to it
            HStack(spacing: 6) {
                Text(blockLabel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(blockColor)

                // Duration next to label (if available)
                if let duration = item.durationString {
                    Text(duration)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if item.isOngoing {
                    // Live duration for ongoing activities
                    LiveDurationText(startTime: item.startTime, color: blockColor)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .liquidGlass(style: .card, tint: glassTint, cornerRadius: 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Live Duration Text

/// Shows live-updating duration for ongoing activities
struct LiveDurationText: View {
    let startTime: Date
    let color: Color

    @State private var now = Date()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var durationString: String {
        let minutes = Int(now.timeIntervalSince(startTime) / 60)
        return DurationFormatter.format(minutes, style: .compact)
    }

    var body: some View {
        Text(durationString)
            .font(.caption2)
            .foregroundStyle(color)
            .onReceive(timer) { _ in
                now = Date()
            }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Text("Duration blocks are rendered within VerticalTimelineView")
            .foregroundStyle(.secondary)
    }
    .padding()
}
