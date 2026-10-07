---
title: Match the Code Around You
impact: HIGH
impactDescription: One idiom for one job, so a reader learns it once and the export format can't drift
tags: [quality, consistency, idioms, reuse]
paths: ["FitnessExporter/**/*.swift", "FitnessExporterTests/**/*.swift"]
---

## Match the Code Around You

**Impact: HIGH**

New code reads like the file it lands in: the same naming, comment density,
error style, and idioms. Before writing a helper, look for the one that exists
and call it:

- `ExportService.makeEncoder()` and `makeDecoder()` for any JSON the app writes
  or reads back (ISO 8601 dates, pretty-printed, sorted keys), so the HTTP body
  and the year files can't disagree;
- `HealthDataPoint.dateFormatter` for a `yyyy-MM-dd` day, and
  `HealthDataPoint.roundedWeight(_:)` for a weight;
- `DailyStatistic` to pair a HealthKit query option with its accessor;
- `ExportError(_:)` to carry an error across an actor boundary, and
  `LocalizedError` with an `errorDescription` on every error type, so its
  message survives being erased to `any Error`;
- `KeychainService` for anything secret.

In tests: `makeConfig(mode:url:)` in `TestHelpers.swift`, and the per-test
temporary directory `FileExporterTests` makes in `init` and removes in
`deinit`. A second spelling of the same thing is a bug waiting for one of them
to drift.

**Incorrect (a fresh encoder that drops the sorted keys and the date format):**

```swift
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let body = try encoder.encode(data)
```

**Correct:**

```swift
let body = try ExportService.makeEncoder().encode(data)
```
