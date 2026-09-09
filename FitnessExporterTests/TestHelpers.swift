import Foundation

/// Shared fixture builder for exporter tests.
func makeConfig(mode: ExportMode = .http, url: String = "") -> ExportConfiguration {
    ExportConfiguration(mode: mode, httpURL: url, httpToken: "", lookbackDays: 7)
}
