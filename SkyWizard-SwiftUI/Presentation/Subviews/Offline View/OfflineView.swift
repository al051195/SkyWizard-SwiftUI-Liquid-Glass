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
            Color.clear
                .ignoresSafeArea()
                .opacity(0.9)
                .background(.ultraThinMaterial)
            VStack(spacing: 18) {
                    offlineImage
                    offlineText
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
                .foregroundStyle(.primary)
                .symbolEffect(.pulse, options: .speed(3).repeating)
                .padding()
                .glassEffect(.clear.tint(.orange).interactive())
                .shadow(color: .black.opacity(0.2), radius: 16)
    }
}

extension OfflineView {
    @ViewBuilder
    var offlineText: some View {
        Text("You are offline!")
            .font(.title3)
            .foregroundStyle(.primary)
            .padding()
            .glassEffect(in : .rect(cornerRadius: 32))
            .shadow(color: .black.opacity(0.14), radius: 16)
    }
    
}
#Preview {
    OfflineView()
}
