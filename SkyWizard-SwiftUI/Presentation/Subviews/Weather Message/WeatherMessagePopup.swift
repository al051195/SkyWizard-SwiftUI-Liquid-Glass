//
//  WeatherMessagePopup.swift
//  SkyWizard-SwiftUI
//
//  Created by Hishara Dilshan on 15/11/2024.
//

import SwiftUI

struct WeatherMessagePopup: View {
    let message: String
    @Binding var isPresent: Bool
    @State private var showPopup = false
    
    var body: some View {
        ZStack {
            if showPopup {
                HStack(spacing: 14) {
                    Image(.wizardFace)
                        .resizable()
                        .frame(width: 60, height: 60)
                    Text(message)
                        .foregroundStyle(.daySubTitle)
                        .font(.getFont(type: .medium, size: 14))
                        .multilineTextAlignment(.leading)
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.3)) {
                            showPopup = false
                            isPresent = false
                        }
                    } label: {
                        Circle()
                            .foregroundStyle(.gray.opacity(0.25))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "multiply")
                                    .foregroundStyle(.daySubTitle)
                            }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .glassEffect(.clear.interactive().tint(.white.opacity(0.55)), in: .rect(cornerRadius: 40))
                .shadow(radius: 24)
                .padding(.bottom, 40)
                .padding(.horizontal, 28)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom)
                            .combined(with: .scale(scale: 0.8))
                            .combined(with: .opacity)
                            .animation(.spring(response: 0.55, dampingFraction: 0.55, blendDuration: 0.25)),
                        removal: .scale(scale: 0.9)
                            .combined(with: .opacity)
                            .animation(.spring(response: 0.45, dampingFraction: 0.75, blendDuration: 0.2))
                    )
                )
                .zIndex(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: isPresent) { newValue in
            withAnimation(.spring(response: 0.55, dampingFraction: 0.55, blendDuration: 0.25)) {
                showPopup = newValue
            }
        }
        .onAppear {
            if isPresent {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.55, blendDuration: 0.25)) {
                    showPopup = true
                }
            }
        }
    }
}

fileprivate struct WeatherMessagePopupWrapper: View {
    @State var message = "Rain's embrace awaits, take your umbrella."
    @State var isPresent: Bool = true
    
    var body: some View {
        ZStack {
            // Background to make glass visible
            LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            WeatherMessagePopup(message: message, isPresent: $isPresent)
                .opacity(isPresent ? 1 : 0)
        }
    }
}

#Preview {
    WeatherMessagePopupWrapper()
}


