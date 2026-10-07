---
title: Every Run Gives the Same Answer
impact: HIGH
impactDescription: A flaky test is a test nobody trusts
tags: [testing, determinism, fixtures, network, files]
paths: ["FitnessExporterTests/**/*.swift"]
---

## Every Run Gives the Same Answer

**Impact: HIGH**

- **Fixtures are literal.** Data points are written out in the test, and
  their dates are `yyyy-MM-dd` strings, so no test depends on today's date or
  the time zone. Where a `Date` is needed it is fixed
  (`Date(timeIntervalSince1970: 0)`), or used only as an opaque value that is
  compared with itself. `AppViewModel.sendTestExport()` uses `Int.random`; it is
  the app's mock data, not a fixture, and no test reads it.
- **Files go in the test's own directory.** `FileExporterTests` makes a fresh
  temporary directory per test in `init` and removes it in `deinit` (Swift
  Testing makes a new instance per test), and hands it to
  `FileExporter(directoryURL:)`. No test touches the app's Documents folder.
- **No shared settings.** No test reads or writes `UserDefaults` or the
  Keychain; `AppViewModel`, which does, is not under test.
  `KeychainServiceTests` hand `KeychainService` fake Security calls: the
  unhosted test bundle has no Keychain access (`-34018`), and a fake can refuse
  a write on demand.
- **Nothing leaves the machine.** No test makes a real request.
  `HTTPExporterRequestTests` hands `HTTPExporter` an ephemeral session whose
  only protocol is `StubURLProtocol`, which answers with the status the test
  sets and records what was sent; the suite is `.serialized` because that
  record is shared.
- **Waiting is for something.** Async results are awaited, not slept for.

**Incorrect:**

```swift
let config = makeConfig(url: "https://httpbin.org/post")              // a real server, sometimes down
let point = HealthDataPoint(date: HealthDataPoint.dateFormatter.string(from: Date()), …)   // today's date
```

**Correct:**

```swift
let exporter = HTTPExporter(session: StubURLProtocol.session(answering: 200))   // answered in-process
let point = HealthDataPoint(date: "2026-01-02", stepCount: 2_500, flightsClimbed: 3)
```
