// DailyWeatherItem.swift
// SkyWizard-SwiftUI

// Created by Hishara Dilshan on 05/11/2024.

import SwiftUI
import SkyWizardModel


struct DailyWeatherItem: View {
    let weatherItem: DailyWeatherData
    
    @EnvironmentObject private var settings: SettingsStore
    
    var body: some View {
        HStack(spacing: 3) {
            Text(weatherItem.dateString)
                .font(.getFont(type: .medium, size: 17))
            Spacer()
            Image(weatherItem.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 28)
            tempLowView
            tempHighView
        }
        .foregroundStyle(.dayTitle)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
    }
}

extension DailyWeatherItem {
    var tempLowView: some View {
        Text("L \(weatherItem.tempLow)\(settings.unitSymbol)")
            .font(.getFont(type: .medium, size: 15))
            .fixedSize()
            .padding(.top, 5)
            .frame(minWidth: 58, alignment: .leading)
    }
    
    var tempHighView: some View {
        Text("H \(weatherItem.tempHigh)\(settings.unitSymbol)")
            .font(.getFont(type: .medium, size: 15))
            .fixedSize()
            .padding(.top, 5)
            .frame(minWidth: 58, alignment: .leading)
    }
}
