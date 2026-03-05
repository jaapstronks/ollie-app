//
//  BetaFeedbackSection.swift
//  Otis-app
//
//  Beta feedback section for TestFlight and debug builds

import SwiftUI
import UIKit
import OtisShared

/// Feedback section visible in beta builds (debug and TestFlight)
struct BetaFeedbackSection: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @EnvironmentObject var profileStore: ProfileStore
    @State private var showingCopiedToast = false

    /// Available subscription states for testing
    private enum TestSubscriptionState: String, CaseIterable, Identifiable {
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

        static func from(_ status: OtisPlusStatus?) -> TestSubscriptionState {
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
        Section {
            // Send feedback button
            Button {
                sendFeedbackEmail()
            } label: {
                HStack {
                    Label(Strings.Beta.sendFeedback, systemImage: "envelope")
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Subscription override picker
            Picker(selection: Binding(
                get: { TestSubscriptionState.from(subscriptionManager.betaOverrideStatus) },
                set: { subscriptionManager.betaOverrideStatus = $0.toOtisPlusStatus() }
            )) {
                ForEach(TestSubscriptionState.allCases) { state in
                    Label(state.rawValue, systemImage: state.icon)
                        .tag(state)
                }
            } label: {
                Label(Strings.Beta.subscriptionOverride, systemImage: "creditcard")
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

            // Copy device ID button
            Button {
                copyDeviceId()
            } label: {
                HStack {
                    Label(Strings.Beta.deviceId, systemImage: "doc.on.doc")
                    Spacer()
                    if showingCopiedToast {
                        Text(Strings.Beta.copiedToClipboard)
                            .font(.caption)
                            .foregroundStyle(Color.otisSuccess)
                    } else {
                        Text(deviceId.prefix(8) + "...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Label(Strings.Beta.sectionTitle, systemImage: "hammer.fill")
        } footer: {
            Text(Strings.Beta.feedbackDescription)
        }
    }

    // MARK: - Device Info

    private var deviceId: String {
        UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
    }

    private var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    private var iOSVersion: String {
        "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    }

    private var puppyAgeWeeks: Int? {
        profileStore.profile?.ageInWeeks
    }

    // MARK: - Actions

    private func sendFeedbackEmail() {
        Analytics.track(.feedbackSent, properties: [
            "environment": AppEnvironment.current.displayName
        ])

        var deviceInfo = """
        ---
        App Version: \(appVersion)
        Environment: \(AppEnvironment.current.displayName)
        iOS Version: \(iOSVersion)
        Device: \(deviceModel)
        Subscription: \(subscriptionManager.effectiveStatus.displayLabel)
        """

        if let weeks = puppyAgeWeeks {
            deviceInfo += "\nPuppy Age: \(weeks) weeks"
        }

        deviceInfo += "\nDevice ID: \(deviceId)"

        let subject = "Otis Beta Feedback"
        let body = """
        [Your feedback here]


        \(deviceInfo)
        """

        // URL encode the email components
        guard let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let mailURL = URL(string: "mailto:feedback@otis.pet?subject=\(encodedSubject)&body=\(encodedBody)") else {
            return
        }

        UIApplication.shared.open(mailURL)
    }

    private func copyDeviceId() {
        UIPasteboard.general.string = deviceId
        withAnimation {
            showingCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingCopiedToast = false
            }
        }
    }
}

#Preview {
    Form {
        BetaFeedbackSection()
    }
    .environmentObject(ProfileStore())
}
