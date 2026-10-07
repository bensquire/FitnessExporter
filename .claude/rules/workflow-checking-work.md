---
title: A Change Is Checked, Not Believed
impact: CRITICAL
impactDescription: CI lints the whole tree and runs the suite on the simulator; HealthKit itself is checked by nothing automatic
tags: [workflow, verification, tests, lint, build, healthkit]
paths: ["FitnessExporter/**", "FitnessExporterTests/**", "Makefile", "project.yml"]
---

## A Change Is Checked, Not Believed

**Impact: CRITICAL**

Before saying a change is done:

1. **`make lint`** — `swift format lint --strict` over
   `FitnessExporter/` and `FitnessExporterTests/`, as CI and the pre-commit
   hook run it. 0.15 s.
2. **`make test`**, the whole suite on the iPhone 17 Pro simulator: 46 tests in
   11 suites, 10–14 s warm with the simulator's start-up. It regenerates the
   project first, so a change to `project.yml` is checked too.
3. **`make build`** when the change touches `project.yml`, the entitlements,
   `Info.plist` keys or the asset catalog. It builds for a generic iOS device,
   which the simulator tests don't.
4. **The app, for anything the suite can't reach.** `HealthKitService`'s
   queries, `AppViewModel` and the views have no tests (only
   `HealthKitService.dataPoints` does): the test target runs without HealthKit
   data and without the app. A change there is checked in the
   running app (`workflow-hand-over-for-trial`): the simulator's Health app
   with samples entered by hand, or the user's iPhone. Say which, and what
   was entered.

A change to what the app reads or sends — a new HealthKit type, a new field, a
new destination — is checked against `PRIVACY.md` and the
`NSHealthShareUsageDescription` in `project.yml` too, and both are updated in
the same change.

Report what was run and what it showed. A check that was skipped is named as
skipped, not left out.

**Incorrect (one suite, no lint, HealthKit assumed):**

```
Ran FileExporterTests; passes. The weight query should work the same way. Done.
```

**Correct:**

```
make lint clean; make test: 46 tests in 11 suites pass; make build succeeds.
Not run on a device: in the simulator I added two weigh-ins on 3 October
(80.1 kg, then 79.6 kg) and the export wrote weightKg 79.6 for that day.
```
