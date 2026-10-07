import Foundation

/// Shared fixture builder for exporter tests.
func makeConfig(mode: ExportMode = .http, url: String = "", token: String = "") -> ExportConfiguration {
    ExportConfiguration(mode: mode, httpURL: url, httpToken: token, lookbackDays: 7)
}
