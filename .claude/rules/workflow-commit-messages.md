---
title: Commit Messages Say Why
impact: HIGH
impactDescription: The history is where the reasoning is kept
tags: [workflow, git, commits, history]
---

## Commit Messages Say Why

**Impact: HIGH**

When told to commit, the message says what changed and why, in prose: the
problem, what was done about it, and what was tried and taken out, if anything
was. A figure goes in where one decided it. A commit of several changes lists
them, each with its reason, as this repo's history does. One commit per change
of meaning: work that was already in the tree and is not part of the change
goes in its own commit, described honestly. End with the attribution lines the
session prescribes.

**Incorrect:**

```
Fix CI
```

**Correct:**

```
CI: fail the test step when xcodebuild fails

The test step pipes xcodebuild into xcpretty. GitHub's default shell for
`run` is `bash -e` without pipefail, so the step's exit status was
xcpretty's and a failing build or test still passed CI.
```
