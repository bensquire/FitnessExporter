import Foundation

/// A reply from the endpoint that the exporter doesn't count as a delivery.
enum HTTPExporterError: LocalizedError, Equatable, Sendable {
    case unexpectedStatus(Int)

    var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let code):
            return "The server answered with HTTP \(code), so the export wasn't accepted."
        }
    }
}

struct HTTPExporter: Sendable {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// The endpoint the user typed, if the exporter will send to it. Only HTTPS is
    /// accepted: the body is health data and the request may carry a bearer token.
    /// The settings screen's warning uses this too, so the two can't disagree.
    static func endpoint(from string: String) throws -> URL {
        guard !string.isEmpty, let url = URL(string: string) else {
            throw URLError(.badURL)
        }
        guard url.scheme?.lowercased() == "https" else {
            throw URLError(.appTransportSecurityRequiresSecureConnection)
        }
        return url
    }

    func export(data: [HealthDataPoint], config: ExportConfiguration) async throws -> Int {
        let url = try Self.endpoint(from: config.httpURL)
        let body = try ExportService.makeEncoder().encode(data)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !config.httpToken.isEmpty {
            request.setValue("Bearer \(config.httpToken)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body

        let (_, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
            !(200..<300).contains(httpResponse.statusCode)
        {
            throw HTTPExporterError.unexpectedStatus(httpResponse.statusCode)
        }

        return data.count
    }
}
