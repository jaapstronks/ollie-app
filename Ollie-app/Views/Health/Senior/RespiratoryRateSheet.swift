//
//  RespiratoryRateSheet.swift
//  Ollie-app
//
//  Sheet for logging resting respiratory rate readings
//  Part of Brief 05: Senior Wellness
//

import SwiftUI
import OtisShared

struct RespiratoryRateSheet: View {
    let onSave: (RespiratoryRateReading) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileStore: ProfileStore
    @StateObject private var wellnessStore = SeniorWellnessStore.shared

    @State private var breathCount: Int = 0
    @State private var isTimerRunning = false
    @State private var timerSeconds: Int = 30
    @State private var wasResting = true
    @State private var note: String = ""
    @State private var showResult = false

    private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var puppyName: String {
        profileStore.activeProfile?.name ?? "Your dog"
    }

    private var breathsPerMinute: Int {
        breathCount * 2
    }

    private var status: RRRStatus {
        switch breathsPerMinute {
        case 0..<20: return .normal
        case 20..<30: return .elevated
        default: return .emergency
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if showResult {
                    resultView
                } else {
                    countingView
                }

                Spacer()

                // Recent readings
                if !wellnessStore.respiratoryReadings.isEmpty {
                    recentReadings
                }

                // Emergency alert
                if breathsPerMinute >= 30 {
                    emergencyAlert
                }
            }
            .padding()
            .navigationTitle(Strings.SeniorWellness.respiratoryRate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                if showResult {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(Strings.Common.save) {
                            saveReading()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .onReceive(timer) { _ in
                if isTimerRunning && timerSeconds > 0 {
                    timerSeconds -= 1
                    if timerSeconds == 0 {
                        isTimerRunning = false
                        showResult = true
                    }
                }
            }
        }
    }

    // MARK: - Counting View

    @ViewBuilder
    private var countingView: some View {
        VStack(spacing: 24) {
            // Instructions
            Text(Strings.SeniorWellness.countBreathsFor(name: puppyName))
                .font(.headline)
                .multilineTextAlignment(.center)

            // Timer circle
            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 8)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: CGFloat(timerSeconds) / 30.0)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerSeconds)

                VStack(spacing: 4) {
                    Text("\(timerSeconds)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                    Text("seconds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Breath counter
            VStack(spacing: 8) {
                Text("Breaths counted")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 20) {
                    Button {
                        if breathCount > 0 {
                            breathCount -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.gray)
                    }
                    .disabled(!isTimerRunning)

                    Text("\(breathCount)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .frame(width: 100)

                    Button {
                        breathCount += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)
                    }
                    .disabled(!isTimerRunning)
                }
            }

            // Start/Stop button
            Button {
                if isTimerRunning {
                    isTimerRunning = false
                    showResult = true
                } else {
                    isTimerRunning = true
                    timerSeconds = 30
                    breathCount = 0
                }
            } label: {
                Text(isTimerRunning ? Strings.SeniorWellness.stopTimer : Strings.SeniorWellness.startTimer)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isTimerRunning ? Color.orange : Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Result View

    @ViewBuilder
    private var resultView: some View {
        VStack(spacing: 24) {
            // Result icon
            Image(systemName: status.icon)
                .font(.system(size: 60))
                .foregroundStyle(Color(status.colorName))

            // BPM display
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(breathsPerMinute)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                    Text("bpm")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Text(status.label)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(status.colorName))
            }

            // Status message
            Text(status.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Resting toggle
            Toggle(isOn: $wasResting) {
                HStack {
                    Image(systemName: "moon.zzz.fill")
                        .foregroundStyle(.blue)
                    Text("Was resting/sleeping")
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Note
            TextField(Strings.SeniorWellness.optionalNotes, text: $note, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)

            // Try again button
            Button {
                showResult = false
                timerSeconds = 30
                breathCount = 0
            } label: {
                Text("Count Again")
                    .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Recent Readings

    @ViewBuilder
    private var recentReadings: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.SeniorWellness.recentReadings)
                .font(.subheadline)
                .fontWeight(.semibold)

            VStack(spacing: 4) {
                ForEach(wellnessStore.respiratoryReadings.prefix(3)) { reading in
                    HStack {
                        Text(reading.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(reading.formattedBPM)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Image(systemName: reading.status.icon)
                            .font(.caption)
                            .foregroundStyle(Color(reading.status.colorName))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Emergency Alert

    @ViewBuilder
    private var emergencyAlert: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("Emergency")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(Strings.SeniorWellness.rrrEmergencyAlert)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer()
        }
        .padding()
        .background(Color.red)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions

    private func saveReading() {
        let reading = RespiratoryRateReading(
            breathsPerMinute: breathsPerMinute,
            wasResting: wasResting,
            note: note.isEmpty ? nil : note
        )
        onSave(reading)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    RespiratoryRateSheet { reading in
        print("Saved: \(reading)")
    }
    .environmentObject(ProfileStore.shared)
}
