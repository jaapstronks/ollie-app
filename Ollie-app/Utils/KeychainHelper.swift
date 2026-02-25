//
//  KeychainHelper.swift
//  Ollie-app
//
//  Secure storage for sensitive data using iOS Keychain
//

import Foundation
import Security

/// Helper for secure Keychain storage
/// Use this for sensitive data that shouldn't be stored in UserDefaults
enum KeychainHelper {

    // MARK: - Errors

    enum KeychainError: Error {
        case saveFailed(OSStatus)
        case loadFailed(OSStatus)
        case deleteFailed(OSStatus)
        case dataConversionFailed
    }

    // MARK: - Service Identifier

    private static let service = "nl.jaapstronks.Ollie"

    // MARK: - Public API

    /// Save data to Keychain
    static func save(_ data: Data, for key: String) throws {
        // Delete existing item first (update not supported simply)
        try? delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    /// Save a string to Keychain
    static func save(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.dataConversionFailed
        }
        try save(data, for: key)
    }

    /// Save a Codable object to Keychain
    static func save<T: Encodable>(_ object: T, for key: String) throws {
        let data = try JSONEncoder().encode(object)
        try save(data, for: key)
    }

    /// Load data from Keychain
    static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            return nil
        }

        return result as? Data
    }

    /// Load a string from Keychain
    static func loadString(key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Load a Codable object from Keychain
    static func load<T: Decodable>(key: String, as type: T.Type) -> T? {
        guard let data = load(key: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// Delete item from Keychain
    static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        // errSecItemNotFound is acceptable (item didn't exist)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    /// Check if an item exists in Keychain
    static func exists(key: String) -> Bool {
        load(key: key) != nil
    }

    /// Delete all items for this app
    static func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Keychain Keys

extension KeychainHelper {
    /// Keys for secure storage
    enum Key {
        static let subscriptionStatus = "subscription.status"
        static let participantZoneOwner = "cloudkit.participantZoneOwner"
        static let participantZoneName = "cloudkit.participantZoneName"
    }
}
