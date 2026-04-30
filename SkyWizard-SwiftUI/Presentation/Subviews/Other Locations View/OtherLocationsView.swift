//
//  OtherLocationsView.swift
//  SkyWizard-SwiftUI
//
//  Created by Codex on 06/04/2026.
//

import SwiftUI
import CoreLocation
import DependencyInjector
import SkyWizardService

struct OtherLocationsView: View {
    @StateObject private var otherLocationsStore = OtherLocationsStore()
    @State private var isAddLocationPresented: Bool = false

    @Injectable(\.weatherServiceRemote) private var weatherService: WeatherService
    @Injectable(\.geoCodingServiceRemote) private var geocodingService: GeocodingService
    @Injectable(\.locationServiceGps) private var locationService: LocationService
    @Injectable(\.networkReachabilityService) private var reachabilityService: ReachabilityService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Saved places")
                    .font(.getFont(type: .bold, size: 24))

                if otherLocationsStore.savedLocations.isEmpty {
                    emptyState
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(otherLocationsStore.savedLocations) { savedLocation in
                                SavedLocationCardView(
                                    savedLocation: savedLocation,
                                    weatherDataStore: makeWeatherDataStore()
                                ) {
                                    otherLocationsStore.remove(savedLocation)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Other Locations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddLocationPresented = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                }
            }
        }
        .sheet(isPresented: $isAddLocationPresented) {
            NavigationStack {
                AddLocationView(otherLocationsStore: otherLocationsStore)
            }
        }
    }
}

extension OtherLocationsView {
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No saved places yet")
                .font(.getFont(type: .semibold, size: 18))
            Text("Search for a city and save it to compare conditions beyond your current location.")
                .font(.getFont(type: .medium, size: 14))
            Button {
                isAddLocationPresented = true
            } label: {
                Text("Add a location")
                    .font(.getFont(type: .semibold, size: 15))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .glassEffect(.regular.interactive().tint(.cyan), in: .capsule)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 30))
    }

    private func makeWeatherDataStore() -> WeatherDataStore {
        WeatherDataStore(
            weatherService: weatherService,
            geocodingService: geocodingService,
            locationService: locationService,
            reachabilityService: reachabilityService
        )
    }
}

private struct SavedLocationCardView: View {
    let savedLocation: SavedLocation
    let onDelete: () -> Void

    @StateObject private var weatherDataStore: WeatherDataStore
    @State private var hasLoaded: Bool = false

    init(savedLocation: SavedLocation, weatherDataStore: @autoclosure @escaping () -> WeatherDataStore, onDelete: @escaping () -> Void) {
        self.savedLocation = savedLocation
        self.onDelete = onDelete
        _weatherDataStore = StateObject(wrappedValue: weatherDataStore())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text(savedLocation.name)
                    .font(.getFont(type: .bold, size: 20))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .center) {
                weatherDataStore.weatherTypeResource.weatherIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)

                Spacer()

                if weatherDataStore.weatherLoading {
                    ProgressView()
                        .tint(.dayTitle)
                } else {
                    HStack(alignment: .top, spacing: 2) {
                        Text("\(weatherDataStore.currentTemperature)")
                            .font(.getFont(type: .bold, size: 34))
                        Text("°")
                            .font(.getFont(type: .semibold, size: 18))
                            .padding(.top, 5)
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .padding(20)
        .frame(width: 220, height: 150, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 30))
        .task {
            guard hasLoaded == false else { return }
            hasLoaded = true
            weatherDataStore.loadWeather(
                for: CLLocationCoordinate2D(
                    latitude: savedLocation.latitude,
                    longitude: savedLocation.longitude
                )
            )
        }
    }
}

private struct AddLocationView: View {
    @ObservedObject var otherLocationsStore: OtherLocationsStore
    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var isSearching: Bool = false
    @State private var errorMessage: String?
    @State private var results: [LocationSearchResult] = []

    var body: some View {
    GlassEffectContainer(spacing: 10.0) {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                TextField("Search for a city", text: $query)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .font(.getFont(type: .medium, size: 16))
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .clipShape(.capsule(style: .continuous))
                    .glassEffect(.regular.interactive())

                Button("Search") {
                    Task {
                        await search()
                    }
                }
                .font(.getFont(type: .semibold, size: 16))
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .frame(height: 52)
                .glassEffect(.regular.interactive())
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.getFont(type: .medium, size: 13))
                    .foregroundStyle(.daySubTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if isSearching {
                Spacer()
                ProgressView()
                    .tint(.dayTitle)
                Spacer()
            } else if results.isEmpty {
                Spacer()
                Text("Search for a place to add it to your saved weather cards.")
                    .font(.getFont(type: .medium, size: 15))
                    .foregroundStyle(.daySubTitle)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                Spacer()
            } else {
                List(results) { result in
                    Button {
                        otherLocationsStore.add(
                            SavedLocation(
                                name: result.name,
                                latitude: result.latitude,
                                longitude: result.longitude
                            )
                        )
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.name)
                                .font(.getFont(type: .semibold, size: 16))
                            if let subtitle = result.subtitle {
                                Text(subtitle)
                                    .font(.getFont(type: .medium, size: 13))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .scrollContentBackground(.hidden)
                .background(.clear)
            }
        }
    }
        .padding(24)
        .navigationTitle("Add Location")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }

    @MainActor
    private func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else {
            errorMessage = "Enter a location name to search."
            results = []
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            let placemarks = try await CLGeocoder().geocodeAddressStringAsync(trimmedQuery)
            let mappedResults = placemarks.compactMap(LocationSearchResult.init)
            results = mappedResults
            if mappedResults.isEmpty {
                errorMessage = "No matching locations were found."
            }
        } catch {
            results = []
            errorMessage = "That place couldn't be found. Try a more specific search."
        }

        isSearching = false
    }
}

private struct LocationSearchResult: Identifiable {
    let name: String
    let subtitle: String?
    let latitude: Double
    let longitude: Double

    var id: String {
        "\(name)-\(latitude)-\(longitude)"
    }

    init?(placemark: CLPlacemark) {
        guard let location = placemark.location else { return nil }

        let primary = placemark.locality ?? placemark.name ?? placemark.administrativeArea ?? placemark.country
        guard let name = primary else { return nil }

        let secondary = [placemark.administrativeArea, placemark.country]
            .compactMap { $0 }
            .filter { $0 != name }
            .joined(separator: ", ")

        self.name = name
        self.subtitle = secondary.isEmpty ? nil : secondary
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }
}

private extension CLGeocoder {
    func geocodeAddressStringAsync(_ address: String) async throws -> [CLPlacemark] {
        try await withCheckedThrowingContinuation { continuation in
            geocodeAddressString(address) { placemarks, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: placemarks ?? [])
            }
        }
    }
}

