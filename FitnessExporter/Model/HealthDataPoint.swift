import Foundation

/// One day's aggregated health data.
struct HealthDataPoint: Codable, Sendable, Equatable {
    /// ISO-8601 date string, format "yyyy-MM-dd"
    let date: String
    let stepCount: Int
    let flightsClimbed: Int
    /// Most recent weigh-in of the day in kilograms, or nil if there was none.
    /// Encoded only when present.
    let weightKg: Double?
    let caloriesActive: Int
    let caloriesResting: Int

    /// Active plus resting energy. Encoded for convenience, never decoded.
    var caloriesTotal: Int { caloriesActive + caloriesResting }

    init(
        date: String,
        stepCount: Int,
        flightsClimbed: Int,
        weightKg: Double? = nil,
        caloriesActive: Int = 0,
        caloriesResting: Int = 0
    ) {
        self.date = date
        self.stepCount = stepCount
        self.flightsClimbed = flightsClimbed
        self.weightKg = weightKg
        self.caloriesActive = caloriesActive
        self.caloriesResting = caloriesResting
    }

    private enum CodingKeys: String, CodingKey {
        case date
        case stepCount
        case flightsClimbed
        case weightKg
        case caloriesActive
        case caloriesResting
        case caloriesTotal
    }

    /// Fields added after the first release are optional on decode so that
    /// year files written by older versions still load and merge.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(String.self, forKey: .date)
        stepCount = try container.decode(Int.self, forKey: .stepCount)
        flightsClimbed = try container.decode(Int.self, forKey: .flightsClimbed)
        weightKg = try container.decodeIfPresent(Double.self, forKey: .weightKg)
        caloriesActive = try container.decodeIfPresent(Int.self, forKey: .caloriesActive) ?? 0
        caloriesResting = try container.decodeIfPresent(Int.self, forKey: .caloriesResting) ?? 0
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(stepCount, forKey: .stepCount)
        try container.encode(flightsClimbed, forKey: .flightsClimbed)
        try container.encodeIfPresent(weightKg, forKey: .weightKg)
        try container.encode(caloriesActive, forKey: .caloriesActive)
        try container.encode(caloriesResting, forKey: .caloriesResting)
        try container.encode(caloriesTotal, forKey: .caloriesTotal)
    }

    /// Rounds a weight in kilograms to the one-decimal precision used in exports.
    static func roundedWeight(_ kilograms: Double) -> Double {
        (kilograms * 10).rounded() / 10
    }

    /// Shared date formatter for "yyyy-MM-dd" health data dates.
    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        return f
    }()
}

/// Root object written to each year's JSON file.
struct YearExport: Codable, Sendable {
    let year: Int
    let exportedAt: Date
    let data: [HealthDataPoint]
}
