## Why

SkyWizard already has the Notelet package pinned, but users do not yet get an in-app explanation of what changed or what the app can do. Adding launch-aware release notes gives new users a welcoming first-run overview while keeping update notes concise for returning users.

## What Changes

- Add an in-app release notes experience powered by Notelet.
- Show first-time users a combined welcome flow with core SkyWizard features plus the v27.0 Nightly highlights.
- Show returning users only the v27.0 Nightly highlights the first time they launch that app version.
- Prevent first-time users from seeing both the welcome flow and the returning-user update flow for the same version.
- Adapt the v27.0 Nightly release copy for in-app presentation:
  - identify the build as a nightly work-in-progress,
  - mention that it is compiled with Xcode 27 and based mainly on v26.3.1,
  - highlight the new Sunset app icon,
  - summarize UI polish and visual improvements.

## Capabilities

### New Capabilities

- `release-notes`: Defines how SkyWizard presents first-run and per-version release notes.

### Modified Capabilities

- None.

## Impact

- App launch/root SwiftUI view composition.
- Notelet Swift Package target wiring.
- Local persistence via UserDefaults and Notelet's seen-version storage.
- Release note content for `27.0-Nightly`.
