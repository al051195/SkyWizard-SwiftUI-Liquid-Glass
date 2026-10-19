// WeatherDataStore+Dependencies.swift
// SkyWizard-SwiftUI

import Foundation
import DependencyInjector
import SkyWizardService

fileprivate final class WeatherDataStoreInjectableDependency: InjectableDependency {
    @Injectable(\.locationServiceGps) private static var locationService: LocationService
    @Injectable(\.weatherServiceRemote) private static var weatherService: WeatherService
    @Injectable(\.geoCodingServiceRemote) private static var geocodingService: GeocodingService
    @Injectable(\.networkReachabilityService) private static var reachabilityService: ReachabilityService
    @Injectable(\.settingsStore) private static var settingsStore: SettingsStore
    
    static var dependency: WeatherDataStore = .init(
        weatherService: weatherService,
        geocodingService: geocodingService,
        locationService: locationService,
        reachabilityService: reachabilityService,
        settingsStore: settingsStore
    )
}

#if DEBUG
fileprivate final class WeatherDataStoreMockInjectableDependency: InjectableDependency {
    @Injectable(\.locationServiceMock) private static var locationService: LocationService
    @Injectable(\.weatherServiceMock) private static var weatherService: WeatherService
    @Injectable(\.geoCodingServiceMock) private static var geocodingService: GeocodingService
    @Injectable(\.reachabilityServiceMock) private static var reachabilityService: ReachabilityService
    @Injectable(\.settingsStore) private static var settingsStore: SettingsStore
    
    static var dependency: WeatherDataStore = .init(
        weatherService: weatherService,
        geocodingService: geocodingService,
        locationService: locationService,
        reachabilityService: reachabilityService,
        settingsStore: settingsStore
    )
}
#endif

extension InjectableValues {
    var weatherDataStore: WeatherDataStore {
        get {
            WeatherDataStoreInjectableDependency.dependency
        }
    }
    #if DEBUG
    var weatherDataStoreMock: WeatherDataStore {
        get {
            WeatherDataStoreMockInjectableDependency.dependency
        }
    }
    #endif
}
