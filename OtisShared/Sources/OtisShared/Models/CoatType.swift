//
//  CoatType.swift
//  OtisShared
//
//  Coat types for dogs with grooming schedule defaults
//

import Foundation

// MARK: - Coat Type

/// Dog coat types that determine grooming frequency recommendations
public enum CoatType: String, Codable, CaseIterable, Identifiable, Sendable {
    case shortSmooth    // Beagle, Boxer, Greyhound, Dachshund
    case medium         // Border Collie, Australian Shepherd
    case long           // Shih Tzu, Yorkie, Maltese, Afghan Hound
    case curly          // Poodle, Bichon, Doodles, Portuguese Water Dog
    case double         // Husky, Golden Retriever, GSD, Lab, Corgi
    case wire           // Schnauzer, most Terriers, Wirehaired Pointer
    case hairless       // Chinese Crested, Xolo, American Hairless

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .shortSmooth: return String(localized: "Short/Smooth", table: "Routines")
        case .medium: return String(localized: "Medium", table: "Routines")
        case .long: return String(localized: "Long", table: "Routines")
        case .curly: return String(localized: "Curly", table: "Routines")
        case .double: return String(localized: "Double Coat", table: "Routines")
        case .wire: return String(localized: "Wire/Wiry", table: "Routines")
        case .hairless: return String(localized: "Hairless", table: "Routines")
        }
    }

    public var description: String {
        switch self {
        case .shortSmooth:
            return String(localized: "Short, sleek coat that lies close to the body", table: "Routines")
        case .medium:
            return String(localized: "Moderate length coat, may have some feathering", table: "Routines")
        case .long:
            return String(localized: "Long, flowing coat that requires daily attention", table: "Routines")
        case .curly:
            return String(localized: "Curly or wavy coat that doesn't shed much but mats easily", table: "Routines")
        case .double:
            return String(localized: "Dense undercoat with longer outer coat, heavy seasonal shedding", table: "Routines")
        case .wire:
            return String(localized: "Coarse, bristly outer coat that may need hand-stripping", table: "Routines")
        case .hairless:
            return String(localized: "Little to no coat, requires skin care instead", table: "Routines")
        }
    }

    public var examples: String {
        switch self {
        case .shortSmooth: return "Beagle, Boxer, Greyhound, Dachshund"
        case .medium: return "Border Collie, Australian Shepherd, Brittany"
        case .long: return "Shih Tzu, Yorkshire Terrier, Maltese"
        case .curly: return "Poodle, Bichon Frise, Labradoodle"
        case .double: return "Golden Retriever, Husky, German Shepherd"
        case .wire: return "Schnauzer, Wire Fox Terrier, Airedale"
        case .hairless: return "Chinese Crested, Xoloitzcuintli"
        }
    }

    public var icon: String {
        switch self {
        case .shortSmooth: return "hare"
        case .medium: return "dog"
        case .long: return "wind"
        case .curly: return "circle.grid.cross"
        case .double: return "square.stack.3d.up"
        case .wire: return "line.3.horizontal"
        case .hairless: return "circle"
        }
    }

    // MARK: - Grooming Defaults

    /// Default grooming intervals for each grooming type based on coat
    public func defaultInterval(for groomingType: GroomingType) -> Int {
        switch groomingType {
        case .brushing:
            return brushingIntervalDays
        case .bathing:
            return bathingIntervalDays
        case .nailTrim:
            return 21  // Universal: every 3 weeks
        case .earCleaning:
            return 14  // Universal: every 2 weeks
        case .teethBrushing:
            return 1   // Universal: daily
        case .haircut:
            return haircutIntervalDays ?? 60
        case .deShedding:
            return desheddingIntervalDays ?? 7
        case .pawCare:
            return 14  // Universal: every 2 weeks
        case .eyeCleaning:
            return 7   // Universal: weekly
        case .analGlands:
            return 60  // As needed, track every 2 months
        }
    }

    /// Brushing interval in days
    public var brushingIntervalDays: Int {
        switch self {
        case .shortSmooth: return 7      // Weekly
        case .medium: return 3           // Every 3 days
        case .long: return 1             // Daily
        case .curly: return 2            // Every other day
        case .double: return 3           // Every 3 days (daily when shedding)
        case .wire: return 3             // Every 3 days
        case .hairless: return 0         // Not needed
        }
    }

    /// Bathing interval in days
    public var bathingIntervalDays: Int {
        switch self {
        case .shortSmooth: return 60     // Every 2 months
        case .medium: return 35          // Every 5 weeks
        case .long: return 28            // Every 4 weeks
        case .curly: return 21           // Every 3 weeks
        case .double: return 49          // Every 7 weeks
        case .wire: return 35            // Every 5 weeks
        case .hairless: return 7         // Weekly (skin care)
        }
    }

    /// Haircut interval in days (nil if not typically needed)
    public var haircutIntervalDays: Int? {
        switch self {
        case .shortSmooth: return nil
        case .medium: return 56          // Every 8 weeks
        case .long: return 42            // Every 6 weeks
        case .curly: return 42           // Every 6 weeks
        case .double: return nil         // Never shave
        case .wire: return 56            // Every 8 weeks (hand-stripping)
        case .hairless: return nil
        }
    }

    /// De-shedding interval in days (nil if minimal shedding)
    public var desheddingIntervalDays: Int? {
        switch self {
        case .shortSmooth: return 14     // Every 2 weeks
        case .medium: return 7           // Weekly
        case .long: return nil           // Brush instead
        case .curly: return nil          // Minimal shedding
        case .double: return 7           // Weekly (more during season)
        case .wire: return nil           // Hand-strip instead
        case .hairless: return nil
        }
    }

    /// Whether this coat needs professional grooming
    public var needsProfessionalGrooming: Bool {
        switch self {
        case .shortSmooth, .hairless: return false
        case .medium, .long, .curly, .double, .wire: return true
        }
    }

    /// Professional grooming interval in days (nil if not needed)
    public var professionalGroomingIntervalDays: Int? {
        switch self {
        case .shortSmooth: return nil
        case .medium: return 56          // Every 8 weeks
        case .long: return 42            // Every 6 weeks
        case .curly: return 42           // Every 6 weeks
        case .double: return 70          // Every 10 weeks (de-shedding)
        case .wire: return 56            // Every 8 weeks
        case .hairless: return nil
        }
    }

    // MARK: - Care Tips

    /// Care tips specific to this coat type
    public var careTips: [String] {
        switch self {
        case .shortSmooth:
            return [
                String(localized: "Use a rubber curry brush to remove loose hair", table: "Routines"),
                String(localized: "Occasional bathing keeps the coat shiny", table: "Routines"),
                String(localized: "Watch for skin issues that are more visible on short coats", table: "Routines")
            ]
        case .medium:
            return [
                String(localized: "Focus on feathering around legs and belly", table: "Routines"),
                String(localized: "A good brushing routine prevents tangles", table: "Routines"),
                String(localized: "Seasonal coat changes may require more attention", table: "Routines")
            ]
        case .long:
            return [
                String(localized: "Daily brushing prevents painful mats", table: "Routines"),
                String(localized: "Pay attention to behind ears, armpits, and legs", table: "Routines"),
                String(localized: "Consider a sanitary trim for hygiene", table: "Routines")
            ]
        case .curly:
            return [
                String(localized: "Dry thoroughly after baths to prevent mildew", table: "Routines"),
                String(localized: "Use a slicker brush to prevent matting", table: "Routines"),
                String(localized: "Regular professional grooming keeps the coat manageable", table: "Routines")
            ]
        case .double:
            return [
                String(localized: "Never shave a double coat - it won't grow back the same", table: "Routines"),
                String(localized: "Brush more frequently during spring and fall shedding", table: "Routines"),
                String(localized: "Use an undercoat rake during heavy shedding periods", table: "Routines")
            ]
        case .wire:
            return [
                String(localized: "Hand-stripping maintains coat texture and color", table: "Routines"),
                String(localized: "Clipping will soften and lighten the coat over time", table: "Routines"),
                String(localized: "Use a stripping knife or stone for proper technique", table: "Routines")
            ]
        case .hairless:
            return [
                String(localized: "Apply sunscreen before outdoor time", table: "Routines"),
                String(localized: "Moisturize regularly to prevent dry skin", table: "Routines"),
                String(localized: "Watch for blackheads and skin irritation", table: "Routines")
            ]
        }
    }

    // MARK: - Breed Suggestions

    /// Suggest coat type based on breed name
    public static func suggested(for breed: String?) -> CoatType? {
        guard let breed = breed?.lowercased() else { return nil }

        // Short/Smooth
        if breed.contains("beagle") || breed.contains("boxer") ||
           breed.contains("greyhound") || breed.contains("dachshund") ||
           breed.contains("bulldog") || breed.contains("pit bull") ||
           breed.contains("weimaraner") || breed.contains("vizsla") ||
           breed.contains("basenji") || breed.contains("whippet") ||
           breed.contains("dalmatian") || breed.contains("doberman") {
            return .shortSmooth
        }

        // Double coat
        if breed.contains("retriever") || breed.contains("husky") ||
           breed.contains("shepherd") && !breed.contains("australian") ||
           breed.contains("corgi") || breed.contains("labrador") ||
           breed.contains("malamute") || breed.contains("bernese") ||
           breed.contains("samoyed") || breed.contains("newfoundland") ||
           breed.contains("akita") || breed.contains("shiba") ||
           breed.contains("chow") || breed.contains("keeshond") ||
           breed.contains("spitz") || breed.contains("collie") && !breed.contains("border") {
            return .double
        }

        // Curly
        if breed.contains("poodle") || breed.contains("bichon") ||
           breed.contains("doodle") || breed.contains("portuguese water") ||
           breed.contains("lagotto") || breed.contains("barbet") ||
           breed.contains("irish water") || breed.contains("curly") {
            return .curly
        }

        // Long
        if breed.contains("shih tzu") || breed.contains("yorkie") ||
           breed.contains("yorkshire") || breed.contains("maltese") ||
           breed.contains("afghan") || breed.contains("lhasa") ||
           breed.contains("havanese") || breed.contains("papillon") ||
           breed.contains("pekingese") || breed.contains("coton") ||
           breed.contains("japanese chin") || breed.contains("silky") {
            return .long
        }

        // Wire
        if breed.contains("schnauzer") ||
           (breed.contains("terrier") &&
            (breed.contains("wire") || breed.contains("airedale") ||
             breed.contains("scottish") || breed.contains("west highland") ||
             breed.contains("welsh") || breed.contains("lakeland") ||
             breed.contains("border terrier") || breed.contains("cairn") ||
             breed.contains("norfolk") || breed.contains("norwich"))) ||
           breed.contains("wirehaired") || breed.contains("griffon") {
            return .wire
        }

        // Medium (Australian Shepherd, Border Collie, etc.)
        if breed.contains("australian shepherd") || breed.contains("border collie") ||
           breed.contains("brittany") || breed.contains("springer") ||
           breed.contains("cocker") || breed.contains("cavalier") ||
           breed.contains("setter") {
            return .medium
        }

        // Hairless
        if breed.contains("hairless") || breed.contains("xolo") ||
           breed.contains("chinese crested") {
            return .hairless
        }

        return nil
    }
}

// MARK: - GroomingActivity Extension

public extension GroomingActivity {

    /// Create default grooming activities based on coat type
    static func defaultActivities(for coatType: CoatType) -> [GroomingActivity] {
        var activities: [GroomingActivity] = []

        for groomingType in GroomingType.allCases {
            let interval = coatType.defaultInterval(for: groomingType)

            // Skip activities that don't apply to this coat type
            if interval == 0 { continue }

            // Skip professional activities for coats that don't need them
            if groomingType == .haircut && coatType.haircutIntervalDays == nil { continue }
            if groomingType == .deShedding && coatType.desheddingIntervalDays == nil { continue }

            let isEnabled: Bool
            switch groomingType {
            case .haircut, .analGlands:
                // Professional activities disabled by default
                isEnabled = false
            case .teethBrushing:
                // Teeth brushing off by default (daily is ambitious)
                isEnabled = false
            default:
                isEnabled = true
            }

            activities.append(GroomingActivity(
                type: groomingType,
                intervalDays: interval,
                isEnabled: isEnabled
            ))
        }

        return activities
    }
}
