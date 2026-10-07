---
title: Use the System's Feature, Not a Copy of It
impact: HIGH
impactDescription: The OS version already handles accessibility, Dynamic Type, Dark Mode, privacy prompts and next year's iOS
tags: [native, ios, swiftui, healthkit, keychain, files]
paths: ["FitnessExporter/**/*.swift", "project.yml"]
---

## Use the System's Feature, Not a Copy of It

**Impact: HIGH**

Fitness Exporter should feel like an iPhone app Apple could have shipped: it
behaves the way the user's other apps behave, by using what iOS provides rather
than building a version of its own. Before writing a control, a store or a file
browser, ask whether the OS has one. It usually does.

- **The screen** is a SwiftUI `Form` in a `NavigationStack`: `Section`s, a
  segmented `Picker`, a `SecureField` for the token, buttons and labels with SF
  Symbols. The URL field asks for the URL keyboard and content type rather
  than checking keystrokes itself.
- **Health data** comes from HealthKit's statistics queries, which aggregate
  by day inside HealthKit, and permission is HealthKit's own sheet, worded by
  the usage strings in `project.yml`.
- **Secrets** are the Keychain (`Security`), not a file or `UserDefaults`.
- **Files** are reached through the Files app — `UIFileSharingEnabled` and
  `LSSupportsOpeningDocumentsInPlace` expose the Documents folder — not a
  browser or share flow of the app's own.
- **JSON and HTTP** are `JSONEncoder`, `JSONDecoder` and `URLSession`.

When the system can't do the job, say so in a comment with the page that shows
it. Native is not generic: the export format and the merge into year files are
the app's own work, built from the system's parts.

**Incorrect (summing raw samples by hand):**

```swift
let query = HKSampleQuery(sampleType: HKQuantityType(.stepCount), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
    let total = (samples as? [HKQuantitySample])?.reduce(0) { $0 + $1.quantity.doubleValue(for: .count()) }
}
```

**Correct (HealthKit aggregates; the app reads one value per day):**

```swift
let query = HKStatisticsCollectionQuery(
    quantityType: type, quantitySamplePredicate: predicate,
    options: statistic.hkOptions, anchorDate: anchorDate, intervalComponents: DateComponents(day: 1))
```
