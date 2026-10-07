---
title: Every Test Arranges, Acts and Asserts
impact: HIGH
impactDescription: A test with a step missing tests something other than it claims
tags: [testing, aaa, structure, swift-testing]
paths: ["FitnessExporterTests/**/*.swift"]
---

## Every Test Arranges, Acts and Asserts

**Impact: HIGH**

Every `@Test` has three steps, in this order, each present and identifiable,
and the suite marks them `// Arrange`, `// Act`, `// Assert`, with a short note
after a dash when the step needs one (`// Arrange — a previous export covering
January`, `// Assert — old day kept, overlapping day replaced, new day added`):

1. **Arrange** — build the input: data points, a configuration from
   `makeConfig`, a file written into the test's own directory. When the input
   is a literal argument, the act carries it and only `// Assert` is marked, as
   in `ExportModeTests`.
2. **Act** — the one call under test. One act per test where the design
   allows; a test that acts twice is two tests, or a test of the pair, as
   `mergesWithExistingFilePreservingOlderDays` exports twice because the merge
   is the behaviour.
3. **Assert** — `#expect` against what the act produced; `try #require` for
   the thing the rest of the test can't run without.

**Incorrect (the act hidden inside the assert):**

```swift
#expect(try await exporter.export(data: points, config: makeConfig(mode: .file)) == 3)
```

**Correct:**

```swift
// Arrange
let points = [HealthDataPoint(date: "2026-05-05", stepCount: 1, flightsClimbed: 1)]

// Act
let count = try await exporter.export(data: points, config: makeConfig(mode: .file))

// Assert
#expect(count == 1)
```
