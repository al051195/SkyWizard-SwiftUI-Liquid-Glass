//
//  SettingsView.swift
//  SkyWizard-SwiftUI
//
//  Created by Antoine on 04/11/2025.
//

import SwiftUI

enum AppIcon: String, CaseIterable, Identifiable {
    case `default` = "AppIcon"
    case alternative1 = "Weather Mono"
    case alternative2 = "Weather Colorful"
    case alternative3 = "Weather Cool"
    
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
        case .alternative1: return "Mono"
        case .alternative2: return "Colored"
        case .alternative3: return "Cool"
        }
    }

    var previewImageName: String {
        switch self {
        case .default: return "Weather-Preview"
        case .alternative1: return "Weather Mono-Preview"
        case .alternative2: return "Weather Colorful-Preview"
        case .alternative3: return "Weather Cool-Preview"
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
                                        .frame(height: 55)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(settings.selectedIcon == icon ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                        .shadow(color: settings.selectedIcon == icon ? Color.blue.opacity(0.7) : .clear,
                                                radius: 8)
                                        .opacity(settings.selectedIcon == icon ? 1 : 0.6)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 55)
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
        }
        .navigationTitle("Settings")
        .listStyle(.insetGrouped)
    }
}

#Preview {
    NavigationView {
        ChangeAppIconView()
    }
}

