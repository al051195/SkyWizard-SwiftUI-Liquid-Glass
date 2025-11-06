//
//  SettingsView.swift
//  SkyWizard-SwiftUI
//
//  Created by Antoine on 04/11/2025.
//

import SwiftUI

enum AppIcon: String, CaseIterable, Identifiable {
    case `default` = "AppIcon"              // Icône par défaut (ne pas mettre "Weather")
    case alternative1 = "Weather Mono"      // Nom exact du fichier .icon sans extension
    case alternative2 = "Weather Colorful"  // Nom exact du fichier .icon sans extension

    var id: String { rawValue }

    /// L'icône à passer à setAlternateIconName (nil = icône par défaut)
    var iconName: String? {
        switch self {
        case .default:
            return nil
        default:
            return rawValue
        }
    }

    /// Une description user-friendly
    var description: String {
        switch self {
        case .default:
            return "Default"
        case .alternative1:
            return "Monochrome"
        case .alternative2:
            return "Colored"
        }
    }

    /// Nom de l'image d'aperçu dans Assets
    var previewImageName: String {
        switch self {
        case .default:
            return "Weather-Preview"
        case .alternative1:
            return "Weather Mono-Preview"
        case .alternative2:
            return "Weather Colorful-Preview"
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
                       }
            Section {
                ForEach(AppIcon.allCases) { icon in
                    Button(action: {
                        settings.updateIcon(to: icon)
                    }) {
                        HStack(spacing: 15) {
                            // Image d'aperçu
                            if let uiImage = UIImage(named: icon.previewImageName) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(13)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 13)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            } else {
                                // Image placeholder si l'aperçu n'existe pas
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "app.fill")
                                            .foregroundColor(.gray)
                                    )
                            }
                            
                            Text(icon.description)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if settings.selectedIcon == icon {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .navigationTitle("Settings")
        .listStyle(InsetGroupedListStyle())
    }
}

#Preview {
    NavigationView {
        ChangeAppIconView()
    }
}
