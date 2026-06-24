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
    
    var body: some View {
        ZStack {
            ZStack {
                HStack(spacing: 14) {
                    Image(.wizardFace)
                        .resizable()
                        .frame(width: 60, height: 60)
                    Text(self.message)
                        .foregroundStyle(.daySubTitle)
                        .font(.getFont(type: .medium, size: 14))
                    Button {
                        withAnimation {
                            isPresent.toggle()
                        }
                    } label: {
                        Circle()
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "xmark")
                                    .foregroundStyle(.daySubTitle)
                            }
                            .glassEffect(.clear.interactive())
                    }
<<<<<<< Updated upstream
                    
                }
                .padding(.horizontal, 4)
=======
                    .shadow(color: .black.opacity(0.24), radius: 12)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .glassEffect(.clear.tint(.white.opacity(0.4)), in: .rect(cornerRadius: 40))
                .shadow(radius: 9)
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
>>>>>>> Stashed changes
            }
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 40)
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 40)
            .padding(.horizontal, 28)
            .shadow(radius: 6)
            .drawingGroup()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

fileprivate struct WeatherMessagePopupWrapper: View {
    @State var message = "Rain's embrace awaits, take your umbrella."
    @State var isPresent: Bool = true
    
    var body: some View {
        ZStack {
            Color.gray
            WeatherMessagePopup(message: message, isPresent: $isPresent)
                .opacity(isPresent ? 1 : 0)
        }

        .ignoresSafeArea()
    }
}

#Preview {
    WeatherMessagePopupWrapper()
}
