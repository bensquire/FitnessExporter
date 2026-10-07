---
title: Each Part Does One Job, and Knows Only Its Neighbours
impact: HIGH
impactDescription: The model and the exporters are tested without HealthKit or a screen because neither knows about either
tags: [quality, architecture, separation-of-concerns, layers, concurrency]
paths: ["FitnessExporter/**/*.swift"]
---

## Each Part Does One Job, and Knows Only Its Neighbours

**Impact: HIGH**

The app is one target, so the layers are kept by the folders and the types,
and the dependencies run one way — views to the view model, the view model to
the services, the services to the model:

- **`Model/`** holds the values: `HealthDataPoint`, `YearExport`,
  `ExportConfiguration` with `ExportMode` and `LookbackPeriod`, `ExportResult`
  and `ExportError`. Foundation only, all `Sendable`.
- **`Services/HealthKitService`** is the only place that queries HealthKit. It
  hands back `[HealthDataPoint]`, extracting plain values inside the query's
  handler before they cross the actor boundary.
- **`Services/ExportService`** routes a configuration to `HTTPExporter` or
  `FileExporter` and turns their errors into an `ExportResult`. It owns the
  JSON encoder and decoder settings.
- **`Services/KeychainService`** is the only place that touches the Keychain.
- **`ViewModels/AppViewModel`** is `@MainActor`: it holds the settings,
  snapshots them into an `ExportConfiguration` before any `await`, and
  sequences authorization, fetch and export.
- **`Views/`** shows the view model's state and sends the user's taps to it.

A change that needs an exporter to know about HealthKit, a view to build a
request, or the view model to parse JSON, is at the wrong layer.

**Incorrect (a view doing the service's work):**

```swift
Button("Export Now") {
    Task { try await URLSession.shared.data(for: request(from: viewModel.httpURL)) }
}
```

**Correct (the view sends the tap; the layers below do the rest):**

```swift
Button {
    Task { await viewModel.exportNow() }
} label: {
    Label("Export Now", systemImage: "square.and.arrow.up")
}
```
