//
//  Strings+FoodRecall.swift
//  Otis-app
//
//  Food recall alert strings

import Foundation

private let table = "FoodRecall"

extension Strings {

    // MARK: - Food Recall Alerts
    enum FoodRecall {
        // Settings
        static let title = String(localized: "Food Recall Alerts", table: table)
        static let enableAlerts = String(localized: "Enable Alerts", table: table)
        static let enableAlertsFooter = String(localized: "Get notified when pet food brands you use are recalled. Data from FDA.", table: table)
        static let savedBrands = String(localized: "Your Brands", table: table)
        static let addBrand = String(localized: "Add Brand", table: table)
        static let noBrandsHint = String(localized: "Add the pet food brands you use to receive relevant alerts.", table: table)
        static let checkFrequency = String(localized: "Check Frequency", table: table)
        static let daily = String(localized: "Daily", table: table)
        static let weekly = String(localized: "Weekly", table: table)
        static let status = String(localized: "Status", table: table)
        static let checking = String(localized: "Checking for recalls...", table: table)
        static let lastChecked = String(localized: "Last checked", table: table)
        static let checkNow = String(localized: "Check Now", table: table)

        // Brand picker
        static let selectBrands = String(localized: "Select Brands", table: table)
        static let popularBrands = String(localized: "Popular Brands", table: table)
        static let customBrand = String(localized: "Custom Brand", table: table)
        static let customBrandPlaceholder = String(localized: "Enter brand name...", table: table)

        // Recall list
        static let recallAlerts = String(localized: "Recall Alerts", table: table)
        static let recallDetails = String(localized: "Recall Details", table: table)
        static let brand = String(localized: "Brand", table: table)
        static let product = String(localized: "Product", table: table)
        static let date = String(localized: "Date", table: table)
        static let reason = String(localized: "Reason", table: table)
        static let viewSource = String(localized: "View FDA Source", table: table)
        static let acknowledge = String(localized: "Acknowledge & Dismiss", table: table)

        // Severity levels
        static let severityLow = String(localized: "Quality Issue", table: table)
        static let severityMedium = String(localized: "Potential Health Risk", table: table)
        static let severityHigh = String(localized: "Confirmed Health Risk", table: table)
        static let severityCritical = String(localized: "Serious Illness Reported", table: table)

        // Alert card
        static let alertTitle = String(localized: "Food Recall Alert", table: table)

        static func alertMessageSingle(brand: String) -> String {
            String(localized: "A recall affects \(brand)", table: table)
        }

        static func alertMessageMultiple(count: Int) -> String {
            String(localized: "\(count) recalls affect your brands", table: table)
        }

        static func matchingRecalls(count: Int) -> String {
            String(localized: "\(count) recalls match your brands", table: table)
        }

        // Errors (nonisolated for use in LocalizedError conformance - hardcoded table name)
        nonisolated static let parseError = String(localized: "Could not process recall data", table: "FoodRecall")
    }
}
