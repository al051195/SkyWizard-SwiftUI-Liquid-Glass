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
<<<<<<< Updated upstream
                offlineImage
                Text("You are offline!")
                    .font(.title3)
                    .foregroundStyle(.white)
=======
                    offlineImage
                    offlineText
>>>>>>> Stashed changes
            }
        }
    }
}

extension OfflineView {
    @ViewBuilder
    var offlineImage: some View {
        if #available(iOS 17.0, *) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .resizable()
                .frame(width: 52, height: 52)
                .foregroundStyle(.white)
                .symbolEffect(.pulse, options: .speed(3).repeating)
<<<<<<< Updated upstream
        } else {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .resizable()
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
        }
=======
                .padding()
                .glassEffect(.clear.tint(.orange).interactive())
                .shadow(color: .black.opacity(0.2), radius: 16)
>>>>>>> Stashed changes
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
