## 1. Package Wiring

- [x] 1.1 Add the `Notelet` package product dependency to the `SkyWizard-SwiftUI` app target.
- [x] 1.2 Verify the app target can import `Notelet` without project configuration errors.

## 2. Release Note Content

- [x] 2.1 Create a release notes definition for `27.0-Nightly` with returning-user highlights only.
- [x] 2.2 Create a first-ever release notes definition for `27.0-Nightly` with global SkyWizard features plus the current release highlights.
- [x] 2.3 Adapt the v27.0 Nightly wording into concise in-app rows for nightly status, Xcode 27 build context, Sunset app icon, and UI tweaks.

## 3. Launch Presentation State

- [x] 3.1 Add a dedicated first-ever release note completion flag backed by `UserDefaults`.
- [x] 3.2 Add launch decision logic that selects first-ever notes before returning-user current-version notes.
- [x] 3.3 Mark the first-ever flag and the current Notelet version as seen when first-ever notes are dismissed.
- [x] 3.4 Let Notelet mark the current version as seen when returning-user notes are dismissed.

## 4. SwiftUI Integration

- [x] 4.1 Attach the Notelet sheet coordinator at the app root or an app-root wrapper around `WeatherView`.
- [x] 4.2 Ensure first-time users do not see both first-ever and returning-user notes for the same version.
- [x] 4.3 Ensure no sheet appears when there are no notes matching the current bundle version.

## 5. Verification

- [ ] 5.1 Build the `SkyWizard-SwiftUI` scheme with Xcode to verify project wiring and Swift compilation.
- [ ] 5.2 Manually verify first-ever launch by clearing the first-ever flag and Notelet seen-version storage.
- [ ] 5.3 Manually verify returning-user update launch by setting the first-ever flag and clearing only Notelet seen-version storage.
- [ ] 5.4 Manually verify repeat launch suppression after dismissing the applicable notes.
