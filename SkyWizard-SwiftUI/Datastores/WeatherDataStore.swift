//
//  WeatherDataStore.swift
//  SkyWizard-SwiftUI
//
//  Created by Hishara Dilshan on 07/11/2024.
//

import Foundation
import CoreLocation
import OSLog
import Combine
import SkyWizardModel
import SkyWizardEnum
import SkyWizardService


final class WeatherDataStore: @unchecked Sendable, ObservableObject {
    @Published var currentTemperature: Int = 0
    @Published var realFeel: Int = 0
    @Published var currentWindSpeed: Int = 0
    @Published var currentWindDirection: Int = 0
    /// Localised with the temperature setting: °C goes with km/h, °F with mph.
    @Published var currentWindSpeedUnit: String = "km/h"
    @Published var currentCity: String = "No Location"
    @Published var currentWeatherType: CurrentWeatherType = .day_sunny
    @Published var hourlyWeatherData: [HourlyWeatherData] = .init()
    @Published var dailyWeatherData: [DailyWeatherData] = .init()
    @Published var error: Swift.Error?
    @Published var weatherLoading: Bool = true
    @Published var isOnline: Bool = true
    @Published var greetingMessage: String = .init()
    private var currentWeatherTask: Task<WeatherData, Error>?
    private var currentGeocodingTask: Task<GeocodeData, Error>?
    private var cancelable: Set<AnyCancellable> = .init()
    private var isLocationLoadingStarted: Bool = false
    private var isMonitoringForReachabilityStarted: Bool = false
    private var rawWeatherData: WeatherData?
    
    var weatherTypeResource: WeatherTypeResource {
        currentWeatherType.getWeatherTypeResource()
    }
    
    let weatherService: WeatherService
    let geocodingService: GeocodingService
    let locationService: LocationService
    let reachabilityService: ReachabilityService
    let settingsStore: SettingsStore
    
    init(weatherService: WeatherService, geocodingService: GeocodingService, locationService: LocationService, reachabilityService: ReachabilityService, settingsStore: SettingsStore) {
        self.weatherService = weatherService
        self.geocodingService = geocodingService
        self.locationService = locationService
        self.reachabilityService = reachabilityService
        self.settingsStore = settingsStore

        settingsStore.$useCelsius
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, let data = self.rawWeatherData else { return }
                Task { @MainActor in
                    self.applyUnitConversion(to: data)
                }
            }
            .store(in: &cancelable)
    }
    
    func loadWeather() {
        if !isLocationLoadingStarted {
            startLoadingLocation()
        }
        
        if !isMonitoringForReachabilityStarted {
            startMonitoringForReachability()
        }
    }
    
    func reloadWeather() {
        guard let location = locationService.getLastKnownLocation() else {
            self.error = WeatherDataStoreError.locationError
            return
        }
        
        Task {
            await loadWeatherData(for: location)
            await geocodeLocation(with: location)
        }
    }
    
    // Public API to load weather for a specific coordinate (used by OtherLocationsView)
    public func loadWeather(for coordinate: CLLocationCoordinate2D) {
        Task {
            await loadWeatherData(for: coordinate)
            await geocodeLocation(with: coordinate)
        }
    }
    
    private func startLoadingLocation() {
        self.isLocationLoadingStarted = true
        locationService.locationResult
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] result in
                if case let .failure(error) = result {
                    self?.weatherLoading = false
                    self?.error = error
                    return
                }
                
                guard case let .success(result) = result else { return }
                Task {
                    await self?.loadWeatherData(for: result)
                    await self?.geocodeLocation(with: result)
                }
            })
            .store(in: &cancelable)
        locationService.start()
    }
    
    private func startMonitoringForReachability() {
        self.isMonitoringForReachabilityStarted = true
        reachabilityService
            .isReachable
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isOnline in
                let lastOnline = self?.isOnline
                self?.isOnline = isOnline
                
                if !isOnline { return }
                
                guard lastOnline != isOnline else {
                    Logger.viewCycle.info("Reachability hasn't changed. Returning")
                    return
                }
                
                Logger.viewCycle.info("Reachability changed to \(isOnline). Reloading weather data.")
                self?.reloadWeather()
            })
            .store(in: &cancelable)
    }
    
    private func loadWeatherData(for coordinate: CLLocationCoordinate2D) async {
        self.currentWeatherTask?.cancel()
        do {
            self.currentWeatherTask = try await weatherService.fetchWeather(for: coordinate)
            let data = try await currentWeatherTask!.value
                        
            await updateData(from: data)
        } catch {
            await MainActor.run {
                self.weatherLoading = false
                self.error = error
            }
        }
    }
    
    private func geocodeLocation(with coordinates: CLLocationCoordinate2D) async {
        Logger.statistics.info("Location changed to : \(coordinates.latitude), \(coordinates.longitude)")
        self.currentGeocodingTask?.cancel()
        do {
            self.currentGeocodingTask = try await geocodingService.geocode(with: coordinates)
            
            let location = try await currentGeocodingTask?.value
            guard let location else { return }
            
            await MainActor.run {
                Logger.statistics.info("Geocoded location: \(location.city)")
                self.weatherLoading = false
                self.currentCity = location.city
            }
        } catch {
            await MainActor.run {
                self.weatherLoading = false
                self.error = error
            }
        }
    }
    
    @MainActor
    private func updateData(from weather: WeatherData) {
        self.rawWeatherData = weather
        self.weatherLoading = false
        self.currentWeatherType = weatherService.getWeatherType(for: weather.current)
        applyUnitConversion(to: weather)

        Task {
            try? await Task.sleep(for: .seconds(1))
            self.greetingMessage = currentWeatherType.greeting
        }
    }

    @MainActor
    private func applyUnitConversion(to weather: WeatherData) {
        let unit = settingsStore.useCelsius ? TemperatureUnit.celsius : TemperatureUnit.fahrenheit
        let timeZone: TimeZone = {
            guard let offset = weather.utcOffsetSeconds else { return .current }
            return TimeZone(secondsFromGMT: offset) ?? .current
        }()

        do {
            self.currentTemperature = Int(unit.convert(weather.current.temperature_2m))
            self.realFeel = Int(unit.convert(weather.current.apparent_temperature))

            if settingsStore.useCelsius {
                self.currentWindSpeed = Int(weather.current.wind_speed_10m.rounded())
                self.currentWindSpeedUnit = "km/h"
            } else {
                self.currentWindSpeed = Int((weather.current.wind_speed_10m * 0.621371).rounded())
                self.currentWindSpeedUnit = "mph"
            }
            self.currentWindDirection = weather.current.wind_direction_10m

            let hourlyData = try weatherService.getWeather(for: weather.hourly, timeZone: timeZone)
            self.hourlyWeatherData = hourlyData.map { hour in
                HourlyWeatherData(
                    timeText: hour.timeText,
                    weatherType: hour.weatherType,
                    temperature: Int(unit.convert(Double(hour.temperature)))
                )
            }

            let dailyData = try weatherService.getWeather(for: weather.daily, timeZone: timeZone)
            self.dailyWeatherData = dailyData.map { day in
                DailyWeatherData(
                    dateString: day.dateString,
                    tempHigh: Int(unit.convert(Double(day.tempHigh))),
                    tempLow: Int(unit.convert(Double(day.tempLow))),
                    weatherType: day.weatherType,
                    sunrise: day.sunrise,
                    sunset: day.sunset,
                    timeZone: day.timeZone
                )
            }
        } catch {
            self.error = error
        }
    }
    
    func cancelCurrentTask() {
        currentWeatherTask?.cancel()
        currentGeocodingTask?.cancel()
        cancelable.removeAll()
    }
    
    #if DEBUG
    func changeWeatherType() {
        let type = CurrentWeatherType.allCases.randomElement()!
        self.currentWeatherType = type
        self.greetingMessage = type.greeting
    }
    #endif
}

enum WeatherDataStoreError: LocalizedError {
    case locationError
}

extension WeatherDataStoreError {
    var errorDescription: String? {
        switch self {
        case .locationError:
            return "Could not load location. Please try again later."
        }
    }
}

