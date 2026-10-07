---
title: A Comment Is Short, and Says Why
impact: HIGH
impactDescription: A comment costs every reader time and every token money; it earns that or it goes
tags: [quality, comments, documentation, measurements, brevity]
paths: ["FitnessExporter/**/*.swift", "FitnessExporterTests/**/*.swift"]
---

## A Comment Is Short, and Says Why

**Impact: HIGH**

A comment adds what the code cannot say — why this, what was measured, what was
rejected — in as few plain words as will still read. It doesn't restate a
method or property name. A claim about speed or size carries its measurement:
the device, the data, before, after. A constant carries the reason for its
value. A decision that rests on Apple's documentation carries the page's path,
as `native-check-apples-documentation` asks. A comment about code that has
gone goes with it.

The model's comments are the house style: `HealthDataPoint.init(from:)` says
why the newer fields are optional on decode (year files from v1.0 still load),
and `readTypes` says what adding a type there is enough to do.

**Incorrect (restates the name; no reason):**

```swift
/// Fetches health data.
func fetchHealthData(lookbackDays: Int) async throws -> [HealthDataPoint]
```

**Correct (what it promises the caller, then stop):**

```swift
/// Fetches steps, flights climbed, weight, active energy and resting energy for
/// the given number of past days, merged into an array of HealthDataPoint
/// sorted by date ascending. Every day in the window is present; counts and
/// energies default to 0 on days without samples, weight is nil.
```
