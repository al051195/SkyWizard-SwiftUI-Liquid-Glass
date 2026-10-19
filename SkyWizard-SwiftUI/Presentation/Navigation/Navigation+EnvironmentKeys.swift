// Navigation+EnvironmentKeys.swift
// SkyWizard-SwiftUI

// Created by Hishara Dilshan on 15/11/2024.

import Foundation
import SwiftUI

struct NavigationHandler {
    let callback: (AppRoute) -> Void
    
    func callAsFunction(route: AppRoute) {
        callback(route)
    }
}

struct NavigationHandlerKey: EnvironmentKey {
    static var defaultValue: NavigationHandler = .init { _ in }
}

struct SettingsStoreKey: EnvironmentKey {
    static var defaultValue: SettingsStore = SettingsStore.dependency
}

extension EnvironmentValues {
    var navigation: NavigationHandler {
        get {
            self[NavigationHandlerKey.self]
        }
        
        set {
            self[NavigationHandlerKey.self] = newValue
        }
    }
    
    var settingsStore: SettingsStore {
        get {
            self[SettingsStoreKey.self]
        }
        
        set {
            self[SettingsStoreKey.self] = newValue
        }
    }
}
