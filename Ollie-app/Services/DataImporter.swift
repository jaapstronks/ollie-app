//
//  DataImporter.swift
//  Ollie-app
//

import Foundation
import Combine

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
    @Published private(set) var progress: String = ""
    @Published private(set) var lastResult: ImportResult?

    private let fileManager = FileManager.default

    // MARK: - Public Methods

    /// Import all available JSONL files from GitHub
    func importFromGitHub(overwriteExisting: Bool = false) async throws -> ImportResult {
        isImporting = true
        progress = "Bestanden ophalen..."

        defer {
            isImporting = false
        }

        // Step 1: Get list of files from GitHub API
        let files = try await fetchFileList()
        let jsonlFiles = files.filter { $0.name.hasSuffix(".jsonl") }

        progress = "Gevonden: \(jsonlFiles.count) dagen"

        // Step 2: Download each file
        var result = ImportResult(filesImported: 0, eventsImported: 0, skipped: 0, errors: [])

        for (index, file) in jsonlFiles.enumerated() {
            progress = "Importeren: \(index + 1)/\(jsonlFiles.count)"

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
        let apiURL = URL(string: "https://api.github.com/repos/\(Constants.gitHubOwner)/\(Constants.gitHubRepo)/contents/\(Constants.gitHubDataPath)")!

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
            return GitHubFile(name: name, downloadURL: downloadURL)
        }
    }

    private func downloadFile(url: URL) async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ImportError.downloadFailed
        }

        guard let content = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidContent
        }

        return content
    }
}

enum ImportError: LocalizedError {
    case apiError
    case invalidResponse
    case downloadFailed
    case invalidContent

    var errorDescription: String? {
        switch self {
        case .apiError: return "Kon GitHub API niet bereiken"
        case .invalidResponse: return "Ongeldig antwoord van GitHub"
        case .downloadFailed: return "Download mislukt"
        case .invalidContent: return "Bestandsinhoud ongeldig"
        }
    }
}
