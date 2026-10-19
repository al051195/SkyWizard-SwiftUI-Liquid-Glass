// TemperatureUnit.swift
import Foundation

enum TemperatureUnit: String, CaseIterable {
    case celsius = "°C"
    case fahrenheit = "°F"
}

extension TemperatureUnit {
    static let defaultUnit: TemperatureUnit = .celsius
    
    func convert(_ celsius: Double) -> Double {
        switch self {
        case .celsius:
            return celsius
        case .fahrenheit:
            return celsius * 9 / 5 + 32
        }
    }
    
    var symbol: String { rawValue }
}
