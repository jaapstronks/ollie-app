import Foundation

/// Hourly weather forecast data from Open-Meteo API
struct HourForecast: Codable, Identifiable {
    let time: Date
    let temperature: Double      // °C
    let precipProbability: Int   // 0-100%
    let weatherCode: Int         // WMO code
    let windSpeed: Double        // km/h

    var id: Date { time }

    /// Weather SF Symbol name based on WMO weather codes
    var icon: String {
        switch weatherCode {
        case 0: return "sun.max.fill"                    // Clear sky
        case 1, 2: return "cloud.sun.fill"               // Partly cloudy
        case 3: return "cloud.fill"                      // Overcast
        case 45, 48: return "cloud.fog.fill"             // Fog
        case 51, 53, 55: return "cloud.drizzle.fill"     // Drizzle
        case 56, 57: return "cloud.sleet.fill"           // Freezing drizzle
        case 61, 63, 65: return "cloud.rain.fill"        // Rain
        case 66, 67: return "cloud.sleet.fill"           // Freezing rain
        case 71, 73, 75: return "cloud.snow.fill"        // Snow
        case 77: return "cloud.snow.fill"                // Snow grains
        case 80, 81, 82: return "cloud.heavyrain.fill"   // Rain showers
        case 85, 86: return "cloud.snow.fill"            // Snow showers
        case 95: return "cloud.bolt.rain.fill"           // Thunderstorm
        case 96, 99: return "cloud.bolt.rain.fill"       // Thunderstorm with hail
        default: return "cloud.sun.fill"
        }
    }

    /// High wind warning (> 40 km/h)
    var windWarning: Bool { windSpeed > 40 }

    /// Rain warning (> 60% probability)
    var rainWarning: Bool { precipProbability > 60 }

    /// Freezing temperature warning
    var freezingWarning: Bool { temperature < 0 }
}

// MARK: - Open-Meteo API Response

/// Raw API response structure from Open-Meteo
struct OpenMeteoResponse: Codable {
    let hourly: HourlyData

    struct HourlyData: Codable {
        let time: [String]
        let temperature_2m: [Double]
        let precipitation_probability: [Int]
        let weathercode: [Int]
        let windspeed_10m: [Double]
    }
}
