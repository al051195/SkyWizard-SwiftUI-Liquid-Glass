//
//  DuoInnerDisplay.swift
//  SkyWizard-SwiftUI
//
//  Created by Antoine LEPRETRE on 19/10/2026.
//

import SwiftUI

struct DuoInnerDisplayKey: EnvironmentKey {
    static var defaultValue: Bool = false
}

extension EnvironmentValues {
    /// `true` only on the iPhone Duo's inner display.
    ///
    /// Asks the display, not the device: the fold shows up in the display's
    /// reserved regions (`.division`, reported by `.includeInactive` even
    /// while the device is flat). Nothing on a standard iPhone or an iPad
    /// reports one, and the Duo's outer display is a separate screen that
    /// reports none either. Size classes alone cannot make this call — the
    /// iPad is regular in both classes, exactly like the inner display.
    var isDuoInnerDisplay: Bool {
        get { self[DuoInnerDisplayKey.self] }
        set { self[DuoInnerDisplayKey.self] = newValue }
    }
}

/// Measures the current display's reserved regions and injects
/// `isDuoInnerDisplay` into the whole hierarchy attached below it.
///
///     SomeRootView()
///         .duoInnerDisplayAware()
///
/// Always `false` before iOS 27.1 (no folding iPhone exists there).
struct DuoInnerDisplayModifier: ViewModifier {
    @State private var isDuoInnerDisplay = false

    func body(content: Content) -> some View {
        content
            .background {
                if #available(iOS 27.1, *) {
                    Color.clear
                        .onGeometryChange(for: Bool.self) { proxy in
                            !proxy.reservedRegions(kind: .division, options: .includeInactive).isEmpty
                        } action: { isDuoInner in
                            isDuoInnerDisplay = isDuoInner
                        }
                }
            }
            .environment(\.isDuoInnerDisplay, isDuoInnerDisplay)
    }
}

extension View {
    func duoInnerDisplayAware() -> some View {
        modifier(DuoInnerDisplayModifier())
    }
}
