import Foundation

struct HTTPExporter: Sendable {
    func export(data: [HealthDataPoint], config: ExportConfiguration) async throws -> Int {
        guard !config.httpURL.isEmpty, let url = URL(string: config.httpURL) else {
            throw URLError(.badURL)
        }

        guard url.scheme == "https" else {
            throw URLError(.appTransportSecurityRequiresSecureConnection)
        }

        let body = try ExportService.makeEncoder().encode(data)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !config.httpToken.isEmpty {
            request.setValue("Bearer \(config.httpToken)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
            !(200..<300).contains(httpResponse.statusCode)
        {
            throw URLError(.badServerResponse)
        }

        return data.count
    }
}
