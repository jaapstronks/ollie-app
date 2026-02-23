//
//  NapLiveActivityWidget.swift
//  OllieWidget
//
//  Live Activity widget views for nap tracking
//

import SwiftUI
import OllieShared
import WidgetKit
import ActivityKit
import AppIntents

@available(iOS 16.1, *)
struct NapLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NapActivityAttributes.self) { context in
            // Lock Screen / Banner view
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded region (long press)
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeading(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    expandedCenter(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(context: context)
                }
            } compactLeading: {
                // Compact leading (left side of pill)
                compactLeading()
            } compactTrailing: {
                // Compact trailing (right side of pill)
                compactTrailing(context: context)
            } minimal: {
                // Minimal view (when multiple activities)
                minimalView()
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<NapActivityAttributes>) -> some View {
        HStack(spacing: 16) {
            // Moon icon
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 36))
                .foregroundStyle(.indigo)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(context.attributes.puppyName) is napping")
                    .font(.headline)
                    .foregroundStyle(.primary)

                // Timer that counts up automatically
                Text(context.attributes.startTime, style: .timer)
                    .font(.system(.title2, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Wake button (iOS 17+ for interactive)
            if #available(iOS 17.0, *) {
                Button(intent: WakeUpIntent(activityId: context.attributes.activityId.uuidString)) {
                    Label("Wake", systemImage: "sun.max.fill")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            } else {
                // Non-interactive on iOS 16
                Image(systemName: "sun.max.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.8))
    }

    // MARK: - Dynamic Island Compact Views

    @ViewBuilder
    private func compactLeading() -> some View {
        Image(systemName: "moon.zzz.fill")
            .foregroundStyle(.indigo)
    }

    @ViewBuilder
    private func compactTrailing(context: ActivityViewContext<NapActivityAttributes>) -> some View {
        // Timer counting up
        Text(context.attributes.startTime, style: .timer)
            .font(.system(.body, design: .monospaced))
            .monospacedDigit()
            .frame(minWidth: 50)
    }

    // MARK: - Dynamic Island Minimal View

    @ViewBuilder
    private func minimalView() -> some View {
        Image(systemName: "moon.zzz.fill")
            .foregroundStyle(.indigo)
    }

    // MARK: - Dynamic Island Expanded Views

    @ViewBuilder
    private func expandedLeading(context: ActivityViewContext<NapActivityAttributes>) -> some View {
        VStack(alignment: .leading) {
            Image(systemName: "moon.zzz.fill")
                .font(.title)
                .foregroundStyle(.indigo)
        }
    }

    @ViewBuilder
    private func expandedTrailing(context: ActivityViewContext<NapActivityAttributes>) -> some View {
        VStack(alignment: .trailing) {
            Text("Started")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(context.attributes.startTime, style: .time)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private func expandedCenter(context: ActivityViewContext<NapActivityAttributes>) -> some View {
        VStack {
            Text("\(context.attributes.puppyName) is napping")
                .font(.headline)

            Text(context.attributes.startTime, style: .timer)
                .font(.system(.title, design: .monospaced))
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func expandedBottom(context: ActivityViewContext<NapActivityAttributes>) -> some View {
        if #available(iOS 17.0, *) {
            Button(intent: WakeUpIntent(activityId: context.attributes.activityId.uuidString)) {
                HStack {
                    Image(systemName: "sun.max.fill")
                    Text("Wake Up")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        } else {
            // Non-interactive hint on iOS 16
            HStack {
                Image(systemName: "hand.tap")
                Text("Open app to end nap")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 16.1, *)
struct NapLiveActivityWidget_Previews: PreviewProvider {
    static let attributes = NapActivityAttributes(
        puppyName: "Ollie",
        startTime: Date().addingTimeInterval(-15 * 60),  // 15 min ago
        activityId: UUID()
    )

    static let state = NapActivityAttributes.ContentState(hasEnded: false)

    static var previews: some View {
        attributes
            .previewContext(state, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Compact")

        attributes
            .previewContext(state, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Expanded")

        attributes
            .previewContext(state, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Minimal")

        attributes
            .previewContext(state, viewKind: .content)
            .previewDisplayName("Lock Screen")
    }
}
#endif
