import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    // MARK: - Published State
    @Published var lastExportResult: ExportResult?

    var lastExportDate: Date? {
        guard case .success(let date, _) = lastExportResult else { return nil }
        return date
    }
    @Published var isExporting = false
    /// Whether the Health permission sheet has been shown for every type the app
    /// reads. Not whether access was granted: HealthKit never reveals a denied read.
    @Published var hasRequestedHealthAccess = false
    @Published var authorizationError: String?
    @Published var statusMessage = "Not exported yet"

    // MARK: - AppStorage Settings
    @AppStorage("exportMode") var exportMode: String = ExportMode.http.rawValue
    @AppStorage("httpURL") var httpURL: String = ""
    @AppStorage("lookbackDays") var lookbackDaysRaw: Int = LookbackPeriod.oneYear.rawValue

    // MARK: - Keychain-backed Token
    private static let tokenKey = "httpToken"
    @Published var httpToken: String = KeychainService().load(key: AppViewModel.tokenKey) {
        didSet { saveToken() }
    }
    /// Set when the last edit to the token couldn't be written to the Keychain.
    @Published var tokenSaveError: String?

    // MARK: - Services
    private let keychain = KeychainService()
    private let healthKitService = HealthKitService()
    private let exportService = ExportService()
    /// HealthKit only prompts for types the user hasn't decided on yet, so asking once
    /// per launch picks up newly added types for existing users and is otherwise a no-op.
    /// /documentation/healthkit/hkhealthstore/requestauthorization(toshare:read:completion:)
    private var requestedHealthAccessThisLaunch = false

    // MARK: - Computed
    var currentMode: ExportMode {
        ExportMode(rawValue: exportMode) ?? .http
    }

    var currentLookback: LookbackPeriod {
        LookbackPeriod(rawValue: lookbackDaysRaw) ?? .oneYear
    }

    /// Whether the settings screen should warn that the exporter will refuse the URL.
    /// Asks the exporter's own check, so the warning and the export can't disagree.
    var httpURLWillBeRefused: Bool {
        !httpURL.isEmpty && (try? HTTPExporter.endpoint(from: httpURL)) == nil
    }

    var currentConfig: ExportConfiguration {
        ExportConfiguration(
            mode: currentMode,
            httpURL: httpURL,
            httpToken: httpToken,
            lookbackDays: currentLookback.rawValue
        )
    }

    // MARK: - Token
    private func saveToken() {
        do {
            try keychain.save(key: Self.tokenKey, value: httpToken)
            tokenSaveError = nil
        } catch {
            tokenSaveError =
                "The token wasn't saved to the Keychain (\(error.localizedDescription)). "
                + "It will be used until the app quits."
        }
    }

    // MARK: - Authorization
    func refreshHealthAccessState() async {
        hasRequestedHealthAccess = await healthKitService.hasRequestedAuthorization()
    }

    func requestAuthorization() async {
        do {
            try await askForHealthAccess()
        } catch {
            authorizationError = error.localizedDescription
        }
    }

    /// Shows HealthKit's sheet for any type not decided yet, and records that it was asked.
    private func askForHealthAccess() async throws {
        try await healthKitService.requestAuthorization()
        requestedHealthAccessThisLaunch = true
        hasRequestedHealthAccess = true
        authorizationError = nil
    }

    // MARK: - Export
    func exportNow() async {
        guard !isExporting else { return }
        isExporting = true
        statusMessage = "Exporting…"

        defer { isExporting = false }

        let config = currentConfig

        do {
            if !requestedHealthAccessThisLaunch {
                try await askForHealthAccess()
            }

            let data = try await healthKitService.fetchHealthData(lookbackDays: config.lookbackDays)
            let result = await exportService.export(data: data, config: config)

            lastExportResult = result
            switch result {
            case .success(_, let count):
                statusMessage = "Exported \(count) days"
            case .failure(let error):
                statusMessage = "Export failed"
                #if DEBUG
                    print("Export error: \(error.message)")
                #endif
            }
        } catch {
            let exportError = ExportError(error)
            lastExportResult = .failure(exportError)
            statusMessage =
                (error as? HealthKitError) == .noData ? "No health data found" : "Couldn't read Health data"
            #if DEBUG
                print("HealthKit fetch error: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Test Export
    @Published var isTestExporting = false
    @Published var testExportResult: ExportResult?

    func sendTestExport() async {
        guard !isTestExporting else { return }
        isTestExporting = true
        testExportResult = nil
        defer { isTestExporting = false }

        let today = Date()
        let calendar = Calendar.current
        let mockData: [HealthDataPoint] = (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return HealthDataPoint(
                date: HealthDataPoint.dateFormatter.string(from: date),
                stepCount: Int.random(in: 4000...12000),
                flightsClimbed: Int.random(in: 0...20),
                weightKg: HealthDataPoint.roundedWeight(Double.random(in: 60...100)),
                caloriesActive: Int.random(in: 200...900),
                caloriesResting: Int.random(in: 1400...2000)
            )
        }

        let result = await exportService.export(data: mockData, config: currentConfig)
        testExportResult = result
    }

}
