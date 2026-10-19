// AppSettings+Dependencies.swift
import Foundation
import Combine
import DependencyInjector

final class SettingsStore: ObservableObject, InjectableDependency {
    static var dependency: SettingsStore = .init()

    @Published var useCelsius: Bool

    init() {
        if UserDefaults.standard.object(forKey: "temperatureUseCelsius") != nil {
            self.useCelsius = UserDefaults.standard.bool(forKey: "temperatureUseCelsius")
        } else {
            self.useCelsius = true
        }
    }

    var unitSymbol: String {
        useCelsius ? "°C" : "°F"
    }
}

extension InjectableValues {
    var settingsStore: SettingsStore {
        get {
            SettingsStore.dependency
        } set {
            Self[SettingsStore.self] = newValue
        }
    }
}