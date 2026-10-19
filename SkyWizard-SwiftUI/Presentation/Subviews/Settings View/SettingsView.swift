// SettingsView.swift
// SkyWizard-SwiftUI

// Created by Antoine on 04/11/2025.

import SwiftUI

import Foundation


enum AppIcon: String, CaseIterable, Identifiable {
    case `default` = "AppIcon"
    case alternative2 = "Weather Colorful"
    case alternative3 = "Weather Cool"
    case alternative4 = "Weather Sunset"
    
    var id: String { rawValue }

    var iconName: String? {
        switch self {
        case .default:
            return nil
        default:
            return rawValue
        }
    }

    var description: String {
        switch self {
        case .default: return "Default"
        case .alternative2: return "Colored"
        case .alternative3: return "Cool"
        case .alternative4: return "Sunset"
        }
    }

    var previewImageName: String {
        switch self {
        case .default: return "Weather-Preview"
        case .alternative2: return "Weather Colorful-Preview"
        case .alternative3: return "Weather Cool-Preview"
        case .alternative4: return "Weather Sunset-Preview"
        }
    }
}

final class AppIconSettings: ObservableObject {
    @Published var selectedIcon: AppIcon

    init() {
        if let current = UIApplication.shared.alternateIconName,
           let icon = AppIcon(rawValue: current) {
            self.selectedIcon = icon
        } else {
            self.selectedIcon = .default
        }
    }

    func updateIcon(to icon: AppIcon) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("The device does not support changing icons")
            return
        }

        guard UIApplication.shared.alternateIconName != icon.iconName else {
            print("This icon is already selected")
            return
        }

        UIApplication.shared.setAlternateIconName(icon.iconName) { error in
            DispatchQueue.main.async {
                if let err = error {
                    print("Error changing icon : \(err.localizedDescription)")
                } else {
                    self.selectedIcon = icon
                    print("Icon successfully changed : \(icon.description)")
                }
            }
        }
    }
}

struct ChangeAppIconView: View {
    @StateObject private var settings = AppIconSettings()
    @Environment(\.settingsStore) private var settingsStore: SettingsStore
    @State private var useCelsius: Bool = SettingsStore.dependency.useCelsius
    @State private var iconRowWidth: CGFloat = 0

    var body: some View {
        List {
            Section(header: Text("Application Icon")) {
                
                VStack(spacing: 16) {
                    HStack(spacing: 0) {
                        ForEach(AppIcon.allCases) { icon in
                            VStack {
                                if let uiImage = UIImage(named: icon.previewImageName) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: appIconPreviewHeight)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14.5)
                                                .stroke(settings.selectedIcon == icon ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                        .shadow(color: settings.selectedIcon == icon ? Color.blue.opacity(0.7) : .clear,
                                                radius: 8)
                                        .opacity(settings.selectedIcon == icon ? 1 : 0.6)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: appIconPreviewHeight)
                                        .overlay(
                                            Image(systemName: "app.fill")
                                                .font(.title2)
                                                .foregroundColor(.gray)
                                        )
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 4)
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.width
                    } action: { newWidth in
                        iconRowWidth = newWidth
                    }

                    Picker("App Icon", selection: $settings.selectedIcon) {
                        ForEach(AppIcon.allCases) { icon in
                            Text(icon.description).tag(icon)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: settings.selectedIcon) { newIcon in
                        settings.updateIcon(to: newIcon)
                    }
                }
                .padding(.vertical, 8)
            }

            Section(header: Text("Temperature Units")) {
                Picker("Units", selection: $useCelsius) {
                    Text("°C").tag(true)
                    Text("°F").tag(false)
                }
                .pickerStyle(.segmented)
                .onChange(of: useCelsius) { newValue in
                    settingsStore.useCelsius = newValue
                    UserDefaults.standard.set(newValue, forKey: "temperatureUseCelsius")
                }
            }
        }
        .navigationTitle("Settings")
        .listStyle(.insetGrouped)
    }
}

extension ChangeAppIconView {
    /// App-icon previews scale with the row on wide containers — the iPhone
    /// Duo inner display and the iPad — so the four cells fill their quarters
    /// instead of floating with dead space around them. Clamped at 55, the
    /// value on every standard iPhone, so phones render exactly as before.
    var appIconPreviewHeight: CGFloat {
        min(96, max(55, iconRowWidth / 12))
    }
}

#Preview {
    NavigationView {
        ChangeAppIconView()
    }
}
