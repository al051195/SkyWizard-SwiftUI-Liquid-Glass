//
//  SubTemperatureView.swift
//  SkyWizard-SwiftUI
//
//  Created by Hishara Dilshan on 05/11/2024.
//

import SwiftUI
import LiquidGlassText

struct SubTemperatureView: View {
    @Binding var temperature: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            LiquidGlassText("\(temperature)",
                            glass: .clear.interactive().tint(.white.opacity(0.1)),
                size: 18,
                weight: .black,
                            design: .rounded
            )
            LiquidGlassText("0",
                            glass: .clear.interactive().tint(.white.opacity(0.1)),
                size: 10,
                weight: .black,
                            design: .rounded
            )
            LiquidGlassText("C",
                            glass: .clear.interactive().tint(.white.opacity(0.1)),
                size: 14,
                weight: .black,
                            design: .rounded
            )
                .padding(.top, 3)
        }
    }
}
