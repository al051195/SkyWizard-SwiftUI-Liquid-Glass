//
//  AISummaryView.swift
//  SkyWizard-SwiftUI
//
//  Created by Antoine LEPRETRE on 22/10/2025.
//

import SwiftUI
import SkyWizardEnum
import SkyWizardModel

struct AISummaryView: View {
    let today: DailyWeatherData
    let yesterday: DailyWeatherData?
    
    private func generateSummary() -> String {
        let condition = today.weatherType.conditionText()
        let minTemp = today.tempLow
        let maxTemp = today.tempHigh
        
        // Compare to yesterday’s data, if available
        if let yesterday {
            let diff = today.tempHigh - yesterday.tempHigh
            let trend: String
            if diff > 2 {
                trend = "slightly warmer than yesterday"
            } else if diff < -2 {
                trend = "cooler than yesterday"
            } else {
                trend = "similar to yesterday"
            }
            
            return "Expect a \(condition) day, \(trend), with temperatures ranging from \(minTemp)°C to \(maxTemp)°C."
        } else {
            return "Expect a \(condition) day with temperatures between \(minTemp)°C and \(maxTemp)°C."
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Summary")
                .font(.getFont(type: .bold, size: 20))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

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
        .glassEffect(.clear.tint(.white).interactive(), in: .rect(cornerRadius: 30))
        .padding(.horizontal, 25)
    }
}

