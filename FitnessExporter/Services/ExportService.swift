import Foundation

actor ExportService {
    private let httpExporter: HTTPExporter
    private let fileExporter: FileExporter

    init(httpExporter: HTTPExporter = HTTPExporter(), fileExporter: FileExporter = FileExporter()) {
        self.httpExporter = httpExporter
        self.fileExporter = fileExporter
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func export(data: [HealthDataPoint], config: ExportConfiguration) async -> ExportResult {
        do {
            let count: Int
            switch config.mode {
            case .http:
                count = try await httpExporter.export(data: data, config: config)
            case .file:
                count = try await fileExporter.export(data: data, config: config)
            }
            return .success(exportedAt: Date(), recordCount: count)
        } catch {
            return .failure(ExportError(error))
        }
    }
}
