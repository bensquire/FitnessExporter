import Foundation
import Testing

struct HealthDataPointTests {
    @Test func codableRoundTrip() throws {
        // Arrange
        let point = HealthDataPoint(date: "2026-03-03", stepCount: 8_000, flightsClimbed: 5)

        // Act
        let data = try JSONEncoder().encode(point)
        let decoded = try JSONDecoder().decode(HealthDataPoint.self, from: data)

        // Assert
        #expect(decoded == point)
    }

    @Test func encodesToExpectedJSONKeys() throws {
        // Arrange
        let point = HealthDataPoint(date: "2026-03-03", stepCount: 8_000, flightsClimbed: 5)

        // Act
        let data = try JSONEncoder().encode(point)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        // Assert
        #expect(json["date"] as? String == "2026-03-03")
        #expect(json["stepCount"] as? Int == 8_000)
        #expect(json["flightsClimbed"] as? Int == 5)
    }

    @Test func encodesAllMetricsAndComputedTotal() throws {
        // Arrange
        let point = HealthDataPoint(
            date: "2026-03-03",
            stepCount: 8_000,
            flightsClimbed: 5,
            weightKg: 78.4,
            caloriesActive: 512,
            caloriesResting: 1_650
        )

        // Act
        let data = try ExportService.makeEncoder().encode(point)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        // Assert
        #expect(json["weightKg"] as? Double == 78.4)
        #expect(json["caloriesActive"] as? Int == 512)
        #expect(json["caloriesResting"] as? Int == 1_650)
        #expect(json["caloriesTotal"] as? Int == 2_162)
        #expect(point.caloriesTotal == point.caloriesActive + point.caloriesResting)
    }

    @Test func omitsWeightKeyWhenNil() throws {
        // Arrange
        let point = HealthDataPoint(date: "2026-03-03", stepCount: 1, flightsClimbed: 0)

        // Act
        let data = try JSONEncoder().encode(point)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        // Assert
        #expect(json["weightKg"] == nil)
        #expect(json["caloriesActive"] as? Int == 0)
        #expect(json["caloriesResting"] as? Int == 0)
        #expect(json["caloriesTotal"] as? Int == 0)
    }

    @Test func decodesLegacyJSONWithoutNewerFields() throws {
        // Arrange — shape written by v1.0
        let legacy = Data(
            """
            {"date":"2026-01-01","flightsClimbed":4,"stepCount":8542}
            """.utf8)

        // Act
        let point = try JSONDecoder().decode(HealthDataPoint.self, from: legacy)

        // Assert
        #expect(point == HealthDataPoint(date: "2026-01-01", stepCount: 8_542, flightsClimbed: 4))
        #expect(point.weightKg == nil)
        #expect(point.caloriesActive == 0)
        #expect(point.caloriesResting == 0)
    }

    @Test func ignoresTotalEnergyOnDecode() throws {
        // Arrange — a stale or tampered total must not survive a round trip
        let json = Data(
            """
            {"date":"2026-01-01","flightsClimbed":0,"stepCount":0,
             "caloriesActive":100,"caloriesResting":200,"caloriesTotal":999}
            """.utf8)

        // Act
        let point = try JSONDecoder().decode(HealthDataPoint.self, from: json)

        // Assert
        #expect(point.caloriesTotal == 300)
    }

    @Test func fullRoundTripPreservesAllFields() throws {
        // Arrange
        let point = HealthDataPoint(
            date: "2026-03-03",
            stepCount: 8_000,
            flightsClimbed: 5,
            weightKg: 78.4,
            caloriesActive: 512,
            caloriesResting: 1_650
        )

        // Act
        let data = try JSONEncoder().encode(point)
        let decoded = try JSONDecoder().decode(HealthDataPoint.self, from: data)

        // Assert
        #expect(decoded == point)
    }

    @Test func equalityByAllFields() {
        // Arrange
        let a = HealthDataPoint(date: "2026-01-01", stepCount: 100, flightsClimbed: 2)
        let b = HealthDataPoint(date: "2026-01-01", stepCount: 100, flightsClimbed: 2)
        let c = HealthDataPoint(date: "2026-01-01", stepCount: 999, flightsClimbed: 2)

        // Assert
        #expect(a == b)
        #expect(a != c)
    }
}

struct YearExportTests {
    @Test func codableRoundTrip() throws {
        // Arrange
        let points = [
            HealthDataPoint(date: "2026-01-01", stepCount: 5_000, flightsClimbed: 3),
            HealthDataPoint(date: "2026-01-02", stepCount: 7_500, flightsClimbed: 8),
        ]
        let export = YearExport(year: 2026, exportedAt: Date(timeIntervalSince1970: 0), data: points)

        // Act
        let data = try ExportService.makeEncoder().encode(export)
        let decoded = try ExportService.makeDecoder().decode(YearExport.self, from: data)

        // Assert
        #expect(decoded.year == 2026)
        #expect(decoded.data.count == 2)
        #expect(decoded.data[0] == points[0])
        #expect(decoded.data[1] == points[1])
    }
}
