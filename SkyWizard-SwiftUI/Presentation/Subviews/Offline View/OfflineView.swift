//
//  OfflineView.swift
//  SkyWizard-SwiftUI
//
//  Created by Hishara Dilshan on 14/11/2024.
//

import SwiftUI

struct OfflineView: View {
    var body: some View {
        ZStack {
            Color.daySubTitle
                .ignoresSafeArea()
                .opacity(0.9)
            VStack(spacing: 18) {
                offlineImage
                Text("You are offline!")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding()
                    .glassEffect(in : .rect(cornerRadius: 26))
            }
        }
    }
}

extension OfflineView {
    @ViewBuilder
    var offlineImage: some View {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .resizable()
                .frame(width: 52, height: 52)
                .foregroundStyle(.white)
                .symbolEffect(.pulse, options: .speed(3).repeating)
                .padding()
                .glassEffect(.clear.tint(.orange).interactive())
    }
}

#Preview {
    OfflineView()
}
