//
//  AppError.swift
//  Otis-app
//
//  Structured error type for consistent error handling across stores

import Foundation

/// Structured error type for store operations
struct AppError: Identifiable, Equatable {
    let id: UUID
    let category: Category
    let message: String
    let timestamp: Date

    /// Error categories for store operations
    enum Category: String, Equatable {
        case save
        case delete
        case load
        case notFound
        case validation
        case sync
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        category: Category,
        message: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.message = message
        self.timestamp = timestamp
    }

    // MARK: - Factory Methods

    /// Create a save failed error
    static func saveFailed(message: String = Strings.Common.saveFailed) -> AppError {
        AppError(category: .save, message: message)
    }

    /// Create a delete failed error
    static func deleteFailed(message: String = Strings.Common.deleteFailed) -> AppError {
        AppError(category: .delete, message: message)
    }

    /// Create a load failed error
    static func loadFailed(message: String = Strings.Common.loadFailed) -> AppError {
        AppError(category: .load, message: message)
    }

    /// Create a not found error
    static func notFound(message: String = Strings.Common.notFound) -> AppError {
        AppError(category: .notFound, message: message)
    }

    /// Create a validation error
    static func validation(message: String) -> AppError {
        AppError(category: .validation, message: message)
    }

    /// Create a sync error
    static func syncFailed(message: String = Strings.Common.syncFailed) -> AppError {
        AppError(category: .sync, message: message)
    }

    // MARK: - Equatable

    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.id == rhs.id
    }
}
