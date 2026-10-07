---
title: Add a Case and Its Behaviour, Not an `if`
impact: HIGH
impactDescription: A special case on shared code is a band-aid the next change tears off
tags: [quality, extensibility, altitude, design]
paths: ["FitnessExporter/**/*.swift"]
---

## Add a Case and Its Behaviour, Not an `if`

**Impact: HIGH**

The places the app grows are enumerations and one value type, each with one
mechanism behind it:

- An **export destination** is an `ExportMode` case with its `displayName`, and
  `ExportService.export` switches on it to pick the exporter.
- A **lookback** is a `LookbackPeriod` case; the picker lists `allCases`, so a
  new case appears without the view being told.
- A **per-day statistic** is a `DailyStatistic` case carrying both its
  `HKStatisticsOptions` and its accessor.
- A **HealthKit type** is a field on `HealthDataPoint` and an entry in
  `HealthKitService.readTypes`; `CLAUDE.md` lists every place it touches,
  `PRIVACY.md` and the usage string included.

The switches are exhaustive, so a new case makes the compiler list every place
that has to decide what it means. Adding one means adding a case and its
behaviour, not an `if` in an exporter or a view for the new one.

When a change wants a special case on shared code, the fix is usually one level
deeper: give the shared mechanism what the case needs.

**Incorrect (the fetch learns about one lookback):**

```swift
let start = lookbackDays == 3650 ? Date.distantPast : calendar.date(byAdding: .day, value: -(lookbackDays - 1), to: end)!
```

**Correct (the case carries its value through the one mechanism):**

```swift
enum LookbackPeriod: Int, CaseIterable, Codable, Sendable {
    case oneDay = 1
    case sevenDays = 7
    …
}
```
