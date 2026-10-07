---
title: Challenge a Rule When It Is in the Way
impact: CRITICAL
impactDescription: The rules serve the best app; a rule that blocks a better one is a defect to raise, not a wall to work around
tags: [workflow, rules, architecture, standards, judgement]
---

## Challenge a Rule When It Is in the Way

**Impact: CRITICAL**

These rules exist to make the best app, not to be obeyed for their own sake.
When following one would make the code, the architecture, a standard or the
product worse — or when a better way exists that a rule forbids — raise it with
the user, plainly: which rule, what it costs here, what the alternative is, and
what it would take. Then wait. Sometimes the answer is to rearchitect, change a
standard, or rewrite the rule.

Complying in silence and breaking the rule in silence both hide the decision,
so do neither. A rule the user has just confirmed stands.

**Incorrect (working around it, or working under it in silence):**

```
"Use the system's feature" says HealthKit sums the steps, so the per-sample
query I added for heart rate goes through HKStatisticsCollectionQuery too.
```

**Correct (the case made, the decision left with the user):**

```
Heart rate doesn't fit the statistics query the way steps do: a day's
"sum" of beats per minute means nothing, and `.discreteAverage` gives a
mean the export format has no field for. I'd add a `DailyStatistic.average`
case and a `heartRateAvg` field. Want that, or min/max as well?
```
