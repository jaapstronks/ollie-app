//
//  HourForecast.swift
//  OtisShared
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

// MARK: - Air Quality

/// Current air quality data from Open-Meteo Air Quality API
public struct AirQuality: Codable, Sendable {
    /// European Air Quality Index (1-5 scale: Good, Fair, Moderate, Poor, Very Poor)
    public let europeanAqi: Int

    /// US EPA Air Quality Index (0-500 scale)
    public let usAqi: Int

    /// PM2.5 concentration (μg/m³) - fine particulate matter
    public let pm2_5: Double

    /// PM10 concentration (μg/m³) - coarse particulate matter
    public let pm10: Double

    /// Ozone concentration (μg/m³)
    public let ozone: Double?

    /// Nitrogen dioxide concentration (μg/m³)
    public let nitrogenDioxide: Double?

    /// UV Index
    public let uvIndex: Double?

    /// Timestamp of the measurement
    public let time: Date

    public init(europeanAqi: Int, usAqi: Int, pm2_5: Double, pm10: Double, ozone: Double?, nitrogenDioxide: Double?, uvIndex: Double?, time: Date) {
        self.europeanAqi = europeanAqi
        self.usAqi = usAqi
        self.pm2_5 = pm2_5
        self.pm10 = pm10
        self.ozone = ozone
        self.nitrogenDioxide = nitrogenDioxide
        self.uvIndex = uvIndex
        self.time = time
    }

    /// European AQI category description
    public var category: AirQualityCategory {
        switch europeanAqi {
        case 0...20: return .good
        case 21...40: return .fair
        case 41...60: return .moderate
        case 61...80: return .poor
        case 81...100: return .veryPoor
        default: return .hazardous
        }
    }

    /// Whether air quality poses a warning for outdoor exercise
    public var isWarning: Bool {
        europeanAqi > 60 || (uvIndex ?? 0) > 8
    }

    /// SF Symbol for air quality status
    public var icon: String {
        switch category {
        case .good: return "aqi.low"
        case .fair: return "aqi.medium"
        case .moderate: return "aqi.medium"
        case .poor: return "aqi.high"
        case .veryPoor, .hazardous: return "aqi.high"
        }
    }
}

/// Air quality category based on European AQI
public enum AirQualityCategory: String, Codable, Sendable {
    case good
    case fair
    case moderate
    case poor
    case veryPoor
    case hazardous
}

// MARK: - Open-Meteo API Responses

/// Raw API response structure from Open-Meteo Weather API
public struct OpenMeteoResponse: Codable, Sendable {
    public let hourly: HourlyData
    public let daily: DailyData?

    public struct HourlyData: Codable, Sendable {
        public let time: [String]
        public let temperature_2m: [Double]
        public let precipitation_probability: [Int]
        public let weathercode: [Int]
        public let windspeed_10m: [Double]
    }

    public struct DailyData: Codable, Sendable {
        public let sunrise: [String]
        public let sunset: [String]
    }
}

/// Raw API response structure from Open-Meteo Air Quality API
public struct OpenMeteoAirQualityResponse: Codable, Sendable {
    public let hourly: HourlyAirQualityData

    public struct HourlyAirQualityData: Codable, Sendable {
        public let time: [String]
        public let european_aqi: [Int?]
        public let us_aqi: [Int?]
        public let pm2_5: [Double?]
        public let pm10: [Double?]
        public let ozone: [Double?]?
        public let nitrogen_dioxide: [Double?]?
        public let uv_index: [Double?]?
    }
}
