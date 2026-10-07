---
title: Fast Where It Counts, and Measured
impact: HIGH
impactDescription: An All Time export asks HealthKit for ten years of five types and rewrites every year file
tags: [quality, performance, concurrency, healthkit]
paths: ["FitnessExporter/**/*.swift"]
---

## Fast Where It Counts, and Measured

**Impact: HIGH**

The cost is in two places, and they are written for the machine:

- **HealthKit.** `fetchHealthData` asks for five types, each as one
  `HKStatisticsCollectionQuery` bucketed by day, so HealthKit does the
  aggregation and the app never loads raw samples. The five queries run
  concurrently (`async let`), and the result is one pass over the days of the
  window. All Time is 3650 days.
- **The year files.** `FileExporter` reads, decodes, merges, re-encodes and
  atomically rewrites one file per year in the window — up to eleven for All
  Time.

Everything else is written for the reader. Which is which is decided by
measuring, on a device with real Health data, before and after, with the
figures in the commit and in a comment on the fast path. No figures are
recorded yet; the first change made for speed records the baseline it was
measured against.

**Incorrect (five queries one after another, or samples summed by hand):**

```swift
let steps = try await fetch(.stepCount, .count(), .sum)
let flights = try await fetch(.flightsClimbed, .count(), .sum)   // waits for steps first
```

**Correct (concurrent, aggregated by HealthKit):**

```swift
async let stepsTask = fetch(.stepCount, .count(), .sum)
async let flightsTask = fetch(.flightsClimbed, .count(), .sum)
let (steps, flights) = try await (stepsTask, flightsTask)
```
