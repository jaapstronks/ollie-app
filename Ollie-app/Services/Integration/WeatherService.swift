import Foundation
import OtisShared
import Combine

/// Service for fetching weather forecasts from Open-Meteo API
@Observable
@MainActor
class WeatherService {

    // MARK: - Observable State

    var forecasts: [HourForecast] = []
    var isLoading = false
    var lastError: Error?

    /// Today's sunrise time (if available)
    var sunrise: Date?

    /// Today's sunset time (if available)
    var sunset: Date?

    /// Current air quality (if available)
    var airQuality: AirQuality?

    // MARK: - Dependencies

    @ObservationIgnored
    private weak var locationManager: LocationManager?

    // MARK: - Cache

    @ObservationIgnored
    private var cache: (forecasts: [HourForecast], sunrise: Date?, sunset: Date?, airQuality: AirQuality?, fetchedAt: Date, location: (lat: Double, lon: Double))?
    @ObservationIgnored
    private let cacheValidityMinutes: Double = 30

    // MARK: - Default Location (Rotterdam - fallback when location unavailable)

    nonisolated static let defaultLocation = (lat: 51.9225, lon: 4.4792)

    // MARK: - Init

    init(locationManager: LocationManager? = nil) {
        self.locationManager = locationManager
    }

    /// Set the location manager (useful when injected via environment)
    func setLocationManager(_ manager: LocationManager) {
        self.locationManager = manager
    }

    // MARK: - Public Methods

    /// Fetch hourly forecasts using user's current location (or default if unavailable)
    func fetchForecasts() async {
        var coordinates: (Double, Double)?

        // Try to get user's location if authorized
        if let manager = locationManager, manager.isAuthorized {
            // Request fresh location if we don't have one cached
            if manager.currentCoordinates == nil {
                _ = try? await manager.requestLocation()
            }
            coordinates = manager.currentCoordinates
        }

        // Fall back to default location (Rotterdam) if location unavailable
        let finalCoords = coordinates ?? (Self.defaultLocation.lat, Self.defaultLocation.lon)
        await fetchForecasts(lat: finalCoords.0, lon: finalCoords.1)
    }

    /// Fetch hourly forecasts for a specific location
    /// Uses cached data if available and fresh (< 30 minutes old)
    func fetchForecasts(lat: Double, lon: Double) async {
        // Check cache validity
        if let cached = cache,
           cached.location.lat == lat,
           cached.location.lon == lon,
           Date().timeIntervalSince(cached.fetchedAt) < cacheValidityMinutes * 60 {
            forecasts = cached.forecasts
            sunrise = cached.sunrise
            sunset = cached.sunset
            airQuality = cached.airQuality
            return
        }

        isLoading = true
        lastError = nil

        do {
            // Fetch weather and air quality in parallel
            async let weatherResult = performFetch(lat: lat, lon: lon)
            async let aqResult = fetchAirQuality(lat: lat, lon: lon)

            let weather = try await weatherResult
            let aq = await aqResult  // Air quality is best-effort, doesn't throw

            forecasts = weather.forecasts
            sunrise = weather.sunrise
            sunset = weather.sunset
            airQuality = aq
            cache = (forecasts: weather.forecasts, sunrise: weather.sunrise, sunset: weather.sunset, airQuality: aq, fetchedAt: Date(), location: (lat, lon))
        } catch {
            lastError = error
            // On error, keep showing cached data if available
            if let cached = cache {
                forecasts = cached.forecasts
                sunrise = cached.sunrise
                sunset = cached.sunset
                airQuality = cached.airQuality
            }
        }

        isLoading = false
    }

    /// Get forecast for a specific hour (for potty predictions)
    func forecast(for date: Date) -> HourForecast? {
        let calendar = Calendar.current
        return forecasts.first { forecast in
            calendar.isDate(forecast.time, equalTo: date, toGranularity: .hour)
        }
    }

    /// Get forecasts for the next N hours from now
    func upcomingForecasts(hours: Int = 6) -> [HourForecast] {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.startOfHour(for: now)

        return forecasts.filter { forecast in
            forecast.time >= currentHour && forecast.time < currentHour.addingTimeInterval(Double(hours) * 3600)
        }
    }

    /// Generate smart weather alert if conditions warrant it
    /// Returns a simple, minimal alert for weather conditions
    func smartAlert(predictedPottyTime: Date?) -> WeatherAlert? {
        let upcoming = upcomingForecasts(hours: 4)
        guard !upcoming.isEmpty else { return nil }

        // Check air quality first (highest priority for outdoor exercise)
        if let aq = airQuality, aq.isWarning {
            return WeatherAlert(
                icon: aq.icon,
                message: Strings.Weather.airQualityPoor,
                type: .warning
            )
        }

        // Check for high UV (harmful for prolonged outdoor activity)
        if let aq = airQuality, let uv = aq.uvIndex, uv > 8 {
            return WeatherAlert(
                icon: "sun.max.trianglebadge.exclamationmark",
                message: Strings.Weather.highUV,
                type: .warning
            )
        }

        // Check for incoming rain
        if upcoming.contains(where: { $0.precipProbability > 60 }) {
            return WeatherAlert(
                icon: "cloud.rain.fill",
                message: Strings.Weather.rainSoon,
                type: .warning
            )
        }

        // Check for freezing temperatures
        if let current = upcoming.first, current.freezingWarning {
            return WeatherAlert(
                icon: "thermometer.snowflake",
                message: Strings.Weather.freezing,
                type: .info
            )
        }

        // Check for good weather window (dry ahead)
        let dryHours = upcoming.filter { $0.precipProbability < 20 }
        if dryHours.count >= 3, let first = upcoming.first, first.precipProbability < 20 {
            // Add air quality context if it's good
            if let aq = airQuality, aq.category == .good {
                return WeatherAlert(
                    icon: "sun.max.fill",
                    message: Strings.Weather.dryAheadGoodAir,
                    type: .positive
                )
            }
            return WeatherAlert(
                icon: "sun.max.fill",
                message: Strings.Weather.dryAhead,
                type: .positive
            )
        }

        return nil
    }

    /// Force refresh using user's location, bypassing cache
    func refresh() async {
        cache = nil
        await fetchForecasts()
    }

    /// Force refresh for a specific location, bypassing cache
    func refresh(lat: Double, lon: Double) async {
        cache = nil
        await fetchForecasts(lat: lat, lon: lon)
    }

    // MARK: - Private Methods

    /// Result type for fetch operation including sunrise/sunset
    private struct FetchResult {
        let forecasts: [HourForecast]
        let sunrise: Date?
        let sunset: Date?
    }

    private func performFetch(lat: Double, lon: Double) async throws -> FetchResult {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&hourly=temperature_2m,precipitation_probability,weathercode,windspeed_10m&daily=sunrise,sunset&timezone=Europe/Amsterdam&forecast_days=1"

        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherError.networkError
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(OpenMeteoResponse.self, from: data)

        return parseResponse(apiResponse)
    }

    private func parseResponse(_ response: OpenMeteoResponse) -> FetchResult {
        let hourly = response.hourly
        var forecasts: [HourForecast] = []

        // Open-Meteo returns times without seconds: "2026-02-24T14:00"
        // ISO8601DateFormatter with .withTime expects seconds, so we use a custom DateFormatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        dateFormatter.timeZone = TimeZone(identifier: "Europe/Amsterdam")

        for i in 0..<hourly.time.count {
            guard let time = dateFormatter.date(from: hourly.time[i]) else { continue }

            let forecast = HourForecast(
                time: time,
                temperature: hourly.temperature_2m[i],
                precipProbability: hourly.precipitation_probability[i],
                weatherCode: hourly.weathercode[i],
                windSpeed: hourly.windspeed_10m[i]
            )
            forecasts.append(forecast)
        }

        // Parse sunrise/sunset from daily data
        var sunriseDate: Date?
        var sunsetDate: Date?

        if let daily = response.daily {
            if let sunriseString = daily.sunrise.first {
                sunriseDate = dateFormatter.date(from: sunriseString)
            }
            if let sunsetString = daily.sunset.first {
                sunsetDate = dateFormatter.date(from: sunsetString)
            }
        }

        return FetchResult(forecasts: forecasts, sunrise: sunriseDate, sunset: sunsetDate)
    }

    // MARK: - Air Quality

    /// Fetch air quality data from Open-Meteo Air Quality API
    /// Returns nil on error (best-effort, non-blocking)
    private func fetchAirQuality(lat: Double, lon: Double) async -> AirQuality? {
        let urlString = "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=\(lat)&longitude=\(lon)&current=european_aqi,us_aqi,pm2_5,pm10,ozone,nitrogen_dioxide,uv_index"

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(AirQualityAPIResponse.self, from: data)

            guard let current = apiResponse.current else { return nil }

            // Parse time
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            dateFormatter.timeZone = TimeZone(identifier: "Europe/Amsterdam")
            let time = dateFormatter.date(from: current.time) ?? Date()

            return AirQuality(
                europeanAqi: current.european_aqi ?? 0,
                usAqi: current.us_aqi ?? 0,
                pm2_5: current.pm2_5 ?? 0,
                pm10: current.pm10 ?? 0,
                ozone: current.ozone,
                nitrogenDioxide: current.nitrogen_dioxide,
                uvIndex: current.uv_index,
                time: time
            )
        } catch {
            // Air quality is best-effort - don't propagate errors
            return nil
        }
    }
}

// MARK: - Air Quality API Response

/// Response structure for Open-Meteo Air Quality API (current values)
private struct AirQualityAPIResponse: Codable {
    let current: CurrentAirQuality?

    struct CurrentAirQuality: Codable {
        let time: String
        let european_aqi: Int?
        let us_aqi: Int?
        let pm2_5: Double?
        let pm10: Double?
        let ozone: Double?
        let nitrogen_dioxide: Double?
        let uv_index: Double?
    }
}

// MARK: - Supporting Types

enum WeatherError: LocalizedError {
    case invalidURL
    case networkError
    case parseError

    nonisolated var errorDescription: String? {
        switch self {
        case .invalidURL: return Strings.Errors.invalidURL
        case .networkError: return Strings.Errors.networkError
        case .parseError: return Strings.Errors.couldNotProcessWeather
        }
    }
}

struct WeatherAlert {
    let icon: String
    let message: String
    let type: AlertType

    enum AlertType {
        case warning  // Red/orange
        case info     // Blue
        case positive // Green
    }
}

// MARK: - Calendar Extension

private extension Calendar {
    func startOfHour(for date: Date) -> Date {
        let components = dateComponents([.year, .month, .day, .hour], from: date)
        return self.date(from: components) ?? date
    }
}
