//
//  AtmosphereTypes.swift
//  Ollie-app
//
//  Type definitions for the contextual atmosphere system

import Foundation

// MARK: - Time of Day Period

/// Time periods with distinct atmospheric qualities
enum TimeOfDayPeriod: String, CaseIterable {
    case earlyMorning   // 5-7: Cool blue, calm
    case morning        // 7-11: Warm white, energetic
    case midday         // 11-14: Neutral
    case afternoon      // 14-17: Golden
    case evening        // 17-20: Amber, calm
    case night          // 20-23: Warm gray, calm
    case lateNight      // 23-5: Dark neutral, calm

    /// Hour range for this period (start hour, end hour exclusive)
    var hourRange: (start: Int, end: Int) {
        switch self {
        case .earlyMorning: return (5, 7)
        case .morning: return (7, 11)
        case .midday: return (11, 14)
        case .afternoon: return (14, 17)
        case .evening: return (17, 20)
        case .night: return (20, 23)
        case .lateNight: return (23, 5)  // Wraps around midnight
        }
    }

    /// Get the current period for a given date
    static func current(for date: Date = Date()) -> TimeOfDayPeriod {
        let hour = Calendar.current.component(.hour, from: date)
        return period(forHour: hour)
    }

    /// Get period for a specific hour (0-23)
    static func period(forHour hour: Int) -> TimeOfDayPeriod {
        switch hour {
        case 5..<7: return .earlyMorning
        case 7..<11: return .morning
        case 11..<14: return .midday
        case 14..<17: return .afternoon
        case 17..<20: return .evening
        case 20..<23: return .night
        default: return .lateNight  // 23, 0, 1, 2, 3, 4
        }
    }

    /// Next period in sequence
    var next: TimeOfDayPeriod {
        switch self {
        case .earlyMorning: return .morning
        case .morning: return .midday
        case .midday: return .afternoon
        case .afternoon: return .evening
        case .evening: return .night
        case .night: return .lateNight
        case .lateNight: return .earlyMorning
        }
    }

    /// Default mood for this period
    var defaultMood: AtmosphereMood {
        switch self {
        case .earlyMorning, .evening, .night, .lateNight:
            return .calm
        case .morning:
            return .energetic
        case .midday, .afternoon:
            return .neutral
        }
    }
}

// MARK: - Puppy Activity State

/// Simplified puppy activity state for atmosphere calculations
enum PuppyActivityState: String {
    case sleeping
    case awake
    case unknown

    /// Create from SleepState
    static func from(isSleeping: Bool?) -> PuppyActivityState {
        guard let sleeping = isSleeping else { return .unknown }
        return sleeping ? .sleeping : .awake
    }
}

// MARK: - Weather Atmosphere

/// Weather conditions mapped to atmosphere qualities
enum WeatherAtmosphere: String {
    case sunny      // Clear skies - warm, bright
    case cloudy     // Overcast - neutral, muted
    case rainy      // Precipitation - cool, cozy
    case foggy      // Mist/fog - soft, muted
    case snowy      // Snow - cool, bright
    case stormy     // Thunderstorm - dramatic
    case unknown

    /// Create from WMO weather code
    static func from(weatherCode: Int?) -> WeatherAtmosphere {
        guard let code = weatherCode else { return .unknown }
        switch code {
        case 0:
            return .sunny       // Clear sky
        case 1, 2:
            return .sunny       // Mainly clear, partly cloudy
        case 3:
            return .cloudy      // Overcast
        case 45, 48:
            return .foggy       // Fog
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82:
            return .rainy       // Drizzle, rain, showers
        case 71, 73, 75, 77, 85, 86:
            return .snowy       // Snow
        case 95, 96, 99:
            return .stormy      // Thunderstorm
        default:
            return .cloudy
        }
    }

    /// Mood influence of this weather
    var moodInfluence: AtmosphereMood {
        switch self {
        case .sunny:
            return .energetic
        case .cloudy, .foggy, .unknown:
            return .neutral
        case .rainy, .snowy:
            return .calm
        case .stormy:
            return .calm  // Cozy indoors feeling
        }
    }

    /// Whether this weather brings warmth visually
    var isWarm: Bool {
        self == .sunny
    }

    /// Whether this weather brings coolness visually
    var isCool: Bool {
        switch self {
        case .rainy, .snowy, .stormy:
            return true
        default:
            return false
        }
    }
}

// MARK: - Season

/// Seasons for optional seasonal atmosphere touches
enum Season: String, CaseIterable {
    case spring
    case summer
    case autumn
    case winter

    /// Current season based on date (Northern Hemisphere)
    static func current(for date: Date = Date()) -> Season {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 3, 4, 5: return .spring
        case 6, 7, 8: return .summer
        case 9, 10, 11: return .autumn
        default: return .winter
        }
    }

    /// Base color temperature adjustment (-1.0 to 1.0)
    /// Negative = cooler, Positive = warmer
    var colorTemperatureShift: Double {
        switch self {
        case .spring: return 0.05   // Slightly warm
        case .summer: return 0.15   // Warm
        case .autumn: return 0.1    // Warm golden
        case .winter: return -0.1   // Cool
        }
    }
}

// MARK: - Atmosphere Mood

/// Overall emotional quality of the atmosphere
enum AtmosphereMood: String {
    case calm       // Soft, muted, relaxed
    case neutral    // Standard, balanced
    case energetic  // Bright, vibrant

    /// Saturation multiplier for this mood
    var saturationMultiplier: Double {
        switch self {
        case .calm: return 0.7
        case .neutral: return 1.0
        case .energetic: return 1.15
        }
    }

    /// Brightness adjustment for this mood
    var brightnessAdjustment: Double {
        switch self {
        case .calm: return -0.02
        case .neutral: return 0
        case .energetic: return 0.03
        }
    }
}
