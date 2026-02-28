import SwiftUI
import OllieShared

/// Compact horizontal weather strip showing upcoming hours
struct WeatherBar: View {
    let forecasts: [HourForecast]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(forecasts) { hour in
                    WeatherHourCell(forecast: hour)
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Single hour cell in the weather bar
struct WeatherHourCell: View {
    let forecast: HourForecast
    @AppStorage(UserPreferences.Key.temperatureUnit.rawValue) private var temperatureUnitRaw = TemperatureUnit.celsius.rawValue

    private var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRaw) ?? .celsius
    }

    var body: some View {
        VStack(spacing: 4) {
            // Hour
            Text(forecast.time, format: .dateTime.hour())
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Weather icon
            Image(systemName: forecast.icon)
                .font(.title3)
                .symbolRenderingMode(.multicolor)

            // Temperature
            Text(temperatureUnit.format(forecast.temperature))
                .font(.caption)
                .fontWeight(.medium)

            // Rain probability (only show if > 10%)
            if forecast.precipProbability > 10 {
                HStack(spacing: 2) {
                    Text("\(forecast.precipProbability)%")
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                }
                .font(.caption2)
                .foregroundStyle(forecast.rainWarning ? Color.ollieDanger : Color.secondary)
            }

            // Wind warning indicator
            if forecast.windWarning {
                HStack(spacing: 2) {
                    Image(systemName: "wind")
                        .font(.caption2)
                    Text("\(Int(forecast.windSpeed))")
                        .font(.caption2)
                }
                .foregroundStyle(Color.ollieWarning)
            }
        }
        .frame(minWidth: 44)
    }
}

/// Weather alert banner
struct WeatherAlertBanner: View {
    let alert: WeatherAlert

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: alert.icon)
                .font(.title3)
                .symbolRenderingMode(.multicolor)

            Text(alert.message)
                .font(.subheadline)
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var backgroundColor: Color {
        switch alert.type {
        case .warning: return Color.ollieWarning.opacity(0.15)
        case .info: return Color.ollieInfo.opacity(0.15)
        case .positive: return Color.ollieSuccess.opacity(0.15)
        }
    }

    private var textColor: Color {
        switch alert.type {
        case .warning: return .ollieWarning
        case .info: return .primary
        case .positive: return .ollieSuccess
        }
    }
}

/// Compact single-line weather section
struct WeatherSection: View {
    let forecasts: [HourForecast]
    let alert: WeatherAlert?
    let isLoading: Bool
    @AppStorage(UserPreferences.Key.temperatureUnit.rawValue) private var temperatureUnitRaw = TemperatureUnit.celsius.rawValue

    private var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRaw) ?? .celsius
    }

    var body: some View {
        if isLoading && forecasts.isEmpty {
            // Loading state
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.7)
                Text(Strings.Weather.loading)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } else if let current = forecasts.first {
            // Compact single-line weather display
            HStack(spacing: 12) {
                // Current weather icon + temp
                HStack(spacing: 4) {
                    Image(systemName: current.icon)
                        .font(.subheadline)
                        .symbolRenderingMode(.multicolor)
                    Text(temperatureUnit.format(current.temperature))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                // Rain probability if significant
                if current.precipProbability > 20 {
                    HStack(spacing: 2) {
                        Image(systemName: "drop.fill")
                            .font(.caption2)
                        Text("\(current.precipProbability)%")
                            .font(.caption)
                    }
                    .foregroundStyle(current.rainWarning ? .red : .secondary)
                }

                // Alert message (minimal)
                if let alert = alert {
                    Text(alert.message)
                        .font(.caption)
                        .foregroundStyle(alertColor(for: alert.type))
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        // When offline with no cached data, show nothing (graceful degradation)
    }

    private func alertColor(for type: WeatherAlert.AlertType) -> Color {
        switch type {
        case .warning: return .ollieWarning
        case .info: return .secondary
        case .positive: return .ollieSuccess
        }
    }
}

// MARK: - Weather Section Container

/// Isolated container that owns weather observation
/// Prevents parent view from re-rendering when weather updates
struct WeatherSectionContainer: View {
    @ObservedObject var weatherService: WeatherService
    let isToday: Bool
    let predictedPottyTime: Date?

    var body: some View {
        if isToday {
            WeatherSection(
                forecasts: weatherService.upcomingForecasts(hours: 6),
                alert: weatherService.smartAlert(predictedPottyTime: predictedPottyTime),
                isLoading: weatherService.isLoading
            )
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Previews

#Preview("Weather Bar") {
    let sampleForecasts = [
        HourForecast(time: Date(), temperature: 12, precipProbability: 10, weatherCode: 2, windSpeed: 15),
        HourForecast(time: Date().addingTimeInterval(3600), temperature: 13, precipProbability: 30, weatherCode: 3, windSpeed: 20),
        HourForecast(time: Date().addingTimeInterval(7200), temperature: 11, precipProbability: 80, weatherCode: 61, windSpeed: 25),
        HourForecast(time: Date().addingTimeInterval(10800), temperature: 10, precipProbability: 20, weatherCode: 2, windSpeed: 12),
        HourForecast(time: Date().addingTimeInterval(14400), temperature: 9, precipProbability: 5, weatherCode: 0, windSpeed: 8),
        HourForecast(time: Date().addingTimeInterval(18000), temperature: 8, precipProbability: 0, weatherCode: 0, windSpeed: 5)
    ]

    VStack {
        WeatherBar(forecasts: sampleForecasts)
    }
    .padding()
}

#Preview("Weather Alert - Rain") {
    WeatherAlertBanner(alert: WeatherAlert(
        icon: "cloud.rain.fill",
        message: Strings.Weather.rainSoon,
        type: .warning
    ))
    .padding()
}

#Preview("Weather Alert - Dry") {
    WeatherAlertBanner(alert: WeatherAlert(
        icon: "sun.max.fill",
        message: Strings.Weather.dryAhead,
        type: .positive
    ))
    .padding()
}

#Preview("Weather Section - Compact") {
    let sampleForecasts = [
        HourForecast(time: Date(), temperature: 12, precipProbability: 10, weatherCode: 2, windSpeed: 15),
        HourForecast(time: Date().addingTimeInterval(3600), temperature: 13, precipProbability: 30, weatherCode: 3, windSpeed: 20)
    ]

    VStack {
        WeatherSection(
            forecasts: sampleForecasts,
            alert: WeatherAlert(icon: "sun.max.fill", message: Strings.Weather.dryAhead, type: .positive),
            isLoading: false
        )

        Divider()

        WeatherSection(
            forecasts: [HourForecast(time: Date(), temperature: 8, precipProbability: 75, weatherCode: 61, windSpeed: 20)],
            alert: WeatherAlert(icon: "cloud.rain.fill", message: Strings.Weather.rainSoon, type: .warning),
            isLoading: false
        )
    }
    .padding()
}
