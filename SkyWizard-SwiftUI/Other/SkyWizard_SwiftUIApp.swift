// SkyWizard_SwiftUIApp.swift
// SkyWizard-SwiftUI

// Created by Hishara Dilshan on 07/10/2024.

import SwiftUI
import DependencyInjector

@main
struct SkyWizard_SwiftUIApp: App {
    @Injectable(\.weatherDataStore) var weatherDataStore: WeatherDataStore
    
    @State var routes: [AppRoute] = .init()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $routes) {
                ReleaseNotesPresenter {
                    WeatherView()
                        .environmentObject(weatherDataStore)
                        .environmentObject(SettingsStore.dependency)
                        .environment(\.navigation, .init(callback: { route in
                            self.routes.append(route)
                        }))
                }
            }
            .compactScreenAware()
            // Injects `isDuoInnerDisplay` above the app's views so wrapper
            // readers see it; an injection inside WeatherView itself would
            // not reach WeatherView's own `@Environment` wrappers.
            .duoInnerDisplayAware()
        }
    }
}
