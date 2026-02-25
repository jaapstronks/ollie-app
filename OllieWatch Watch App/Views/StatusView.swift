//
//  StatusView.swift
//  OllieWatch
//
//  Shows potty timer and sleep status

import SwiftUI

struct StatusView: View {
    @ObservedObject var dataProvider: WatchDataProvider

    var body: some View {
        VStack(spacing: 12) {
            // Puppy name header
            Text(dataProvider.puppyName)
                .font(.headline)
                .foregroundColor(.secondary)

            Spacer()

            if dataProvider.isSleeping {
                // SLEEPING: Show sleep status prominently at top, potty timer below
                sleepingContent
            } else {
                // AWAKE: Show potty timer prominently
                awakeContent
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Sleeping Layout

    private var sleepingContent: some View {
        VStack(spacing: 16) {
            // Sleep status - prominent
            VStack(spacing: 6) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.purple)

                Text("Sleeping")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)

                if let sleepStart = dataProvider.sleepStartTime {
                    Text(sleepDuration(since: sleepStart))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }

            // Potty timer - smaller, below sleep info
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.caption)
                        .foregroundColor(urgencyColor)
                    Text(dataProvider.timeSinceLastPee())
                        .font(.headline)
                        .foregroundColor(urgencyColor)
                }
                Text("since last pee")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Awake Layout

    private var awakeContent: some View {
        // Potty Timer - prominent when awake
        VStack(spacing: 4) {
            Text(dataProvider.timeSinceLastPee())
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundColor(urgencyColor)

            Text("since last pee")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Computed Properties

    private var urgencyColor: Color {
        switch dataProvider.urgencyLevel() {
        case .good:
            return .green
        case .attention:
            return .yellow
        case .warning:
            return .orange
        case .urgent:
            return .red
        case .unknown:
            return .gray
        }
    }

    private func sleepDuration(since date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }
}

#Preview {
    StatusView(dataProvider: WatchDataProvider.shared)
}
