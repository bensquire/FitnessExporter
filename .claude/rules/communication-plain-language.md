---
title: Messages to the User Are Plain Language
impact: MEDIUM
impactDescription: The reader gets what they need, can find it, understand it and use it — ISO 24495-1:2023
tags: [communication, plain-language, iso-24495]
---

## Messages to the User Are Plain Language

**Impact: MEDIUM**

Messages follow ISO 24495-1:2023's four principles: the reader gets what they
need, can find it, can understand it, and can use it.

- **Lead with what matters.** The outcome or the answer first; the reasoning
  after. If something failed, say so in the first line.
- **Make it findable.** Headings and short lists when a message has more than
  one part. One idea per paragraph.
- **Make it understandable.** Short sentences. Everyday words where they will
  do; a term of art only where it is the precise one, defined the first time.
  Active voice: say who did what.
- **Make it usable.** Numbers carry their unit and what they are compared with.
  End with what the reader can do next, or that nothing is needed. Put a caveat
  where it will be read, not at the bottom.
- **Say what was done, not what was intended.** A test that was not run was not
  run. A check skipped is named as skipped. A check that could only run in the
  simulator says so, rather than standing in for a device.

The same holds for the app's own text: an error the user sees says what
happened and what to do, as `FileExporterError.existingFileCorrupt` does
("…was left untouched. Move or delete it and try again.").

**Incorrect:**

```
I've improved the weight export, which should handle most cases now; there
may be some edge cases with multiple weigh-ins.
```

**Correct:**

```
Weight now exports the day's last weigh-in: in the simulator, 80.1 kg at 8:00
then 79.6 kg at 21:00 exported as 79.6. Not tried on a device. Nothing is
committed.
```

Reference: ISO 24495-1:2023, Plain language — Part 1: Governing principles and guidelines.
