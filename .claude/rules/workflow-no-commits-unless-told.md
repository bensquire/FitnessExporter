---
title: Never Commit or Push Unless Told To
impact: CRITICAL
impactDescription: A committed feature the user did not want costs a revert and trust
tags: [workflow, git, commits, handover]
---

## Never Commit or Push Unless Told To

**Impact: CRITICAL**

Commit and push only when the user has said to in this conversation. "Make it
work", "fix it" and "finish it" are not that instruction. "Commit", "commit and
push", or a reply that says the work stays, are. When told to commit on
`main`, branch first and say so.

The user tries a feature before deciding whether it stays. A working feature is
not the same as a wanted one, and only they can tell the difference.

This is about product decisions, not about editing: change files without asking
permission.

**Incorrect (committing because the work is done):**

```
Tests pass and the new field is in the export, so I've committed and pushed.
```

**Correct (handing over and waiting):**

```
Tests pass. The app is running in the iPhone 17 Pro simulator — add a weigh-in
in the simulator's Health app, export in Local File mode, and check 2026.json.
Nothing is committed; say if it stays.
```
