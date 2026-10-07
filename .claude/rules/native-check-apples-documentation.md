---
title: Check Apple's Documentation Before Using Its API
impact: HIGH
impactDescription: A guessed default compiles and quietly does nothing; an asserted platform fact goes unchecked
tags: [native, documentation, scrapple, apple, healthkit, wwdc]
paths: ["**/*.swift", "project.yml"]
---

## Check Apple's Documentation Before Using Its API

**Impact: HIGH**

Before using a system API you are not certain of, before building anything the
system might already provide, and before stating a platform fact in a comment,
look it up. `scrapple` holds Apple's framework documentation, WWDC transcripts
and sample code offline. The `apple-docs` skill says how to ask it, and where
to look when a page is only a declaration: the SDK headers, then the running
app.

A decision that rests on what a page says carries the page's path in a
one-line comment, so the next reader can check it too. A doc that contradicts a
rule here is raised with the user, not followed or ignored in silence.

**Incorrect (a platform fact, asserted without a source — and wrong):**

```swift
// After requestAuthorization we know whether the user allowed reading steps.
isAuthorized = true
```

**Correct (looked up, and the claim cut to what the docs support):**

```sh
scrapple -h show "/documentation/healthkit/hkhealthstore/authorizationstatus(for:)"
```

```swift
// The request finished; it doesn't say what was granted. A denied read type
// reads as no data. /documentation/healthkit/hkhealthstore/authorizationstatus(for:)
```

Reference: `scrapple` (github.com/searlsco/scrapple); Apple Developer Documentation.
