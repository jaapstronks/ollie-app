//
//  HourForecast.swift
//  OllieShared
//

import Foundation

/// Hourly weather forecast data from Open-Meteo API
public struct HourForecast: Codable, Identifiable, Sendable {
    public let time: Date
    public let temperature: Double
    public let precipProbability: Int
    public let weatherCode: Int
    public let windSpeed: Double

    public var id: Date { time }

    public init(time: Date, temperature: Double, precipProbability: Int, weatherCode: Int, windSpeed: Double) {
        self.time = time
        self.temperature = temperature
        self.precipProbability = precipProbability
        self.weatherCode = weatherCode
        self.windSpeed = windSpeed
    }

    /// Weather SF Symbol name based on WMO weather codes
    public var icon: String {
        switch weatherCode {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55: return "cloud.drizzle.fill"
        case 56, 57: return "cloud.sleet.fill"
        case 61, 63, 65: return "cloud.rain.fill"
        case 66, 67: return "cloud.sleet.fill"
        case 71, 73, 75: return "cloud.snow.fill"
        case 77: return "cloud.snow.fill"
        case 80, 81, 82: return "cloud.heavyrain.fill"
        case 85, 86: return "cloud.snow.fill"
        case 95: return "cloud.bolt.rain.fill"
        case 96, 99: return "cloud.bolt.rain.fill"
        default: return "cloud.sun.fill"
        }
    }

    /// High wind warning (> 40 km/h)
    public var windWarning: Bool { windSpeed > 40 }

    /// Rain warning (> 60% probability)
    public var rainWarning: Bool { precipProbability > 60 }

    /// Freezing temperature warning
    public var freezingWarning: Bool { temperature < 0 }
}

// MARK: - Open-Meteo API Response

/// Raw API response structure from Open-Meteo
public struct OpenMeteoResponse: Codable, Sendable {
    public let hourly: HourlyData

    public struct HourlyData: Codable, Sendable {
        public let time: [String]
        public let temperature_2m: [Double]
        public let precipitation_probability: [Int]
        public let weathercode: [Int]
        public let windspeed_10m: [Double]
    }
}
