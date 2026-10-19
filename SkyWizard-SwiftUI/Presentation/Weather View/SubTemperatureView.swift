// SubTemperatureView.swift
// SkyWizard-SwiftUI

// Created by Hishara Dilshan on 05/11/2024.

import SwiftUI
import LiquidGlassText


struct SubTemperatureView: View {
    @Binding var temperature: Int
    @EnvironmentObject private var settings: SettingsStore
    
    var unitSymbol: String {
        settings.useCelsius ? "°C" : "°F"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            LiquidGlassText("\(temperature)",
                            glass: .clear.interactive().tint(.white.opacity(0.1)),
                size: 18,
                weight: .black,
                            design: .rounded
            )
            LiquidGlassText(unitSymbol,
                            glass: .clear.interactive().tint(.white.opacity(0.1)),
                size: 14,
                weight: .black,
                            design: .rounded
            )
                .padding(.top, 3)
        }
    }
}
