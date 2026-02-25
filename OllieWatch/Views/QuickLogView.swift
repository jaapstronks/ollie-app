//
//  QuickLogView.swift
//  OllieWatch
//
//  6-button grid for fast event logging

import SwiftUI
import WatchKit

struct QuickLogView: View {
    @ObservedObject var dataProvider: WatchDataProvider

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                QuickLogButton(
                    icon: "drop.fill",
                    label: "Pee Out",
                    color: .green
                ) {
                    logPeeOutside()
                }

                QuickLogButton(
                    icon: "drop.fill",
                    label: "Pee In",
                    color: .orange
                ) {
                    logPeeInside()
                }

                QuickLogButton(
                    icon: "circle.fill",
                    label: "Poop Out",
                    color: .green
                ) {
                    logPoopOutside()
                }

                QuickLogButton(
                    icon: "circle.fill",
                    label: "Poop In",
                    color: .orange
                ) {
                    logPoopInside()
                }

                QuickLogButton(
                    icon: "fork.knife",
                    label: "Meal",
                    color: .blue
                ) {
                    logMeal()
                }

                QuickLogButton(
                    icon: "sun.max.fill",
                    label: "Wake Up",
                    color: .yellow
                ) {
                    logWakeUp()
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Logging Actions

    private func logPeeOutside() {
        guard dataProvider.canLogEvents else {
            WKInterfaceDevice.current().play(.failure)
            return
        }

        do {
            let event = PuppyEvent.potty(type: .plassen, location: .buiten)
            try WatchIntentDataStore.shared.addEvent(event)
            WKInterfaceDevice.current().play(.success)
            dataProvider.sendEventToPhone(event)
            dataProvider.refresh()
        } catch {
            WKInterfaceDevice.current().play(.failure)
        }
    }

    private func logPeeInside() {
        guard dataProvider.canLogEvents else {
            WKInterfaceDevice.current().play(.failure)
            return
        }

        do {
            let event = PuppyEvent.potty(type: .plassen, location: .binnen)
            try WatchIntentDataStore.shared.addEvent(event)
            WKInterfaceDevice.current().play(.success)
            dataProvider.sendEventToPhone(event)
            dataProvider.refresh()
        } catch {
            WKInterfaceDevice.current().play(.failure)
        }
    }

    private func logPoopOutside() {
        guard dataProvider.canLogEvents else {
            WKInterfaceDevice.current().play(.failure)
            return
        }

        do {
            let event = PuppyEvent.potty(type: .poepen, location: .buiten)
            try WatchIntentDataStore.shared.addEvent(event)
            WKInterfaceDevice.current().play(.success)
            dataProvider.sendEventToPhone(event)
            dataProvider.refresh()
        } catch {
            WKInterfaceDevice.current().play(.failure)
        }
    }

    private func logPoopInside() {
        guard dataProvider.canLogEvents else {
            WKInterfaceDevice.current().play(.failure)
            return
        }

        do {
            let event = PuppyEvent.potty(type: .poepen, location: .binnen)
            try WatchIntentDataStore.shared.addEvent(event)
            WKInterfaceDevice.current().play(.success)
            dataProvider.sendEventToPhone(event)
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
            dataProvider.sendEventToPhone(event)
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
            dataProvider.sendEventToPhone(event)
            dataProvider.refresh()
        } catch {
            WKInterfaceDevice.current().play(.failure)
        }
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
