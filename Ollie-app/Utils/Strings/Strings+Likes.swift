//
//  Strings+Likes.swift
//  Ollie-app
//
//  Localized strings for likes feature.
//

import Foundation

extension Strings {
    enum Likes {
        private static let table = "Likes"

        // MARK: - Like Button

        /// "No likes"
        static let noLikes = String(localized: "No likes", table: table)

        /// "You liked this"
        static let youLiked = String(localized: "You liked this", table: table)

        /// "1 like"
        static let oneLike = String(localized: "1 like", table: table)

        /// "%d likes"
        static func multipleLikes(_ count: Int) -> String {
            String(localized: "\(count) likes", table: table)
        }

        /// "Tap to like or unlike"
        static let tapToToggle = String(localized: "Tap to like or unlike", table: table)

        // MARK: - Likers Sheet

        /// "Liked by"
        static let likedBy = String(localized: "Liked by", table: table)

        /// "Liked by [name]"
        static func likedByName(_ name: String) -> String {
            String(localized: "Liked by \(name)", table: table)
        }

        /// "Liked by [name] and 1 other"
        static func likedByNameAndOneOther(_ name: String) -> String {
            String(localized: "Liked by \(name) and 1 other", table: table)
        }

        /// "Liked by [name] and X others"
        static func likedByNameAndOthers(_ name: String, count: Int) -> String {
            String(localized: "Liked by \(name) and \(count) others", table: table)
        }

        /// "No likes yet"
        static let noLikesYet = String(localized: "No likes yet", table: table)

        /// "Be the first to like this"
        static let beFirstToLike = String(localized: "Be the first to like this", table: table)

        // MARK: - Notifications

        /// "liked your"
        static let likedYour = String(localized: "liked your", table: table)

        /// "%@ liked your %@"
        static func likedNotification(name: String, eventType: String) -> String {
            String(localized: "\(name) liked your \(eventType)", table: table)
        }
    }
}
