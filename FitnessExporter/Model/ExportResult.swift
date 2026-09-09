import Foundation

/// A value-type error that snapshots the underlying error's message so it can be
/// stored, compared and displayed without holding on to the original error.
struct ExportError: LocalizedError, Sendable {
    let message: String
    var errorDescription: String? { message }

    init(_ error: any Error) {
        self.message = error.localizedDescription
    }

    init(message: String) {
        self.message = message
    }
}

enum ExportResult: Sendable {
    case success(exportedAt: Date, recordCount: Int)
    case failure(ExportError)
}
