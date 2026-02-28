//
//  HourGridLayer.swift
//  Ollie-app
//
//  24-hour grid background with hour lines and labels for the vertical timeline

import SwiftUI

/// Background layer showing 24 horizontal hour lines with time labels
struct HourGridLayer: View {
    let calculator: TimelineGridCalculator

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Hour lines and labels (0-23)
            ForEach(0..<24, id: \.self) { hour in
                HStack(alignment: .top, spacing: 0) {
                    // Hour label
                    Text(hourString(for: hour))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(width: LayoutConstants.timelineTimeColumnWidth, alignment: .trailing)
                        .padding(.trailing, 8)

                    // Horizontal line
                    Rectangle()
                        .fill(lineColor)
                        .frame(height: 1)
                }
                .offset(y: calculator.yPosition(forHour: hour))
            }
        }
        .frame(height: calculator.totalHeight)
    }

    // MARK: - Helpers

    private func hourString(for hour: Int) -> String {
        if hour == 0 {
            return "12am"
        } else if hour == 12 {
            return "12pm"
        } else if hour < 12 {
            return "\(hour)am"
        } else {
            return "\(hour - 12)pm"
        }
    }

    private var lineColor: Color {
        colorScheme == .dark ? Color.ollieBorderDark : Color.ollieBorderLight
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        HourGridLayer(calculator: TimelineGridCalculator(for: Date()))
            .padding()
    }
    .background(Color(.systemGray6))
}
