//
//  JSONFileStorage.swift
//  Otis-app
//
//  Reusable JSON file storage utilities for store classes
//

import Foundation
import OtisShared
import os

/// Shared utilities for JSON-based file storage
/// Used by SpotStore, MedicationStore, SocializationStore, etc.
enum JSONFileStorage {

    // MARK: - Shared Encoder/Decoder

    /// Pre-configured JSON encoder with ISO8601 dates and pretty printing
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()

    /// Pre-configured JSON decoder with ISO8601 dates
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - File URLs

    /// Documents directory URL
    /// Falls back to temporary directory if documents directory is unavailable (should never happen in practice)
    static var documentsURL: URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            // This should never happen on iOS, but provide a fallback to prevent crashes
            return FileManager.default.temporaryDirectory
        }
        return url
    }

    /// Data directory URL (for JSONL event files)
    static var dataDirectoryURL: URL {
        documentsURL.appendingPathComponent(Constants.dataDirectoryName, isDirectory: true)
    }

    /// Get file URL for a given filename in documents directory
    static func fileURL(for fileName: String) -> URL {
        documentsURL.appendingPathComponent(fileName)
    }

    /// Get file URL for a given filename in data directory
    static func dataFileURL(for fileName: String) -> URL {
        dataDirectoryURL.appendingPathComponent(fileName)
    }

    // MARK: - Directory Operations

    /// Ensure data directory exists
    /// Logs error if directory creation fails but does not throw (best-effort operation)
    static func ensureDataDirectoryExists() {
        let url = dataDirectoryURL
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            } catch {
                // Log error but don't throw - caller will fail on subsequent file operations
                print("ERROR: Failed to create data directory at \(url.path): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - JSON Array Operations

    /// Load an array of Codable items from a JSON file
    static func loadArray<T: Codable>(from fileName: String, logger: Logger? = nil) -> [T] {
        let url = fileURL(for: fileName)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([T].self, from: data)
        } catch {
            logger?.error("Failed to load \(fileName): \(error.localizedDescription)")
            return []
        }
    }

    /// Save an array of Codable items to a JSON file
    static func saveArray<T: Codable>(_ items: [T], to fileName: String, logger: Logger? = nil) {
        let url = fileURL(for: fileName)

        do {
            let data = try encoder.encode(items)
            try data.write(to: url, options: .atomic)
        } catch {
            logger?.error("Failed to save \(fileName): \(error.localizedDescription)")
        }
    }

    // MARK: - JSONL Operations (one item per line)

    /// Load items from a JSONL file (one JSON object per line)
    static func loadJSONL<T: Codable>(from fileName: String, inDataDirectory: Bool = true, logger: Logger? = nil) -> [T] {
        let url = inDataDirectory ? dataFileURL(for: fileName) : fileURL(for: fileName)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        let content: String
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            logger?.error("Failed to read JSONL file \(fileName): \(error.localizedDescription)")
            return []
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        return lines.compactMap { line in
            guard let data = line.data(using: .utf8) else { return nil }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                logger?.warning("Failed to decode line in \(fileName): \(error.localizedDescription)")
                return nil
            }
        }
    }

    /// Save items to a JSONL file (one JSON object per line)
    static func saveJSONL<T: Codable>(_ items: [T], to fileName: String, inDataDirectory: Bool = true, logger: Logger? = nil) {
        if inDataDirectory {
            ensureDataDirectoryExists()
        }

        let url = inDataDirectory ? dataFileURL(for: fileName) : fileURL(for: fileName)

        // Use compact encoder for JSONL (no pretty printing)
        let compactEncoder = JSONEncoder()
        compactEncoder.dateEncodingStrategy = .iso8601

        var failedCount = 0
        let lines = items.compactMap { item -> String? in
            do {
                let data = try compactEncoder.encode(item)
                return String(data: data, encoding: .utf8)
            } catch {
                failedCount += 1
                logger?.warning("Failed to encode item for \(fileName): \(error.localizedDescription)")
                return nil
            }
        }

        if failedCount > 0 {
            logger?.warning("Skipped \(failedCount) items that failed to encode in \(fileName)")
        }

        let content = lines.joined(separator: "\n")

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            logger?.error("Failed to save \(fileName): \(error.localizedDescription)")
        }
    }

    // MARK: - Single Object Operations

    /// Load a single Codable object from a JSON file
    static func loadObject<T: Codable>(from fileName: String, logger: Logger? = nil) -> T? {
        let url = fileURL(for: fileName)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch {
            logger?.error("Failed to load \(fileName): \(error.localizedDescription)")
            return nil
        }
    }

    /// Save a single Codable object to a JSON file
    static func saveObject<T: Codable>(_ object: T, to fileName: String, logger: Logger? = nil) {
        let url = fileURL(for: fileName)

        do {
            let data = try encoder.encode(object)
            try data.write(to: url, options: .atomic)
        } catch {
            logger?.error("Failed to save \(fileName): \(error.localizedDescription)")
        }
    }
}
