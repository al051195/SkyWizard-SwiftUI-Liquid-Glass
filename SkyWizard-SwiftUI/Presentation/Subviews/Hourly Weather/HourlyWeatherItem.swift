// HourlyWeatherItem.swift
// SkyWizard-SwiftUI

// Created by Hishara Dilshan on 05/11/2024.

import SwiftUI
import SkyWizardModel


struct HourlyWeatherItem: View {
    let data: HourlyWeatherData
    
    @EnvironmentObject private var settings: SettingsStore
    
    init(hourlyWeatherData: HourlyWeatherData) {
        self.data = hourlyWeatherData
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text(data.timeText)
                .font(.getFont(type: .medium, size: 17))
                .foregroundStyle(.dayTitle)
            Image(data.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
            HStack(alignment: .top, spacing: 3) {
                Text("\(data.temperature)\(settings.unitSymbol)")
                    .font(.getFont(type: .medium, size: 20))
            }
            .foregroundStyle(.dayTitle)
        }
    }
}
