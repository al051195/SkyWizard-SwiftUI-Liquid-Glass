## Context

SkyWizard's SwiftUI app root is `SkyWizard_SwiftUIApp`, which hosts `WeatherView` inside a `NavigationStack`. The project already pins the `notelet` Swift package at version `1.1.0`, and the package reference exists in the Xcode project. The app target still needs the `Notelet` product dependency added before Swift code can import it.

Notelet is designed for this exact release-note use case: `.noteletSheet(notes:version:)` can present notes for the current bundle version, then persist the seen version in `UserDefaults` when dismissed. SkyWizard needs one extra layer above that default behavior because first-time users should see a combined welcome and release note experience, while returning users should only see release-specific changes.

The current app marketing version is `27.0-Nightly`, so release note entries for automatic current-version presentation must match that string.

## Goals / Non-Goals

**Goals:**

- Present a Notelet sheet on first launch ever with global SkyWizard feature notes plus v27.0 Nightly highlights.
- Present a Notelet sheet on first launch of a new app version for returning users with only v27.0 Nightly highlights.
- Avoid presenting two release note sheets to first-time users during the same launch/version.
- Store only lightweight local presentation state.
- Adapt the GitHub release note wording into concise in-app copy.

**Non-Goals:**

- Remote release note loading.
- A full onboarding flow with permissions, tutorial state, or account setup.
- Historical changelog browsing from Settings.
- Changing the app version, icon assets, or release packaging.

## Decisions

### Use Notelet for presentation and per-version storage

Use Notelet's sheet modifier for the user-facing release note UI and its built-in current-version seen storage for returning-user update notes.

Alternative considered: build a custom SwiftUI sheet. This would duplicate a package that is already added and would require maintaining presentation, paging, and storage behavior locally.

### Add app-level first-ever launch state

Track first-ever release note completion with a dedicated `UserDefaults` key, separate from Notelet's per-version seen storage. On the first-ever flow dismissal, mark both the first-ever key and the current Notelet version as seen.

Alternative considered: rely only on Notelet's seen-version storage. That cannot distinguish a brand-new user from a returning user who has not seen the current version notes yet.

### Keep two note collections

Define one collection for first-time users and one collection for returning users:

- first-time collection: welcome/global app features plus v27.0 Nightly highlights,
- returning collection: v27.0 Nightly highlights only.

Both collections should use the current bundle version string so they remain aligned with Notelet's `.current` behavior.

Alternative considered: use one collection for all users. That would make update notes too noisy for existing users or make first-time notes too sparse for new users.

### Attach the release note coordinator at the app root

The launch decision should live near `SkyWizard_SwiftUIApp` or a small root-level view wrapper around `WeatherView`, rather than inside weather content sections. This keeps release note state independent from weather loading, navigation, and sheet expansion state.

Alternative considered: attach directly inside `WeatherView`. This works mechanically, but mixes product messaging state with weather screen interactions and makes the first-launch behavior harder to reason about.

### Use adapted in-app v27.0 Nightly copy

The GitHub release note should be condensed for a sheet:

- "Nightly build" warning: work in progress, bugs and imperfections expected.
- "Built with Xcode 27": mainly a tweaked build of v26.3.1 for now.
- "Sunset App Icon": new app icon showcasing the new platform visual capabilities.
- "UI Tweaks": broad visual polish and needed interface improvements.

The in-app copy should avoid long Markdown-style headings and focus on short titles, SF Symbols, and compact descriptions.

## Risks / Trade-offs

- First-time users could see release notes before weather data appears -> Attach the sheet at the root and let it present independently from weather loading, or delay only if Notelet presentation conflicts with app startup.
- Version string mismatch could suppress notes -> Ensure the Notelet entry version matches `CFBundleShortVersionString`, currently `27.0-Nightly`.
- First-time users could see both first-ever and version notes -> On first-ever dismissal, call Notelet's current-version mark-seen API in addition to setting the first-ever key.
- Notelet package may be referenced but not linked -> Add the `Notelet` product to the app target package dependencies before importing it.
- Nightly wording may sound alarming in a polished UI -> Keep the warning clear but brief, framed as expectation-setting rather than an error state.
