//
//  DaylightGradientView.swift
//  Ollie-app
//
//  Subtle background gradient showing daylight (sunrise to sunset) vs night

import SwiftUI

/// Background gradient showing daylight hours based on sunrise/sunset
struct DaylightGradientView: View {
    let sunrise: Date?
    let sunset: Date?
    let calculator: TimelineGridCalculator

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Night section (midnight to sunrise)
                if let sunrise = sunrise {
                    nightSection(from: 0, to: calculator.yPosition(for: sunrise))
                }

                // Day section (sunrise to sunset)
                if let sunrise = sunrise, let sunset = sunset {
                    daySection(
                        from: calculator.yPosition(for: sunrise),
                        to: calculator.yPosition(for: sunset)
                    )
                }

                // Night section (sunset to midnight)
                if let sunset = sunset {
                    nightSection(
                        from: calculator.yPosition(for: sunset),
                        to: calculator.totalHeight
                    )
                }

                // Fallback: no sunrise/sunset data - show neutral background
                if sunrise == nil && sunset == nil {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: calculator.totalHeight)
                }
            }
        }
        .frame(height: calculator.totalHeight)
    }

    // MARK: - Sections

    @ViewBuilder
    private func nightSection(from yStart: CGFloat, to yEnd: CGFloat) -> some View {
        let height = yEnd - yStart
        if height > 0 {
            Rectangle()
                .fill(nightColor)
                .frame(height: height)
                .offset(y: yStart)
        }
    }

    @ViewBuilder
    private func daySection(from yStart: CGFloat, to yEnd: CGFloat) -> some View {
        let height = yEnd - yStart
        if height > 0 {
            Rectangle()
                .fill(dayColor)
                .frame(height: height)
                .offset(y: yStart)
        }
    }

    // MARK: - Colors

    private var nightColor: Color {
        colorScheme == .dark
            ? Color.blue.opacity(0.05)
            : Color(hue: 0.6, saturation: 0.15, brightness: 0.95).opacity(0.3)
    }

    private var dayColor: Color {
        colorScheme == .dark
            ? Color.orange.opacity(0.03)
            : Color(hue: 0.12, saturation: 0.15, brightness: 1.0).opacity(0.2)
    }
}

// MARK: - Preview

#Preview {
    let calculator = TimelineGridCalculator(for: Date())
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let sunrise = calendar.date(byAdding: .hour, value: 7, to: today)
    let sunset = calendar.date(byAdding: .hour, value: 20, to: today)

    return ScrollView {
        ZStack(alignment: .topLeading) {
            DaylightGradientView(
                sunrise: sunrise,
                sunset: sunset,
                calculator: calculator
            )

            HourGridLayer(calculator: calculator)
        }
        .padding()
    }
    .background(Color(.systemGray6))
}
