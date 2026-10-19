//
//  ContentView.swift
//  SkyWizard-SwiftUI
//
//  Created by Hishara Dilshan on 07/10/2024.
//

import SwiftUI
import Lottie
import SceneKit
import DependencyInjector
import SkyWizardEnum
import LiquidGlassText

struct WeatherView: View {
    @State private var isPresented: Bool = false
    @State private var isGreetingPresented: Bool = false
    @State private var sunScrubProgress: CGFloat?
    @EnvironmentObject private var weatherDataStore: WeatherDataStore
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.navigation) var navigation
    
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    @Environment(\.isCompactScreen) private var isCompactScreen
    var isOnIpad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    
    @ViewBuilder
    var weatherLayout: some View {
        if #available(iOS 27.1, *), usesArrangement {
            arrangementLayout
        } else {
            mainContent
        }
    }
    
    /// The iPhone Duo's inner display and the iPad are regular in both size
    /// classes in every pose. Those get the two-pane weather screen, which the
    /// arrangement adjusts live as the device folds. Every other container —
    /// all standard iPhones, and the Duo's outer display, both being compact
    /// width — keeps the single-column scene with the drag-up sheet.
    private var usesArrangement: Bool {
        isOnIpad
    }
    
    var body: some View {
        ZStack {
            weatherLayout
            
            if weatherDataStore.weatherLoading {
                weatherLoadingView
            }
            
            if !weatherDataStore.isOnline {
                OfflineView()
            }
        }
        .duoLayoutProbe("home")
        .navigationTitle("Weather")
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: {
            weatherDataStore.loadWeather()
        })
        .animation(.easeInOut, value: weatherDataStore.currentWeatherType)
        .onTapGesture {
            guard isPresented else { return }
            withAnimation {
                isPresented.toggle()
            }
        }
        .onChange(of: weatherDataStore.greetingMessage) { _ in
            withAnimation {
                isGreetingPresented = true
            }
        }
        .navigationDestination(for: AppRoute.self) { route in
            route.content
        }
    }
}

// MARK: - View Components
extension WeatherView {
    /// The phone layout: full-bleed scene behind a drag-up sheet. Unchanged on
    /// every standard iPhone and the Duo's outer display; on the inner display
    /// the sheet just fills the whole width now instead of stopping at a cap.
    private var mainContent: some View {
        ZStack {
            backgroundColorGradient
                .ignoresSafeArea()
            HouseView(
                isEffectsEnabled: true,
                lightIntensity: houseLightIntensity,
                weatherType: weatherDataStore.currentWeatherType,
                allowRotation: !isPresented
            )
            .ignoresSafeArea()
            weatherIcon
            leadingStack
            
            sheetView
            
            weatherGreetingPopup
        }.opacity(isDataReady ? 1 : 0)
    }
    
    /// The wide-screen layout: the weather scene sits in a leading pane, the
    /// forecast details in a trailing one. The arrangement re-flows live as
    /// the device folds — side by side in landscape, stacked in portrait, and
    /// the panes snap onto the two halves while partially folded. The card
    /// content outside the panes stays scrolled out of the safe area of the
    /// pane, so the status bar keeps its breathing room.
    @available(iOS 27.1, *)
    private var arrangementLayout: some View {
        ZStack {
            backgroundColorGradient
                .ignoresSafeArea()
            ArrangementView {
                scenePane
                    .splitArrangementLayoutSize(minWidth: 300, idealWidth: 420, maxWidth: 440)
            } secondary: {
                weatherDetailsPane
                    .splitArrangementLayoutSize(minWidth: 320)
            }
            .arrangementViewStyle(.split)
            .duoLayoutProbe("arrangement")
        }
        .opacity(isDataReady ? 1 : 0)
    }
    
    private var scenePane: some View {
        ZStack {
            HouseView(
                isEffectsEnabled: true,
                lightIntensity: houseLightIntensity,
                weatherType: weatherDataStore.currentWeatherType,
                allowRotation: true
            )
            weatherIcon
            leadingStack
            weatherGreetingPopup
        }
        .duoLayoutProbe("scene")
    }
    
    private var weatherDetailsPane: some View {
        ScrollView {
            weatherDetailsContent
                .frame(maxWidth: .infinity)
                .padding(.top, 30)
                .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .duoLayoutProbe("details")
    }
    
    private var weatherIcon: some View {
        VStack {
            LottieView(animation: .named(weatherDataStore.weatherTypeResource.weatherIconAnimationName))
                .playing(loopMode: .loop)
                .resizable()
                .frame(width: weatherIconSize, height: weatherIconSize)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .onTapGesture {
            guard !isGreetingPresented else { return }
            withAnimation {
                isGreetingPresented.toggle()
            }
        }
    }
    
    private var temperatureView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                LiquidGlassText("\(weatherDataStore.currentTemperature)",
                                glass: .clear.interactive().tint(.white.opacity(0.1)),
                    size: temperatureSize,
                    weight: .black,
                                design: .default
                )
                LiquidGlassText(settings.unitSymbol,
                                glass: .clear.interactive().tint(.white.opacity(0.1)),
                    size: temperatureDegreeSize,
                    weight: .black,
                                design: .default
                )
                Spacer()
            }
            .foregroundStyle(mainTitleColor)
            HStack(spacing: 8) {
                LiquidGlassText("Feels like",
                                glass: .clear.interactive().tint(.white.opacity(0.1)),
                    size: feelsLikeSize,
                    weight: .black,
                                design: .rounded
                )
                SubTemperatureView(temperature: $weatherDataStore.realFeel)
                Spacer()
            }
            .padding(.top, 6)
            .foregroundStyle(mainTitleColor)
        }.padding(.bottom, 16)
            .shadow(color: .black.opacity(0.1), radius: 16)

    }
    
    private var currentCityView: some View {
        GlassEffectContainer(spacing: 10.0) {
            HStack {
                Button {
                    navigation(route: .otherLocations)
                } label: {
                    Text(weatherDataStore.currentCity)
                        .font(.getFont(type: .bold, size: cityFontSize))
                        .padding(10)
                        .frame(height: controlButtonSize)
                        .glassEffect(.clear.interactive())
                }

                Button {
#if DEBUG
                    weatherDataStore.changeWeatherType()
#endif
                } label: {
                    Image(systemName: "location.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: locationIconSize, height: locationIconSize)
                        .frame(width: controlButtonSize, height: controlButtonSize)
                        .glassEffect(.clear.interactive())
                }
                
            }
            .foregroundStyle(subTitleColor)
        }
    }
    
    private var weatherLoadingView: some View {
        ZStack {
            Color(.daySubTitle)
                .opacity(0.95)
            
            VStack(spacing: 0) {
                LottieView(animation: .named("sun_moon"))
                    .playing(loopMode: .loop)
                    .resizable()
                    .frame(width: weatherIconSize, height: weatherIconSize)
                
                Text("Loading...!")
                    .font(.getFont(type: .semibold, size: 16))
                    .foregroundStyle(.white)
            }
        }
        .ignoresSafeArea()
    }
    
    /// The forecast content shown both in the drag-up sheet on phones and in
    /// the detail pane on wide screens.
    @ViewBuilder
    private var weatherDetailsContent: some View {
        VStack {
            if let today = weatherDataStore.dailyWeatherData.first {
                let comparisonDay = weatherDataStore.dailyWeatherData.dropFirst().first
                TodayBriefView(
                    today: today,
                    comparisonDay: comparisonDay,
                    realFeel: weatherDataStore.realFeel,
                    hourlyData: weatherDataStore.hourlyWeatherData
                )
            }
            
            HourlyWeatherView(hourlyData: weatherDataStore.hourlyWeatherData)
                .padding(.horizontal, 25)
            DailyWeatherView(weatherData: weatherDataStore.dailyWeatherData)
                .padding(.horizontal, 25)
            
            SunriseSunsetGraphView(
                sunrise: weatherDataStore.dailyWeatherData.first?.sunrise,
                sunset: weatherDataStore.dailyWeatherData.first?.sunset,
                timeZone: weatherDataStore.dailyWeatherData.first?.timeZone ?? .current,
                scrubProgress: $sunScrubProgress
            )
            .padding(.horizontal, 25)
            .padding(.top, 4)
            
            HStack(spacing: 15) {
                Button {
                    navigation(route: .about)
                } label: {
                    Text("About Application")
                        .font(.getFont(type: .semibold, size: 16))
                        .frame(maxWidth: .infinity)
                        .frame(height: sheetFooterButtonHeight)
                        .foregroundStyle(.dayTitle)
                        .glassEffect(.regular, in: .rect(cornerRadius: 33))
                }
                
                Button {
                    navigation(route: .settings)
                } label: {
                    Image(systemName: "gear")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: sheetFooterIconSize, height: sheetFooterIconSize)
                        .foregroundColor(.dayTitle)
                        .frame(width: sheetFooterButtonHeight, height: sheetFooterButtonHeight)
                        .glassEffect(.regular, in: .rect(cornerRadius: 33))
                }
        }
            .padding(.horizontal, 25)
        }
    }
    
    private var sheetView: some View {
        SheetView(isBackgroundVisible: false, isPresented: $isPresented) {
            weatherDetailsContent
        }
    }
    
    /// Temperature and city controls, top-leading above the house. Shared by
    /// the phone layout and the scene pane.
    private var leadingStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            temperatureView
            currentCityView
            Spacer()
        }.padding(mainPadding)
    }
}

// MARK: - View computed properties
extension WeatherView {
    private var mainPadding: CGFloat {
        isCompactScreen ? 12 : 16
    }
    private var weatherIconSize: CGFloat {
        isCompactScreen ? 150 : 180
    }
    private var temperatureSize: CGFloat {
        isCompactScreen ? 68 : 78
    }
    private var temperatureDegreeSize: CGFloat {
        isCompactScreen ? 24 : 28
    }
    private var feelsLikeSize: CGFloat {
        isCompactScreen ? 18 : 20
    }
    private var cityFontSize: CGFloat {
        isCompactScreen ? 19 : 22
    }
    private var controlButtonSize: CGFloat {
        isCompactScreen ? 42 : 48
    }
    private var locationIconSize: CGFloat {
        isCompactScreen ? 19 : 22
    }
    private var sheetFooterButtonHeight: CGFloat {
        isCompactScreen ? 44 : 50
    }
    private var sheetFooterIconSize: CGFloat {
        isCompactScreen ? 22 : 24
    }
    private var isDataReady: Bool {
        weatherDataStore.dailyWeatherData.isEmpty == false
    }
    private var backgroundColorGradient: LinearGradient {
        weatherDataStore.weatherTypeResource.backgroundGradient
    }
    private var mainTitleColor: Color {
        weatherDataStore.weatherTypeResource.mainTitleColor
    }
    private var subTitleColor: Color {
        weatherDataStore.currentWeatherType.getWeatherTypeResource().subTitleColor
    }
    private var weatherGreetingPopup: some View {
        WeatherMessagePopup(message: weatherDataStore.greetingMessage, isPresent: $isGreetingPresented)
            .opacity(isGreetingPresented ? 1 : 0)
    }
    private var houseLightIntensity: CGFloat {
        let base = weatherDataStore.weatherTypeResource.lightIntensity
        guard let progress = sunScrubProgress else { return base }

        let daylight = 0.25 + (0.75 * sin(progress * .pi))
        return max(base * daylight, 20)
    }
}

// MARK: - Helper types for the view
struct WeatherTypeResource {
    let backgroundGradient: LinearGradient
    let houseIcon: Image
    let weatherIcon: Image
    let weatherIconAnimationName: String
    let mainTitleColor: Color
    let subTitleColor: Color
    let lightIntensity: CGFloat
}

extension CurrentWeatherType {
    func getWeatherTypeResource() -> WeatherTypeResource {
        return switch self {
        case .day_sunny:
                .init(
                    backgroundGradient: .init(
                        colors: [
                            .init(hex: "#FFFCEF"),
                            .init(hex: "#EAE2B2")
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    houseIcon: Image(.houseDaySunny),
                    weatherIcon: Image(.weatherDaySunny),
                    weatherIconAnimationName: "sunny.json",
                    mainTitleColor: .dayTitle,
                    subTitleColor: .daySubTitle,
                    lightIntensity: 600
                )
        case .day_cloudy:
                .init(
                    backgroundGradient: .init(
                        colors: [
                            .init(hex: "#FCF9EA"),
                            .init(hex: "#CCCCCC")
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    houseIcon: Image(.houseDayCloudy),
                    weatherIcon: Image(.weatherDayCloudy),
                    weatherIconAnimationName: "cloudy_sun.json",
                    mainTitleColor: .dayTitle,
                    subTitleColor: .daySubTitle,
                    lightIntensity: 250
                )
        case .day_rainy:
                .init(
                    backgroundGradient: .init(
                        colors: [
                            .init(hex: "#FAFCFF"),
                            .init(hex: "#807C69")
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    houseIcon: Image(.houseDayRainy),
                    weatherIcon: Image(.weatherDayRainy),
                    weatherIconAnimationName: "rainy.json",
                    mainTitleColor: .dayTitle,
                    subTitleColor: .daySubTitle,
                    lightIntensity: 400
                )
        case .night_clear:
                .init(
                    backgroundGradient: .init(
                        colors: [
                            .init(hex: "#E5E5E5"),
                            .init(hex: "#291888")
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    houseIcon: Image(.houseNightClear),
                    weatherIcon: Image(.weatherNightClear),
                    weatherIconAnimationName: "night.json",
                    mainTitleColor: .nightTitle,
                    subTitleColor: .nightSubTitle,
                    lightIntensity: 600
                )
        case .night_cloudy:
                .init(
                    backgroundGradient: .init(
                        colors: [
                            .init(hex: "#C7C8F2"),
                            .init(hex: "#191A2F")
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    houseIcon: Image(.houseNightCloudy),
                    weatherIcon: Image(.weatherNightCloudy),
                    weatherIconAnimationName: "night_cloudy.json",
                    mainTitleColor: .nightTitle,
                    subTitleColor: .nightSubTitle,
                    lightIntensity: 200
                )
        case .night_rainy:
                .init(
                    backgroundGradient: .init(
                        colors: [
                            .init(hex: "#37398D"),
                            .init(hex: "#16171C")
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    houseIcon: Image(.houseNightRainy),
                    weatherIcon: Image(.weatherNightRainy),
                    weatherIconAnimationName: "night_rainy.json",
                    mainTitleColor: .nightTitle,
                    subTitleColor: .nightSubTitle,
                    lightIntensity: 100
                )
        case .snow:
                .init(
                    backgroundGradient: .init(
                        colors: [
                            .init(hex: "#FDFDFD"),
                            .init(hex: "#CBEFFF")
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    houseIcon: Image(.houseSnow),
                    weatherIcon: Image(.weatherSnow),
                    weatherIconAnimationName: "snow.json",
                    mainTitleColor: .dayTitle,
                    subTitleColor: .daySubTitle,
                    lightIntensity: 600
                )
        case .undefined:
                .init(
                    backgroundGradient: .init(
                        colors: [
                            .init(hex: "#D3D3D3"),
                            .init(hex: "#5C5C5C")
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    houseIcon: Image(.houseDaySunny),
                    weatherIcon: Image(.weatherUnknown),
                    weatherIconAnimationName: "unknown_weather.json",
                    mainTitleColor: .dayTitle,
                    subTitleColor: .daySubTitle,
                    lightIntensity: 600
                )
        }
    }
}

#if DEBUG
#Preview {
    @Injectable(\.weatherDataStoreMock) var weatherDataStore: WeatherDataStore
    WeatherView()
        .environmentObject(weatherDataStore)
        .environmentObject(SettingsStore.dependency)
}
#endif
