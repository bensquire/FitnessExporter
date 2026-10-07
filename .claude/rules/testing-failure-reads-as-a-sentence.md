---
title: A Failure Reads as a Sentence
impact: MEDIUM
impactDescription: A bare comparison fails as a pair of values with no story
tags: [testing, expectations, messages, swift-testing]
paths: ["FitnessExporterTests/**/*.swift"]
---

## A Failure Reads as a Sentence

**Impact: MEDIUM**

Swift Testing already prints both sides of a failed `#expect`, so a single
comparison whose expression says what it checks
(`#expect(error.code == .appTransportSecurityRequiresSecureConnection)`) needs
nothing more, and that is most of this suite's 86. An `#expect` gets a message
when the expression alone wouldn't say which case failed or why it matters: in
a loop or across `@Test(arguments:)`, the message names the input; for a
figure, it gives the figure. `Issue.record` always says what was expected, as
the suite's four do (`"Expected .existingFileCorrupt, got \(error)"`).
`try #require` is for the thing the rest of the test can't run without. The
message is a string literal, with interpolation; the macro takes a `Comment`,
so a concatenated `String` doesn't compile.

**Incorrect:**

```swift
for point in merged.data {
    #expect(point.stepCount > 0)                              // which day?
}
#expect(json["weightKg"] == nil, "weight: " + String(describing: json["weightKg"]))   // doesn't compile
```

**Correct:**

```swift
for point in merged.data {
    #expect(point.stepCount > 0, "\(point.date) lost its steps in the merge")
}
Issue.record("Expected export to throw for HTTP URL")
```
