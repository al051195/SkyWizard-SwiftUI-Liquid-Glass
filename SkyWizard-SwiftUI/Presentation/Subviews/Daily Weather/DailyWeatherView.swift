//
//  DailyWeatherView.swift
//  SkyWizard-SwiftUI
//
//  Created by Hishara Dilshan on 04/11/2024.
//

import SwiftUI
import SkyWizardModel

struct DailyWeatherView: View {
    let weatherData: [DailyWeatherData]
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(weatherData) { weatherItem in
                DailyWeatherItem(weatherItem: weatherItem)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .frame(height: 260)
        .glassEffect(.clear .interactive() .tint(.white), in: .rect(cornerRadius: 30))
    }
}

#if DEBUG
#Preview {
    DailyWeatherView(weatherData: [.sample])
}
#endif

