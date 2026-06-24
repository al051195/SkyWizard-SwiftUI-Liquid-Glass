## ADDED Requirements

### Requirement: First-ever launch notes
The system SHALL present first-ever release notes to users who have never completed the app's initial release note experience.

#### Scenario: New user opens the app for the first time
- **WHEN** a user launches SkyWizard and the first-ever release note completion flag has not been set
- **THEN** the app presents release notes containing global SkyWizard feature highlights and the current release highlights

#### Scenario: First-ever notes are dismissed
- **WHEN** a user dismisses the first-ever release notes
- **THEN** the app records that the first-ever release note experience has been completed
- **THEN** the app records the current app version as seen for release note purposes

### Requirement: Returning-user version notes
The system SHALL present current-version release notes to returning users who have completed the first-ever release note experience but have not seen release notes for the current app version.

#### Scenario: Returning user opens an unseen version
- **WHEN** a user launches SkyWizard after completing the first-ever release note experience
- **AND** the current app version has not been recorded as seen
- **THEN** the app presents release notes containing only the current release highlights

#### Scenario: Returning-user notes are dismissed
- **WHEN** a user dismisses the current-version release notes
- **THEN** the app records the current app version as seen for release note purposes

### Requirement: Release note suppression
The system SHALL avoid presenting release notes when there is no applicable unseen release note experience.

#### Scenario: User has seen the initial flow and current version
- **WHEN** a user launches SkyWizard after completing the first-ever release note experience
- **AND** the current app version has already been recorded as seen
- **THEN** the app does not present a release note sheet

#### Scenario: No notes exist for current version
- **WHEN** a user launches SkyWizard
- **AND** there are no release notes matching the current app version
- **THEN** the app does not present an empty or incorrect release note sheet

### Requirement: v27.0 Nightly content
The system SHALL include adapted in-app release note content for version `27.0-Nightly`.

#### Scenario: v27.0 Nightly notes are shown
- **WHEN** release notes are presented for version `27.0-Nightly`
- **THEN** the notes communicate that the build is a work-in-progress nightly
- **THEN** the notes mention the Xcode 27 build context
- **THEN** the notes mention the new Sunset app icon
- **THEN** the notes mention UI tweaks and visual improvements
