//
//  AtmosphereProvider.swift
//  Ollie-app
//
//  Main observable object providing contextual atmosphere state

import SwiftUI
import Combine
import OllieShared

/// Provides contextual atmosphere based on time, weather, and puppy state
@MainActor
final class AtmosphereProvider: ObservableObject {

    // MARK: - Published State

    @Published private(set) var currentPeriod: TimeOfDayPeriod = .current()
    @Published private(set) var transitionProgress: Double = 0  // 0-1 progress into next period
    @Published private(set) var puppyState: PuppyActivityState = .unknown
    @Published private(set) var weatherAtmosphere: WeatherAtmosphere = .unknown
    @Published private(set) var currentSeason: Season = .current()
    @Published private(set) var computedMood: AtmosphereMood = .neutral

    // MARK: - User Preferences

    @AppStorage(UserPreferences.Key.atmosphereTimeOfDay.rawValue)
    private var timeOfDayEnabled: Bool = true

    @AppStorage(UserPreferences.Key.atmosphereWeather.rawValue)
    private var weatherEnabled: Bool = true

    @AppStorage(UserPreferences.Key.atmosphereState.rawValue)
    private var stateEnabled: Bool = true

    @AppStorage(UserPreferences.Key.atmosphereSeasonal.rawValue)
    private var seasonalEnabled: Bool = false

    // MARK: - Dependencies

    private weak var weatherService: WeatherService?
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?

    // Throttling
    private var lastUpdate = Date.distantPast
    private let minUpdateInterval: TimeInterval = 60  // Max 1 update per minute

    // MARK: - Computed Properties

    /// Whether atmosphere effects are completely disabled
    var isDisabled: Bool {
        !timeOfDayEnabled && !weatherEnabled && !stateEnabled && !seasonalEnabled
    }

    /// Whether time-of-day effects should be applied
    var shouldApplyTimeEffects: Bool {
        timeOfDayEnabled
    }

    /// Whether weather effects should be applied
    var shouldApplyWeatherEffects: Bool {
        weatherEnabled && weatherAtmosphere != .unknown
    }

    /// Whether puppy state effects should be applied
    var shouldApplyStateEffects: Bool {
        stateEnabled && puppyState != .unknown
    }

    /// Whether seasonal effects should be applied
    var shouldApplySeasonalEffects: Bool {
        seasonalEnabled
    }

    // MARK: - Init

    init() {
        updateTimeOfDay()
        startPeriodicUpdates()
    }

    deinit {
        updateTimer?.invalidate()
    }

    // MARK: - Configuration

    /// Wire up the weather service for weather atmosphere updates
    func setWeatherService(_ service: WeatherService) {
        self.weatherService = service

        // Observe weather changes
        service.$forecasts
            .receive(on: RunLoop.main)
            .sink { [weak self] forecasts in
                self?.updateWeatherAtmosphere(from: forecasts)
            }
            .store(in: &cancellables)
    }

    /// Update puppy activity state (called from TimelineViewModel)
    func updatePuppyState(isSleeping: Bool?) {
        let newState = PuppyActivityState.from(isSleeping: isSleeping)
        guard newState != puppyState else { return }
        puppyState = newState
        recomputeMood()
    }

    // MARK: - Private Methods

    private func startPeriodicUpdates() {
        // Update every minute for smooth transitions
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.throttledUpdate()
            }
        }
    }

    private func throttledUpdate() {
        let now = Date()
        guard now.timeIntervalSince(lastUpdate) >= minUpdateInterval else { return }
        lastUpdate = now
        updateTimeOfDay()
    }

    private func updateTimeOfDay() {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let minute = Calendar.current.component(.minute, from: now)

        // Update period
        let newPeriod = TimeOfDayPeriod.period(forHour: hour)
        currentPeriod = newPeriod

        // Calculate transition progress (30 min transition window at period boundaries)
        transitionProgress = calculateTransitionProgress(hour: hour, minute: minute, period: newPeriod)

        // Update season (only changes daily, but cheap to check)
        currentSeason = Season.current(for: now)

        recomputeMood()
    }

    private func calculateTransitionProgress(hour: Int, minute: Int, period: TimeOfDayPeriod) -> Double {
        let range = period.hourRange

        // Handle late night wrap-around
        let effectiveHour: Int
        if period == .lateNight && hour < 5 {
            effectiveHour = hour + 24
        } else {
            effectiveHour = hour
        }

        let startHour = range.start
        let endHour: Int
        if period == .lateNight {
            endHour = 5 + 24  // 29 (represents 5:00 next day)
        } else {
            endHour = range.end
        }

        // Minutes into period
        let minutesFromStart = (effectiveHour - startHour) * 60 + minute
        let totalMinutes = (endHour - startHour) * 60

        // Transition happens in last 30 minutes of period
        let transitionWindow = 30
        let minutesUntilEnd = totalMinutes - minutesFromStart

        if minutesUntilEnd <= transitionWindow {
            return Double(transitionWindow - minutesUntilEnd) / Double(transitionWindow)
        }
        return 0
    }

    private func updateWeatherAtmosphere(from forecasts: [HourForecast]) {
        // Use current hour's weather
        let now = Date()
        let calendar = Calendar.current

        let currentForecast = forecasts.first { forecast in
            calendar.isDate(forecast.time, equalTo: now, toGranularity: .hour)
        }

        let newAtmosphere = WeatherAtmosphere.from(weatherCode: currentForecast?.weatherCode)
        guard newAtmosphere != weatherAtmosphere else { return }
        weatherAtmosphere = newAtmosphere
        recomputeMood()
    }

    private func recomputeMood() {
        // Start with time-based default mood
        var mood = timeOfDayEnabled ? currentPeriod.defaultMood : .neutral

        // Puppy sleeping overrides to calm
        if stateEnabled && puppyState == .sleeping {
            mood = .calm
        }

        // Weather can influence (but sleeping takes precedence)
        if weatherEnabled && puppyState != .sleeping && weatherAtmosphere != .unknown {
            // Weather only bumps toward energetic if sunny & not already calm from time
            if weatherAtmosphere == .sunny && mood != .calm {
                mood = .energetic
            } else if weatherAtmosphere.isCool {
                mood = .calm
            }
        }

        computedMood = mood
    }
}
