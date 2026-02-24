import Foundation
import OllieShared
import Combine

/// Service for fetching weather forecasts from Open-Meteo API
@MainActor
class WeatherService: ObservableObject {

    // MARK: - Published State

    @Published var forecasts: [HourForecast] = []
    @Published var isLoading = false
    @Published var lastError: Error?

    // MARK: - Dependencies

    private weak var locationManager: LocationManager?

    // MARK: - Cache

    private var cache: (forecasts: [HourForecast], fetchedAt: Date, location: (lat: Double, lon: Double))?
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
        // Use user's location if available, otherwise fall back to default
        let coordinates = locationManager?.currentCoordinates ?? (Self.defaultLocation.lat, Self.defaultLocation.lon)
        await fetchForecasts(lat: coordinates.0, lon: coordinates.1)
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
            return
        }

        isLoading = true
        lastError = nil

        do {
            let fetched = try await performFetch(lat: lat, lon: lon)
            forecasts = fetched
            cache = (forecasts: fetched, fetchedAt: Date(), location: (lat, lon))
        } catch {
            lastError = error
            // On error, keep showing cached data if available
            if let cached = cache {
                forecasts = cached.forecasts
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
    func smartAlert(predictedPottyTime: Date?) -> WeatherAlert? {
        let upcoming = upcomingForecasts(hours: 4)
        guard !upcoming.isEmpty else { return nil }

        // Check for incoming rain
        if let rainHour = upcoming.first(where: { $0.precipProbability > 60 }) {
            let timeString = rainHour.time.timeString

            // If rain is coming before predicted potty time
            if let pottyTime = predictedPottyTime, rainHour.time <= pottyTime {
                return WeatherAlert(
                    icon: "cloud.rain.fill",
                    message: "Regen verwacht om \(timeString) — misschien nu alvast even naar buiten?",
                    type: .warning
                )
            } else {
                return WeatherAlert(
                    icon: "cloud.rain.fill",
                    message: "Regen verwacht om \(timeString)",
                    type: .info
                )
            }
        }

        // Check for freezing temperatures
        if let current = upcoming.first, current.freezingWarning {
            return WeatherAlert(
                icon: "thermometer.snowflake",
                message: "\(Int(current.temperature))° buiten — kort tuinbezoek is genoeg",
                type: .info
            )
        }

        // Check for good weather window
        let dryHours = upcoming.filter { $0.precipProbability < 20 }
        if dryHours.count >= 3, let first = upcoming.first, first.precipProbability < 20 {
            if let lastDry = dryHours.last {
                let untilTime = lastDry.time.addingTimeInterval(3600).hourString
                return WeatherAlert(
                    icon: "sun.max.fill",
                    message: "Droog tot \(untilTime) — goed moment voor een wandeling",
                    type: .positive
                )
            }
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

    private func performFetch(lat: Double, lon: Double) async throws -> [HourForecast] {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&hourly=temperature_2m,precipitation_probability,weathercode,windspeed_10m&timezone=Europe/Amsterdam&forecast_days=1"

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

    private func parseResponse(_ response: OpenMeteoResponse) -> [HourForecast] {
        let hourly = response.hourly
        var forecasts: [HourForecast] = []

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]

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

        return forecasts
    }
}

// MARK: - Supporting Types

enum WeatherError: LocalizedError {
    case invalidURL
    case networkError
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Ongeldige URL"
        case .networkError: return "Netwerkfout"
        case .parseError: return "Kon weerdata niet verwerken"
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
