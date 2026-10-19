//
//  CompactScreenMetrics.swift
//  SkyWizard-SwiftUI
//
//  Created by Antoine LEPRETRE on 11/09/2026.
//

import SwiftUI

/// Threshold used to single out the small-screen iPhones. iPhone SE (2nd/3rd
/// gen), iPhone 6/7/8 and every "mini" model report a 375pt wide portrait
/// screen, while regular iPhones start at 390pt.
enum CompactScreen {
    static let compactWidthThreshold: CGFloat = 380
}

struct CompactScreenKey: EnvironmentKey {
    static var defaultValue: Bool = false
}

extension EnvironmentValues {
    /// `true` on the small-screen iPhones (SE and mini), `false` on the
    /// regular and larger iPhones.
    var isCompactScreen: Bool {
        get { self[CompactScreenKey.self] }
        set { self[CompactScreenKey.self] = newValue }
    }
}

/// Measures the available width and injects `isCompactScreen` in the
/// environment so the whole hierarchy can adapt to the SE/mini lineup.
struct CompactScreenAwareModifier: ViewModifier {
    @State private var isCompact = false

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { isCompact = proxy.size.width <= CompactScreen.compactWidthThreshold }
                        .onChange(of: proxy.size.width) { _, newWidth in
                            isCompact = newWidth <= CompactScreen.compactWidthThreshold
                        }
                }
            }
            .environment(\.isCompactScreen, isCompact)
    }
}

extension View {
    func compactScreenAware() -> some View {
        modifier(CompactScreenAwareModifier())
    }
}