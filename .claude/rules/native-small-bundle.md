---
title: Small, Because the System Does the Rest
impact: MEDIUM
impactDescription: The app is 628 KB; growth is a signal the wrong path was taken
tags: [native, ios, bundle, dependencies, size]
paths: ["project.yml", "FitnessExporter/Assets.xcassets/**", "icon/**"]
---

## Small, Because the System Does the Rest

**Impact: MEDIUM**

The Release `FitnessExporter.app` for a generic iOS device is 628 KB (6 October
2026, unsigned): a 536 KB arm64 executable, a 68 KB asset catalog, and no
`Frameworks` folder. There are no Swift packages; HealthKit, Security, SwiftUI
and Foundation are the system's. A Debug build is larger (924 KB) because
Xcode adds a 740 KB preview dylib to it, so measure Release:

```sh
xcodebuild -scheme FitnessExporter -configuration Release -destination "generic/platform=iOS" \
    -derivedDataPath build/size build CODE_SIGNING_ALLOWED=NO
du -sh build/size/Build/Products/Release-iphoneos/FitnessExporter.app
```

That size is a consequence of using the system's features and a check on
them. A feature that arrives with a package, a bundled networking or JSON
library, or a second copy of something iOS provides is a sign the wrong path
was taken. Growth needs a reason, stated in the commit with the before and
after.

**Incorrect:**

```
Add a networking package for the HTTP export   # URLSession does it in one call
```

**Correct:**

```swift
let (_, response) = try await session.data(for: request)   // a URLSession, from Foundation
```
