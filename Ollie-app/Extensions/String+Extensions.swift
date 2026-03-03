//
//  String+Extensions.swift
//  Otis-app
//
//  String utilities and extensions

import Foundation

extension String {
    /// Returns true if the string is empty or contains only whitespace characters
    var isBlank: Bool {
        trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Returns the string with leading and trailing whitespace removed
    var trimmed: String {
        trimmingCharacters(in: .whitespaces)
    }

    /// Returns nil if blank, otherwise returns the trimmed string
    var nilIfBlank: String? {
        let trimmed = self.trimmed
        return trimmed.isEmpty ? nil : trimmed
    }
}
