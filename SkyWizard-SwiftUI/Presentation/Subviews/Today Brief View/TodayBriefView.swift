//
//  TodayBriefView.swift
//  SkyWizard-SwiftUI
//
//  Created by Antoine LEPRETRE on 22/10/2025.
//

import SwiftUI
import SkyWizardEnum
import SkyWizardModel

struct TodayBriefView: View {
    let today: DailyWeatherData
    let comparisonDay: DailyWeatherData?
    let realFeel: Int
    let hourlyData: [HourlyWeatherData]
    
    @State private var showSheet = false
    
    private func generateSummary() -> String {
        TodayBriefSummary(
            today: today,
            comparisonDay: comparisonDay,
            realFeel: realFeel,
            hourlyData: hourlyData
        ).text
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Today Brief")
                    .font(.getFont(type: .bold, size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Spacer(minLength: 8)

                Text("View more")
                    .font(.getFont(type: .light, size: 14))
                    .foregroundStyle(.primary)
                    .padding(8)
                    .glassEffect()
            }

            Text(generateSummary())
                .font(.getFont(type: .semibold, size: 14))
                .lineSpacing(4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .glassEffect(.clear.tint(.white.opacity(0.8)).interactive(), in: .rect(cornerRadius: 30))
        .padding(.horizontal, 25)
        .onTapGesture {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            ExpandedSummarySheet(summary: generateSummary())
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct TodayBriefSummary {
    let today: DailyWeatherData
    let comparisonDay: DailyWeatherData?
    let realFeel: Int
    let hourlyData: [HourlyWeatherData]
    
    var text: String {
        Array(sentences.prefix(3)).joined(separator: " ")
    }
    
    private var sentences: [String] {
        var result = [openingSentence]
        
        if let daypartSentence {
            result.append(daypartSentence)
        }
        
        if let realFeelSentence {
            result.append(realFeelSentence)
        }
        
        if let trendSentence, result.count < 3 {
            result.append(trendSentence)
        }
        
        return result
    }
    
    private var openingSentence: String {
        let condition = today.weatherType.conditionText()
        let range = temperatureRangeText
        
        return switch today.weatherType {
        case .sunny:
            "A \(condition) setup today, with \(range)."
        case .cloudy:
            "Clouds are hanging around today, keeping things \(condition) with \(range)."
        case .rainy:
            "Keep the umbrella close today: it's \(condition), with \(range)."
        case .snow:
            "Snow is the headline today, and temperatures run \(range)."
        case .undefined:
            "The sky is a little hard to read today, but temperatures sit \(range)."
        }
    }
    
    private var temperatureRangeText: String {
        "\(today.tempLow)°C to \(today.tempHigh)°C"
    }
    
    private var realFeelSentence: String? {
        let actualTemperature = representativeTemperature
        let delta = realFeel - actualTemperature
        
        guard abs(delta) > 3 else { return nil }
        
        if delta < 0 {
            return "It'll feel closer to \(realFeel)°C, so the wind chill may have a bit of bite."
        } else {
            return "It'll feel closer to \(realFeel)°C, so you'll probably notice the humidity in the air."
        }
    }
    
    private var representativeTemperature: Int {
        hourlyData.first?.temperature ?? ((today.tempHigh + today.tempLow) / 2)
    }
    
    private var daypartSentence: String? {
        let dayparts = groupedDayparts
        guard dayparts.count > 1 else { return nil }
        
        let ordered = Daypart.allCases.compactMap { daypart -> (Daypart, WeatherMood)? in
            guard let mood = dayparts[daypart] else { return nil }
            return (daypart, mood)
        }
        
        guard let first = ordered.first, let last = ordered.last, first.1 != last.1 else { return nil }
        
        return "\(first.0.name.capitalized) leans \(first.1.description), then \(last.0.name) turns \(last.1.description)."
    }
    
    private var groupedDayparts: [Daypart: WeatherMood] {
        var grouped: [Daypart: [WeatherMood]] = [:]
        
        for item in hourlyData {
            guard let daypart = Daypart(timeText: item.timeText) else { continue }
            grouped[daypart, default: []].append(WeatherMood(weatherType: item.weatherType))
        }
        
        return grouped.compactMapValues { moods in
            let counts = moods.reduce(into: [WeatherMood: Int]()) { counts, mood in
                counts[mood, default: 0] += 1
            }
            
            return counts.max { $0.value < $1.value }?.key
        }
    }
    
    private var trendSentence: String? {
        guard let comparisonDay else { return nil }
        
        let diff = today.tempHigh - comparisonDay.tempHigh
        
        if diff > 2 {
            return "Compared with the next day, today runs warmer, so lighter layers should do."
        } else if diff < -2 {
            return "Compared with the next day, today is cooler, so don't skip the extra layer."
        } else {
            return "Temperatures look pretty steady against the next day, without much of a swing."
        }
    }
}

private enum Daypart: CaseIterable, Hashable {
    case morning
    case afternoon
    case evening
    
    init?(timeText: String) {
        let text = timeText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let components = text.split(separator: " ")
        guard let hourText = components.first, var hour = Int(hourText) else { return nil }
        
        if text.contains("PM"), hour != 12 {
            hour += 12
        } else if text.contains("AM"), hour == 12 {
            hour = 0
        }
        
        switch hour {
        case 5..<12:
            self = .morning
        case 12..<17:
            self = .afternoon
        case 17..<24:
            self = .evening
        default:
            return nil
        }
    }
    
    var name: String {
        switch self {
        case .morning:
            return "morning"
        case .afternoon:
            return "afternoon"
        case .evening:
            return "evening"
        }
    }
}

private enum WeatherMood: Hashable {
    case clear
    case cloudy
    case rainy
    case snowy
    case unknown
    
    init(weatherType: CurrentWeatherType) {
        switch weatherType {
        case .day_sunny, .night_clear:
            self = .clear
        case .day_cloudy, .night_cloudy:
            self = .cloudy
        case .day_rainy, .night_rainy:
            self = .rainy
        case .snow:
            self = .snowy
        case .undefined:
            self = .unknown
        }
    }
    
    var description: String {
        switch self {
        case .clear:
            return "clear"
        case .cloudy:
            return "cloudier"
        case .rainy:
            return "rainy"
        case .snowy:
            return "snowy"
        case .unknown:
            return "uncertain"
        }
    }
}

struct ExpandedSummarySheet: View {
    let summary: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Today Brief")
                    .font(.getFont(type: .bold, size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(summary)
                    .font(.getFont(type: .semibold, size: 16))
                    .lineSpacing(5)
            }
            .padding(20)
        }
    }
}

#if DEBUG
#Preview("Today Brief - Sunny") {
    TodayBriefPreviewContainer(
        today: .init(dateString: "10 May, Sunday", tempHigh: 24, tempLow: 15, weatherType: .sunny),
        comparisonDay: nil,
        realFeel: 23,
        hourlyData: [
            .init(timeText: "9 AM", weatherType: .day_sunny, temperature: 18),
            .init(timeText: "1 PM", weatherType: .day_sunny, temperature: 23),
            .init(timeText: "6 PM", weatherType: .day_sunny, temperature: 20)
        ]
    )
}

#Preview("Today Brief - Rain Shift") {
    TodayBriefPreviewContainer(
        today: .init(dateString: "10 May, Sunday", tempHigh: 18, tempLow: 12, weatherType: .rainy),
        comparisonDay: .init(dateString: "11 May, Monday", tempHigh: 21, tempLow: 14, weatherType: .cloudy),
        realFeel: 13,
        hourlyData: [
            .init(timeText: "9 AM", weatherType: .day_cloudy, temperature: 16),
            .init(timeText: "2 PM", weatherType: .day_rainy, temperature: 17),
            .init(timeText: "7 PM", weatherType: .night_rainy, temperature: 14)
        ]
    )
}

#Preview("Today Brief - Snow") {
    TodayBriefPreviewContainer(
        today: .init(dateString: "10 May, Sunday", tempHigh: 2, tempLow: -4, weatherType: .snow),
        comparisonDay: .init(dateString: "11 May, Monday", tempHigh: 1, tempLow: -5, weatherType: .snow),
        realFeel: -6,
        hourlyData: [
            .init(timeText: "8 AM", weatherType: .snow, temperature: -2),
            .init(timeText: "12 PM", weatherType: .snow, temperature: 1),
            .init(timeText: "6 PM", weatherType: .night_cloudy, temperature: -3)
        ]
    )
}

#Preview("Today Brief - Cloudy Humid") {
    TodayBriefPreviewContainer(
        today: .init(dateString: "10 May, Sunday", tempHigh: 28, tempLow: 21, weatherType: .cloudy),
        comparisonDay: .init(dateString: "11 May, Monday", tempHigh: 28, tempLow: 20, weatherType: .cloudy),
        realFeel: 32,
        hourlyData: [
            .init(timeText: "10 AM", weatherType: .day_cloudy, temperature: 25),
            .init(timeText: "3 PM", weatherType: .day_cloudy, temperature: 28),
            .init(timeText: "8 PM", weatherType: .night_cloudy, temperature: 24)
        ]
    )
}

private struct TodayBriefPreviewContainer: View {
    let today: DailyWeatherData
    let comparisonDay: DailyWeatherData?
    let realFeel: Int
    let hourlyData: [HourlyWeatherData]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .init(hex: "#FFFCEF"),
                    .init(hex: "#EAE2B2")
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .ignoresSafeArea()
            
            TodayBriefView(
                today: today,
                comparisonDay: comparisonDay,
                realFeel: realFeel,
                hourlyData: hourlyData
            )
        }
    }
}
#endif
