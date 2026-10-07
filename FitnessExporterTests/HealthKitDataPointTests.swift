import Foundation
import Testing

/// How the days HealthKit returned become the exported points. The queries themselves
/// need HealthKit data and authorization, which the test target doesn't have.
struct HealthKitDataPointTests {
    private let days = ["2026-01-01", "2026-01-02", "2026-01-03"]

    @Test func reportsNoDataWhenHealthReturnedNoSampleAtAll() {
        // Act & Assert
        #expect(throws: HealthKitError.noData) {
            try HealthKitService.dataPoints(
                days: days, steps: [:], flights: [:], weights: [:], active: [:], resting: [:])
        }
    }

    @Test func fillsEveryDayOfTheWindowAroundASingleSample() throws {
        // Act
        let points = try HealthKitService.dataPoints(
            days: days, steps: ["2026-01-02": 2_500], flights: [:], weights: [:], active: [:], resting: [:])

        // Assert
        #expect(
            points == [
                HealthDataPoint(date: "2026-01-01", stepCount: 0, flightsClimbed: 0),
                HealthDataPoint(date: "2026-01-02", stepCount: 2_500, flightsClimbed: 0),
                HealthDataPoint(date: "2026-01-03", stepCount: 0, flightsClimbed: 0),
            ])
    }

    @Test func aWeighInAloneIsEnoughToExport() throws {
        // Act
        let points = try HealthKitService.dataPoints(
            days: days, steps: [:], flights: [:], weights: ["2026-01-03": 72.34], active: [:], resting: [:])

        // Assert
        #expect(points.map(\.weightKg) == [nil, nil, 72.3])
    }
}
