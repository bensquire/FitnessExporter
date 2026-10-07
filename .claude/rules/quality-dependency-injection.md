---
title: Settings and Collaborators Are Handed In as Values
impact: HIGH
impactDescription: Code that reaches for a global — the Documents folder, the shared session, UserDefaults — cannot be tested without it
tags: [quality, dependency-injection, values, testability]
paths: ["FitnessExporter/**/*.swift", "FitnessExporterTests/**/*.swift"]
---

## Settings and Collaborators Are Handed In as Values

**Impact: HIGH**

A type takes its settings as a value, and whoever calls it hands that value
in. The exporters take an `ExportConfiguration`, which `AppViewModel` builds
from its settings before crossing into an actor; nothing below the view model
reads `@AppStorage`, `UserDefaults` or the Keychain.

What a type writes to or talks to is a parameter with the real thing as its
default, so the app's call site doesn't change and a test hands in its own.
`FileExporter(directoryURL:)` is the pattern: the app gets the Documents
folder, `FileExporterTests` a fresh temporary directory per test.
`HTTPExporter(session:)` takes its `URLSession` the same way, so a test checks
what it sends through a stub `URLProtocol`, and `KeychainService(calls:)` takes
its three Security calls, so a test can make the Keychain refuse a write.
`ExportService(httpExporter:fileExporter:)` passes them through. When a test
needs a seam, add it this way, not as a global switch.

When a setting is added, it is added once — a field on
`ExportConfiguration` — and reaches the exporter through that value, not as a
second parameter on every call.

**Incorrect (the exporter reading the settings store; a fixed folder):**

```swift
let url = URL(string: UserDefaults.standard.string(forKey: "httpURL") ?? "")
let fileURL = FileExporter.documentsDirectory.appendingPathComponent("\(year).json")
```

**Correct:**

```swift
func export(data: [HealthDataPoint], config: ExportConfiguration) async throws -> Int
init(directoryURL: URL = FileExporter.documentsDirectory)
```
