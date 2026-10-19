//
//  WeatherServiceRemote.swift
//  SkyWizard-SwiftUI
//
//  Created by Hishara Dilshan on 07/11/2024.
//

import Foundation
import CoreLocation
import SkyWizardEnum
import NetworkingService
import SkyWizardModel

public final class WeatherServiceRemote: WeatherService {
    private let dataTransferService: NetworkDataTransferService
    
    public init(dataTransferService: NetworkDataTransferService) {
        self.dataTransferService = dataTransferService
    }
    
    public func fetchWeather(for location: CLLocationCoordinate2D) async throws -> TaskType {
        await dataTransferService.request(with: WeatherEndpoints.getWeather(latitude: location.latitude, longitude: location.longitude))
    }
    
    public func getWeatherType(for current: WeatherData.CurrentWeatherData) -> CurrentWeatherType {
        let code = current.weather_code
        let isDay = current.is_day == 1
        
        return switch code {
        case let code where (0...1).contains(code) && isDay:
            .day_sunny
        case let code where (2...48).contains(code) && isDay:
            .day_cloudy
        case let code where ((51...67).contains(code) || (80...82).contains(code) || (95...99).contains(code)) && isDay:
            .day_rainy
        case let code where (0...3).contains(code) && !isDay:
            .night_clear
        case let code where (45...48).contains(code) && !isDay:
            .night_cloudy
        case let code where ((51...67).contains(code) || (80...82).contains(code) || (95...99).contains(code)) && !isDay:
            .night_rainy
        case let code where (71...77).contains(code) || (85...86).contains(code):
            .snow
        default:
            .undefined
        }
    }
    
    public func getWeather(for daily: WeatherData.DailyWeatherData, timeZone: TimeZone) throws -> [DailyWeatherData] {
        var data: [DailyWeatherData] = .init()
        let dateFormatter: DateFormatter = .init()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = timeZone
        
        guard !daily.time.isEmpty else {
            throw WeatherServiceError.invalidData(message: "Empty time data found.")
        }
        
        guard Set(
            [
                daily.temperature_2m_max.count,
                daily.temperature_2m_min.count,
                daily.time.count,
                daily.weather_code.count
            ]
        ).count == 1 else {
            throw WeatherServiceError.invalidData(message: "Inconsistent data found.")
        }
        
        
        for index in 0..<daily.time.count {
            guard let date = dateFormatter.date(from: daily.time[index]) else {
                throw WeatherServiceError.invalidData(message: "Invalid date format found.")
            }
            
            let dateText = dayDescription(for: date, timeZone: timeZone)

            let sunrise = index < daily.sunrise.count ? isoDateFormatter(timeZone: timeZone).date(from: daily.sunrise[index]) : nil
            let sunset = index < daily.sunset.count ? isoDateFormatter(timeZone: timeZone).date(from: daily.sunset[index]) : nil

            data.append(.init(
                dateString: dateText,
                tempHigh: Int(daily.temperature_2m_max[index]),
                tempLow: Int(daily.temperature_2m_min[index]),
                weatherType: getWeatherType(for: daily.weather_code[index]),
                sunrise: sunrise,
                sunset: sunset,
                timeZone: timeZone
            ))
        }
        
        return Array(data.prefix(5))
    }
    
    public func getWeather(for hourly: WeatherData.HourlyWeatherData, timeZone: TimeZone) throws -> [HourlyWeatherData] {
        var data: [HourlyWeatherData] = .init()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let currentDate: Date = .now
        let currentHour: Int = calendar.component(.hour, from: currentDate)
        let currentDay: Int = calendar.component(.day, from: currentDate)
        let dateFormatter = isoDateFormatter(timeZone: timeZone)
        
        guard !hourly.time.isEmpty else {
            throw WeatherServiceError.invalidData(message: "Empty time data found.")
        }
        
        guard Set(
            [
                hourly.time.count,
                hourly.temperature_2m.count,
                hourly.weather_code.count
            ]
        ).count == 1 else {
            throw WeatherServiceError.invalidData(message: "Inconsistent data found.")
        }
        
        
        for index in 0..<hourly.time.count {
            guard let date = dateFormatter.date(from: hourly.time[index]) else {
                throw WeatherServiceError.invalidData(message: "Invalid date format found.")
            }
            
            let hour = calendar.component(.hour, from: date)
            let day = calendar.component(.day, from: date)
            
            if day == currentDay && hour <= currentHour {
                continue
            }
            
            let timeText = hourDescription(for: date, hour: hour, timeZone: timeZone)
            
            data.append(
                .init(
                    timeText: timeText,
                    weatherType: getWeatherType(for: hourly.weather_code[index], by: hourly.is_day[index] == 1),
                    temperature: Int(hourly.temperature_2m[index])
                )
            )
        }
        
        return Array(data.prefix(12))
    }
}

extension WeatherServiceRemote {
    private func isoDateFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = timeZone
        return formatter
    }

    private func dayDescription(for date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = timeZone
        formatter.dateFormat = "d MMM, EEEE"
        return formatter.string(from: date)
    }

    private func hourDescription(for date: Date, hour: Int, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = timeZone
        // "h" is a plain 12-hour digit (1…12). The previous format specifier
        // "j" is the locale-dependent stand-alone day period: on 24-hour
        // locales like French it yields no numeric hour at all, so the sheet
        // only rendered "AM"/"PM" with nothing beside it.
        formatter.dateFormat = "h"
        return "\(formatter.string(from: date)) \(hour >= 12 ? "PM" : "AM")"
    }

    private func getWeatherType(for code: Int) -> DailyWeatherType {
        return switch code {
        case let code where (0...1).contains(code):
                .sunny
        case let code where (2...48).contains(code):
                .cloudy
        case let code where ((51...67).contains(code) || (80...82).contains(code) || (95...99).contains(code)):
                .rainy
        case let code where (0...3).contains(code):
                .sunny
        case let code where (45...48).contains(code):
                .cloudy
        case let code where ((51...67).contains(code) || (80...82).contains(code) || (95...99).contains(code)):
                .rainy
        case let code where (71...77).contains(code) || (85...86).contains(code):
                .snow
        default:
                .undefined
        }
    }
    
    private func getWeatherType(for code: Int, by isDay: Bool) -> CurrentWeatherType {
        return switch code {
        case let code where (0...1).contains(code) && isDay:
            .day_sunny
        case let code where (2...48).contains(code) && isDay:
            .day_cloudy
        case let code where ((51...67).contains(code) || (80...82).contains(code) || (95...99).contains(code)) && isDay:
            .day_rainy
        case let code where (0...3).contains(code) && !isDay:
            .night_clear
        case let code where (45...48).contains(code) && !isDay:
            .night_cloudy
        case let code where ((51...67).contains(code) || (80...82).contains(code) || (95...99).contains(code)) && !isDay:
            .night_rainy
        case let code where (71...77).contains(code) || (85...86).contains(code):
            .snow
        default:
            .undefined
        }
    }
}
