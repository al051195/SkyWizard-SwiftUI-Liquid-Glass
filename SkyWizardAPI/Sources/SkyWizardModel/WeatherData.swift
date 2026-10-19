//
//  WeatherResult.swift
//  SkyWizard-SwiftUI
//
//  Created by Hishara Dilshan on 07/11/2024.
//

import Foundation

public struct WeatherData: Sendable, Decodable {
    public let latitude: Double
    public let longitude: Double
    public let current: CurrentWeatherData
    public let hourly: HourlyWeatherData
    public let daily: DailyWeatherData
    public let utcOffsetSeconds: Int?

    public init(
        latitude: Double,
        longitude: Double,
        current: CurrentWeatherData,
        hourly: HourlyWeatherData,
        daily: DailyWeatherData,
        utcOffsetSeconds: Int? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.current = current
        self.hourly = hourly
        self.daily = daily
        self.utcOffsetSeconds = utcOffsetSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        self.current = try container.decode(CurrentWeatherData.self, forKey: .current)
        self.hourly = try container.decode(HourlyWeatherData.self, forKey: .hourly)
        self.daily = try container.decode(DailyWeatherData.self, forKey: .daily)
        self.utcOffsetSeconds = try container.decodeIfPresent(Int.self, forKey: .utcOffsetSeconds)
    }

    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case current
        case hourly
        case daily
        case utcOffsetSeconds = "utc_offset_seconds"
    }
}

extension WeatherData {
    public struct HourlyWeatherData: Decodable, Sendable {
        public let time: [String]
        public let temperature_2m: [Double]
        public let weather_code: [Int]
        public let is_day: [Int]
    }
}

extension WeatherData {
    public struct DailyWeatherData: Decodable, Sendable {
        public let time: [String]
        public let temperature_2m_max: [Double]
        public let temperature_2m_min: [Double]
        public let weather_code: [Int]
        public let sunrise: [String]
        public let sunset: [String]
    }
}

extension WeatherData {
    public struct CurrentWeatherData: Decodable, Sendable {
        public let temperature_2m: Double
        public let apparent_temperature: Double
        public let weather_code: Int
        public let is_day: Int
    }
}


extension WeatherData {
    #if DEBUG
    public static var sample: Self {
        let hourlySample: HourlyWeatherData = .init(
            time: (0...5).map { "\($0):00" },
            temperature_2m: (0...5).map { Double($0) },
            weather_code: (0...5).map { $0 },
            is_day: (0...5).map{ $0.isMultiple(of: 2) ? 1 : 0 }
        )
        
        let dailySample: DailyWeatherData = .init(
            time: (0...5).map { "\($0):00" },
            temperature_2m_max: (0...5).map { Double($0) },
            temperature_2m_min: (0...5).map { Double($0) },
            weather_code: (0...5).map { $0 },
            sunrise: (0...5).map { "2024-10-11T06:\($0)" },
            sunset: (0...5).map { "2024-10-11T18:\($0)" }
        )
        
        let currentSample: CurrentWeatherData = .init(
            temperature_2m: 20.0,
            apparent_temperature: 12.0,
            weather_code: 3,
            is_day: 0
        )
        
        return .init(latitude: 52.52, longitude: 13.41, current: currentSample, hourly: hourlySample, daily: dailySample)
    }
    #endif
}
