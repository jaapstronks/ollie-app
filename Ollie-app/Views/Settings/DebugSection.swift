//
//  DebugSection.swift
//  Otis-app
//
//  Debug settings section - only included in DEBUG builds
//  Split into modules in Views/Settings/Debug/

#if DEBUG

import SwiftUI
import OtisShared

/// Debug section for testing features like subscription states
struct DebugSection: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    /// Available debug subscription states
    private enum DebugSubscriptionState: String, CaseIterable, Identifiable {
        case useActual = "Use Actual"
        case free = "Free"
        case trial = "Trial"
        case active = "Active"
        case expired = "Expired"
        case legacy = "Legacy"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .useActual: return "gear"
            case .free: return "person"
            case .trial: return "clock"
            case .active: return "checkmark.seal.fill"
            case .expired: return "xmark.circle"
            case .legacy: return "star.fill"
            }
        }

        func toOtisPlusStatus() -> OtisPlusStatus? {
            switch self {
            case .useActual: return nil
            case .free: return .free
            case .trial: return .trial(until: Date().addingTimeInterval(7 * 24 * 60 * 60)) // 7 days
            case .active: return .active(until: Date().addingTimeInterval(365 * 24 * 60 * 60)) // 1 year
            case .expired: return .expired
            case .legacy: return .legacy
            }
        }

        static func from(_ status: OtisPlusStatus?) -> DebugSubscriptionState {
            guard let status = status else { return .useActual }
            switch status {
            case .free: return .free
            case .trial: return .trial
            case .active: return .active
            case .expired: return .expired
            case .legacy: return .legacy
            }
        }
    }

    var body: some View {
        // Subscription Override Section
        Section {
            Picker(selection: Binding(
                get: { DebugSubscriptionState.from(subscriptionManager.betaOverrideStatus) },
                set: { subscriptionManager.betaOverrideStatus = $0.toOtisPlusStatus() }
            )) {
                ForEach(DebugSubscriptionState.allCases) { state in
                    Label(state.rawValue, systemImage: state.icon)
                        .tag(state)
                }
            } label: {
                Label("Subscription Override", systemImage: "ladybug")
            }

            // Show current effective state
            HStack {
                Text("Effective Status")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(subscriptionManager.effectiveStatus.displayLabel)
                    .foregroundStyle(subscriptionManager.effectiveStatus.hasOtisPlus ? Color.otisSuccess : Color.otisWarning)
            }
            .font(.caption)
        } header: {
            Label("Debug", systemImage: "hammer.fill")
        } footer: {
            Text("Debug overrides are only available in development builds and persist across app launches.")
        }

        // AI Broker Configuration
        DebugAIBrokerSection()

        // AI Surface Testing
        DebugAISurfaceTestingSection()

        // Data Management (Import/Reset)
        DebugDataSection()
    }
}

#Preview {
    Form {
        DebugSection()
    }
    .environmentObject(ProfileStore())
    .environmentObject(EventStore())
}

#endif
