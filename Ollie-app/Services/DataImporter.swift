//
//  DataImporter.swift
//  Ollie-app
//

import Foundation
import OllieShared
import Combine

/// Preview of what will be imported
struct ImportPreview {
    let totalDays: Int
    let dateRange: (start: Date, end: Date)?
    let localDays: Int
    let newDays: Int
    let availableFiles: [String]
    let localFiles: [String]
}

/// Progress update during import
struct ImportProgress {
    let currentFile: Int
    let totalFiles: Int
    let currentFileName: String
    let eventsImportedSoFar: Int
}

/// Result of a data import operation
struct ImportResult {
    var filesImported: Int
    var eventsImported: Int
    var skipped: Int
    var errors: [String]
}

/// Service for importing data from the Ollie web app GitHub repo
@MainActor
class DataImporter: ObservableObject {
    @Published private(set) var isImporting: Bool = false
    @Published private(set) var isFetchingPreview: Bool = false
    @Published private(set) var progress: String = ""
    @Published private(set) var importProgress: ImportProgress?
    @Published private(set) var lastResult: ImportResult?
    @Published private(set) var lastPreview: ImportPreview?
    @Published private(set) var lastError: String?

    private let fileManager = FileManager.default

    // MARK: - Security

    /// Allowed domains for downloading files
    private static let allowedDownloadHosts = ["raw.githubusercontent.com", "github.com", "objects.githubusercontent.com"]

    /// Maximum allowed file size for imports (5MB)
    private static let maxFileSize = 5 * 1024 * 1024

    /// Maximum allowed line length in JSONL files (prevents memory attacks)
    private static let maxLineLength = 50_000

    /// Validates that a URL is from an allowed GitHub domain
    private func isURLAllowed(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return Self.allowedDownloadHosts.contains(host)
    }

    /// Validates and sanitizes JSONL content
    /// Returns nil if content appears malicious
    private func sanitizeJSONLContent(_ content: String) throws -> String {
        var sanitizedLines: [String] = []

        for line in content.components(separatedBy: .newlines) {
            // Skip empty lines
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else {
                continue
            }

            // Check line length
            guard line.count <= Self.maxLineLength else {
                throw ImportError.contentTooLarge
            }

            // Validate that each line is valid JSON
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                // Skip invalid JSON lines rather than failing entirely
                continue
            }

            // Validate required fields and sanitize paths
            if let photoPath = json["photo"] as? String {
                // Block path traversal attempts in photo paths
                if photoPath.contains("..") || photoPath.hasPrefix("/") {
                    throw ImportError.maliciousContent
                }
            }

            if let videoPath = json["video"] as? String {
                if videoPath.contains("..") || videoPath.hasPrefix("/") {
                    throw ImportError.maliciousContent
                }
            }

            sanitizedLines.append(line)
        }

        return sanitizedLines.joined(separator: "\n")
    }

    // MARK: - Public Methods

    /// Fetch preview of what will be imported (without actually importing)
    func fetchPreview() async throws -> ImportPreview {
        isFetchingPreview = true
        lastError = nil

        defer {
            isFetchingPreview = false
        }

        // Get list of files from GitHub
        let files = try await fetchFileList()
        let jsonlFiles = files.filter { $0.name.hasSuffix(".jsonl") }
        let availableFileNames = jsonlFiles.map { $0.name }.sorted()

        // Get list of local files
        let localFileNames = getLocalFileNames()

        // Calculate which files are new
        let localSet = Set(localFileNames)
        let newFiles = availableFileNames.filter { !localSet.contains($0) }

        // Parse date range from file names
        let dateRange = parseDateRange(from: availableFileNames)

        let preview = ImportPreview(
            totalDays: availableFileNames.count,
            dateRange: dateRange,
            localDays: localFileNames.count,
            newDays: newFiles.count,
            availableFiles: availableFileNames,
            localFiles: localFileNames
        )

        lastPreview = preview
        return preview
    }

    /// Import all available JSONL files from GitHub
    func importFromGitHub(overwriteExisting: Bool = false) async throws -> ImportResult {
        isImporting = true
        lastError = nil
        progress = "Bestanden ophalen..."
        importProgress = nil

        defer {
            isImporting = false
        }

        // Step 1: Get list of files from GitHub API
        let files = try await fetchFileList()
        let jsonlFiles = files.filter { $0.name.hasSuffix(".jsonl") }.sorted { $0.name < $1.name }

        progress = "Gevonden: \(jsonlFiles.count) dagen"

        // Step 2: Download each file
        var result = ImportResult(filesImported: 0, eventsImported: 0, skipped: 0, errors: [])

        for (index, file) in jsonlFiles.enumerated() {
            progress = "Importeren: \(index + 1)/\(jsonlFiles.count)"
            importProgress = ImportProgress(
                currentFile: index + 1,
                totalFiles: jsonlFiles.count,
                currentFileName: file.name,
                eventsImportedSoFar: result.eventsImported
            )

            let localURL = dataDirectoryURL.appendingPathComponent(file.name)

            // Skip if exists and not overwriting
            if !overwriteExisting && fileManager.fileExists(atPath: localURL.path) {
                result.skipped += 1
                continue
            }

            do {
                let content = try await downloadFile(url: file.downloadURL)
                try ensureDataDirectoryExists()
                try content.write(to: localURL, atomically: true, encoding: .utf8)

                let eventCount = content.components(separatedBy: .newlines).filter { !$0.isEmpty }.count
                result.filesImported += 1
                result.eventsImported += eventCount
            } catch {
                result.errors.append("\(file.name): \(error.localizedDescription)")
            }
        }

        progress = "Klaar!"
        importProgress = nil
        lastResult = result

        return result
    }

    // MARK: - Private Methods

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var dataDirectoryURL: URL {
        documentsURL.appendingPathComponent(Constants.dataDirectoryName, isDirectory: true)
    }

    private func ensureDataDirectoryExists() throws {
        if !fileManager.fileExists(atPath: dataDirectoryURL.path) {
            try fileManager.createDirectory(at: dataDirectoryURL, withIntermediateDirectories: true)
        }
    }

    private struct GitHubFile {
        let name: String
        let downloadURL: URL
    }

    private func fetchFileList() async throws -> [GitHubFile] {
        guard let apiURL = URL(string: "https://api.github.com/repos/\(Constants.gitHubOwner)/\(Constants.gitHubRepo)/contents/\(Constants.gitHubDataPath)") else {
            throw ImportError.invalidResponse
        }

        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ImportError.apiError
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw ImportError.invalidResponse
        }

        return json.compactMap { item -> GitHubFile? in
            guard let name = item["name"] as? String,
                  let downloadURLString = item["download_url"] as? String,
                  let downloadURL = URL(string: downloadURLString) else {
                return nil
            }

            // Security: Validate the download URL is from an allowed domain
            guard isURLAllowed(downloadURL) else {
                return nil
            }

            // Security: Validate filename format (YYYY-MM-DD.jsonl)
            let filenamePattern = #"^\d{4}-\d{2}-\d{2}\.jsonl$"#
            guard name.range(of: filenamePattern, options: .regularExpression) != nil else {
                return nil
            }

            return GitHubFile(name: name, downloadURL: downloadURL)
        }
    }

    private func downloadFile(url: URL) async throws -> String {
        // Security: Validate URL before downloading
        guard isURLAllowed(url) else {
            throw ImportError.untrustedURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ImportError.downloadFailed
        }

        // Security: Check file size
        guard data.count <= Self.maxFileSize else {
            throw ImportError.contentTooLarge
        }

        guard let content = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidContent
        }

        // Security: Sanitize and validate JSONL content
        return try sanitizeJSONLContent(content)
    }

    /// Get list of local JSONL file names
    private func getLocalFileNames() -> [String] {
        guard fileManager.fileExists(atPath: dataDirectoryURL.path) else {
            return []
        }

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: dataDirectoryURL.path)
            return contents.filter { $0.hasSuffix(".jsonl") }.sorted()
        } catch {
            return []
        }
    }

    /// Parse date range from JSONL file names (format: YYYY-MM-DD.jsonl)
    private func parseDateRange(from fileNames: [String]) -> (start: Date, end: Date)? {
        let dates = fileNames.compactMap { fileName -> Date? in
            let datePart = fileName.replacingOccurrences(of: ".jsonl", with: "")
            return DateFormatters.dateOnly.date(from: datePart)
        }.sorted()

        guard let first = dates.first, let last = dates.last else {
            return nil
        }

        return (start: first, end: last)
    }

    /// Reset state for new import attempt
    func reset() {
        lastError = nil
        lastPreview = nil
        lastResult = nil
        importProgress = nil
    }
}

enum ImportError: LocalizedError {
    case apiError
    case invalidResponse
    case downloadFailed
    case invalidContent
    case untrustedURL
    case contentTooLarge
    case maliciousContent

    var errorDescription: String? {
        switch self {
        case .apiError: return Strings.Errors.apiError
        case .invalidResponse: return Strings.Errors.invalidResponse
        case .downloadFailed: return Strings.Errors.downloadFailed
        case .invalidContent: return Strings.Errors.invalidContent
        case .untrustedURL: return Strings.Errors.untrustedURL
        case .contentTooLarge: return Strings.Errors.contentTooLarge
        case .maliciousContent: return Strings.Errors.maliciousContent
        }
    }
}
