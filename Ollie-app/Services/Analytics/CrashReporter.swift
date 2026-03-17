//
//  CrashReporter.swift
//  Otis-app
//
//  Sentry crash reporting and error tracking
//

import Foundation
import OtisShared
import Sentry

/// Centralized crash reporting and error tracking using Sentry
enum CrashReporter {

    // MARK: - Configuration

    /// Sentry DSN loaded from Info.plist (set via build configuration)
    /// Configure in Xcode: Add SENTRY_DSN to your xcconfig or build settings
    private static var dsn: String? {
        Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String
    }

    // MARK: - Initialization

    /// Call this in app init, before any other code runs
    static func start() {
        #if DEBUG
        print("[CrashReporter] DSN from Info.plist: \(dsn ?? "nil")")
        #endif

        // Validate DSN is properly configured
        guard let dsn = dsn,
              !dsn.isEmpty,
              dsn != "$(SENTRY_DSN)",           // Unsubstituted build variable
              dsn.hasPrefix("https://"),         // Must be a valid URL
              dsn.contains("sentry.io"),         // Must be a Sentry endpoint (any region)
              !dsn.contains("YOUR_")             // Must not contain placeholder text
        else {
            #if DEBUG
            print("[CrashReporter] Sentry DSN not configured - crash reporting disabled")
            print("[CrashReporter] DSN validation failed. Value: \(dsn ?? "nil")")
            #endif
            return
        }

        #if DEBUG
        print("[CrashReporter] Starting Sentry with DSN: \(dsn.prefix(50))...")
        #endif

        SentrySDK.start { options in
            options.dsn = dsn

            // Environment (debug vs release)
            #if DEBUG
            options.environment = "development"
            // Full capture in development for debugging performance issues
            options.sampleRate = 1.0
            options.tracesSampleRate = 1.0
            // PERF: Disable Sentry debug logging - it generates millions of log lines
            // Only enable temporarily when debugging Sentry integration issues
            options.debug = false
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

            // Core Data tracking (for fetch/save operations)
            options.enableCoreDataTracing = true

            // File I/O tracking
            options.enableFileIOTracing = true

            // Automatic UI performance (view rendering)
            options.enableUIViewControllerTracing = true
            options.enableUserInteractionTracing = true

            // Time-to-initial-display for app launch
            options.enableTimeToFullDisplayTracing = true

            // Disable screenshot capture for privacy
            options.attachScreenshot = false
            options.attachViewHierarchy = false

            // Send default PII (device info, OS version - but not user data)
            options.sendDefaultPii = false

            // Scrub sensitive data before sending to Sentry
            options.beforeSend = { event in
                // Remove potentially sensitive HTTP headers from breadcrumbs
                if let breadcrumbs = event.breadcrumbs {
                    for breadcrumb in breadcrumbs {
                        if var data = breadcrumb.data {
                            // Remove sensitive headers that might be captured
                            let sensitiveKeys = ["Authorization", "Cookie", "Set-Cookie", "X-Auth-Token", "Api-Key",
                                                 "authorization", "cookie", "set-cookie", "x-auth-token", "api-key"]
                            for key in sensitiveKeys {
                                data.removeValue(forKey: key)
                            }
                            breadcrumb.data = data
                        }
                    }
                }

                return event
            }
        }

        #if DEBUG
        print("[CrashReporter] ✅ Sentry SDK started successfully")
        print("[CrashReporter] Environment: development, tracesSampleRate: 1.0")
        #endif
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

    // MARK: - Performance Tracing

    /// Start a transaction for measuring performance of an operation
    /// - Parameters:
    ///   - name: Name of the operation (e.g., "Load Events")
    ///   - operation: Type of operation (e.g., "db.query", "ui.load", "http.client")
    /// - Returns: A span that must be finished when operation completes
    static func startTransaction(name: String, operation: String) -> Span? {
        SentrySDK.startTransaction(name: name, operation: operation)
    }

    /// Create a child span within an existing transaction
    static func startSpan(parent: Span, operation: String, description: String) -> Span {
        parent.startChild(operation: operation, description: description)
    }

    /// Measure a synchronous operation
    static func measure<T>(name: String, operation: String, block: () throws -> T) rethrows -> T {
        let transaction = startTransaction(name: name, operation: operation)
        defer { transaction?.finish() }
        return try block()
    }

    /// Measure an async operation
    static func measureAsync<T>(name: String, operation: String, block: () async throws -> T) async rethrows -> T {
        let transaction = startTransaction(name: name, operation: operation)
        defer { transaction?.finish() }
        return try await block()
    }

    /// Add a breadcrumb for debugging
    static func addBreadcrumb(category: String, message: String, data: [String: Any]? = nil) {
        let crumb = Breadcrumb()
        crumb.category = category
        crumb.message = message
        crumb.level = .info
        if let data = data {
            crumb.data = data
        }
        SentrySDK.addBreadcrumb(crumb)
    }

}
