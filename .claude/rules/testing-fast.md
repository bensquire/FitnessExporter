---
title: Fast, but Not Over Accuracy
impact: MEDIUM
impactDescription: A test that is quick because it cannot see the defect is not a test; a slow suite is one nobody runs
tags: [testing, performance, accuracy, fixtures]
paths: ["FitnessExporterTests/**/*.swift"]
---

## Fast, but Not Over Accuracy

**Impact: MEDIUM**

A test is first for what it proves, then as cheap as that allows — never the
other way round. The 46 tests take 0.1–0.3 s, the slowest suite being the
requests through the stub session at 0.04 s; `make test` takes 10–14 s warm,
nearly all of it the build and the simulator starting. Speed is bought by
not paying for what the test doesn't need: values built in memory, a few days
of data, files in a temporary directory, and a rule about one unit pinned on
that unit (`roundedWeight`, `makeEncoder()`, `HealthDataPoint`'s decoding)
rather than on a whole export.

Speed is never bought by making the test see less. The merge test needs three
days — one kept, one replaced, one added — because a merge can get each of them
wrong on its own; a fixture cut to one day would pass a merge that overwrites
everything. Exporting ten years of data is a benchmark, run by hand on a device
with its figures in the commit, not a unit test.

**Incorrect (fast because it cannot see):**

```swift
let later = [HealthDataPoint(date: "2026-01-02", stepCount: 2_500, flightsClimbed: 3)]
// with no earlier file: passes whether or not anything is merged
```

**Correct (small, and big enough where it counts):**

```swift
_ = try await exporter.export(data: january, config: makeConfig(mode: .file))   // 1 and 2 January
let count = try await exporter.export(data: later, config: makeConfig(mode: .file))   // 2 and 3 January
```
