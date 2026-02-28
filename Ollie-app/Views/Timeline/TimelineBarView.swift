//
//  TimelineBarView.swift
//  Ollie-app
//
//  Canvas-rendered horizontal time bar for visual timeline

import SwiftUI
import OllieShared

/// Visual horizontal time bar showing activity blocks
struct TimelineBarView: View {
    let blocks: [ActivityBlock]
    let startTime: Date
    let endTime: Date
    let isToday: Bool
    let onBlockTap: (ActivityBlock) -> Void

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Layout Constants

    private let barHeight: CGFloat = 48
    private let sleepBarHeight: CGFloat = 40
    private let walkBarHeight: CGFloat = 28
    private let pottyTickHeight: CGFloat = 16
    private let mealDotSize: CGFloat = 10
    private let cornerRadius: CGFloat = 6
    private let nowIndicatorWidth: CGFloat = 2

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            // Time axis labels
            timeLabels

            // Main timeline bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    backgroundTrack

                    // Activity blocks
                    ForEach(blocks) { block in
                        blockView(for: block, in: geometry.size)
                    }

                    // Current time indicator (today only)
                    if isToday {
                        currentTimeIndicator(in: geometry.size)
                    }
                }
            }
            .frame(height: barHeight)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .padding(.horizontal)
    }

    // MARK: - Time Labels

    private var timeLabels: some View {
        GeometryReader { geometry in
            let hours = hourLabels
            HStack(spacing: 0) {
                ForEach(hours, id: \.self) { hour in
                    Text(hourString(hour))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 16)
        .padding(.horizontal)
    }

    private var hourLabels: [Int] {
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: startTime)
        let endHour = calendar.component(.hour, from: endTime)

        // Show labels every 3 hours
        var hours: [Int] = []
        var hour = startHour
        while hour <= endHour {
            hours.append(hour)
            hour += 3
        }
        return hours
    }

    private func hourString(_ hour: Int) -> String {
        if hour == 0 || hour == 12 {
            return hour == 0 ? "12am" : "12pm"
        } else if hour < 12 {
            return "\(hour)am"
        } else {
            return "\(hour - 12)pm"
        }
    }

    // MARK: - Background Track

    private var backgroundTrack: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(colorScheme == .dark ? Color.ollieCardDark : Color.ollieCardLight)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        colorScheme == .dark ? Color.ollieBorderDark : Color.ollieBorderLight,
                        lineWidth: 1
                    )
            )
    }

    // MARK: - Block Views

    @ViewBuilder
    private func blockView(for block: ActivityBlock, in size: CGSize) -> some View {
        let xPosition = xPosition(for: block.startTime, in: size.width)
        let blockWidth = width(from: block.startTime, to: block.endTime, in: size.width)

        switch block.type {
        case .sleep:
            sleepBlock(block: block, at: xPosition, width: blockWidth, height: size.height)
        case .walk:
            walkBlock(block: block, at: xPosition, width: blockWidth, height: size.height)
        case .potty(let outdoor):
            pottyTick(block: block, outdoor: outdoor, at: xPosition, height: size.height)
        case .meal:
            mealDot(block: block, at: xPosition, height: size.height)
        case .awake:
            EmptyView()
        }
    }

    private func sleepBlock(block: ActivityBlock, at x: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        Button {
            onBlockTap(block)
        } label: {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.ollieSleep.opacity(block.isOngoing ? 0.7 : 0.9))
                .frame(width: max(width, 4), height: sleepBarHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.ollieSleep, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .position(x: x + width / 2, y: height / 2)
    }

    private func walkBlock(block: ActivityBlock, at x: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        Button {
            onBlockTap(block)
        } label: {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.ollieSuccess.opacity(0.9))
                .frame(width: max(width, 8), height: walkBarHeight)
                .overlay(
                    Image(systemName: "figure.walk")
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .opacity(width > 30 ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
        .position(x: x + width / 2, y: height / 2)
    }

    private func pottyTick(block: ActivityBlock, outdoor: Bool, at x: CGFloat, height: CGFloat) -> some View {
        Button {
            onBlockTap(block)
        } label: {
            Capsule()
                .fill(outdoor ? Color.ollieSuccess : Color.ollieDanger)
                .frame(width: 4, height: pottyTickHeight)
        }
        .buttonStyle(.plain)
        .position(x: x, y: height - pottyTickHeight / 2 - 4)
    }

    private func mealDot(block: ActivityBlock, at x: CGFloat, height: CGFloat) -> some View {
        Button {
            onBlockTap(block)
        } label: {
            Circle()
                .fill(Color.ollieAccent)
                .frame(width: mealDotSize, height: mealDotSize)
        }
        .buttonStyle(.plain)
        .position(x: x, y: 8 + mealDotSize / 2)
    }

    // MARK: - Current Time Indicator

    private func currentTimeIndicator(in size: CGSize) -> some View {
        let x = xPosition(for: Date(), in: size.width)
        return VStack(spacing: 0) {
            // Triangle at top
            Triangle()
                .fill(Color.ollieDanger)
                .frame(width: 8, height: 6)

            // Vertical line
            Rectangle()
                .fill(Color.ollieDanger)
                .frame(width: nowIndicatorWidth, height: size.height - 6)
        }
        .position(x: x, y: size.height / 2)
    }

    // MARK: - Position Calculations

    private func xPosition(for time: Date, in width: CGFloat) -> CGFloat {
        let totalDuration = endTime.timeIntervalSince(startTime)
        guard totalDuration > 0 else { return 0 }

        let timeSinceStart = time.timeIntervalSince(startTime)
        let fraction = timeSinceStart / totalDuration
        return CGFloat(fraction) * width
    }

    private func width(from start: Date, to end: Date, in totalWidth: CGFloat) -> CGFloat {
        let totalDuration = endTime.timeIntervalSince(startTime)
        guard totalDuration > 0 else { return 0 }

        let duration = end.timeIntervalSince(start)
        let fraction = duration / totalDuration
        return max(CGFloat(fraction) * totalWidth, 2)
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let now = Date()
    let dayStart = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: now)!
    let dayEnd = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now)!

    let blocks: [ActivityBlock] = [
        ActivityBlock(
            type: .sleep,
            startTime: dayStart,
            endTime: calendar.date(byAdding: .hour, value: 2, to: dayStart)!
        ),
        ActivityBlock(
            type: .meal,
            startTime: calendar.date(byAdding: .hour, value: 2, to: dayStart)!,
            endTime: calendar.date(byAdding: .hour, value: 2, to: dayStart)!
        ),
        ActivityBlock(
            type: .potty(outdoor: true),
            startTime: calendar.date(byAdding: .minute, value: 130, to: dayStart)!,
            endTime: calendar.date(byAdding: .minute, value: 130, to: dayStart)!
        ),
        ActivityBlock(
            type: .walk,
            startTime: calendar.date(byAdding: .hour, value: 3, to: dayStart)!,
            endTime: calendar.date(byAdding: .minute, value: 210, to: dayStart)!
        ),
        ActivityBlock(
            type: .sleep,
            startTime: calendar.date(byAdding: .hour, value: 5, to: dayStart)!,
            endTime: calendar.date(byAdding: .hour, value: 7, to: dayStart)!
        ),
        ActivityBlock(
            type: .potty(outdoor: false),
            startTime: calendar.date(byAdding: .hour, value: 8, to: dayStart)!,
            endTime: calendar.date(byAdding: .hour, value: 8, to: dayStart)!
        )
    ]

    return TimelineBarView(
        blocks: blocks,
        startTime: dayStart,
        endTime: dayEnd,
        isToday: true,
        onBlockTap: { _ in }
    )
    .padding()
}
