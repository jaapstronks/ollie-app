//
//  AmenityParser.swift
//  Otis-app
//
//  Parses amenity data from discovered spots for organized display
//

import Foundation
import OtisShared

/// Parsed amenity data for organized display
struct ParsedAmenities {
    var openingHours: String?
    var openingHoursFormatted: [DayHours] = []
    var openingHoursSummary: String?
    var phone: String?
    var website: String?
    var facilities: [String] = []
    var contactInfo: [String] = []

    struct DayHours {
        let day: String
        let time: String
        var isClosed: Bool { time.lowercased().contains("closed") || time == "-" }
    }

    var hasOpeningHours: Bool {
        openingHours != nil || !openingHoursFormatted.isEmpty
    }

    init(amenities: [String]) {
        for amenity in amenities {
            let lowered = amenity.lowercased()

            // Phone detection
            if lowered.contains("phone") || lowered.hasPrefix("+") || lowered.hasPrefix("tel:") {
                let cleaned = amenity
                    .replacingOccurrences(of: "phone:", with: "")
                    .replacingOccurrences(of: "tel:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                phone = cleaned
                continue
            }

            // Website detection
            if lowered.contains("http") || lowered.contains("www.") || lowered.contains("website:") {
                let cleaned = amenity
                    .replacingOccurrences(of: "website:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                website = cleaned.hasPrefix("http") ? cleaned : "https://\(cleaned)"
                continue
            }

            // Opening hours detection (OSM format: "Mo-Fr 09:00-18:00; Sa 10:00-16:00")
            if isOpeningHoursFormat(lowered) {
                openingHours = amenity
                openingHoursFormatted = parseOpeningHours(amenity)
                openingHoursSummary = generateHoursSummary(amenity)
                continue
            }

            // Email detection
            if lowered.contains("@") && lowered.contains(".") {
                contactInfo.append(amenity)
                continue
            }

            // Everything else is a facility
            facilities.append(amenity)
        }
    }

    private func isOpeningHoursFormat(_ text: String) -> Bool {
        // OSM opening hours typically contain day abbreviations and times
        let dayPatterns = ["mo", "tu", "we", "th", "fr", "sa", "su", "mon", "tue", "wed", "thu", "fri", "sat", "sun"]
        let hasDay = dayPatterns.contains { text.contains($0) }
        let hasTime = text.contains(":") && (text.contains("-") || text.contains("off") || text.contains("closed"))
        return hasDay && hasTime
    }

    private func parseOpeningHours(_ hours: String) -> [DayHours] {
        // Map day abbreviations to full names
        let dayMap: [(abbrev: [String], full: String)] = [
            (["mo", "mon"], "Mon"),
            (["tu", "tue"], "Tue"),
            (["we", "wed"], "Wed"),
            (["th", "thu"], "Thu"),
            (["fr", "fri"], "Fri"),
            (["sa", "sat"], "Sat"),
            (["su", "sun"], "Sun")
        ]

        var result: [DayHours] = []
        let components = hours.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }

        for component in components {
            let lowered = component.lowercased()

            // Handle day ranges like "Mo-Fr"
            if let rangeMatch = lowered.range(of: #"(mo|tu|we|th|fr|sa|su)-(mo|tu|we|th|fr|sa|su)"#, options: .regularExpression) {
                let range = String(lowered[rangeMatch])
                let parts = range.split(separator: "-")
                if parts.count == 2 {
                    let startDay = String(parts[0])
                    let endDay = String(parts[1])
                    let dayOrder = ["mo", "tu", "we", "th", "fr", "sa", "su"]
                    if let startIdx = dayOrder.firstIndex(of: startDay),
                       let endIdx = dayOrder.firstIndex(of: endDay) {
                        let time = extractTime(from: component)
                        for idx in startIdx...endIdx {
                            let fullDay = dayMap[idx].full
                            if !result.contains(where: { $0.day == fullDay }) {
                                result.append(DayHours(day: fullDay, time: time))
                            }
                        }
                        continue
                    }
                }
            }

            // Find individual days
            for (abbrevs, fullDay) in dayMap {
                if abbrevs.contains(where: { lowered.contains($0) }) {
                    let time = extractTime(from: component)
                    if !result.contains(where: { $0.day == fullDay }) {
                        result.append(DayHours(day: fullDay, time: time))
                    }
                }
            }
        }

        // Sort by day order
        let dayOrder = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        result.sort { dayOrder.firstIndex(of: $0.day) ?? 0 < dayOrder.firstIndex(of: $1.day) ?? 0 }

        return result
    }

    private func extractTime(from component: String) -> String {
        // Remove day parts and clean up
        var time = component
        let dayPatterns = ["mo-fr", "mo-su", "mo-sa", "sa-su", "mo", "tu", "we", "th", "fr", "sa", "su",
                          "mon-fri", "mon-sun", "mon-sat", "sat-sun", "mon", "tue", "wed", "thu", "fri", "sat", "sun"]

        for pattern in dayPatterns {
            time = time.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }

        time = time.trimmingCharacters(in: .whitespaces)

        if time.lowercased().contains("off") || time.lowercased().contains("closed") {
            return Strings.Places.hoursClosed
        }

        return time.isEmpty ? "-" : time
    }

    private func generateHoursSummary(_ hours: String) -> String? {
        let lowered = hours.lowercased()

        // Check for 24/7
        if lowered.contains("24/7") || lowered.contains("24h") {
            return Strings.Places.hoursOpen24h
        }

        // Try to extract a simple summary
        if let timeRange = hours.range(of: #"\d{1,2}:\d{2}\s*-\s*\d{1,2}:\d{2}"#, options: .regularExpression) {
            return String(hours[timeRange])
        }

        return nil
    }
}
