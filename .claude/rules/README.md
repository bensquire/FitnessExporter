---
title: Fitness Exporter Rules Index
impact: LOW
impactDescription: About the rules themselves; loads only when a rule is being written
tags: [meta, rules]
paths: [".claude/rules/*.md"]
---

# Fitness Exporter Rules

Modular, machine-readable rules for working on Fitness Exporter. Each file is
one rule, named `{section}-{rule-name}.md`, with YAML frontmatter Claude Code
reads: a rule with `paths` loads only when a matching file is in play; one
without applies always. `_sections.md` defines the sections and their order;
`_template.md` is the shape of a new rule.

## Rules Index

### Workflow

- [workflow-challenge-the-rules](workflow-challenge-the-rules.md) - A rule in the way is raised with the user, not obeyed or broken in silence
- [workflow-no-commits-unless-told](workflow-no-commits-unless-told.md) - Never commit or push unless told to; branch first on `main`
- [workflow-hand-over-for-trial](workflow-hand-over-for-trial.md) - Build, run in the simulator, say what to enter and look at, stop
- [workflow-checking-work](workflow-checking-work.md) - Lint, the whole suite, a device build when the project changes, then the app for what tests can't reach
- [workflow-commit-messages](workflow-commit-messages.md) - What and why, in prose
- [workflow-diagnostics](workflow-diagnostics.md) - Debug-only, no health data or token; `Logger` if it must ship

### Quality

- [quality-separation-of-concerns](quality-separation-of-concerns.md) - Model, services, view model, views; dependencies run one way
- [quality-dependency-injection](quality-dependency-injection.md) - A configuration snapshot in; a directory or session as a defaulted parameter
- [quality-readability](quality-readability.md) - Code reads like the prose around it
- [quality-consistency](quality-consistency.md) - Match the code around you; reuse the encoder, formatter and error types that exist
- [quality-extensible](quality-extensible.md) - Add a case and its behaviour, not an `if`
- [quality-performant](quality-performant.md) - Concurrent, aggregated HealthKit queries; measured on a device
- [quality-secure](quality-secure.md) - Read only, HTTPS only, token in the Keychain; `PRIVACY.md` kept true
- [quality-comments-carry-measurements](quality-comments-carry-measurements.md) - Short, says why, carries the number or the doc path
- [quality-formatting-is-the-tools](quality-formatting-is-the-tools.md) - swift-format decides, at the toolchain's version
- [quality-images-minified](quality-images-minified.md) - Lossless first, then quantized to the edge, judged at 1:1

### Testing

- [testing-arrange-act-assert](testing-arrange-act-assert.md) - Each step present, in order, marked
- [testing-one-behaviour-per-test](testing-one-behaviour-per-test.md) - One behaviour, named as a sentence
- [testing-ground-truth-with-teeth](testing-ground-truth-with-teeth.md) - Judge the JSON written; set bars that can't be cleared by accident
- [testing-deterministic](testing-deterministic.md) - Literal fixtures, own temp dirs, no shared settings, nothing off the machine
- [testing-fast](testing-fast.md) - Fast by paying only for what the test needs, never by seeing less
- [testing-failure-reads-as-a-sentence](testing-failure-reads-as-a-sentence.md) - A message where the expression alone doesn't tell the story

### Native

- [native-use-the-systems-feature](native-use-the-systems-feature.md) - SwiftUI forms, HealthKit statistics, the Keychain, the Files app
- [native-small-bundle](native-small-bundle.md) - About 628 KB, no frameworks of its own
- [native-check-apples-documentation](native-check-apples-documentation.md) - Look it up in `scrapple` before using, copying or asserting

### Communication

- [communication-plain-language](communication-plain-language.md) - ISO 24495-1: relevant, findable, understandable, usable
