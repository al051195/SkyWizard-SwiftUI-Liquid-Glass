//
//  OtherLocationsView.swift
//  SkyWizard-SwiftUI
//
//  Created by Codex on 06/04/2026.
//

import SwiftUI
import CoreLocation
import DependencyInjector
import SkyWizardModel
import SkyWizardService

struct OtherLocationsView: View {
    @StateObject private var otherLocationsStore = OtherLocationsStore()
    @State private var isAddLocationPresented: Bool = false
    @State private var savedLocationsWidth: CGFloat = 0

    @Injectable(\.weatherServiceRemote) private var weatherService: WeatherService
    @Injectable(\.geoCodingServiceRemote) private var geocodingService: GeocodingService
    @Injectable(\.locationServiceGps) private var locationService: LocationService
    @Injectable(\.networkReachabilityService) private var reachabilityService: ReachabilityService
    @Injectable(\.settingsStore) private var settingsStore: SettingsStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Saved places")
                    .font(.getFont(type: .bold, size: 24))

                if otherLocationsStore.savedLocations.isEmpty {
                    emptyState
                } else {
                    savedLocationsList
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
    /// Saved-location cards. On wide containers — the iPhone Duo inner
    /// display in landscape, the iPad in landscape — the cards reflow into a
    /// two-column grid whose gutter sits over the fold; portrait and every
    /// standard iPhone keep the single column.
    private var savedLocationsList: some View {
        LazyVGrid(columns: savedLocationColumns, spacing: 16) {
            ForEach(otherLocationsStore.savedLocations) { savedLocation in
                SavedLocationCardView(
                    savedLocation: savedLocation,
                    weatherDataStore: makeWeatherDataStore()
                ) {
                    otherLocationsStore.remove(savedLocation)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            savedLocationsWidth = newWidth
        }
    }

    /// Two columns need roughly 2 x 330 pt of card plus the gutter; below
    /// that every portrait iPhone and the Duo inner display's portrait pose
    /// show one column, exactly as before.
    private var savedLocationColumns: [GridItem] {
        let columnCount = savedLocationsWidth >= 700 ? 2 : 1
        return Array(repeating: .init(.flexible(), spacing: 16), count: columnCount)
    }

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
                    .glassEffect(.clear.interactive().tint(.cyan), in: .capsule)
                    .shadow(color: .cyan.opacity(0.35), radius: 20)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 33))
    }

    private func makeWeatherDataStore() -> WeatherDataStore {
        WeatherDataStore(
            weatherService: weatherService,
            geocodingService: geocodingService,
            locationService: locationService,
            reachabilityService: reachabilityService,
            settingsStore: settingsStore
        )
    }
}

private struct SavedLocationCardView: View {
    let savedLocation: SavedLocation
    let onDelete: () -> Void

    @StateObject private var weatherDataStore: WeatherDataStore
    @State private var hasLoaded: Bool = false
    @State private var isDetailPresented: Bool = false

    init(savedLocation: SavedLocation, weatherDataStore: @autoclosure @escaping () -> WeatherDataStore, onDelete: @escaping () -> Void) {
        self.savedLocation = savedLocation
        self.onDelete = onDelete
        _weatherDataStore = StateObject(wrappedValue: weatherDataStore())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerView
            summaryButton
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 166, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 33))
        .sheet(isPresented: $isDetailPresented) {
            SavedLocationForecastDetailView(
                savedLocation: savedLocation,
                weatherDataStore: weatherDataStore
            )
            .environmentObject(SettingsStore.dependency)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
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

private extension SavedLocationCardView {
    var headerView: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                isDetailPresented = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(savedLocation.name)
                        .font(.getFont(type: .bold, size: 22))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(weatherDataStore.weatherLoading ? "Loading forecast" : conditionText)
                        .font(.getFont(type: .medium, size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.primary)
                    .frame(width: 22, height: 22)
                    .glassEffect(.regular.interactive())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete \(savedLocation.name)")
        }
    }

    var summaryButton: some View {
        Button {
            isDetailPresented = true
        } label: {
            Group {
                if weatherDataStore.weatherLoading {
                    loadingSummary
                } else {
                    loadedSummary
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    var loadingSummary: some View {
        HStack(spacing: 14) {
            ProgressView()
                .tint(.dayTitle)
                .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.primary.opacity(0.16))
                    .frame(width: 130, height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(.primary.opacity(0.1))
                    .frame(width: 190, height: 12)
            }

            Spacer()
        }
        .padding(.top, 8)
    }

    var loadedSummary: some View {
        HStack(alignment: .center, spacing: 16) {
            weatherDataStore.weatherTypeResource.weatherIcon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    temperatureText(weatherDataStore.currentTemperature)
                        .font(.getFont(type: .bold, size: 34))
                        .foregroundStyle(.primary)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: -1))
                    if let today {
                        weatherMetric("H", temperatureLabel(today.tempHigh))
                        weatherMetric("L", temperatureLabel(today.tempLow))
                    }

                    if let nextHour = weatherDataStore.hourlyWeatherData.first {
                        weatherMetric(nextHour.timeText, temperatureLabel(nextHour.temperature))
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }

    var today: DailyWeatherData? {
        weatherDataStore.dailyWeatherData.first
    }

    var conditionText: String {
        today?.weatherType.conditionText().capitalized ?? "Forecast ready"
    }

    func temperatureText(_ value: Int) -> Text {
        Text("\(value)")
            + Text("°")
            .font(.getFont(type: .semibold, size: 20))
    }

    func temperatureLabel(_ value: Int) -> String {
        "\(value)°"
    }

    func weatherMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.getFont(type: .medium, size: 11))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.getFont(type: .semibold, size: 14))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14))
    }
}

private struct SavedLocationForecastDetailView: View {
    let savedLocation: SavedLocation
    @ObservedObject var weatherDataStore: WeatherDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var sunScrubProgress: CGFloat?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if weatherDataStore.weatherLoading {
                        loadingState
                    } else if let today = weatherDataStore.dailyWeatherData.first {
                        forecastContent(today: today)
                    } else {
                        unavailableState
                    }
                }
                .padding(.vertical, 20)
            }
            .navigationTitle(savedLocation.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheetToolbarHorizontal()
        }
    }
}

private extension SavedLocationForecastDetailView {
    var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(.dayTitle)
            Text("Loading forecast...")
                .font(.getFont(type: .semibold, size: 16))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
    }

    var unavailableState: some View {
        VStack(spacing: 10) {
            Image(systemName: "cloud.slash")
                .font(.system(size: 34, weight: .semibold))
            Text("Forecast unavailable")
                .font(.getFont(type: .bold, size: 18))
            Text("Weather details for this saved place are not ready yet.")
                .font(.getFont(type: .medium, size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 260)
    }

    func forecastContent(today: DailyWeatherData) -> some View {
        let comparisonDay = weatherDataStore.dailyWeatherData.dropFirst().first

        return VStack(spacing: 18) {
            TodayBriefView(
                today: today,
                comparisonDay: comparisonDay,
                realFeel: weatherDataStore.realFeel,
                hourlyData: weatherDataStore.hourlyWeatherData
            )

            WeatherInsightCardsRow(
                hourlyData: weatherDataStore.hourlyWeatherData,
                windSpeed: weatherDataStore.currentWindSpeed,
                windSpeedUnit: weatherDataStore.currentWindSpeedUnit,
                windDirection: weatherDataStore.currentWindDirection
            )

            HourlyWeatherView(hourlyData: weatherDataStore.hourlyWeatherData)
                .padding(.horizontal, 25)

            DailyWeatherView(weatherData: weatherDataStore.dailyWeatherData)
                .padding(.horizontal, 25)

            SunriseSunsetGraphView(
                sunrise: today.sunrise,
                sunset: today.sunset,
                timeZone: today.timeZone,
                scrubProgress: $sunScrubProgress
            )
            .padding(.horizontal, 25)
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
        .sheetToolbarHorizontal()
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


#Preview(body: {
    OtherLocationsView()
        .environmentObject(SettingsStore.dependency)

}
)
