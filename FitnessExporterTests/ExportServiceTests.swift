import Foundation
import Testing

struct ExportServiceEncoderTests {
    @Test func writesIndentedJSONWithSortedKeys() throws {
        // Act
        let data = try ExportService.makeEncoder().encode(["b": 2, "a": 1])

        // Assert
        #expect(String(decoding: data, as: UTF8.self) == "{\n  \"a\" : 1,\n  \"b\" : 2\n}")
    }

    @Test func dateEncodingStrategyIsISO8601() throws {
        // Arrange
        struct Wrapper: Encodable { let d: Date }
        let encoder = ExportService.makeEncoder()

        // Act
        let data = try encoder.encode(Wrapper(d: Date(timeIntervalSince1970: 0)))
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        // Assert — Unix epoch must encode to a known ISO8601 string
        #expect(json["d"] as? String == "1970-01-01T00:00:00Z")
    }

    @Test func keysAreSortedAlphabeticallyInOutput() throws {
        // Arrange
        let points = [HealthDataPoint(date: "2026-01-01", stepCount: 100, flightsClimbed: 2)]

        // Act
        let data = try ExportService.makeEncoder().encode(points)
        let jsonString = try #require(String(data: data, encoding: .utf8))

        // Assert — "date" < "flightsClimbed" < "stepCount" alphabetically
        let dateIdx = try #require(jsonString.range(of: "\"date\""))
        let flightsIdx = try #require(jsonString.range(of: "\"flightsClimbed\""))
        let stepsIdx = try #require(jsonString.range(of: "\"stepCount\""))
        #expect(dateIdx.lowerBound < flightsIdx.lowerBound)
        #expect(flightsIdx.lowerBound < stepsIdx.lowerBound)
    }
}
