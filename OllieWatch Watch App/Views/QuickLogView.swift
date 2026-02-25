//
//  QuickLogView.swift
//  OllieWatch
//
//  4-button grid for fast event logging

import SwiftUI
import WatchKit

struct QuickLogView: View {
    @ObservedObject var dataProvider: WatchDataProvider
    @State private var showingPeeLocationPicker = false
    @State private var showingPoopLocationPicker = false

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                QuickLogButton(
                    icon: "drop.fill",
                    label: "Pee",
                    color: .yellow
                ) {
                    showingPeeLocationPicker = true
                }

                QuickLogButton(
                    icon: "circle.fill",
                    label: "Poop",
                    color: .brown
                ) {
                    showingPoopLocationPicker = true
                }

                QuickLogButton(
                    icon: "fork.knife",
                    label: "Meal",
                    color: .blue
                ) {
                    logMeal()
                }

                // Dynamic Sleep/Wake button based on current state
                if dataProvider.isSleeping {
                    QuickLogButton(
                        icon: "sun.max.fill",
                        label: "Wake Up",
                        color: .yellow
                    ) {
                        logWakeUp()
                    }
                } else {
                    QuickLogButton(
                        icon: "moon.fill",
                        label: "Sleep",
                        color: .indigo
                    ) {
                        logSleep()
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showingPeeLocationPicker) {
            LocationPickerSheet(
                title: "Where?",
                icon: "drop.fill",
                onSelect: { location in
                    logPotty(type: .plassen, location: location)
                }
            )
        }
        .sheet(isPresented: $showingPoopLocationPicker) {
            LocationPickerSheet(
                title: "Where?",
                icon: "circle.fill",
                onSelect: { location in
                    logPotty(type: .poepen, location: location)
                }
            )
        }
    }

    // MARK: - Logging Actions

    private func logPotty(type: EventType, location: EventLocation) {
        guard dataProvider.canLogEvents else {
            WKInterfaceDevice.current().play(.failure)
            return
        }

        do {
            let event = PuppyEvent.potty(type: type, location: location)
            try WatchIntentDataStore.shared.addEvent(event)
            WKInterfaceDevice.current().play(.success)
            dataProvider.refresh()
        } catch {
            WKInterfaceDevice.current().play(.failure)
        }
    }

    private func logMeal() {
        guard dataProvider.canLogEvents else {
            WKInterfaceDevice.current().play(.failure)
            return
        }

        do {
            let event = PuppyEvent.meal()
            try WatchIntentDataStore.shared.addEvent(event)
            WKInterfaceDevice.current().play(.success)
            dataProvider.refresh()
        } catch {
            WKInterfaceDevice.current().play(.failure)
        }
    }

    private func logSleep() {
        guard dataProvider.canLogEvents else {
            WKInterfaceDevice.current().play(.failure)
            return
        }

        do {
            let sleepSessionId = UUID()
            let event = PuppyEvent.sleep(sleepSessionId: sleepSessionId)
            try WatchIntentDataStore.shared.addEvent(event)
            WKInterfaceDevice.current().play(.success)
            dataProvider.refresh()
        } catch {
            WKInterfaceDevice.current().play(.failure)
        }
    }

    private func logWakeUp() {
        guard dataProvider.canLogEvents else {
            WKInterfaceDevice.current().play(.failure)
            return
        }

        do {
            // Check for ongoing sleep session
            let sleepSessionId = WatchIntentDataStore.shared.ongoingSleepEvent()?.sleepSessionId
            let event = PuppyEvent.wake(sleepSessionId: sleepSessionId)
            try WatchIntentDataStore.shared.addEvent(event)
            WKInterfaceDevice.current().play(.success)
            dataProvider.refresh()
        } catch {
            WKInterfaceDevice.current().play(.failure)
        }
    }
}

// MARK: - Location Picker Sheet

struct LocationPickerSheet: View {
    let title: String
    let icon: String
    let onSelect: (EventLocation) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)

            Button {
                onSelect(.buiten)
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "leaf.fill")
                    Text("Outside")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.green)

            Button {
                onSelect(.binnen)
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "house.fill")
                    Text("Inside")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
        .padding()
    }
}

// MARK: - Quick Log Button

struct QuickLogButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .tint(color)
    }
}

// MARK: - PuppyEvent factory extension for watch

import OllieShared

#Preview {
    QuickLogView(dataProvider: WatchDataProvider.shared)
}
