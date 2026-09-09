# Fitness Exporter

An iOS app that reads step count and flights climbed from HealthKit and exports the data to an HTTP endpoint or local JSON files.

## Features

- Exports daily step count, flights climbed, active and resting energy (kcal), and the most recent weigh-in (kg) per day
- Two export modes: HTTP POST or local JSON files (one file per year, e.g. `2026.json`)
- Preset lookback periods: 1 Day, 7 Days, 1 Month, 1 Year, All Time
- Test export with mock data to verify your configuration
- Files accessible via Files app on iPhone

## Requirements

- iOS 18.0+
- iPhone with Health app

## Development

### Prerequisites

```bash
brew install xcodegen
```

### Setup

```bash
git clone git@github.com:bensquire/healthkit-exporter.git
cd healthkit-exporter
xcodegen generate
open FitnessExporter.xcodeproj
```

### Common tasks

```bash
make build   # build (unsigned, for local testing)
make test    # run unit tests
make clean   # clean build artefacts
```

## Data format

Each year's data is written to `<year>.json`:

```json
{
  "year" : 2026,
  "exportedAt" : "2026-03-03T12:00:00Z",
  "data" : [
    {
      "caloriesActive" : 512,
      "caloriesResting" : 1650,
      "caloriesTotal" : 2162,
      "date" : "2026-01-01",
      "flightsClimbed" : 4,
      "stepCount" : 8542,
      "weightKg" : 78.4
    }
  ]
}
```

`weightKg` is omitted on days with no weigh-in. `caloriesTotal` is `caloriesActive + caloriesResting`. HTTP mode posts the bare `data` array.

## License

MIT
