import Testing
import Foundation

/// Each test gets a fresh temp directory; Swift Testing instantiates the suite per test.
final class FileExporterTests {
    private let dir: URL
    private let exporter: FileExporter

    init() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileExporterTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        exporter = FileExporter(directoryURL: dir)
    }

    deinit {
        try? FileManager.default.removeItem(at: dir)
    }

    private func readYear(_ year: Int) throws -> YearExport {
        let data = try Data(contentsOf: dir.appendingPathComponent("\(year).json"))
        return try ExportService.makeDecoder().decode(YearExport.self, from: data)
    }

    @Test func writesOneFilePerYearSortedByDate() async throws {
        // Arrange
        let points = [
            HealthDataPoint(date: "2026-01-02", stepCount: 200, flightsClimbed: 2),
            HealthDataPoint(date: "2025-12-31", stepCount: 100, flightsClimbed: 1),
            HealthDataPoint(date: "2026-01-01", stepCount: 150, flightsClimbed: 0),
        ]

        // Act
        let count = try await exporter.export(data: points, config: makeConfig(mode: .file))

        // Assert
        #expect(count == 3)
        let y2025 = try readYear(2025)
        let y2026 = try readYear(2026)
        #expect(y2025.year == 2025)
        #expect(y2025.data.map(\.date) == ["2025-12-31"])
        #expect(y2026.year == 2026)
        #expect(y2026.data.map(\.date) == ["2026-01-01", "2026-01-02"])
    }

    @Test func mergesWithExistingFilePreservingOlderDays() async throws {
        // Arrange — a previous export covering January
        let january = [
            HealthDataPoint(date: "2026-01-01", stepCount: 1_000, flightsClimbed: 1),
            HealthDataPoint(date: "2026-01-02", stepCount: 2_000, flightsClimbed: 2),
        ]
        _ = try await exporter.export(data: january, config: makeConfig(mode: .file))

        // Act — a later, narrower export that overlaps one day and adds one
        let later = [
            HealthDataPoint(date: "2026-01-02", stepCount: 2_500, flightsClimbed: 3),
            HealthDataPoint(date: "2026-01-03", stepCount: 3_000, flightsClimbed: 4),
        ]
        let count = try await exporter.export(data: later, config: makeConfig(mode: .file))

        // Assert — old day kept, overlapping day replaced, new day added
        #expect(count == 2)
        let merged = try readYear(2026)
        #expect(merged.data == [
            HealthDataPoint(date: "2026-01-01", stepCount: 1_000, flightsClimbed: 1),
            HealthDataPoint(date: "2026-01-02", stepCount: 2_500, flightsClimbed: 3),
            HealthDataPoint(date: "2026-01-03", stepCount: 3_000, flightsClimbed: 4),
        ])
    }

    @Test func mergesIntoLegacyFileWrittenBeforeNewerFieldsExisted() async throws {
        // Arrange — a v1.0 year file with only the original three fields
        let legacy = Data("""
        {
          "year" : 2026,
          "exportedAt" : "2026-01-03T00:00:00Z",
          "data" : [
            { "date" : "2026-01-01", "flightsClimbed" : 4, "stepCount" : 8542 }
          ]
        }
        """.utf8)
        try legacy.write(to: dir.appendingPathComponent("2026.json"))
        let newer = [
            HealthDataPoint(
                date: "2026-01-02", stepCount: 100, flightsClimbed: 1,
                weightKg: 80.5, caloriesActive: 400, caloriesResting: 1_500
            )
        ]

        // Act
        let count = try await exporter.export(data: newer, config: makeConfig(mode: .file))

        // Assert — legacy day preserved with defaults, new day written with all fields
        #expect(count == 1)
        let merged = try readYear(2026)
        #expect(merged.data.count == 2)
        #expect(merged.data[0] == HealthDataPoint(date: "2026-01-01", stepCount: 8_542, flightsClimbed: 4))
        #expect(merged.data[1] == newer[0])
    }

    @Test func refusesToOverwriteCorruptExistingFile() async throws {
        // Arrange
        let fileURL = dir.appendingPathComponent("2026.json")
        let garbage = Data("not json".utf8)
        try garbage.write(to: fileURL)
        let points = [HealthDataPoint(date: "2026-05-05", stepCount: 1, flightsClimbed: 1)]

        // Act
        let error = try await #require(throws: FileExporterError.self) {
            try await exporter.export(data: points, config: makeConfig(mode: .file))
        }

        // Assert — error names the file and the file is untouched
        guard case .existingFileCorrupt(let name) = error else {
            Issue.record("Expected .existingFileCorrupt, got \(error)")
            return
        }
        #expect(name == "2026.json")
        #expect(error.localizedDescription.contains("2026.json"))
        #expect(try Data(contentsOf: fileURL) == garbage)
    }
}
