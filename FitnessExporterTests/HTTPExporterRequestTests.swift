import Foundation
import Synchronization
import Testing

/// Answers every request with one status and keeps what was sent, so the exporter's
/// request can be checked without a server. It is registered only on the sessions
/// `session(answering:)` makes, so nothing else is intercepted and nothing leaves the
/// machine.
final class StubURLProtocol: URLProtocol {
    private struct State {
        var status = 200
        var requests: [URLRequest] = []
    }

    private static let state = Mutex(State())

    static func session(answering status: Int) -> URLSession {
        state.withLock { $0 = State(status: status) }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    static var requests: [URLRequest] { state.withLock { $0.requests } }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        // The loading system hands the body over as a stream, not as httpBody.
        var sent = request
        if sent.httpBody == nil, let stream = request.httpBodyStream {
            sent.httpBody = Data(reading: stream)
        }
        let status = Self.state.withLock { state in
            state.requests.append(sent)
            return state.status
        }
        guard let url = request.url,
            let response = HTTPURLResponse(
                url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

extension Data {
    fileprivate init(reading stream: InputStream) {
        self.init()
        stream.open()
        defer { stream.close() }
        var buffer = [UInt8](repeating: 0, count: 4_096)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            guard read > 0 else { break }
            append(buffer, count: read)
        }
    }
}

/// Serialized because the stub keeps one shared record of what was sent.
@Suite(.serialized)
struct HTTPExporterRequestTests {
    private let point = HealthDataPoint(date: "2026-01-02", stepCount: 2_500, flightsClimbed: 3)

    private func config(token: String = "") -> ExportConfiguration {
        makeConfig(url: "https://example.test/export", token: token)
    }

    @Test func postsTheDataAsJSON() async throws {
        // Arrange
        let exporter = HTTPExporter(session: StubURLProtocol.session(answering: 200))

        // Act
        let count = try await exporter.export(data: [point], config: config())

        // Assert
        let request = try #require(StubURLProtocol.requests.first)
        let body = try #require(request.httpBody)
        #expect(count == 1)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(try ExportService.makeDecoder().decode([HealthDataPoint].self, from: body) == [point])
    }

    @Test func sendsTheTokenAsABearerHeader() async throws {
        // Arrange
        let exporter = HTTPExporter(session: StubURLProtocol.session(answering: 200))

        // Act
        _ = try await exporter.export(data: [point], config: config(token: "s3cret"))

        // Assert
        let request = try #require(StubURLProtocol.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer s3cret")
    }

    @Test func sendsNoAuthorizationHeaderWithoutAToken() async throws {
        // Arrange
        let exporter = HTTPExporter(session: StubURLProtocol.session(answering: 200))

        // Act
        _ = try await exporter.export(data: [point], config: config())

        // Assert
        let request = try #require(StubURLProtocol.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    /// The address is refused before any request is made, so nothing is sent.
    @Test(arguments: [
        ("", URLError.Code.badURL),
        ("not a url !!!", URLError.Code.appTransportSecurityRequiresSecureConnection),
        ("http://example.test/export", URLError.Code.appTransportSecurityRequiresSecureConnection),
    ])
    func sendsNothingToAnAddressItRefuses(address: String, expected: URLError.Code) async {
        // Arrange
        let exporter = HTTPExporter(session: StubURLProtocol.session(answering: 200))

        // Act
        let error = await #expect(throws: URLError.self) {
            try await exporter.export(data: [point], config: makeConfig(url: address))
        }

        // Assert
        #expect(error?.code == expected, "\(address.debugDescription)")
        #expect(StubURLProtocol.requests.isEmpty, "\(address.debugDescription) was sent")
    }

    @Test(arguments: [301, 401, 404, 500])
    func refusesAReplyOutside2xx(status: Int) async {
        // Arrange
        let exporter = HTTPExporter(session: StubURLProtocol.session(answering: status))

        // Act & Assert
        await #expect(throws: HTTPExporterError.unexpectedStatus(status)) {
            try await exporter.export(data: [point], config: config())
        }
    }

    @Test func aRefusedExportTellsTheUserTheServersStatus() async {
        // Arrange
        let session = StubURLProtocol.session(answering: 503)
        let service = ExportService(httpExporter: HTTPExporter(session: session))

        // Act
        let result = await service.export(data: [point], config: config())

        // Assert
        guard case .failure(let error) = result else {
            Issue.record("Expected a failure for HTTP 503, got \(result)")
            return
        }
        #expect(error.message == "The server answered with HTTP 503, so the export wasn't accepted.")
    }
}

/// The one HTTPS check that both the exporter and the settings screen's warning use.
struct HTTPExporterEndpointTests {
    @Test(arguments: ["https://example.test/export", "HTTPS://example.test/export"])
    func acceptsAnHTTPSAddress(address: String) throws {
        // Act
        let url = try HTTPExporter.endpoint(from: address)

        // Assert
        #expect(url.host() == "example.test", "\(address)")
    }

    @Test(arguments: ["http://example.test/export", "ftp://example.test/export", "example.test/export"])
    func refusesAnAddressThatIsNotHTTPS(address: String) {
        // Act
        let error = #expect(throws: URLError.self) { try HTTPExporter.endpoint(from: address) }

        // Assert
        #expect(error?.code == .appTransportSecurityRequiresSecureConnection, "\(address)")
    }

    @Test func refusesAnEmptyAddress() {
        // Act
        let error = #expect(throws: URLError.self) { try HTTPExporter.endpoint(from: "") }

        // Assert
        #expect(error?.code == .badURL)
    }
}
