//
//  SunriseSunsetData.swift
//  SkyWizard-SwiftUI
//
//  Created by Antoine LEPRETRE on 06/09/2026.
//

import Foundation

public struct SunriseSunsetData: @unchecked Sendable {
    public let sunrise: Date
    public let sunset: Date
    public let dayLength: TimeInterval

    public init(sunrise: Date, sunset: Date) {
        self.sunrise = sunrise
        self.sunset = sunset
        self.dayLength = sunset.timeIntervalSince(sunrise)
    }

    #if DEBUG
    public static let sample: Self = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return .init(
            sunrise: calendar.date(byAdding: .hour, value: 6, to: today)!,
            sunset: calendar.date(byAdding: .hour, value: 18, to: today)!
        )
    }()
    #endif
}
