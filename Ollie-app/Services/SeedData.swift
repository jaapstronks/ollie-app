//
//  SeedData.swift
//  Ollie-app
//

import Foundation

enum SeedData {
    /// Install bundled JSONL data files on first launch
    static func installSeedDataIfNeeded() {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataDir = docs.appendingPathComponent("data", isDirectory: true)

        // Create data directory if needed
        try? fileManager.createDirectory(at: dataDir, withIntermediateDirectories: true)

        // Check if we already have any data files
        let existingFiles = (try? fileManager.contentsOfDirectory(atPath: dataDir.path)) ?? []
        let existingJsonlFiles = existingFiles.filter { $0.hasSuffix(".jsonl") }

        if !existingJsonlFiles.isEmpty {
            print("SeedData: Skipping install - found \(existingJsonlFiles.count) existing files")
            return // Already have data, don't overwrite
        }

        print("SeedData: No existing data, will copy bundled files")

        // Copy bundled JSONL files from app bundle
        copyBundledDataFiles(to: dataDir)
    }

    /// Copy all bundled .jsonl files to the data directory
    private static func copyBundledDataFiles(to dataDir: URL) {
        let fileManager = FileManager.default

        // Find all .jsonl files in the bundle (try both root and SeedData subdirectory)
        var bundledFiles: [URL] = []

        // Try root of bundle
        if let rootFiles = Bundle.main.urls(forResourcesWithExtension: "jsonl", subdirectory: nil) {
            bundledFiles.append(contentsOf: rootFiles)
        }

        // Try SeedData subdirectory
        if let seedDataFiles = Bundle.main.urls(forResourcesWithExtension: "jsonl", subdirectory: "SeedData") {
            bundledFiles.append(contentsOf: seedDataFiles)
        }

        if bundledFiles.isEmpty {
            print("SeedData: No bundled JSONL files found in bundle")
            // Debug: list what's in the bundle
            if let resourcePath = Bundle.main.resourcePath {
                let contents = try? fileManager.contentsOfDirectory(atPath: resourcePath)
                print("SeedData: Bundle contents: \(contents ?? [])")
            }
            return
        }

        print("SeedData: Found \(bundledFiles.count) JSONL files to copy")

        for sourceURL in bundledFiles {
            let fileName = sourceURL.lastPathComponent
            let destURL = dataDir.appendingPathComponent(fileName)

            do {
                // Skip if already exists
                if fileManager.fileExists(atPath: destURL.path) {
                    print("SeedData: Skipping \(fileName) (already exists)")
                    continue
                }

                try fileManager.copyItem(at: sourceURL, to: destURL)
                print("SeedData: Copied \(fileName)")
            } catch {
                print("SeedData: Failed to copy \(fileName): \(error)")
            }
        }
    }

    /// Force reinstall bundled data (useful for testing)
    static func forceReinstallBundledData() {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataDir = docs.appendingPathComponent("data", isDirectory: true)

        // Create data directory if needed
        try? fileManager.createDirectory(at: dataDir, withIntermediateDirectories: true)

        copyBundledDataFiles(to: dataDir)
    }
}
