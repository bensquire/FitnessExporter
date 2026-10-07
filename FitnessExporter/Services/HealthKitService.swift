import Foundation
import HealthKit

enum HealthKitError: LocalizedError, Equatable, Sendable {
    case notAvailable
    /// HealthKit returned no sample of any type for the period. A denied read looks
    /// exactly like this, so the message says where to check access.
    case noData
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Health data isn't available on this device, so there's nothing to export."
        case .noData:
            return "Health returned no data for this period, so nothing was exported. "
                + "If you expected some, check what Fitness Exporter is allowed to read "
                + "in Settings or the Health app."
        case .queryFailed(let detail):
            return "Couldn't read from Health: \(detail). Try exporting again."
        }
    }
}

/// Which per-day statistic to read for a quantity type. Ties the query option and
/// the accessor together so they cannot disagree.
enum DailyStatistic: Sendable {
    /// Total of all samples in the day (steps, energy).
    case sum
    /// Last sample recorded in the day (weight).
    case mostRecent

    var hkOptions: HKStatisticsOptions {
        switch self {
        case .sum: return .cumulativeSum
        case .mostRecent: return .mostRecent
        }
    }

    func quantity(from statistics: HKStatistics) -> HKQuantity? {
        switch self {
        case .sum: return statistics.sumQuantity()
        case .mostRecent: return statistics.mostRecentQuantity()
        }
    }
}

actor HealthKitService {
    private let store = HKHealthStore()

    /// Every quantity type the app reads. Adding a type here is enough to
    /// have HealthKit prompt existing users for it on the next authorization request.
    /// /documentation/healthkit/hkhealthstore/requestauthorization(toshare:read:completion:)
    private static let readTypes: Set<HKObjectType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.flightsClimbed),
        HKQuantityType(.bodyMass),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.basalEnergyBurned),
    ]

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        try await store.requestAuthorization(toShare: [], read: Self.readTypes)
    }

    /// Whether the permission sheet has already been shown for every type the app
    /// reads. It says nothing about what the user allowed: HealthKit doesn't reveal a
    /// denied read. /documentation/healthkit/authorizing-access-to-health-data
    func hasRequestedAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        let status = try? await store.statusForAuthorizationRequest(toShare: [], read: Self.readTypes)
        return status == .unnecessary
    }

    /// Fetches one statistic per day for a quantity type over the given date range.
    /// Returns a dictionary keyed by "yyyy-MM-dd" date strings. Days with no
    /// samples are absent rather than zero.
    func fetchDailyStatistics(
        type quantityType: HKQuantityTypeIdentifier,
        unit: HKUnit,
        statistic: DailyStatistic,
        start: Date,
        end: Date
    ) async throws -> [String: Double] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let type = HKQuantityType(quantityType)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let interval = DateComponents(day: 1)

        let calendar = Calendar.current
        let anchorDate = calendar.startOfDay(for: start)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: statistic.hkOptions,
                anchorDate: anchorDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
                    return
                }

                guard let results else {
                    continuation.resume(throwing: HealthKitError.queryFailed("No results returned"))
                    return
                }

                // Extract Sendable primitives before crossing actor boundary
                var daily: [String: Double] = [:]
                let formatter = HealthDataPoint.dateFormatter

                results.enumerateStatistics(from: start, to: end) { statistics, _ in
                    guard let quantity = statistic.quantity(from: statistics) else { return }

                    let dateStr = formatter.string(from: statistics.startDate)
                    daily[dateStr] = quantity.doubleValue(for: unit)
                }

                continuation.resume(returning: daily)
            }

            store.execute(query)
        }
    }

    /// Fetches steps, flights climbed, weight, active energy and resting energy for
    /// the given number of past days, merged into an array of HealthDataPoint
    /// sorted by date ascending. Every day in the window is present; counts and
    /// energies default to 0 on days without samples, weight is nil. Throws `noData`
    /// when the window holds no sample at all.
    func fetchHealthData(lookbackDays: Int) async throws -> [HealthDataPoint] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday),
            let start = calendar.date(byAdding: .day, value: -(lookbackDays - 1), to: startOfToday)
        else {
            throw HealthKitError.queryFailed("the date range couldn't be worked out")
        }

        func fetch(_ type: HKQuantityTypeIdentifier, _ unit: HKUnit, _ statistic: DailyStatistic) async throws
            -> [String: Double]
        {
            try await fetchDailyStatistics(
                type: type, unit: unit, statistic: statistic, start: start, end: startOfTomorrow)
        }

        async let stepsTask = fetch(.stepCount, .count(), .sum)
        async let flightsTask = fetch(.flightsClimbed, .count(), .sum)
        async let weightTask = fetch(.bodyMass, .gramUnit(with: .kilo), .mostRecent)
        async let activeTask = fetch(.activeEnergyBurned, .kilocalorie(), .sum)
        async let restingTask = fetch(.basalEnergyBurned, .kilocalorie(), .sum)

        let (steps, flights, weights, active, resting) = try await (
            stepsTask, flightsTask, weightTask, activeTask, restingTask
        )

        // Every statistics bucket starts on one of these days, so iterating the
        // window is enough to cover everything HealthKit returned.
        let formatter = HealthDataPoint.dateFormatter
        var days: [String] = []
        var current = start
        while current < startOfTomorrow {
            days.append(formatter.string(from: current))
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else {
                throw HealthKitError.queryFailed("the date range couldn't be stepped through")
            }
            current = next
        }

        return try Self.dataPoints(
            days: days, steps: steps, flights: flights, weights: weights, active: active, resting: resting)
    }

    /// One point per day in `days`: counts and energies default to 0 on days without
    /// samples, weight is nil. Throws `noData` when no type has a sample on any day,
    /// rather than handing back a window of zeros that would replace real days in an
    /// existing year file or on the server.
    static func dataPoints(
        days: [String],
        steps: [String: Double],
        flights: [String: Double],
        weights: [String: Double],
        active: [String: Double],
        resting: [String: Double]
    ) throws(HealthKitError) -> [HealthDataPoint] {
        guard !(steps.isEmpty && flights.isEmpty && weights.isEmpty && active.isEmpty && resting.isEmpty)
        else {
            throw .noData
        }

        func count(_ values: [String: Double], _ day: String) -> Int {
            Int((values[day] ?? 0).rounded())
        }

        return days.map { day in
            HealthDataPoint(
                date: day,
                stepCount: count(steps, day),
                flightsClimbed: count(flights, day),
                weightKg: weights[day].map(HealthDataPoint.roundedWeight),
                caloriesActive: count(active, day),
                caloriesResting: count(resting, day)
            )
        }
    }
}
