//
//  OllieAnalytics.swift
//  Ollie-app
//
//  Minimal analytics service for internal usage tracking
//  Fire-and-forget design - never blocks UI, fails silently
//

import Foundation
import UIKit
import os
import OllieShared

/// Minimal analytics service for internal usage tracking
/// Fire-and-forget design - never blocks UI, fails silently
@MainActor
final class OllieAnalytics {
    static let shared = OllieAnalytics()

    private let endpoint = URL(string: "https://ollie-analytics.jaapstronks.workers.dev/events")!
    private let apiKey = "ollie_ak_52d045c46d0e6a336fb9665b1db62111"

    private let deviceId: String
    private let appVersion: String
    private let iosVersion: String
    private let deviceModel: String

    private let logger = Logger.ollie(category: "Analytics")

    /// Whether analytics is enabled
    private let isEnabled = true

    private init() {
        // Get or create persistent device ID
        if let existing = UserDefaults.standard.string(forKey: "analytics_device_id") {
            deviceId = existing
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "analytics_device_id")
            deviceId = newId
        }

        appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        iosVersion = UIDevice.current.systemVersion
        deviceModel = Self.getDeviceModel()
    }

    // MARK: - Public API

    /// Track an event with optional properties
    func track(_ eventName: String, properties: [String: Any] = [:]) {
        guard isEnabled else {
            #if DEBUG
            logger.debug("Analytics disabled - skipping: \(eventName)")
            #endif
            return
        }

        let event = AnalyticsEvent(
            deviceId: deviceId,
            eventName: eventName,
            eventData: properties,
            appVersion: appVersion,
            iosVersion: iosVersion,
            deviceModel: deviceModel
        )

        // Fire and forget - don't await
        Task.detached(priority: .utility) { [weak self] in
            await self?.send(event)
        }
    }

    /// Track app launch - call once from app init
    func trackAppLaunch() {
        track("app_launch")
    }

    /// Track event logged - call from EventStore.addEvent()
    func trackEventLogged(type: String, hasLocation: Bool, hasNote: Bool, hasPhoto: Bool) {
        track("event_logged", properties: [
            "event_type": type,
            "has_location": hasLocation,
            "has_note": hasNote,
            "has_photo": hasPhoto
        ])
    }

    // MARK: - Private

    private func send(_ event: AnalyticsEvent) async {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.timeoutInterval = 10

        do {
            request.httpBody = try JSONEncoder().encode(event)
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                logger.warning("Analytics send failed: \(httpResponse.statusCode)")
            }
        } catch {
            // Silent failure - analytics should never impact user experience
            logger.debug("Analytics send error: \(error.localizedDescription)")
        }
    }

    private static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}

// MARK: - Event Model

private struct AnalyticsEvent: Encodable {
    let deviceId: String
    let eventName: String
    let eventData: [String: Any]
    let appVersion: String
    let iosVersion: String
    let deviceModel: String

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case eventName = "event_name"
        case eventData = "event_data"
        case appVersion = "app_version"
        case iosVersion = "ios_version"
        case deviceModel = "device_model"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(eventName, forKey: .eventName)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(iosVersion, forKey: .iosVersion)
        try container.encode(deviceModel, forKey: .deviceModel)

        // Encode eventData as JSON string (backend expects string, not nested object)
        let jsonData = try JSONSerialization.data(withJSONObject: eventData)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
        try container.encode(jsonString, forKey: .eventData)
    }
}
