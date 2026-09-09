import Foundation
import SwiftUI
import HealthKit

@MainActor
final class AppViewModel: ObservableObject {
    // MARK: - Published State
    @Published var lastExportResult: ExportResult?

    var lastExportDate: Date? {
        guard case .success(let date, _) = lastExportResult else { return nil }
        return date
    }
    @Published var isExporting = false
    @Published var isAuthorized = false
    @Published var authorizationError: String?
    @Published var statusMessage = "Not exported yet"

    // MARK: - AppStorage Settings
    @AppStorage("exportMode") var exportMode: String = ExportMode.http.rawValue
    @AppStorage("httpURL") var httpURL: String = ""
    @AppStorage("lookbackDays") var lookbackDaysRaw: Int = LookbackPeriod.oneYear.rawValue

    // MARK: - Keychain-backed Token
    @Published var httpToken: String = KeychainService.load(key: "httpToken") {
        didSet { KeychainService.save(key: "httpToken", value: httpToken) }
    }

    // MARK: - Services
    private let healthKitService = HealthKitService()
    private let exportService = ExportService()

    // MARK: - Computed
    var currentMode: ExportMode {
        ExportMode(rawValue: exportMode) ?? .http
    }

    var currentLookback: LookbackPeriod {
        LookbackPeriod(rawValue: lookbackDaysRaw) ?? .oneYear
    }

    var currentConfig: ExportConfiguration {
        ExportConfiguration(
            mode: currentMode,
            httpURL: httpURL,
            httpToken: httpToken,
            lookbackDays: currentLookback.rawValue
        )
    }

    // MARK: - Authorization
    func requestAuthorization() async {
        do {
            try await healthKitService.requestAuthorization()
            isAuthorized = true
            authorizationError = nil
        } catch {
            authorizationError = error.localizedDescription
            isAuthorized = false
        }
    }

    // MARK: - Export
    func exportNow() async {
        guard !isExporting else { return }
        isExporting = true
        statusMessage = "Exporting…"

        defer { isExporting = false }

        let config = currentConfig

        do {
            // HealthKit only prompts for types the user hasn't decided on yet, so this
            // picks up newly added types for existing users and is otherwise a no-op.
            if !isAuthorized {
                try await healthKitService.requestAuthorization()
                isAuthorized = true
                authorizationError = nil
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
            statusMessage = "Fetch failed"
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
