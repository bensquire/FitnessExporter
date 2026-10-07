---
title: Formatting Is Decided by the Tools
impact: MEDIUM
impactDescription: No formatting diffs, no style arguments in review, no drift between machines
tags: [quality, formatting, swift-format, hooks, lint]
paths: ["FitnessExporter/**/*.swift", "FitnessExporterTests/**/*.swift", ".swift-format"]
---

## Formatting Is Decided by the Tools

**Impact: MEDIUM**

swift-format and `.swift-format` (4 spaces, 110 columns, ordered imports) are
the formatting authority and the only linter. It covers `FitnessExporter/` and
`FitnessExporterTests/`; `icon/makeicon.swift` is a script outside them.

- **As you edit**, the hooks in `.claude/hooks` format each Swift file with
  swift-format and then report any line still over 110 columns, once
  `.claude/settings.json` registers them as `PostToolUse` hooks (it doesn't
  exist yet). swift-format cannot break a long string or comment by itself;
  reflow what the hook reports before handing over. The hooks are advisory so
  that a formatting hiccup never blocks an edit.
- **The whole tree:** `make lint` (`swift format lint --strict`; what CI and
  the pre-commit hook run) and `make format` (swift-format in place).
- **Versions:** swift-format comes with Xcode's toolchain, and CI pins Xcode
  26.6 (swift-format 6.3.0), so a local Xcode 26.6 lints exactly as CI does.

Three of its rules are about safety, not layout: `NeverForceUnwrap`,
`NeverUseForceTry` and `NeverUseImplicitlyUnwrappedOptionals`. A nil or a
throw goes into the error path the code already has (`fetchHealthData` throws
`queryFailed` when its date range can't be worked out), and a test unwraps
with `try #require`. Where a value provably can't be nil and handling it would
be noise, `// swift-format-ignore: NeverForceUnwrap` (or the rule in question)
goes on the line above, with the invariant in a short comment; there are none
in this repo.

Leave formatting to the tools rather than hand-formatting around them, and
leave a rule they enforce on rather than disabling it inline, except as above. One thing
swift-format does that reads oddly at first: a wrapped condition puts its
opening brace on a line of its own. That is the house style.

**Incorrect:**

```swift
// swift-format-ignore
if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
```

**Correct:**

```swift
if let httpResponse = response as? HTTPURLResponse,
    !(200..<300).contains(httpResponse.statusCode)
{
```
