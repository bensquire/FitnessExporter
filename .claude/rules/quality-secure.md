---
title: Read Only What Was Granted, Send Only Where the User Said
impact: HIGH
impactDescription: A health app that reads more than it says, sends data somewhere unasked, or leaks a token has broken PRIVACY.md and the user's trust
tags: [quality, security, privacy, healthkit, keychain, network, files]
paths: ["FitnessExporter/**/*.swift", "FitnessExporter/FitnessExporter.entitlements", "project.yml", "PRIVACY.md"]
---

## Read Only What Was Granted, Send Only Where the User Said

**Impact: HIGH**

`PRIVACY.md` is a promise to the user, and the code keeps it:

- **HealthKit, read only, five types.** `HealthKitService.readTypes` asks to
  read steps, flights climbed, body mass, active and basal energy, and to
  share nothing (`toShare: []`). The entitlement is HealthKit without
  clinical records (`com.apple.developer.healthkit.access` is empty). A type
  the user didn't grant reads as no data — HealthKit doesn't say a read was
  denied (/documentation/healthkit/hkhealthstore/authorizationstatus(for:)).
  So the app says access was requested, never that it was granted, and a
  window with no sample of any type stops with `HealthKitError.noData` rather
  than exporting zeros over real days in a year file or on the server.
- **The network is the user's endpoint and nothing else.** `HTTPExporter`
  POSTs the JSON to the URL the user typed, HTTPS only:
  `HTTPExporter.endpoint(from:)` refuses any other scheme before a request is
  made, and the settings screen's warning asks the same function. There are no analytics, no third-party
  SDKs and no Swift packages.
- **The token lives in the Keychain.** `KeychainService` stores it as a
  generic password for the service `com.bengsfort.FitnessExporter`, readable
  after first unlock, and it travels only as the `Authorization` header to
  that endpoint. A save updates the item in place and checks every status, so a
  write the Keychain refuses keeps the old token and the screen says the new
  one wasn't saved. The other settings are not secret and live in `@AppStorage`.
- **Files stay in the app's Documents folder**, one per year, written
  atomically, and visible in the Files app (`UIFileSharingEnabled`,
  `LSSupportsOpeningDocumentsInPlace`). A year file that doesn't decode is left
  as it is and the export fails, rather than being overwritten.
- **Diagnostics carry no health values or token** (`workflow-diagnostics`).

A change to what is read, where it goes or how the token is kept updates
`PRIVACY.md`, the `NSHealthShareUsageDescription` in `project.yml`, and this
rule in the same change. An entitlement or a read type is added only with the
feature that needs it.

**Incorrect:**

```swift
@AppStorage("httpToken") var httpToken = ""                 // UserDefaults is a plist on disk
guard url.scheme == "https" || url.scheme == "http" else { … }  // the token in clear text
```

**Correct:**

```swift
@Published var httpToken: String = KeychainService().load(key: AppViewModel.tokenKey) {
    didSet { saveToken() }   // a refused write sets tokenSaveError, which the screen shows
}
let url = try HTTPExporter.endpoint(from: config.httpURL)   // HTTPS, or a URLError before any request
```
