// Wind&RainInsightsView.swift
// SkyWizard-SwiftUI

// Created by Antoine LEPRETRE on 19/10/2026.

import SwiftUI
import SkyWizardEnum
import SkyWizardModel

/// The two quick-read glass tiles shown right after the Today Brief, side by
/// side everywhere the forecast content renders: the drag-up sheet on phones,
/// the details pane of the Duo's arrangement and the Other Locations sheet.
/// Unlike the wide cards around them they are rounded squares.
struct WeatherInsightCardsRow: View {
    let hourlyData: [HourlyWeatherData]
    let windSpeed: Int
    let windSpeedUnit: String
    /// Meteorological wind direction in degrees, 0 = coming from the north.
    let windDirection: Int

    private var upcomingHours: [HourlyWeatherData] {
        Array(hourlyData.prefix(4))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RainNextHourCard(upcomingHours: upcomingHours)
            WindCard(
                speed: windSpeed,
                speedUnit: windSpeedUnit,
                direction: windDirection
            )
        }
        .padding(.horizontal, 25)
    }
}

// MARK: - Rain

private struct RainNextHourCard: View {
    let upcomingHours: [HourlyWeatherData]

    var body: some View {
        insightTile(title: "Rain next hour") {
            Image(nextWeather.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 34)

            Text(headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.85)

            Text(caption)
                .font(.getFont(type: .medium, size: 13))
                .foregroundStyle(.daySubTitle)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
    }

    /// The first falling hour in the window counts as "rain expected"; when
    /// nothing falls inside the window the tile reads dry.
    private var nextFallingHour: HourlyWeatherData? {
        upcomingHours.first { $0.weatherType.isFalling }
    }

    private var nextWeather: HourlyWeatherData {
        nextFallingHour ?? upcomingHours.first ?? HourlyWeatherData(
            timeText: "",
            weatherType: .day_sunny,
            temperature: 0
        )
    }

    private var headline: String {
        guard let falling = nextFallingHour else { return "No rain expected" }
        switch falling.weatherType {
        case .snow: return "Snow expected"
        default: return "Rain expected"
        }
    }

    private var caption: String {
        guard let falling = nextFallingHour else {
            return upcomingHours.count <= 1 ? "dry for the next hour" : "dry for the next \(upcomingHours.count) hours"
        }
        return "around \(falling.timeText)"
    }
}

// MARK: - Wind

private struct WindCard: View {
    let speed: Int
    let speedUnit: String
    let direction: Int

    var body: some View {
        insightTile(title: "Wind") {
            speedView

            glassCompass

            Text(compassText)
                .font(.getFont(type: .medium, size: 13))
                .foregroundStyle(.daySubTitle)
        }
    }

    private var speedView: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(speed)")
                .font(.getFont(type: .medium, size: 24))

            Text(speedUnit)
                .font(.getFont(type: .bold, size: 14))
                .foregroundStyle(.dayTitle)
        }
    }

    /// A compass face in a clear glass disc: a fixed north marker and his
    /// three side ticks, plus a needle rotated so its tip points where the
    /// wind blows (Apple Weather's convention), away from the direction the
    /// text below names. The glass is the system's `glassEffect` — the same
    /// clear interactive style the app's round buttons use — not a material.
    private var glassCompass: some View {
        ZStack {
            // Fixed dial: N marker at the top, smaller ticks E/S/W.
            Text("N")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.daySubTitle)
                .offset(y: -23)
            Text("S")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.daySubTitle)
                .offset(y: 23)
            Text("W")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.daySubTitle)
                .offset(x: -23)
            Text("E")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.daySubTitle)
                .offset(x: 23)
            HorizontalTick.offset(x: 15, y: 0)
            VerticalTick.offset(x: 0, y: -15)
            VerticalTick.offset(x: 0, y: 15)
            HorizontalTick.offset(x: -15, y: 0)

            // Needle: bright tip towards where the wind blows, muted tail
            // back towards where it comes from, hub at the centre.
            ZStack {
                Capsule()
                    .frame(width: 2.5, height: 14)
                    .foregroundStyle(.orange)
                    .offset(y: -10)
                Capsule()
                    .frame(width: 2.5, height: 10)
                    .foregroundStyle(.daySubTitle.opacity(0.45))
                    .offset(y: 8)
                Circle()
                    .frame(width: 2.5, height: 2.5)
                    .glassEffect(.regular, in: .circle)
                    .shadow(color: .black.opacity(0.2), radius: 4)
            }
            .rotationEffect(.degrees(Double((direction + 180) % 360)))
        }
        .frame(width: 64, height: 64)
        .glassEffect(.regular, in: .circle)
        .shadow(color: .black.opacity(0.1), radius: 8)
    }

    private var VerticalTick: some View {
        Capsule()
            .frame(width: 1.5, height: 5)
            .foregroundStyle(.daySubTitle.opacity(0.55))
    }
    
    private var HorizontalTick: some View {
        Capsule()
            .frame(width: 5, height: 1.5)
            .foregroundStyle(.daySubTitle.opacity(0.55))
    }

    private var compassText: String {
        "from \(WindCompass.code(for: direction))"
    }
}

// MARK: - Shared pieces

private struct InsightTile<Tile: View>: ViewModifier {
    let title: String
    @ViewBuilder let tile: () -> Tile

    func body(content: Content) -> some View {
        VStack(spacing: 4) {
            Spacer()
            tile()
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .glassEffect(.regular, in: .rect(cornerRadius: 33))
    }
}

private extension View {
    func insightTile(
        title: String,
        @ViewBuilder tile: @escaping () -> some View
    ) -> some View {
        modifier(InsightTile(title: title, tile: tile))
    }
}

/// 16-point compass code for a meteorological direction in degrees.
enum WindCompass {
    private static let points = [
        "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
        "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"
    ]

    static func code(for degrees: Int) -> String {
        let normalized = ((degrees % 360) + 360) % 360
        let index = Int((Double(normalized) + 11.25) / 22.5) % points.count
        return points[index]
    }
}

private extension CurrentWeatherType {
    /// Precipitation is falling during this hour.
    var isFalling: Bool {
        switch self {
        case .day_rainy, .night_rainy, .snow:
            return true
        default:
            return false
        }
    }
}

#if DEBUG
#Preview("Insight Cards") {
    WeatherInsightCardsRow(
        hourlyData: [
            .init(timeText: "9 AM", weatherType: .day_rainy, temperature: 18),
            .init(timeText: "10 AM", weatherType: .day_rainy, temperature: 18),
            .init(timeText: "11 AM", weatherType: .day_cloudy, temperature: 19),
            .init(timeText: "12 PM", weatherType: .day_sunny, temperature: 20)
        ],
        windSpeed: 14,
        windSpeedUnit: "km/h",
        windDirection: 138
    )
    .padding(.top, 60)
    .background(
        LinearGradient(
            colors: [.init(hex: "#E5E5E5"), .init(hex: "#291888")],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
        .ignoresSafeArea()
    )
    .environmentObject(SettingsStore.dependency)
}
#endif
