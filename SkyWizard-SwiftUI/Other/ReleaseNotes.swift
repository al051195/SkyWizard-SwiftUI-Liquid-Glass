//
//  ReleaseNotes.swift
//  SkyWizard-SwiftUI
//
//  Created by Codex on 19/06/2026.
//

import Notelet
import SwiftUI

private enum ReleaseNotesPresentationKind {
    case firstLaunch
    case currentVersion
}

private struct ReleaseNotesPresentation {
    let notes: [NoteletVersionNotes]
    let version: NoteletPresentedVersion?
    let kind: ReleaseNotesPresentationKind?

    static let none = ReleaseNotesPresentation(notes: [], version: nil, kind: nil)

    static func initial(userDefaults: UserDefaults = .standard) -> ReleaseNotesPresentation {
        if !userDefaults.bool(forKey: ReleaseNotesStorage.firstLaunchCompletionKey) {
            return .init(
                notes: SkyWizardReleaseNotes.firstLaunchNotes,
                version: .current,
                kind: .firstLaunch
            )
        }

        return .init(
            notes: SkyWizardReleaseNotes.currentVersionNotes,
            version: .current,
            kind: .currentVersion
        )
    }
}

private enum ReleaseNotesStorage {
    static let firstLaunchCompletionKey = "skywizard.releaseNotes.hasCompletedFirstLaunch"

    static func markFirstLaunchComplete(userDefaults: UserDefaults = .standard) {
        userDefaults.set(true, forKey: firstLaunchCompletionKey)
    }
}

struct ReleaseNotesPresenter<Content: View>: View {
    @State private var presentation = ReleaseNotesPresentation.initial()

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .noteletSheet(
                notes: presentation.notes,
                version: presentation.version,
                onDismiss: handleDismiss,
                configuration: SkyWizardReleaseNotes.configuration
            )
    }

    private func handleDismiss() {
        if presentation.kind == .firstLaunch {
            ReleaseNotesStorage.markFirstLaunchComplete()
            NoteletStorage.markCurrentVersionAsSeen()
        }

        presentation = .none
    }
}

private enum SkyWizardReleaseNotes {
    static let configuration = NoteletConfiguration(
        nextButtonLabel: "Next",
        doneButtonLabel: "Got it",
        accentColor: .blue
    )

    static let currentVersionNotes: [NoteletVersionNotes] = [
        .init(
            version: "27.0-Nightly-2",
            items: [
                currentVersionHighlights
            ]
        )
    ]

    static let firstLaunchNotes: [NoteletVersionNotes] = [
        .init(
            version: "27.0-Nightly-2",
            items: [
                welcomeHighlights,
                forecastHighlights,
                personalizationHighlights,
                currentVersionHighlights
            ]
        )
    ]

    private static let welcomeHighlights: NoteletVersionNoteItem = .list(
        title: "Welcome to SkyWizard",
        rows: [
            .init(
                symbolSystemName: "cloud.sun.fill",
                title: "Weather at a glance",
                description: "See current conditions, temperature, and your city as soon as the forecast is ready."
            ),
            .init(
                symbolSystemName: "sparkles",
                title: "Animated scenes",
                description: "The house, sky, and weather effects shift with the conditions around you."
            )
        ]
    )

    private static let forecastHighlights: NoteletVersionNoteItem = .list(
        title: "Plan the day",
        rows: [
            .init(
                symbolSystemName: "text.line.3.summary",
                title: "Today brief",
                description: "Get a quick readable summary of what today's weather means."
            ),
            .init(
                symbolSystemName: "clock.fill",
                title: "Hourly and daily forecast",
                description: "Open the forecast sheet for upcoming hours and the next few days."
            )
        ]
    )

    private static let personalizationHighlights: NoteletVersionNoteItem = .list(
        title: "Make it yours",
        rows: [
            .init(
                symbolSystemName: "location.fill",
                title: "Saved locations",
                description: "Keep other places close and switch forecasts from the city selector."
            ),
            .init(
                symbolSystemName: "app.specular",
                title: "Alternate icons",
                description: "Choose the app icon style that fits your Home Screen."
            )
        ]
    )

    private static let currentVersionHighlights: NoteletVersionNoteItem = .list(
        title: "New in 27.0 Nightly",
        rows: [
            .init(
                symbolSystemName: "exclamationmark.triangle.fill",
                title: "Nightly build",
                description: "This is a work-in-progress build, so bugs and unfinished details are expected."
            ),
            .init(
                symbolSystemName: "hammer.fill",
                title: "Built with Xcode 27",
                description: "This release is mainly a tweaked build of v26.3.1 while the new toolchain settles in."
            ),
            .init(
                symbolSystemName: "app.gift",
                title: "Sunset app icon",
                description: "A new Sunset icon showcases the latest platform visual capabilities."
            ),
            .init(
                symbolSystemName: "paintbrush.pointed.fill",
                title: "UI tweaks",
                description: "Several interface details were polished to make the app feel cleaner and smoother."
            )
        ]
    )
}
