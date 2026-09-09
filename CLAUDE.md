# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

A `Makefile` wraps the common commands:

```bash
make build    # debug build for iOS (generic device)
make test     # run unit tests on iOS Simulator
make icon     # regenerate the app icon from icon/makeicon.swift
make clean    # remove build/ and clean Xcode build products
```

The app icon is generated, not drawn by hand: `icon/makeicon.swift` renders a 1024 px opaque PNG straight into `Assets.xcassets/AppIcon.appiconset/icon.png` plus a 256 px `icon/preview.png`. It follows the same flat-tile / white-glyph / soft-shadow style as the macOS apps in `../../macos/` (PaperDrop, PaperPress, Prospect). Edit the script and run `make icon`, which also runs oxipng (brew install oxipng) on the output; never edit the PNG.

Raw xcodebuild equivalents:
```bash
xcodegen generate  # regenerate .xcodeproj after changing project.yml
xcodebuild -scheme FitnessExporter -destination "generic/platform=iOS" build CODE_SIGNING_ALLOWED=NO
```

## Tests

```bash
make test
# or directly:
xcodebuild -scheme FitnessExporter -destination "platform=iOS Simulator,OS=latest,name=iPhone 17 Pro" test CODE_SIGNING_ALLOWED=NO
```

Tests live in `FitnessExporterTests/` and use the **Swift Testing** framework (`import Testing`, `@Test`, `#expect()`). `TestHelpers.swift` holds the shared `makeConfig(mode:url:)` fixture. The test target compiles the app's source files directly (excluding `App/FitnessExporterApp.swift`) so there is no `@testable import` — all types are in scope directly.

What is tested: `ExportMode`, `ExportError`, `ExportResult`, `HealthDataPoint`, `YearExport`, `ExportService.makeEncoder()`, `HTTPExporter` URL validation, and `FileExporter` (via an injected temp directory: per-year files, merge with existing file, refusal to overwrite a corrupt file).

What is not tested: `HealthKitService` (requires HealthKit on device), UI views.

## Architecture

This is a Swift 6 iOS app using strict concurrency throughout.

**Data flow:**
1. User taps "Export Now", calling `AppViewModel.exportNow()`
2. `AppViewModel` requests HealthKit authorization on first export per launch (HealthKit only prompts for undecided types), asks `HealthKitService` to fetch data, then passes it to `ExportService`
3. `ExportService` routes to either `HTTPExporter` (POST JSON) or `FileExporter` (write per-year JSON files to Documents)

**Concurrency model:**
- All services are `actor` types — isolate their own state
- `AppViewModel` is `@MainActor ObservableObject` — all `@Published` mutations are automatically on main
- `ExportConfiguration` is a `Sendable` value type used to snapshot settings before crossing actor boundaries
- `HKStatisticsCollectionQuery` is not async — bridged via `withCheckedThrowingContinuation` in `HealthKitService.fetchDailyStatistics(type:unit:statistic:start:end:)`, which returns `[String: Double]` keyed by date. `DailyStatistic` (`.sum` for steps/flights/energy, `.mostRecent` for weight) supplies both the query option and the accessor. Days without samples are absent from the dictionary
- Adding a HealthKit type: append it to `HealthKitService.readTypes`, add a query in `fetchHealthData`, extend `HealthDataPoint` (with a `decodeIfPresent` default), update the usage string in `project.yml` and `PRIVACY.md`

**Key types:**
- `HealthDataPoint` — one day's steps, flights climbed, optional `weightKg` (last weigh-in, omitted when nil), `caloriesActive`, `caloriesResting`, plus a computed `caloriesTotal` that is encoded but never decoded. Custom `init(from:)` defaults the newer fields so year files from v1.0 still decode. Date as `"yyyy-MM-dd"` string
- `YearExport` — root JSON object written per year file, wraps `[HealthDataPoint]`
- `ExportResult` — `.success(exportedAt:recordCount:)` or `.failure(ExportError)`, used across actor boundaries
- `ExportConfiguration` — snapshot of user settings (mode, httpURL, httpToken, lookbackDays)
- `ExportMode` — `.http` or `.file`
- `LookbackPeriod` — `.oneDay`, `.sevenDays`, `.oneMonth`, `.oneYear`, `.allTime`

**Settings persistence:**
- User settings stored via `@AppStorage` (UserDefaults)

**Shared utilities:**
- `ExportService.makeEncoder()` / `makeDecoder()` — single source for `JSONEncoder`/`JSONDecoder` config (iso8601, prettyPrinted, sortedKeys); used by both exporters
- All error types (`ExportError`, `HealthKitError`, `FileExporterError`) conform to `LocalizedError` with `errorDescription` so messages survive erasure to `any Error`
- Date formatting uses `HealthDataPoint.dateFormatter` — `DateFormatter` with `dateFormat = "yyyy-MM-dd"`, `locale = en_US_POSIX`, `timeZone = .current`

**File output:** One JSON file per year (e.g. `2026.json`) written atomically to the app's Documents directory. `FileExporter` groups data by year, merges with any existing year file (new days replace same-date entries, other days are preserved), sorts ascending by date, and wraps in `YearExport`. If an existing year file cannot be decoded the export fails rather than overwriting it. `FileExporter(directoryURL:)` accepts an injected directory for tests. Files accessible via Files app → On My iPhone → Fitness Exporter.

**HTTP output:** POSTs `[HealthDataPoint]` array as JSON body. Bearer token is optional.

## Project Config

- `project.yml` is the XcodeGen spec — edit this instead of `.xcodeproj` directly, then run `xcodegen generate`
- Bundle ID: `com.bengsfort.FitnessExporter`
- Deployment target: iOS 18.0, Swift 6.0
- iPhone only (`TARGETED_DEVICE_FAMILY: "1"`)

## CI

CI runs on push/PR to `main` via `.github/workflows/ci.yml`: lint with SwiftLint, generate project, run tests on iOS Simulator.
