---
title: Code Reads Like the Prose Around It
impact: HIGH
impactDescription: The next reader is a person, usually months later, often the author
tags: [quality, readability, naming]
paths: ["FitnessExporter/**/*.swift", "FitnessExporterTests/**/*.swift"]
---

## Code Reads Like the Prose Around It

**Impact: HIGH**

Names say what a thing is in the words the domain uses —
`fetchDailyStatistics(type:unit:statistic:start:end:)`, `loadExistingPoints(at:using:)`,
`roundedWeight`, `exportNow()`, `refusesToOverwriteCorruptExistingFile` — so a
call site reads as a sentence. Short names are right where the convention uses
them (`f` for a formatter being configured, `i`, `e`) and wrong anywhere else. A function does what its name says and
nothing more; one that needs "and" in its name is two. Nesting is shallow; the
early `guard` says what a function refuses, as `HTTPExporter.export` refuses an
empty or unparseable URL, then a non-HTTPS one, before it encodes a byte.

**Incorrect:**

```swift
func go(_ c: ExportConfiguration, _ d: [HealthDataPoint]) async throws -> Int {
    if let u = URL(string: c.httpURL) { if u.scheme == "https" { /* … twenty lines … */ } }
    throw URLError(.badURL)
}
```

**Correct:**

```swift
guard !config.httpURL.isEmpty, let url = URL(string: config.httpURL) else {
    throw URLError(.badURL)
}
guard url.scheme == "https" else {
    throw URLError(.appTransportSecurityRequiresSecureConnection)
}
```
