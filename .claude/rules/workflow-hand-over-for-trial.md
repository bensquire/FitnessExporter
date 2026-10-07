---
title: Hand Work Over for the User to Try
impact: CRITICAL
impactDescription: The user judges a feature in the app, not in a report
tags: [workflow, handover, simulator, healthkit, app]
---

## Hand Work Over for the User to Try

**Impact: CRITICAL**

When a change the user can see in the app is done and checked, put it in front
of them there. A change to the tests, the rules or the docs is handed over as
what it is: the suite's result, the file to read.

1. Build for the simulator, signed to run locally so the HealthKit entitlement
   is embedded:
   `xcodebuild -scheme FitnessExporter -destination "platform=iOS Simulator,name=iPhone 17 Pro" build`
   (`make test` and `make build` pass `CODE_SIGNING_ALLOWED=NO`, which leaves
   it out).
2. Boot that simulator, install the `.app` from `Debug-iphonesimulator` under
   DerivedData, and launch it: `xcrun simctl boot <udid>`,
   `xcrun simctl install <udid> <app>`,
   `xcrun simctl launch <udid> com.bengsfort.FitnessExporter`, then
   `open -a Simulator` so the user sees it. Installing over an earlier copy
   keeps its settings (`@AppStorage`) and token (Keychain), so say which the
   trial assumes.
3. Say what to look at and what to enter. The simulator's Health app starts
   empty; data a trial needs is added there by hand. In Local File mode the
   year files are in the app's data container under `Documents/`
   (`xcrun simctl get_app_container <udid> com.bengsfort.FitnessExporter data`).
   A trial against real data is the user's: they run it on their iPhone from
   Xcode, signed with their own team.
4. Stop.

**Incorrect (declaring done from the command line):**

```
The suite passes and HealthDataPoint encodes weightKg. Done.
```

**Correct (the app running, the eye pointed):**

```
Running in the iPhone 17 Pro simulator, Local File mode, lookback 7 Days.
In Health, add a weigh-in for today, then tap Export Now: today's entry in
2026.json should have weightKg, and yesterday's should not have the key at all.
```
