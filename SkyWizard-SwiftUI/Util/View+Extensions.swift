//
//  View+Extensions.swift
//  SkyWizard-SwiftUI
//
//  Created by Hishara Dilshan on 07/11/2024.
//

import Foundation
import SwiftUI

extension View {
    /// iPhone Duo opt-out for sheet toolbars. On the outer display a sheet's
    /// toolbar bar is vertical by default, and a title-only item such as the
    /// close button below does not present vertically. Sheets whose only bar
    /// item is Close keep the familiar horizontal look instead. No-op below
    /// iOS 27.1 (deployment target is iOS 26) and wherever the bar is
    /// already horizontal — incl. every standard iPhone and the inner
    /// display's centred sheets.
    @ViewBuilder
    func sheetToolbarHorizontal() -> some View {
        if #available(iOS 27.1, *) {
            self.toolbarVerticalBehavior(.disabled)
        } else {
            self
        }
    }
}

extension View {
    func errorAlert(error: Binding<Error?>, buttonTitle: String = "OK") -> some View {
        let localizedAlertError = LocalizedAlertError(error: error.wrappedValue)
        return alert(isPresented: .constant(localizedAlertError != nil), error: localizedAlertError) { _ in
            Button(buttonTitle) {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.errorDescription ?? "")
        }
    }
}
