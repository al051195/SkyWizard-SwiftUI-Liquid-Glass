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
        public let wind_speed_10m: Double
        public let wind_direction_10m: Int

        public init(
            temperature_2m: Double,
            apparent_temperature: Double,
            weather_code: Int,
            is_day: Int,
            wind_speed_10m: Double = 0,
            wind_direction_10m: Int = 0
        ) {
            self.temperature_2m = temperature_2m
            self.apparent_temperature = apparent_temperature
            self.weather_code = weather_code
            self.is_day = is_day
            self.wind_speed_10m = wind_speed_10m
            self.wind_direction_10m = wind_direction_10m
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.temperature_2m = try container.decode(Double.self, forKey: .temperature_2m)
            self.apparent_temperature = try container.decode(Double.self, forKey: .apparent_temperature)
            self.weather_code = try container.decode(Int.self, forKey: .weather_code)
            self.is_day = try container.decode(Int.self, forKey: .is_day)
            // Wind fields default to zero so responses (and mocks) built
            // before they existed keep decoding.
            self.wind_speed_10m = try container.decodeIfPresent(Double.self, forKey: .wind_speed_10m) ?? 0
            self.wind_direction_10m = try container.decodeIfPresent(Int.self, forKey: .wind_direction_10m) ?? 0
        }

        private enum CodingKeys: String, CodingKey {
            case temperature_2m
            case apparent_temperature
            case weather_code
            case is_day
            case wind_speed_10m
            case wind_direction_10m
        }
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
