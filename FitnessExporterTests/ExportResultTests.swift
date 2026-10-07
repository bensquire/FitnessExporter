import Foundation
import Testing

struct ExportErrorTests {
    @Test func messageFromString() {
        // Act
        let error = ExportError(message: "Something went wrong")

        // Assert
        #expect(error.message == "Something went wrong")
        #expect(error.localizedDescription == "Something went wrong")
    }

    @Test func messageFromUnderlyingError() {
        // Arrange
        let underlying = URLError(.badURL)

        // Act
        let error = ExportError(underlying)

        // Assert
        #expect(error.message == underlying.localizedDescription)
    }

    @Test func messageSurvivesErasureToAnyError() {
        // Arrange
        let erased: any Error = ExportError(message: "disk full")

        // Act
        let description = erased.localizedDescription

        // Assert — must not fall back to the generic NSError description
        #expect(description == "disk full")
    }

    @Test func wrapsFileExporterErrorWithReadableMessage() {
        // Act
        let error = ExportError(FileExporterError.writeFailed("no space left"))

        // Assert
        #expect(error.message == "Couldn't save the export file: no space left. Try exporting again.")
    }

    @Test func wrapsHealthKitErrorWithReadableMessage() {
        // Act
        let error = ExportError(HealthKitError.queryFailed("timeout"))

        // Assert
        #expect(error.message == "Couldn't read from Health: timeout. Try exporting again.")
    }

    @Test func wrapsAnyError() {
        // Arrange
        struct CustomError: Error, LocalizedError {
            var errorDescription: String? { "custom error" }
        }

        // Act
        let error = ExportError(CustomError())

        // Assert
        #expect(error.message == "custom error")
    }
}

struct ExportResultTests {
    @Test func successStoresExportedAtAndCount() {
        // Arrange
        let date = Date()

        // Act
        let result = ExportResult.success(exportedAt: date, recordCount: 42)

        // Assert
        if case .success(let exportedAt, let count) = result {
            #expect(exportedAt == date)
            #expect(count == 42)
        } else {
            Issue.record("Expected .success")
        }
    }

    @Test func failureStoresMessage() {
        // Arrange
        let error = ExportError(message: "disk full")

        // Act
        let result = ExportResult.failure(error)

        // Assert
        if case .failure(let e) = result {
            #expect(e.message == "disk full")
        } else {
            Issue.record("Expected .failure")
        }
    }
}
