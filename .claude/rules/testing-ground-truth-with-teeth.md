---
title: Ground Truth Is the JSON Written, and the Bar Has Teeth
impact: HIGH
impactDescription: An export can succeed, report the right count and still hold the wrong days
tags: [testing, ground-truth, json, fixtures, compatibility]
paths: ["FitnessExporterTests/**/*.swift"]
---

## Ground Truth Is the JSON Written, and the Bar Has Teeth

**Impact: HIGH**

Build the input so its answer is known — days across a year boundary, an
overlap between two exports, a v1.0 year file, a file that isn't JSON — then
judge the output by what was written: read the year file back and decode it,
or parse the encoded bytes with `JSONSerialization`, which knows nothing of the
app's `Codable` code, and check the keys and values. A returned count is
checked too, but it is not the proof.

The bar is set so it can't be cleared by accident: the merge test overlaps one
day with a changed value, so a merge that kept the old one fails;
`ignoresTotalEnergyOnDecode` feeds a total of 999 against parts summing to 300;
`refusesToOverwriteCorruptExistingFile` compares the file's bytes before and
after, not just the error. When a bug is fixed, a test pins it, as the 1.1.0
merge fix is pinned by these.

What the suite can't see is said plainly: `HealthKitService`'s queries need
HealthKit data, so only its day-filling (`dataPoints`) is tested, and
`HTTPExporter`'s requests are observed through a stub `URLProtocol` on an
injected session (`quality-dependency-injection`), never a real server. A change
to the queries is checked in the app (`workflow-checking-work`), not assumed
from the tests that pass.

**Incorrect (a bar with no teeth — passes on a file that holds nothing useful):**

```swift
#expect(count == 2)
#expect(FileManager.default.fileExists(atPath: dir.appendingPathComponent("2026.json").path))
```

**Correct (the file read back, the overlap checked):**

```swift
let merged = try readYear(2026)
#expect(
    merged.data == [
        HealthDataPoint(date: "2026-01-01", stepCount: 1_000, flightsClimbed: 1),
        HealthDataPoint(date: "2026-01-02", stepCount: 2_500, flightsClimbed: 3),
        HealthDataPoint(date: "2026-01-03", stepCount: 3_000, flightsClimbed: 4),
    ])
```
