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
    case settings
}

extension AppRoute {
    @ViewBuilder
    var content: some View {
        switch self {
        case .about:
            AboutAppView()
        case .settings:
            ChangeAppIconView() // ou ChangeAppIconView() si c’est ce que tu veux
        }
    }
}

