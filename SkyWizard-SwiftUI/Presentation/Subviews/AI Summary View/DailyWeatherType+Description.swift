import SkyWizardEnum

extension DailyWeatherType {
    func conditionText() -> String {
        switch self {
        case .sunny:
            return "mostly sunny"
        case .cloudy:
            return "partly cloudy"
        case .rainy:
            return "rainy"
        case .snow:
            return "snowy"
        case .undefined:
            return "undefined"
        }
    }
}
