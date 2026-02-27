//
//  Strings+Profile.swift
//  Ollie-app
//
//  Profile photo related strings

import Foundation

private let table = "Settings"

extension Strings {

    // MARK: - Profile Photo
    enum Profile {
        static let addPhoto = String(localized: "Add Photo", table: table)
        static let changePhoto = String(localized: "Change Photo", table: table)
        static let removePhoto = String(localized: "Remove Photo", table: table)
        static let photoTitle = String(localized: "Profile Photo", table: table)
    }
}
