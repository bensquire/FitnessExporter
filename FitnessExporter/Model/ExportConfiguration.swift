import Foundation

enum ExportMode: String, CaseIterable, Codable, Sendable {
    case http
    case file

    var displayName: String {
        switch self {
        case .http: return "HTTP Endpoint"
        case .file: return "Local File"
        }
    }
}

enum LookbackPeriod: Int, CaseIterable, Codable, Sendable {
    case oneDay = 1
    case sevenDays = 7
    case oneMonth = 30
    case oneYear = 365
    case allTime = 3650

    var displayName: String {
        switch self {
        case .oneDay: return "1 Day"
        case .sevenDays: return "7 Days"
        case .oneMonth: return "1 Month"
        case .oneYear: return "1 Year"
        case .allTime: return "All Time"
        }
    }
}

/// The settings, snapshotted on the main actor before an export crosses into the services.
struct ExportConfiguration: Sendable {
    var mode: ExportMode
    var httpURL: String
    var httpToken: String
    var lookbackDays: Int
}
