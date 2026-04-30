//
//  AppRoutes.swift
//  SkyWizard-SwiftUI
//
//  Created by Hishara Dilshan on 15/11/2024.
//

import Foundation
import SwiftUI

enum AppRoute: Hashable {
    case about
    case otherLocations
    case settings
}

extension AppRoute {
    @ViewBuilder
    var content: some View {
        switch self {
        case .about:
            AboutAppView()
        case .otherLocations:
            OtherLocationsView()
        case .settings:
            ChangeAppIconView()
        }
    }
}

