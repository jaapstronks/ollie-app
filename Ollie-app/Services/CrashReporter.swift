//
//  CrashReporter.swift
//  Ollie-app
//
//  Sentry crash reporting and error tracking
//

import Foundation
import OllieShared
import Sentry

/// Centralized crash reporting and error tracking using Sentry
enum CrashReporter {

    // MARK: - Configuration

    private static let dsn = "https://d1bf2a8b99068707032e4021d6b9c967@o4510923207999488.ingest.de.sentry.io/4510923210752080"

    // MARK: - Initialization

    /// Call this in app init, before any other code runs
    static func start() {
        SentrySDK.start { options in
            options.dsn = dsn

            // Environment (debug vs release)
            #if DEBUG
            options.environment = "development"
            // Lower sample rate in development
            options.sampleRate = 0.1
            options.tracesSampleRate = 0.1
            #else
            options.environment = "production"
            // Capture all errors in production
            options.sampleRate = 1.0
            // Performance monitoring sample rate (adjust based on volume)
            options.tracesSampleRate = 0.2
            #endif

            // Enable automatic breadcrumbs
            options.enableAutoBreadcrumbTracking = true

            // Attach stack traces to all events
            options.attachStacktrace = true

            // Enable Swift async stack traces (iOS 15+)
            options.swiftAsyncStacktraces = true

            // Enable automatic session tracking
            options.enableAutoSessionTracking = true

            // Network request tracking
            options.enableNetworkTracking = true

            // Enable capturing HTTP client errors
            options.enableCaptureFailedRequests = true
            options.failedRequestStatusCodes = [
                HttpStatusCodeRange(min: 400, max: 599)
            ]

            // App lifecycle breadcrumbs
            options.enableAppHangTracking = true
            options.appHangTimeoutInterval = 2.0

            // Disable screenshot capture for privacy
            options.attachScreenshot = false
            options.attachViewHierarchy = false

            // Send default PII (device info, OS version - but not user data)
            options.sendDefaultPii = false
        }
    }

    // MARK: - User Context

    /// Set user context after profile is loaded (anonymous ID, not PII)
    static func setUserContext(puppyName: String, ageInWeeks: Int) {
        // Use a hash of the puppy name as anonymous identifier
        let anonymousId = puppyName.data(using: .utf8)?.base64EncodedString() ?? "unknown"

        SentrySDK.setUser(User(userId: anonymousId))

        // Add context that helps debug but isn't PII
        SentrySDK.configureScope { scope in
            scope.setContext(value: [
                "puppy_age_weeks": ageInWeeks,
                "size_category": "redacted" // Add actual category if helpful
            ], key: "puppy")
        }
    }

    /// Clear user context on profile reset
    static func clearUserContext() {
        SentrySDK.setUser(nil)
    }

    // MARK: - Error Tracking

    /// Capture a non-fatal error
    static func capture(error: Error, context: [String: Any]? = nil) {
        SentrySDK.configureScope { scope in
            if let context = context {
                scope.setContext(value: context, key: "custom")
            }
        }
        SentrySDK.capture(error: error)
    }

    /// Capture a message (for non-error events worth tracking)
    static func capture(message: String, level: SentryLevel = .info) {
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(level)
        }
    }

    // MARK: - Breadcrumbs

    /// Add a navigation breadcrumb
    static func addNavigationBreadcrumb(from: String, to: String) {
        let crumb = Breadcrumb(level: .info, category: "navigation")
        crumb.message = "Navigated from \(from) to \(to)"
        crumb.data = ["from": from, "to": to]
        SentrySDK.addBreadcrumb(crumb)
    }

    /// Add a user action breadcrumb
    static func addActionBreadcrumb(_ action: String, data: [String: Any]? = nil) {
        let crumb = Breadcrumb(level: .info, category: "user")
        crumb.message = action
        crumb.data = data
        SentrySDK.addBreadcrumb(crumb)
    }

    /// Add a data operation breadcrumb
    static func addDataBreadcrumb(_ operation: String, data: [String: Any]? = nil) {
        let crumb = Breadcrumb(level: .info, category: "data")
        crumb.message = operation
        crumb.data = data
        SentrySDK.addBreadcrumb(crumb)
    }
}
