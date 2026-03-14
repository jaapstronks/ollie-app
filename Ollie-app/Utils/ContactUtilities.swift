//
//  ContactUtilities.swift
//  Otis-app
//
//  Utility functions for contact-related actions (phone calls, maps).
//

import Foundation
import UIKit

@MainActor
enum ContactUtilities {

    /// Open the phone dialer with the given number
    /// - Parameter number: Phone number string (will be cleaned of non-digit characters)
    static func callPhoneNumber(_ number: String) {
        let cleaned = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    /// Open the Maps app with the given address
    /// - Parameter address: Address string to search in Maps
    static func openInMaps(_ address: String) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        if let url = URL(string: "maps://?q=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    /// Open the Mail app to compose an email
    /// - Parameter email: Email address to send to
    static func sendEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }

    /// Open a website in Safari
    /// - Parameter urlString: URL string to open
    static func openWebsite(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}
