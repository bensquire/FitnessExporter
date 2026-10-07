---
title: Diagnostics Stay Out of Release, and Out of the User's Data
impact: MEDIUM
impactDescription: A health app's log is a place health data and tokens can leak to
tags: [workflow, diagnostics, logging, privacy]
paths: ["FitnessExporter/**/*.swift"]
---

## Diagnostics Stay Out of Release, and Out of the User's Data

**Impact: MEDIUM**

Diagnostics worth keeping are compiled only into Debug builds, as the two
`print` calls in `AppViewModel.exportNow()` are (`#if DEBUG`). They print what
went wrong — an error's message — and never the bearer token, the endpoint's
query string, or a day's health values.

A diagnostic that has to survive into Release goes through `os.Logger`, whose
interpolated values are redacted by default (/documentation/os/logger); mark a
value `.public` only when it carries nothing about the user.

Diagnostics for one investigation go in a separate file, marked temporary, and
are deleted before handover. Weaving them into `HealthKitService` or
`FileExporter` means editing them again to take them out.

**Incorrect (in Release, and carrying the user's data):**

```swift
print("POST \(config.httpURL) token=\(config.httpToken) body=\(data)")
```

**Correct (Debug only, the error and nothing else):**

```swift
#if DEBUG
    print("Export error: \(error.message)")
#endif
```
