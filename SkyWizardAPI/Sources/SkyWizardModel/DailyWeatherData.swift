//
//  DailyWeatherData.swift
//  SkyWizard-SwiftUI
//
//  Created by Hishara Dilshan on 05/11/2024.
//

import Foundation
import SkyWizardEnum

public struct DailyWeatherData: Identifiable, @unchecked Sendable {
    public let id: UUID = UUID()
    public let dateString: String
    public let tempHigh: Int
    public let tempLow: Int
    public let weatherType: DailyWeatherType
    public let sunrise: Date?
    public let sunset: Date?
    public let timeZone: TimeZone

    #if DEBUG
    public static let sample: Self = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return .init(
            dateString: "12 Oct, Friday",
            tempHigh: 24,
            tempLow: 18,
            weatherType: .sunny,
            sunrise: calendar.date(byAdding: .hour, value: 6, to: today),
            sunset: calendar.date(byAdding: .hour, value: 18, to: today)
        )
    }()
    #endif

    public init(dateString: String, tempHigh: Int, tempLow: Int, weatherType: DailyWeatherType, sunrise: Date? = nil, sunset: Date? = nil, timeZone: TimeZone = .current) {
        self.dateString = dateString
        self.tempHigh = tempHigh
        self.tempLow = tempLow
        self.weatherType = weatherType
        self.sunrise = sunrise
        self.sunset = sunset
        self.timeZone = timeZone
    }
}

extension DailyWeatherData {
    public var icon: String {
        switch weatherType {
        case .sunny: return "forecast_ic_sunny"
        case .cloudy: return "forecast_ic_cloudy"
        case .rainy: return "forecast_ic_rainy"
        case .snow: return "forecast_ic_snow"
        case .undefined: return "forecast_ic_sunny"
        }
    }
}
