//
//  OtherLocationsStore.swift
//  SkyWizard-SwiftUI
//
//  Created by Codex on 06/04/2026.
//

import Foundation
import Combine

struct SavedLocation: Codable, Identifiable, Hashable {
    let name: String
    let latitude: Double
    let longitude: Double

    var id: String {
        "\(name)-\(latitude)-\(longitude)"
    }
}

final class OtherLocationsStore: ObservableObject {
    @Published private(set) var savedLocations: [SavedLocation]

    private let defaults: UserDefaults
    private let storageKey: String

    init(defaults: UserDefaults = .standard, storageKey: String = "saved_locations") {
        self.defaults = defaults
        self.storageKey = storageKey
        self.savedLocations = Self.loadSavedLocations(from: defaults, key: storageKey)
    }

    func add(_ savedLocation: SavedLocation) {
        guard savedLocations.contains(savedLocation) == false else { return }
        savedLocations.append(savedLocation)
        persist()
    }

    func remove(_ savedLocation: SavedLocation) {
        savedLocations.removeAll { $0 == savedLocation }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(savedLocations) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private static func loadSavedLocations(from defaults: UserDefaults, key: String) -> [SavedLocation] {
        guard let data = defaults.data(forKey: key),
              let savedLocations = try? JSONDecoder().decode([SavedLocation].self, from: data) else {
            return []
        }

        return savedLocations
    }
}
