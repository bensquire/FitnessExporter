---
title: One Behaviour Per Test, Named as a Sentence
impact: HIGH
impactDescription: A test of several things fails for one and hides the rest
tags: [testing, naming, scope, swift-testing]
paths: ["FitnessExporterTests/**/*.swift"]
---

## One Behaviour Per Test, Named as a Sentence

**Impact: HIGH**

A test pins one behaviour, and its name says which, as a sentence that reads in
the report: `refusesToOverwriteCorruptExistingFile`,
`mergesIntoLegacyFileWrittenBeforeNewerFieldsExisted`, `omitsWeightKeyWhenNil`,
`ignoresTotalEnergyOnDecode`. A name with "and" that lists unrelated checks is
usually two tests; one with "and" that describes a single outcome is fine. When
the same behaviour is asked of several inputs — URLs the exporter must refuse,
lookbacks, legacy shapes — use `@Test(arguments:)` rather than copying the
test.

Test the behaviour, not the implementation: what the year file contains after
an export, which keys the JSON has, which error a bad URL gets — not which
private function ran. The test target compiles the app's sources directly, so
internal types are in scope; that is for reaching a real seam, not for
asserting on scaffolding.

**Incorrect:**

```swift
@Test func fileExporterWorks() async throws {
    // writes, merges, sorts, refuses a corrupt file and counts, all in one go
}
```

**Correct:**

```swift
@Test func writesOneFilePerYearSortedByDate() async throws { … }
@Test func mergesWithExistingFilePreservingOlderDays() async throws { … }
@Test func refusesToOverwriteCorruptExistingFile() async throws { … }
```
