import Foundation

enum FileExporterError: LocalizedError, Sendable {
    case readFailed(String)
    case existingFileCorrupt(String)
    case encodingFailed(String)
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .readFailed(let detail):
            return "Could not read existing export file: \(detail)"
        case .existingFileCorrupt(let fileName):
            return
                "Existing file \(fileName) is not a valid export and was left untouched. Move or delete it and try again."
        case .encodingFailed(let detail):
            return "Could not encode export data: \(detail)"
        case .writeFailed(let detail):
            return "Could not write export file: \(detail)"
        }
    }
}

struct FileExporter: Sendable {
    /// Returns the app's Documents directory URL.
    static let documentsDirectory: URL =
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    /// Directory that per-year JSON files are written to. Injectable for tests.
    let directoryURL: URL

    init(directoryURL: URL = FileExporter.documentsDirectory) {
        self.directoryURL = directoryURL
    }

    /// Writes `data` into one `<year>.json` file per year, merging with any
    /// data already in that file. Days present in `data` replace the same
    /// days in the file; days only in the file are preserved.
    /// Returns the number of points from `data` that were exported.
    func export(data: [HealthDataPoint], config: ExportConfiguration) async throws -> Int {
        // Group data by year
        let byYear = Dictionary(grouping: data) { point -> Int in
            let parts = point.date.split(separator: "-")
            return Int(parts.first ?? "0") ?? 0
        }

        let now = Date()
        let encoder = ExportService.makeEncoder()
        let decoder = ExportService.makeDecoder()

        var exportedCount = 0
        for (year, points) in byYear {
            let fileURL = directoryURL.appendingPathComponent("\(year).json")

            // Later entries win, so new points replace existing ones for the same date.
            let existing = try loadExistingPoints(at: fileURL, using: decoder)
            let mergedByDate = Dictionary((existing + points).map { ($0.date, $0) }, uniquingKeysWith: { $1 })

            let export = YearExport(
                year: year,
                exportedAt: now,
                data: mergedByDate.values.sorted { $0.date < $1.date }
            )

            let jsonData: Data
            do {
                jsonData = try encoder.encode(export)
            } catch {
                throw FileExporterError.encodingFailed(error.localizedDescription)
            }

            do {
                try jsonData.write(to: fileURL, options: .atomic)
            } catch {
                throw FileExporterError.writeFailed(error.localizedDescription)
            }

            exportedCount += points.count
        }

        return exportedCount
    }

    /// Loads the data points from an existing year file, or an empty array if
    /// the file does not exist. Throws if the file exists but cannot be read or
    /// decoded, so that a bad file is never silently overwritten.
    private func loadExistingPoints(at fileURL: URL, using decoder: JSONDecoder) throws -> [HealthDataPoint] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw FileExporterError.readFailed(error.localizedDescription)
        }

        do {
            return try decoder.decode(YearExport.self, from: data).data
        } catch {
            throw FileExporterError.existingFileCorrupt(fileURL.lastPathComponent)
        }
    }
}
