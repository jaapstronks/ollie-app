//
//  FileMonitoringService.swift
//  Ollie-app
//
//  Monitors file system changes in the data directory for external updates
//

import Foundation
import OllieShared
import os

/// Monitors file system changes to detect updates from App Intents or other processes
/// Uses DispatchSource to watch the data directory for write/extend/rename events
@MainActor
final class FileMonitoringService {
    /// Callback when file system change is detected
    var onFileChange: (() -> Void)?

    private var fileMonitorSource: DispatchSourceFileSystemObject?
    private let logger = Logger.ollie(category: "FileMonitoring")
    private let fileManager = FileManager.default

    deinit {
        // Cancel directly since we can't call async methods in deinit
        fileMonitorSource?.cancel()
    }

    // MARK: - Public Methods

    /// Start monitoring the specified directory for changes
    /// - Parameter directoryURL: The directory to monitor
    func startMonitoring(directoryURL: URL) {
        // Stop any existing monitoring
        stopMonitoring()

        // Ensure directory exists before monitoring
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        // Open directory for monitoring
        let fd = open(directoryURL.path, O_EVTONLY)
        guard fd >= 0 else {
            logger.warning("Could not open data directory for monitoring")
            return
        }

        // Create dispatch source for file system events
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .rename],
            queue: DispatchQueue.global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.handleFileSystemChange()
            }
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        fileMonitorSource = source

        logger.info("File monitoring started for: \(directoryURL.path)")
    }

    /// Stop monitoring file system changes
    func stopMonitoring() {
        fileMonitorSource?.cancel()
        fileMonitorSource = nil
    }

    /// Whether monitoring is currently active
    var isMonitoring: Bool {
        fileMonitorSource != nil
    }

    // MARK: - Private Methods

    private func handleFileSystemChange() {
        logger.debug("Detected file system change")
        onFileChange?()
    }
}
