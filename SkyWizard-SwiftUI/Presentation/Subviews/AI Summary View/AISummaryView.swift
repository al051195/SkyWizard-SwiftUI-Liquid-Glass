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
    
    @State private var showSheet = false
    
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
            HStack(alignment: .firstTextBaseline) {
                Text("AI Summary")
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
        //.glassEffect(.clear.tint(.white).interactive(), in: .rect(cornerRadius: 30))
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

struct ExpandedSummarySheet: View {
    let summary: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Summary")
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
