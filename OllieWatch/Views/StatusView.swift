//
//  StatusView.swift
//  OllieWatch
//
//  Shows potty timer, streak, and sleep status

import SwiftUI
import OllieShared

struct StatusView: View {
    @ObservedObject var dataProvider: WatchDataProvider

    // Timer for periodic refresh
    let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Puppy name header
                Text(dataProvider.puppyName)
                    .font(.headline)
                    .foregroundColor(.secondary)

                // Potty Timer
                VStack(spacing: 4) {
                    Text(dataProvider.timeSinceLastPee())
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundColor(urgencyColor)

                    Text("since last pee")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .padding(.horizontal)

                // Streak
                HStack(spacing: 8) {
                    Image(systemName: streakIcon)
                        .font(.title2)
                        .foregroundColor(streakColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(dataProvider.currentStreak)")
                            .font(.title2.bold())
                        Text("outdoor streak")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Sleep indicator
                if dataProvider.isSleeping {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sleeping")
                                .font(.headline)
                            if let sleepStart = dataProvider.sleepStartTime {
                                Text(sleepDuration(since: sleepStart))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .foregroundColor(.purple)
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .onAppear {
            // Request fresh data when view appears
            dataProvider.requestSync()
        }
        .onReceive(refreshTimer) { _ in
            // Periodic refresh to keep time displays updated
            dataProvider.refresh()
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

    private var streakIcon: String {
        StreakCalculations.iconName(for: dataProvider.currentStreak)
    }

    private var streakColor: Color {
        let streak = dataProvider.currentStreak
        if streak == 0 {
            return .gray
        } else if streak < 3 {
            return .blue
        } else if streak < 5 {
            return .orange
        } else {
            return .red
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
